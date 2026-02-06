// File generated based on google-services.json
// Firebase configuration for City Vape app

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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDeIPngqVLLH3o6l4va3koWZ7sDA1trmm8',
    appId: '1:829446577088:android:76dc118a948708b2714625',
    messagingSenderId: '829446577088',
    projectId: 'city-vape-app',
    storageBucket: 'city-vape-app.firebasestorage.app',
  );

  // iOS configuration - update these values when you add iOS to Firebase
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDeIPngqVLLH3o6l4va3koWZ7sDA1trmm8',
    appId: '1:829446577088:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '829446577088',
    projectId: 'city-vape-app',
    storageBucket: 'city-vape-app.firebasestorage.app',
    iosBundleId: 'com.idisr.cityvape',
  );

  // Web configuration - update these values when you add Web to Firebase
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDeIPngqVLLH3o6l4va3koWZ7sDA1trmm8',
    appId: '1:829446577088:web:YOUR_WEB_APP_ID',
    messagingSenderId: '829446577088',
    projectId: 'city-vape-app',
    storageBucket: 'city-vape-app.firebasestorage.app',
    authDomain: 'city-vape-app.firebaseapp.com',
  );

  // macOS configuration - update these values when you add macOS to Firebase
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDeIPngqVLLH3o6l4va3koWZ7sDA1trmm8',
    appId: '1:829446577088:ios:YOUR_MACOS_APP_ID',
    messagingSenderId: '829446577088',
    projectId: 'city-vape-app',
    storageBucket: 'city-vape-app.firebasestorage.app',
    iosBundleId: 'com.idisr.cityvape',
  );

  // Windows configuration - update these values when you add Windows to Firebase
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDeIPngqVLLH3o6l4va3koWZ7sDA1trmm8',
    appId: '1:829446577088:web:YOUR_WINDOWS_APP_ID',
    messagingSenderId: '829446577088',
    projectId: 'city-vape-app',
    storageBucket: 'city-vape-app.firebasestorage.app',
  );
}
