/* functions/scraper.js
 * Robust scraper with two strategies:
 * 1) Fast static fetch (Axios + Cheerio) with host-specific extractors
 * 2) Fallback headless (Puppeteer + @sparticuz/chromium) for JS-heavy pages
 *
 * Exports: scrapeProduct(url: string) -> { ok, title, price, currency, image, brand, source, rawPriceText }
 */

const axios = require('axios');
const cheerio = require('cheerio');
const chromium = require('@sparticuz/chromium');
const puppeteer = require('puppeteer-core');

const DEFAULT_UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36';

function hostOf(url) {
  try { return new URL(url).host.toLowerCase(); } catch { return ''; }
}
function domain(url) {
  const h = hostOf(url);
  return h.replace(/^www\./, '');
}

function normalizeCurrency(txt = '') {
  const t = (txt || '').trim();
  if (!t) return null;
  if (/[€]/.test(t)) return 'EUR';
  if (/[£]/.test(t)) return 'GBP';
  if (/[$]/.test(t)) return 'USD';
  if (/\bAED\b/i.test(t)) return 'AED';
  if (/\bSAR\b/i.test(t)) return 'SAR';
  if (/\bQAR\b/i.test(t)) return 'QAR';
  if (/\bKWD\b/i.test(t)) return 'KWD';
  if (/\bBHD\b/i.test(t)) return 'BHD';
  if (/\bOMR\b/i.test(t)) return 'OMR';
  const m = t.match(/\b([A-Z]{3})\b/);
  return m ? m[1] : null;
}

function parsePrice(txt = '') {
  if (!txt) return { price: null, raw: null, currency: null };
  const raw = txt.replace(/\s+/g, ' ').trim();
  const currency = normalizeCurrency(raw);
  let num = raw.replace(/[^\d.,]/g, '').trim();

  if (num.includes(',') && num.includes('.')) {
    const lastComma = num.lastIndexOf(',');
    const lastDot = num.lastIndexOf('.');
    if (lastComma < lastDot) {
      num = num.replace(/,/g, '');
    } else {
      num = num.replace(/\./g, '').replace(',', '.');
    }
  } else if (num.includes(',')) {
    const parts = num.split(',');
    if (parts.length > 1 && parts[parts.length - 1].length === 2) {
      num = parts.slice(0, -1).join('') + '.' + parts[parts.length - 1];
    } else {
      num = num.replace(/,/g, '');
    }
  }

  const val = parseFloat(num);
  return Number.isFinite(val)
    ? { price: val, raw, currency }
    : { price: null, raw, currency };
}

function firstTruthy(...vals) { for (const v of vals) if (v) return v; return null; }

// ---------- Generic extractors (JSON-LD + meta) ----------

function extractFromJsonLd($, url) {
  const scripts = $('script[type="application/ld+json"]');
  for (const el of scripts.toArray()) {
    try {
      const json = JSON.parse($(el).contents().text());
      const nodes = Array.isArray(json) ? json : [json];
      for (const node of nodes) {
        const t = node['@type'];
        const type = Array.isArray(t) ? t[0] : t;
        if (!type) continue;
        if (String(type).toLowerCase() === 'product') {
          const title = node.name || node.title || null;
          const brand = (node.brand && (node.brand.name || node.brand)) || null;
          const image = Array.isArray(node.image) ? node.image[0] : node.image || null;

          let priceTxt = null, currency = null;
          if (node.offers) {
            const offersArr = Array.isArray(node.offers) ? node.offers : [node.offers];
            for (const offer of offersArr) {
              if (!offer) continue;
              priceTxt = firstTruthy(offer.price, offer.priceSpecification && offer.priceSpecification.price);
              currency = firstTruthy(offer.priceCurrency, offer.priceSpecification && offer.priceSpecification.priceCurrency);
              if (priceTxt) break;
            }
          }

          const priceObj = parsePrice(String(priceTxt || ''));
          const finalCurrency = priceObj.currency || normalizeCurrency(String(currency || ''));

          return {
            title,
            brand: brand ? String(brand) : null,
            image,
            price: priceObj.price,
            currency: finalCurrency,
            rawPriceText: priceObj.raw || String(priceTxt || ''),
            source: hostOf(url),
          };
        }
      }
    } catch { /* ignore */ }
  }
  return null;
}

