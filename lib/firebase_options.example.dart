// TEMPLATE — Copy this file to lib/firebase_options.dart and fill in your values.
// Run `flutterfire configure` to auto-generate this file for your Firebase project.
// See SETUP.md for full instructions.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured. Run flutterfire configure.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured. Run flutterfire configure.');
      default:
        throw UnsupportedError('Platform not supported.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'YOUR_ANDROID_API_KEY',
    appId:             'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId:         'YOUR_PROJECT_ID',
    storageBucket:     'YOUR_PROJECT_ID.firebasestorage.app',
  );
}
