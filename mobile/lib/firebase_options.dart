import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCpyBEaDTAtME5_bju7GBuu6Ar3nuPExbY',
    appId: '1:530024630479:ios:ec1e2eb147a4cf6d614fba',
    messagingSenderId: '530024630479',
    projectId: 'friendly-881ae',
    storageBucket: 'friendly-881ae.firebasestorage.app',
    iosBundleId: 'com.kylerand.friendly',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCpRL4hNPJV64MauXM7uDoBmQ4cPTpShRA',
    appId: '1:530024630479:android:82a98e29265071bb614fba',
    messagingSenderId: '530024630479',
    projectId: 'friendly-881ae',
    storageBucket: 'friendly-881ae.firebasestorage.app',
  );
}
