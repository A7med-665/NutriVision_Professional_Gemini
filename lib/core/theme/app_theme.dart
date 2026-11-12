import 'package:flutter/material.dart';

class AppTheme {
  static const Color green = Color(0xFF247A58);
  static const Color ink = Color(0xFF1D3028);
  static const Color canvas = Color(0xFFF5F8F4);
  static ThemeData get light => ThemeData(
    useMaterial3: true, scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.light),
    appBarTheme: const AppBarTheme(backgroundColor: canvas, foregroundColor: ink, elevation: 0),
    cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15)),
  );
}
