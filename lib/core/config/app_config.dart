class AppConfig {
  static bool firebaseReady = false;
  static const String aiBackendUrl = String.fromEnvironment('AI_BACKEND_URL');
  static const String nutritionApiBaseUrl = String.fromEnvironment('NUTRITION_API_BASE_URL');

  // Firebase web configuration is public app configuration, not a server secret.
  // Native Android/iOS builds can use their platform config files instead.
  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String firebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String firebaseStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static bool get hasWebFirebaseOptions => firebaseApiKey.isNotEmpty && firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty && firebaseProjectId.isNotEmpty;
}
