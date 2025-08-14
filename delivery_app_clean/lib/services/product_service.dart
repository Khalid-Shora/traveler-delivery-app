// lib/services/product_service.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/product_model.dart';

/// Toggle when switching between local emulator and production.
const bool _useEmulator = true;

/// Your Firebase project ID.
const String _projectId = 'traveler-delivery-app-1';

/// Functions region.
const String _region = 'us-central1';

/// Fixed emulator port (set in firebase.json). If you let it float, update accordingly.
const int _emulatorPort = 5001;

/// Express mount path in functions/index.js
const String _scrapePath = '/scrape-product';

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();

  /// Builds the correct base URL per platform / environment.
  ///
  /// - Android emulator:    http://10.0.2.2:<port>/<project>/us-central1/api
  /// - iOS simulator / mac: http://127.0.0.1:<port>/<project>/us-central1/api
  /// - Web (local dev):     http://127.0.0.1:<port>/<project>/us-central1/api
  /// - Production:          https://<region>-<project>.cloudfunctions.net/api
  String _baseUrl() {
    if (_useEmulator) {
      final host = kIsWeb ? '127.0.0.1' : (Platform.isAndroid ? '10.0.2.2' : '127.0.0.1');
      return 'http://$host:$_emulatorPort/$_projectId/$_region/api';
    } else {
      return 'https://$_region-$_projectId.cloudfunctions.net/api';
    }
  }

  Uri _buildScrapeUri() => Uri.parse('${_baseUrl()}$_scrapePath');

  /// Fetch product metadata by URL via Cloud Functions.
  ///
  /// Uses POST (more reliable for long URLs). Times out after [timeoutSeconds].
  /// Throws an [Exception] with the backend error message when status != 2xx.
  Future<ProductModel> fetchByUrl(String url, {int timeoutSeconds = 25}) async {
    if (url.isEmpty) {
      throw Exception('Product URL is empty');
    }

    final uri = _buildScrapeUri();
    final body = jsonEncode({'url': url});

    final res = await http
        .post(
      uri,
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: body,
    )
        .timeout(Duration(seconds: timeoutSeconds));

    // Expect JSON back
    final String text = res.body;
    Map<String, dynamic> data = {};
    try {
      data = text.isEmpty ? {} : jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      // If server returned non-JSON, surface raw text
      throw Exception('Failed to parse response (HTTP ${res.statusCode}): $text');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      // Our function returns { ok: true, ... } — but ProductModel.fromJson can ignore extra fields.
      return ProductModel.fromJson(data);
    }

    // Surface backend error message if present
    final msg = (data['error'] ?? data['message'] ?? 'Unknown error').toString();
    throw Exception('Failed to scrape product (HTTP ${res.statusCode}): $msg');
  }
}
