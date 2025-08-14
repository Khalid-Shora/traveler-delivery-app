// lib/services/scraping_service.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Toggle this when switching between local emulator and production.
const bool _useEmulator = true;

/// Your Firebase project ID (must match what the emulator prints).
const String _projectId = 'traveler-delivery-app-1';

/// Functions emulator port (we fixed it to 5001 in firebase.json; if you use a random port,
/// update it here to whatever the emulator prints each run).
const int _emulatorPort = 5001;

/// Region of the deployed function (keep us-central1 unless you changed it)
const String _region = 'us-central1';

/// Path to the scraping endpoint mounted in index.js (Express app under `api`)
const String _scrapePath = '/scrape-product';

/// Optional: your deployed prod base (uncomment & set when going live).
/// final String _prodBase = 'https://$_region-$_projectId.cloudfunctions.net/api';

/// Builds the correct base URL per platform / environment.
///
/// - Android emulator:    http://10.0.2.2:<port>/<project>/us-central1/api
/// - iOS simulator/Mac:   http://127.0.0.1:<port>/<project>/us-central1/api
/// - Production:          https://us-central1-<project>.cloudfunctions.net/api
String _baseUrl() {
  if (_useEmulator) {
    final host = kIsWeb
        ? '127.0.0.1'
        : (Platform.isAndroid ? '10.0.2.2' : '127.0.0.1');
    return 'http://$host:$_emulatorPort/$_projectId/$_region/api';
  } else {
    return 'https://$_region-$_projectId.cloudfunctions.net/api';
    // Or if you use a custom domain / rewrite, change here.
  }
}

/// Typed result for scraping.
class ScrapedProduct {
  final bool ok;
  final String name;
  final String imageUrl;
  final double price;
  final String currency;
  final String store;
  final String link;
  final String description;
  final String? rawPriceText;
  final String? source;

  const ScrapedProduct({
    required this.ok,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.currency,
    required this.store,
    required this.link,
    required this.description,
    this.rawPriceText,
    this.source,
  });

  factory ScrapedProduct.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return ScrapedProduct(
      ok: (json['ok'] as bool?) ?? true, // our function returns ok:true on success
      name: (json['name'] ?? json['title'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image'] ?? '').toString(),
      price: _toDouble(json['price']),
      currency: (json['currency'] ?? '').toString(),
      store: (json['store'] ?? '').toString(),
      link: (json['link'] ?? json['sourceUrl'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      rawPriceText: (json['rawPriceText'] as String?)?.toString(),
      source: (json['source'] as String?)?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'ok': ok,
    'name': name,
    'imageUrl': imageUrl,
    'price': price,
    'currency': currency,
    'store': store,
    'link': link,
    'description': description,
    'rawPriceText': rawPriceText,
    'source': source,
  };
}

/// Errors thrown by the scraping service.
class ScrapingException implements Exception {
  final String message;
  final int? statusCode;
  ScrapingException(this.message, {this.statusCode});
  @override
  String toString() => 'ScrapingException($statusCode): $message';
}

class ScrapingService {
  /// Scrape product metadata from a URL via Cloud Functions.
  ///
  /// Throws [ScrapingException] on a non-200/OK response or network error.
  /// Retries up to [retries] times with exponential backoff.
  static Future<ScrapedProduct> scrapeProduct(
      String url, {
        int timeoutSeconds = 25,
        int retries = 2,
      }) async {
    if (url.isEmpty) {
      throw ScrapingException('URL is empty');
    }

    final endpoint = Uri.parse('${_baseUrl()}$_scrapePath');
    final body = jsonEncode({'url': url});

    int attempt = 0;
    late http.Response resp;

    while (true) {
      attempt++;
      try {
        resp = await http
            .post(
          endpoint,
          headers: const {'Content-Type': 'application/json'},
          body: body,
        )
            .timeout(Duration(seconds: timeoutSeconds));

        // Expect JSON
        final Map<String, dynamic> data = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          // API returns { ok:true, ...fields }
          final result = ScrapedProduct.fromJson(data);
          if (!result.ok) {
            throw ScrapingException(
              data['error']?.toString() ?? 'Scrape returned ok:false',
              statusCode: resp.statusCode,
            );
          }
          return result;
        } else {
          // surface API error message if present
          final msg = data['error']?.toString() ??
              'HTTP ${resp.statusCode}: ${resp.reasonPhrase ?? 'Unknown error'}';
          throw ScrapingException(msg, statusCode: resp.statusCode);
        }
      } catch (e) {
        // Retry on network/timeouts/server errors (<= retries)
        if (attempt > (retries + 1)) {
          if (e is ScrapingException) rethrow;
          throw ScrapingException(e.toString());
        }
        // simple backoff: 600ms, 1200ms
        final delayMs = 600 * attempt;
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  /// If you need the raw JSON from the backend (for debugging).
  static Future<Map<String, dynamic>> scrapeRaw(String url) async {
    final result = await scrapeProduct(url);
    return result.toJson();
  }
}
