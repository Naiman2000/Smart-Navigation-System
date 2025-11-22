// lib/firebase_options.dart
// File generated from Firebase Console - replace with your actual credentials

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCTitlnNc7mXU5-W4Pb3fVprm-X_T5SyKk',
    appId: '1:914076766374:android:8dc5a92996caa62e9ee467',
    messagingSenderId: '914076766374',
    projectId: 'smart-navigation-system-6cda6',
    storageBucket: 'smart-navigation-system-6cda6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAKhQKbdfuRbzFkIPld-6D6jp0sOTVLuBE',
    appId: '1:914076766374:ios:f5625dd3e2f43c059ee467',
    messagingSenderId: '914076766374',
    projectId: 'smart-navigation-system-6cda6',
    storageBucket: 'smart-navigation-system-6cda6.firebasestorage.app',
    iosBundleId: 'com.example.smartNavigationSystem',
  );

}
