// Generated from google-services.json for project: vaya-1b1f8
// Run `flutterfire configure` to regenerate with full platform support.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platform not configured yet. Run flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS platform not configured yet. Run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBJa-nTT8iJxwlCmuQ3Ibjvs4fIdn0-rCA',
    appId: '1:135770995183:android:e80977fc227c41e4c89e1a',
    messagingSenderId: '135770995183',
    projectId: 'vaya-1b1f8',
    storageBucket: 'vaya-1b1f8.firebasestorage.app',
  );
}
