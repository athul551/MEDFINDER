import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static bool get isConfigured {
    final options = currentPlatform;
    return !options.apiKey.startsWith('replace-with') &&
        options.messagingSenderId != '000000000000' &&
        !options.appId.contains('000000000000');
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCmucwNjfc8vXNGl879RShsyFmbMX5GeAc',
    appId: '1:244216896549:web:b52cc643feb458ecc073cc',
    messagingSenderId: '244216896549',
    projectId: 'medfinder-ef4f1',
    authDomain: 'medfinder-ef4f1.firebaseapp.com',
    storageBucket: 'medfinder-ef4f1.firebasestorage.app',
    measurementId: 'G-H86VBHF6LG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDdUwNKtPPwigvAWdBlxxvrnd-29LaOqKE',
    appId: '1:244216896549:android:564e9db494f74a21c073cc',
    messagingSenderId: '244216896549',
    projectId: 'medfinder-ef4f1',
    storageBucket: 'medfinder-ef4f1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBxYPAHsAgCdjaFiJZg4bPGVug3iv91u7w',
    appId: '1:244216896549:ios:7418fa433c87ff59c073cc',
    messagingSenderId: '244216896549',
    projectId: 'medfinder-ef4f1',
    storageBucket: 'medfinder-ef4f1.firebasestorage.app',
    iosBundleId: 'com.example.medicineAvailabilityFinder',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCmucwNjfc8vXNGl879RShsyFmbMX5GeAc',
    appId: '1:244216896549:web:b52cc643feb458ecc073cc',
    messagingSenderId: '244216896549',
    projectId: 'medfinder-ef4f1',
    authDomain: 'medfinder-ef4f1.firebaseapp.com',
    storageBucket: 'medfinder-ef4f1.firebasestorage.app',
    measurementId: 'G-H86VBHF6LG',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyCmucwNjfc8vXNGl879RShsyFmbMX5GeAc',
    appId: '1:244216896549:web:b52cc643feb458ecc073cc',
    messagingSenderId: '244216896549',
    projectId: 'medfinder-ef4f1',
    authDomain: 'medfinder-ef4f1.firebaseapp.com',
    storageBucket: 'medfinder-ef4f1.firebasestorage.app',
    measurementId: 'G-H86VBHF6LG',
  );
}
