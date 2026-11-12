import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';

class NutriVisionApp extends StatelessWidget {
  const NutriVisionApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NutriVision', debugShowCheckedModeBanner: false,
    locale: const Locale('ar'), supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AppTheme.light, home: const AuthGate(),
  );
}