function extractFromMeta($, url) {
  const ogTitle = $('meta[property="og:title"]').attr('content');
  const ogImage = $('meta[property="og:image"]').attr('content');
  const metaTitle = $('title').first().text();

  const priceSelectors = [
    'meta[itemprop=price]',
    'meta[property="product:price:amount"]',
    'meta[name=price]',
    'meta[name=product:price:amount]',
  ];
  let priceTxt = null;
  for (const sel of priceSelectors) {
    const v = $(sel).attr('content');
    if (v) { priceTxt = v; break; }
  }
  if (!priceTxt) {
    const priceLike = $('[class*="price"], [id*="price"]').first().text().trim();
    if (priceLike) priceTxt = priceLike;
  }

  const priceObj = parsePrice(priceTxt || '');
  const currency =
    priceObj.currency ||
    normalizeCurrency(
      $('meta[property="product:price:currency"]').attr('content') ||
      $('meta[itemprop=priceCurrency]').attr('content') ||
      ''
    );

  return {
    title: firstTruthy(ogTitle, metaTitle),
    brand: null,
    image: ogImage || null,
    price: priceObj.price,
    currency,
    rawPriceText: priceObj.raw || priceTxt || null,
    source: hostOf(url),
  };
}

// ---------- Host-specific extractors (STATIC HTML) ----------

function extractAmazon($, url) {
  // Title
  const title = $('#productTitle').text().trim()
    || $('meta[name="title"]').attr('content')
    || $('title').text().trim();

  // Price (multiple places)
  const priceTxt =
    $('#corePriceDisplay_desktop_feature_div .a-offscreen').first().text().trim()
    || $('#apex_desktop .a-price .a-offscreen').first().text().trim()
    || $('#priceblock_ourprice').text().trim()
    || $('#priceblock_dealprice').text().trim()
    || $('span.a-price-whole').first().text().trim()
    || $('meta[itemprop=price]').attr('content')
    || $('[data-asin-price]').attr('data-asin-price')
    || '';

  const img =
    $('#landingImage').attr('data-old-hires')
    || $('#landingImage').attr('src')
    || $('img#imgBlkFront').attr('src')
    || $('meta[property="og:image"]').attr('content')
    || null;

  const brand =
    $('#bylineInfo').text().replace(/^Visit the /i, '').replace(/ Store$/i, '').trim()
    || $('tr.po-brand td.a-span9 .a-size-base').first().text().trim()
    || null;

  const priceObj = parsePrice(priceTxt);
  return {
    title: title || null,
    brand: brand || null,
    image: img,
    price: priceObj.price,
    currency: priceObj.currency || normalizeCurrency(priceTxt),
    rawPriceText: priceObj.raw || priceTxt || null,
    source: hostOf(url),
  };
}

function extractShein($, url) {
  // JSON-LD is usually present
  const ld = extractFromJsonLd($, url);
  if (ld && (ld.title || ld.price)) return ld;

  const title =
    $('h1.product-intro__head-name').text().trim()
    || $('meta[property="og:title"]').attr('content')
    || $('title').text().trim();

  const priceTxt =
    $('span[shepname=originalPrice]').text().trim()
    || $('span[itemprop=price]').attr('content')
    || $('meta[property="product:price:amount"]').attr('content')
    || $('[class*=price]').first().text().trim();

  const img =
    $('meta[property="og:image"]').attr('content')
    || $('img.product-intro__cover-image').attr('src')
    || null;

  const priceObj = parsePrice(priceTxt);
  return {
    title: title || null,
    brand: null,
    image: img,
    price: priceObj.price,
    currency: priceObj.currency || normalizeCurrency(priceTxt),
    rawPriceText: priceObj.raw || priceTxt || null,
    source: hostOf(url),
  };
}

function extractNoon($, url) {
  const ld = extractFromJsonLd($, url);
  if (ld && (ld.title || ld.price)) return ld;

  const title =
    $('h1 strong').first().text().trim()
    || $('meta[property="og:title"]').attr('content')
    || $('title').text().trim();

  const priceTxt =
    $('meta[itemprop=price]').attr('content')
    || $('[data-qa="price"]').first().text().trim()
    || $('[class*=price]').first().text().trim();

  const img =
    $('meta[property="og:image"]').attr('content')
    || $('img[itemprop=image]').attr('src')
    || null;

  const priceObj = parsePrice(priceTxt);
  return {
    title: title || null,
    brand: null,
    image: img,
    price: priceObj.price,
    currency: priceObj.currency || normalizeCurrency(priceTxt) || 'AED',
    rawPriceText: priceObj.raw || priceTxt || null,
    source: hostOf(url),
  };
}

