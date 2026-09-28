import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return ios;

      default:
        throw UnsupportedError(
          'Plateforme non configurée. '
          'Lancez `flutterfire configure` pour ajouter cette plateforme.',
        );
    }
  }

  // ============================================================
  // FIREBASE WEB
  // ============================================================

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDhOjOsuFeNGO52xf2b3x1MjOXtw1hMeWI",
    authDomain: 'boutique-firebase-78226.firebaseapp.com',
    projectId: 'boutique-firebase-78226',
    storageBucket: 'boutique-firebase-78226.firebasestorage.app',
    messagingSenderId: '1040909146928',
    appId: '1:1040909146928:web:f8aab72498b077822986f5',
  );

  // ============================================================
  // FIREBASE ANDROID
  // ============================================================

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBO5qsBaEH_GGZpLEFGMUG7WSdT2zD3-34',
    appId: '1:1040909146928:android:7077a85cec028c8c2986f5',
    messagingSenderId: '1040909146928',
    projectId: 'boutique-firebase-78226',
    storageBucket: 'boutique-firebase-78226.firebasestorage.app',
  );

  // ============================================================
  // FIREBASE iOS
  // ============================================================
  //
  // Configuration iOS non fournie dans ton projet Firebase.
  // Elle devra être générée avec :
  //
  // flutterfire configure
  //

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '1040909146928',
    projectId: 'boutique-firebase-78226',
    storageBucket: 'boutique-firebase-78226.firebasestorage.app',
    iosBundleId: 'com.example.firebaseEcommerce',
  );
}
