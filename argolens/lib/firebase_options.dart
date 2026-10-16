import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyAtoK40Ep5uIJfQGY7HhgP1lJUUAMgJwMw',
          appId: '1:236219411838:android:d8913ea8f5409b86ff572f',
          messagingSenderId: '236219411838',
          projectId: 'argolens-6d840',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured');
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}