import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final options = kIsWeb && AppConfig.hasWebFirebaseOptions
        ? FirebaseOptions(
            apiKey: AppConfig.firebaseApiKey,
            appId: AppConfig.firebaseAppId,
            messagingSenderId: AppConfig.firebaseMessagingSenderId,
            projectId: AppConfig.firebaseProjectId,
            authDomain: AppConfig.firebaseAuthDomain.isEmpty ? null : AppConfig.firebaseAuthDomain,
            storageBucket: AppConfig.firebaseStorageBucket.isEmpty ? null : AppConfig.firebaseStorageBucket,
          )
        : null;
    await Firebase.initializeApp(options: options);
    AppConfig.firebaseReady = true;
  } catch (error) {
    // UI/demo mode is available without Firebase. Cloud sync and accounts remain disabled.
    debugPrint('Firebase not configured; starting demo mode: $error');
    AppConfig.firebaseReady = false;
  }
  runApp(const NutriVisionApp());
}
