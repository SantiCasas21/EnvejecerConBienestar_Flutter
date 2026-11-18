import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuración oficial de Firebase generada para envejecerconbienestar-4ffb7.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBstBK087cu_Cz9X02oJZDn_dpYDaqNzIY',
    appId: '1:604603023245:web:249a75030fef48ef0647c4',
    messagingSenderId: '604603023245',
    projectId: 'envejecerconbienestar-4ffb7',
    authDomain: 'envejecerconbienestar-4ffb7.firebaseapp.com',
    storageBucket: 'envejecerconbienestar-4ffb7.firebasestorage.app',
    measurementId: 'G-X3KKBX5MHF',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA1Akak4np134KfkGWooyhozPP22IFklcg',
    appId: '1:604603023245:android:ea2b1de9a75d7fdc0647c4',
    messagingSenderId: '604603023245',
    projectId: 'envejecerconbienestar-4ffb7',
    storageBucket: 'envejecerconbienestar-4ffb7.firebasestorage.app',
  );
}
