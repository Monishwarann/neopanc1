import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  // Configured with the keys provided by the user. 
  // Note: The appId here is technically for web, but for a simple project
  // you can use the same options if you only have one app registered.
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'AIzaSyCtbDdM4NMpfe67x3pQEAGIynr-RUTaW7M',
    appId: '1:1063273414039:web:0c3153f7ba659ce780d8d2',
    messagingSenderId: '1063273414039',
    projectId: 'medi-c3916',
    authDomain: 'medi-c3916.firebaseapp.com',
    storageBucket: 'medi-c3916.firebasestorage.app',
    measurementId: 'G-C0K4QK6B0J',
  );
}
