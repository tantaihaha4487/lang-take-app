import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData getTheme(FontWeight fontWeight, {bool isLightMode = false}) {
    if (isLightMode) {
      return _getLightTheme(fontWeight);
    }
    return _getDarkTheme(fontWeight);
  }

  static ThemeData _getDarkTheme(FontWeight fontWeight) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E),
        primary: const Color(0xFF6C63FF),
        secondary: const Color(0xFF03DAC6),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: GoogleFonts.kanitTextTheme(
        TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: fontWeight, color: Colors.white),
          displayMedium: TextStyle(fontSize: 24, fontWeight: fontWeight, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: fontWeight, color: Colors.white70),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: fontWeight, color: Colors.white60),
          titleLarge: TextStyle(fontWeight: fontWeight),
          titleMedium: TextStyle(fontWeight: fontWeight),
          titleSmall: TextStyle(fontWeight: fontWeight),
          bodySmall: TextStyle(fontWeight: fontWeight),
          labelLarge: TextStyle(fontWeight: fontWeight),
          labelMedium: TextStyle(fontWeight: fontWeight),
          labelSmall: TextStyle(fontWeight: fontWeight),
        ),
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }

  static ThemeData _getLightTheme(FontWeight fontWeight) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.light,
        surface: const Color(0xFFF5F5F5),
        primary: const Color(0xFF6C63FF),
        secondary: const Color(0xFF03DAC6),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: GoogleFonts.kanitTextTheme(
        TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: fontWeight, color: Colors.black87),
          displayMedium: TextStyle(fontSize: 24, fontWeight: fontWeight, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: fontWeight, color: Colors.black54),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: fontWeight, color: Colors.black45),
          titleLarge: TextStyle(fontWeight: fontWeight),
          titleMedium: TextStyle(fontWeight: fontWeight),
          titleSmall: TextStyle(fontWeight: fontWeight),
          bodySmall: TextStyle(fontWeight: fontWeight),
          labelLarge: TextStyle(fontWeight: fontWeight),
          labelMedium: TextStyle(fontWeight: fontWeight),
          labelSmall: TextStyle(fontWeight: fontWeight),
        ),
      ).apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
    );
  }
}

