import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBHIdxpAfGvqsu5yJeqtx8ZEDo37rBvAHU",
            authDomain: "campus-nerds-29593.firebaseapp.com",
            projectId: "campus-nerds-29593",
            storageBucket: "campus-nerds-29593.firebasestorage.app",
            messagingSenderId: "773749778082",
            appId: "1:773749778082:web:d5a5f087e991edbfbc99fb"));
  } else {
    await Firebase.initializeApp();
  }
}
