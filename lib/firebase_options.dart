// File generated from Firebase project configuration.
// Project: expense-mate-af37a

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyApXeW2LbMlEN5HwIJGKciINTYn5q5jkCc',
    appId: '1:286919586290:android:6cf0806e5b60d5c46b3b6b',
    messagingSenderId: '286919586290',
    projectId: 'expense-mate-af37a',
    storageBucket: 'expense-mate-af37a.firebasestorage.app',
  );

  // Add GoogleService-Info.plist from Firebase Console for production iOS builds.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyApXeW2LbMlEN5HwIJGKciINTYn5q5jkCc',
    appId: '1:286919586290:ios:0000000000000000000000',
    messagingSenderId: '286919586290',
    projectId: 'expense-mate-af37a',
    storageBucket: 'expense-mate-af37a.firebasestorage.app',
    iosBundleId: 'com.nurujjaman.expenseMate',
  );
}
