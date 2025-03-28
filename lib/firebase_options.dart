// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
      return web;
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
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCluq1bj3R1jyVVS3sf363RC2h5OQAARaM',
    appId: '1:525679992169:web:d65aa8cc66c9642039f1f8',
    messagingSenderId: '525679992169',
    projectId: 'pro-g-e85ea',
    authDomain: 'pro-g-e85ea.firebaseapp.com',
    storageBucket: 'pro-g-e85ea.firebasestorage.app',
    measurementId: 'G-D36X5V80MN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzDLrs-Fy4qCDZ8HoL3pxHPzdKk2vIHEM',
    appId: '1:525679992169:android:468f8f499da3401339f1f8',
    messagingSenderId: '525679992169',
    projectId: 'pro-g-e85ea',
    storageBucket: 'pro-g-e85ea.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCrjqql3Pmot9_bpkJc-MINzg91bHxtCnw',
    appId: '1:525679992169:ios:daf338f89500969739f1f8',
    messagingSenderId: '525679992169',
    projectId: 'pro-g-e85ea',
    storageBucket: 'pro-g-e85ea.firebasestorage.app',
    iosBundleId: 'com.example.tryout',
  );
}
