import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('지원하지 않는 플랫폼입니다.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBCrI70Ij6mKw92myvBiSlO6AO8OJWQhbE',
    appId: '1:820857265556:web:8b7a1930e76ea4b9534381',
    messagingSenderId: '820857265556',
    projectId: 'westudy-bfcb4',
    authDomain: 'westudy-bfcb4.firebaseapp.com',
    storageBucket: 'westudy-bfcb4.firebasestorage.app',
    measurementId: 'G-HZGB8DDXP8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBCrI70Ij6mKw92myvBiSlO6AO8OJWQhbE',
    appId: '1:820857265556:android:a93317bc717ec0fc534381',
    messagingSenderId: '820857265556',
    projectId: 'westudy-bfcb4',
    storageBucket: 'westudy-bfcb4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBCrI70Ij6mKw92myvBiSlO6AO8OJWQhbE',
    appId: '1:820857265556:web:8b7a1930e76ea4b9534381',
    messagingSenderId: '820857265556',
    projectId: 'westudy-bfcb4',
    storageBucket: 'westudy-bfcb4.firebasestorage.app',
    iosBundleId: 'com.westudy.app',
  );
}