function extractTrendyol($, url) {
  const ld = extractFromJsonLd($, url);
  if (ld && (ld.title || ld.price)) return ld;

  const title =
    $('h1.pr-new-br span').last().text().trim()
    || $('meta[property="og:title"]').attr('content')
    || $('title').text().trim();

  const priceTxt =
    $('span.prc-dsc').text().trim()
    || $('span.prc-org').text().trim()
    || $('meta[itemprop=price]').attr('content')
    || $('[class*=price]').first().text().trim();

  const img =
    $('meta[property="og:image"]').attr('content')
    || $('img[itemprop=image]').attr('src')
    || null;

  const priceObj = parsePrice(priceTxt);
  return {
    title: title || null,
    brand: null,
    image: img,
    price: priceObj.price,
    currency: priceObj.currency || normalizeCurrency(priceTxt),
    rawPriceText: priceObj.raw || priceTxt || null,
    source: hostOf(url),
  };
}

// ---------- Static fetch ----------

async function fetchHtml(url) {
  const res = await axios.get(url, {
    headers: { 'User-Agent': DEFAULT_UA, Accept: 'text/html' },
    timeout: 14000,
    maxRedirects: 5,
    validateStatus: (s) => s >= 200 && s < 400,
  });
  return res.data;
}

function extractStaticByHost($, url) {
  const h = domain(url);

  if (h.includes('amazon.')) return extractAmazon($, url);
  if (h.includes('shein.')) return extractShein($, url);
  if (h.includes('noon.')) return extractNoon($, url);
  if (h.includes('temu.')) return null; // force headless for Temu
  if (h.includes('trendyol.')) return extractTrendyol($, url);

  // Generic fallback
  const ld = extractFromJsonLd($, url);
  if (ld && (ld.title || ld.price)) return ld;
  return extractFromMeta($, url);
}

async function scrapeStatic(url) {
  const html = await fetchHtml(url);
  const $ = cheerio.load(html);
  return extractStaticByHost($, url);
}

// ---------- Headless (Puppeteer) ----------

async function launchBrowser() {
  const exePath = await chromium.executablePath();
  const browser = await puppeteer.launch({
    executablePath: exePath,
    headless: chromium.headless,
    ignoreHTTPSErrors: true,
    args: [
      ...chromium.args,
      '--disable-dev-shm-usage',
      '--no-sandbox',
      '--disable-setuid-sandbox',
    ],
    defaultViewport: { width: 1366, height: 900, deviceScaleFactor: 1 },
  });
  return browser;
}

function needsHeadless(url) {
  const h = domain(url);
  // Temu is SPA and blocks static easily; Shein mobile pages often hydrate content with JS.
  return h.includes('temu.') || h.startsWith('m.shein.');
}

async function scrapeHeadless(url) {
  const browser = await launchBrowser();
  try {
    const page = await browser.newPage();
    await page.setUserAgent(DEFAULT_UA);
    await page.setRequestInterception(true);
    page.on('request', (req) => {
      const type = req.resourceType();
      if (['image', 'media', 'font'].includes(type)) return req.abort();
      req.continue();
    });

    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 25000 });

    // Try to wait for price-ish content to appear
    try {
      await page.waitForSelector(
        '[class*=price], [id*=price], meta[itemprop=price], meta[property="product:price:amount"]',
        { timeout: 6000 }
      );
    } catch { /* non-fatal */ }

    const html = await page.content();
    const $ = cheerio.load(html);

    // Prefer host-specific parse even in headless (markup might differ but still helpful)
    const byHost = extractStaticByHost($, url);
    if (byHost && (byHost.title || byHost.price)) return byHost;

    // Fallback generic
    const ld = extractFromJsonLd($, url) || extractFromMeta($, url);
    return ld || {
      title: (await page.title()) || null,
      brand: null,
      image: null,
      price: null,
      currency: null,
      rawPriceText: null,
      source: hostOf(url),
    };
  } finally {
    await browser.close();
  }
}

// ---------- Public API ----------

async function scrapeProduct(url) {
  if (!url || typeof url !== 'string') throw new Error('Invalid URL');

  // 1) Try STATIC first (fast)
  let staticRes = null;
  try {
    staticRes = await scrapeStatic(url);
  } catch (_) { /* continue */ }

  const okEnough = (r) => r && (r.title || r.price);

  // For most sites, static is enough
  if (!needsHeadless(url) && okEnough(staticRes)) {
    return { ok: true, ...staticRes };
  }

  // 2) Headless for JS-heavy or if static lacking
  let headlessRes = null;
  try {
    headlessRes = await scrapeHeadless(url);
  } catch (_) { /* continue */ }

  if (okEnough(headlessRes)) return { ok: true, ...headlessRes };
  if (okEnough(staticRes)) return { ok: true, ...staticRes };

  return {
    ok: false,
    error: 'parse_error',
    ...(staticRes || {}),
    source: hostOf(url),
  };
}

module.exports = { scrapeProduct };
