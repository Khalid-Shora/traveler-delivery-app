/* eslint-disable */
const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

// ---------- Stripe setup (ENV first, then legacy functions.config()) ----------
let cfg = {};
try { cfg = functions.config ? functions.config() : {}; } catch (_) {}

const STRIPE_SECRET =
  process.env.STRIPE_SECRET || (cfg.stripe && cfg.stripe.secret) || null;

const STRIPE_WEBHOOK_SECRET =
  process.env.STRIPE_WEBHOOK_SECRET || (cfg.stripe && cfg.stripe.webhook_secret) || null;

let stripe = null;
if (STRIPE_SECRET) {
  try {
    stripe = require('stripe')(STRIPE_SECRET);
  } catch (e) {
    console.error('Stripe init failed:', e);
  }
}

// ---------- Scraper ----------
const { scrapeProduct } = require('./scraper');

// Helpers we previously expected from scraper.js
function normalizeUrl(url) {
  try {
    if (!url || typeof url !== 'string') return null;
    const u = new URL(url);
    // normalize basic stuff
    u.hash = '';
    return u.toString();
  } catch {
    return null;
  }
}
function detectStore(url) {
  try {
    const h = new URL(url).host.toLowerCase().replace(/^www\./, '');
    if (h.includes('amazon.')) return 'amazon';
    if (h.includes('noon.')) return 'noon';
    if (h.includes('shein.')) return 'shein';
    if (h.includes('temu.')) return 'temu';
    if (h.includes('trendyol.')) return 'trendyol';
    return h;
  } catch { return ''; }
}

// ---------- Firebase / Express ----------
admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(cors({ origin: true }));

// Keep raw body only for /webhook; JSON everywhere else
app.use((req, res, next) => {
  if (req.originalUrl === '/webhook') return next();
  return bodyParser.json({ limit: '1mb' })(req, res, next);
});

const RUNTIME_OPTS = { memory: '1GB', timeoutSeconds: 120 };

// ===================== Stripe =====================

app.post('/create-payment-intent', async (req, res) => {
  try {
    if (!stripe) return res.status(501).json({ error: 'Stripe not configured' });

    const { amount, currency, buyerId, orderId } = req.body || {};
    if (!amount || !currency || !buyerId || !orderId) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
      metadata: { buyerId, orderId },
    });
    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (err) {
    console.error('create-payment-intent error:', err);
    res.status(400).json({ error: err.message || String(err) });
  }
});

app.post('/webhook', bodyParser.raw({ type: 'application/json' }), async (req, res) => {
  if (!stripe || !STRIPE_WEBHOOK_SECRET) {
    return res.status(501).json({ error: 'Stripe webhook not configured' });
  }

  let event;
  try {
    const signature = req.headers['stripe-signature'];
    event = stripe.webhooks.constructEvent(req.body, signature, STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.error('Webhook signature verification failed.', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    if (event.type === 'payment_intent.succeeded') {
      const pi = event.data.object;
      const { buyerId, orderId } = pi.metadata || {};
      const amount = pi.amount;

      await db.collection('payments').add({
        buyerId,
        orderId,
        amount,
        status: 'paid',
        stripe_payment_intent: pi.id,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      if (orderId) {
        await db.collection('orders').doc(orderId).set(
          {
            paymentStatus: 'paid',
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
            paymentIntentId: pi.id,
          },
          { merge: true }
        );
      }
    }
    res.json({ received: true });
  } catch (e) {
    console.error('Webhook handling error:', e);
    res.status(500).json({ error: 'Webhook handling failed' });
  }
});

app.get('/buyer-payments/:buyerId', async (req, res) => {
  try {
    const buyerId = req.params.buyerId;
    const snap = await db.collection('payments').where('buyerId', '==', buyerId).get();
    const payments = snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json(payments);
  } catch (e) {
    console.error('buyer-payments error:', e);
    res.status(500).json({ error: 'Failed to fetch payments' });
  }
});

// ===================== Scraping =====================

// Preflight support
app.options('/scrape-product', (req, res) => res.sendStatus(204));

// POST /scrape-product  { url }
app.post('/scrape-product', async (req, res) => {
  try {
    const { url } = req.body || {};
    const cleanUrl = normalizeUrl(url);
    if (!cleanUrl) return res.status(400).json({ ok: false, error: 'Invalid or missing url' });

    const result = await scrapeProduct(cleanUrl);
    if (!result || (!result.title && !result.image)) {
      return res.status(422).json({ ok: false, error: 'Could not extract product data' });
    }

    const payload = {
      ok: true,
      id: '',
      name: result.title || '',
      imageUrl: result.image || '',
      price: result.price ?? 0,
      currency: result.currency || '',
      store: detectStore(cleanUrl),
      description: result.description || '',
      link: cleanUrl,
      rawPriceText: result.rawPriceText || null,
      source: result.source || null,
    };

    return res.json(payload);
  } catch (err) {
    console.error('Scrape error:', err);
    return res.status(500).json({ ok: false, error: err.message || String(err) });
  }
});

// GET /scrape-product?url=...
app.get('/scrape-product', async (req, res) => {
  try {
    const cleanUrl = normalizeUrl(req.query.url);
    if (!cleanUrl) return res.status(400).json({ ok: false, error: 'Invalid or missing url' });

    const result = await scrapeProduct(cleanUrl);
    if (!result || (!result.title && !result.image)) {
      return res.status(422).json({ ok: false, error: 'Could not extract product data' });
    }

    const payload = {
      ok: true,
      id: '',
      name: result.title || '',
      imageUrl: result.image || '',
      price: result.price ?? 0,
      currency: result.currency || '',
      store: detectStore(cleanUrl),
      description: result.description || '',
      link: cleanUrl,
      rawPriceText: result.rawPriceText || null,
      source: result.source || null,
    };

    return res.json(payload);
  } catch (err) {
    console.error('Scrape error (GET):', err);
    return res.status(500).json({ ok: false, error: err.message || String(err) });
  }
});

app.post('/scrape-and-save', async (req, res) => {
  try {
    const { url, requestedBy } = req.body || {};
    const cleanUrl = normalizeUrl(url);
    if (!cleanUrl) return res.status(400).json({ ok: false, error: 'Invalid or missing url' });

    const result = await scrapeProduct(cleanUrl);
    if (!result || (!result.title && !result.image)) {
      return res.status(422).json({ ok: false, error: 'Could not extract product data' });
    }

    const doc = {
      title: result.title || '',
      image: result.image || '',
      price: result.price ?? 0,
      currency: result.currency || '',
      description: result.description || '',
      url: cleanUrl,
      store: detectStore(cleanUrl),
      requestedBy: requestedBy || null,
      fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
      rawPriceText: result.rawPriceText || null,
      source: result.source || null,
    };

    const ref = await db.collection('scraped_products').add(doc);
    return res.json({ ok: true, id: ref.id, ...doc });
  } catch (err) {
    console.error('Scrape+Save error:', err);
    return res.status(500).json({ ok: false, error: err.message || String(err) });
  }
});

// ===================== Health =====================
app.get('/', (_, res) => res.send('Delivery App API running!'));
app.get('/health', (_, res) =>
  res.json({ ok: true, node: process.version, stripe: !!stripe, time: new Date().toISOString() })
);

// ===================== Export =====================
exports.api = functions
  .region('us-central1')
  .runWith(RUNTIME_OPTS)
  .https.onRequest(app);
