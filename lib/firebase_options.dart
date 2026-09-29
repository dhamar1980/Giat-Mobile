// File generated for GIAT Mobile Firebase Configuration
// Project: giat-3ac67

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBhJvTnhT_z-7zjD9ZEvteNb3cfdb2Sb84',
    appId: '1:100000000000:web:giatmobileapp3ac67',
    messagingSenderId: '100000000000',
    projectId: 'giat-3ac67',
    authDomain: 'giat-3ac67.firebaseapp.com',
    storageBucket: 'giat-3ac67.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhJvTnhT_z-7zjD9ZEvteNb3cfdb2Sb84',
    appId: '1:100000000000:android:giatmobileapp3ac67',
    messagingSenderId: '100000000000',
    projectId: 'giat-3ac67',
    storageBucket: 'giat-3ac67.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBhJvTnhT_z-7zjD9ZEvteNb3cfdb2Sb84',
    appId: '1:100000000000:ios:giatmobileapp3ac67',
    messagingSenderId: '100000000000',
    projectId: 'giat-3ac67',
    storageBucket: 'giat-3ac67.firebasestorage.app',
    iosBundleId: 'com.example.giat',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBhJvTnhT_z-7zjD9ZEvteNb3cfdb2Sb84',
    appId: '1:100000000000:ios:giatmobileapp3ac67',
    messagingSenderId: '100000000000',
    projectId: 'giat-3ac67',
    storageBucket: 'giat-3ac67.firebasestorage.app',
    iosBundleId: 'com.example.giat',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBhJvTnhT_z-7zjD9ZEvteNb3cfdb2Sb84',
    appId: '1:100000000000:web:giatmobileapp3ac67',
    messagingSenderId: '100000000000',
    projectId: 'giat-3ac67',
    authDomain: 'giat-3ac67.firebaseapp.com',
    storageBucket: 'giat-3ac67.firebasestorage.app',
  );
}
