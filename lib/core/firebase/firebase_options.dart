import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Firebase configuration options for Campus Nerds
///
/// Firebase project: campus-nerds-29593
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCFDHaw-v-QldZD5mTt00B2gnlND7sGvwc',
    appId: '1:773749778082:android:ddb833b963a23ad8bc99fb',
    messagingSenderId: '773749778082',
    projectId: 'campus-nerds-29593',
    storageBucket: 'campus-nerds-29593.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCrCGI4JUMr_0hhQQmcl-OEuZVz9gZetcc',
    appId: '1:773749778082:ios:3c97bd359b87fd7cbc99fb',
    messagingSenderId: '773749778082',
    projectId: 'campus-nerds-29593',
    storageBucket: 'campus-nerds-29593.firebasestorage.app',
    iosBundleId: 'app.campusnerds.app',
  );
}
