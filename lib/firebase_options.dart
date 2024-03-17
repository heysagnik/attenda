// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        return macos;
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
    apiKey: 'AIzaSyDloe19rLMPmvQ6TzhBNTtO8aP2BsGJ2tE',
    appId: '1:190792049686:web:2faebe62b24c63d8140137',
    messagingSenderId: '190792049686',
    projectId: 'attendance-73edb',
    authDomain: 'attendance-73edb.firebaseapp.com',
    storageBucket: 'attendance-73edb.appspot.com',
    measurementId: 'G-89YG2LV93B',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDj7wEss-B3ycmRWZPUFJiUlQYCWO2wu0',
    appId: '1:190792049686:android:9406096707ac045e140137',
    messagingSenderId: '190792049686',
    projectId: 'attendance-73edb',
    storageBucket: 'attendance-73edb.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAwh5nDltFpmqsbQwNd8Otf8l_wMALC9Ew',
    appId: '1:190792049686:ios:098910d6974dcd73140137',
    messagingSenderId: '190792049686',
    projectId: 'attendance-73edb',
    storageBucket: 'attendance-73edb.appspot.com',
    iosBundleId: 'com.example.attendance',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAwh5nDltFpmqsbQwNd8Otf8l_wMALC9Ew',
    appId: '1:190792049686:ios:7c00ff879709ad9c140137',
    messagingSenderId: '190792049686',
    projectId: 'attendance-73edb',
    storageBucket: 'attendance-73edb.appspot.com',
    iosBundleId: 'com.example.attendance.RunnerTests',
  );
}