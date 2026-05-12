import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
    apiKey: 'AIzaSyBe2MH1wARfjl9NEAJsiw5OlyK8Mh9w1N4',
    appId: '1:981647985032:web:a63d43dfbb965f73c6923d',
    messagingSenderId: '981647985032',
    projectId: 'guest-list-e1f39',
    authDomain: 'guest-list-e1f39.firebaseapp.com',
    storageBucket: 'guest-list-e1f39.firebasestorage.app',
    measurementId: 'G-0QEQJBT1XW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBe2MH1wARfjl9NEAJsiw5OlyK8Mh9w1N4',
    appId: '1:981647985032:android:a63d43dfbb965f73c6923d', // Note: Android/iOS usually have different appIds, but we use web as fallback if you're building for Android
    messagingSenderId: '981647985032',
    projectId: 'guest-list-e1f39',
    storageBucket: 'guest-list-e1f39.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBe2MH1wARfjl9NEAJsiw5OlyK8Mh9w1N4',
    appId: '1:981647985032:ios:a63d43dfbb965f73c6923d', // Note: Android/iOS usually have different appIds, but we use web as fallback if you're building for iOS
    messagingSenderId: '981647985032',
    projectId: 'guest-list-e1f39',
    storageBucket: 'guest-list-e1f39.firebasestorage.app',
    iosBundleId: 'com.example.guestList',
  );
}
