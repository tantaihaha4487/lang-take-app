import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C63FF), // Vibrant Indigo
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
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
      const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w200, color: Colors.white),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w200, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w200, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w200, color: Colors.white60),
        titleLarge: TextStyle(fontWeight: FontWeight.w200),
        titleMedium: TextStyle(fontWeight: FontWeight.w200),
        titleSmall: TextStyle(fontWeight: FontWeight.w200),
        bodySmall: TextStyle(fontWeight: FontWeight.w200),
        labelLarge: TextStyle(fontWeight: FontWeight.w200),
        labelMedium: TextStyle(fontWeight: FontWeight.w200),
        labelSmall: TextStyle(fontWeight: FontWeight.w200),
      ),
    ).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
  );
}

