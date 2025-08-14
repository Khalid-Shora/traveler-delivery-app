// lib/env/firebase_env.dart
//
// Reads Firebase configuration from `.env` using flutter_dotenv
// and returns a FirebaseOptions matching the current platform.
//
// Make sure you've called: await dotenv.load(fileName: '.env');
// before using FirebaseEnv.currentPlatform.
//
// If any required key is missing, this will throw a clear error message.

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseEnv {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: _get('FIREBASE_WEB_API_KEY'),
        appId: _get('FIREBASE_WEB_APP_ID'),
        messagingSenderId: _get('FIREBASE_WEB_MESSAGING_SENDER_ID'),
        projectId: _get('FIREBASE_WEB_PROJECT_ID'),
        authDomain: _get('FIREBASE_WEB_AUTH_DOMAIN'),
        storageBucket: _get('FIREBASE_WEB_STORAGE_BUCKET'),
        measurementId: _get('FIREBASE_WEB_MEASUREMENT_ID', required: false),
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: _get('FIREBASE_ANDROID_API_KEY'),
          appId: _get('FIREBASE_ANDROID_APP_ID'),
          messagingSenderId: _get('FIREBASE_ANDROID_MESSAGING_SENDER_ID'),
          projectId: _get('FIREBASE_ANDROID_PROJECT_ID'),
          storageBucket: _get('FIREBASE_ANDROID_STORAGE_BUCKET'),
        );

      case TargetPlatform.iOS:
        return FirebaseOptions(
          apiKey: _get('FIREBASE_IOS_API_KEY'),
          appId: _get('FIREBASE_IOS_APP_ID'),
          messagingSenderId: _get('FIREBASE_IOS_MESSAGING_SENDER_ID'),
          projectId: _get('FIREBASE_IOS_PROJECT_ID'),
          storageBucket: _get('FIREBASE_IOS_STORAGE_BUCKET'),
          iosBundleId: _get('FIREBASE_IOS_BUNDLE_ID'),
        );

      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'FirebaseEnv not configured for this platform. '
              'Add platform keys to .env or handle it here.',
        );
      case TargetPlatform.fuchsia:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  /// Reads a value from .env and throws if it is missing (unless required=false).
  static String _get(String key, {bool required = true}) {
    final value = dotenv.env[key];
    if ((value == null || value.isEmpty) && required) {
      throw StateError(
        'Missing $key in .env. Please add it with the correct value.',
      );
    }
    return value ?? '';
  }
}
