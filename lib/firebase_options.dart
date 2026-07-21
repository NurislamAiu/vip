// GENERATED-STYLE TEMPLATE.
//
// Replace this file by running the FlutterFire CLI once for this project:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// That command regenerates `firebase_options.dart` with the real keys for your
// Firebase project. The placeholders below let the code compile and make the
// misconfiguration obvious at runtime instead of failing cryptically.
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
        throw UnsupportedError(
          'This platform is not configured. Run `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: 'REPLACE_ME',
    authDomain: 'REPLACE_ME',
    storageBucket: 'REPLACE_ME',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBOk5iXMvE4W77XWtC_HQaoYxGrTKndme8',
    appId: '1:832617788878:android:298af829b8d0728b3b679f',
    messagingSenderId: '832617788878',
    projectId: 'vip-client-manager',
    storageBucket: 'vip-client-manager.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjAMP1P2ylfz69OvTM2uvSYRhMvO60i9g',
    appId: '1:832617788878:ios:1bb3a0945c3779eb3b679f',
    messagingSenderId: '832617788878',
    projectId: 'vip-client-manager',
    storageBucket: 'vip-client-manager.firebasestorage.app',
    iosBundleId: 'com.example.vip',
  );
}
