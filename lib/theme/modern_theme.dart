import 'package:flutter/material.dart';

class ModernTheme {
  // Primary Glass Palette
  static const Color primaryBlue = Color(0xFF6366F1); // Indigo-600
  static const Color accentPink = Color(0xFFEC4899); // Pink-500
  static const Color accentCyan = Color(0xFF06B6D4); // Cyan-500
  
  // Neutral Tones
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate50 = Color(0xFFF8FAFC);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: slate900,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: accentPink,
        tertiary: accentCyan,
        surface: slate800,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: slate50,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: slate50,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: -0.5,
          color: slate50,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: slate800.withOpacity(0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: slate50,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentPink,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: slate900,
      ),
      // CRITICAL: Explicitly set a dark text theme for the light mode
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: slate900),
        displayMedium: TextStyle(color: slate900),
        displaySmall: TextStyle(color: slate900),
        headlineLarge: TextStyle(color: slate900),
        headlineMedium: TextStyle(color: slate900),
        headlineSmall: TextStyle(color: slate900),
        titleLarge: TextStyle(color: slate900, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: slate900),
        titleSmall: TextStyle(color: slate900),
        bodyLarge: TextStyle(color: slate900),
        bodyMedium: TextStyle(color: slate900),
        bodySmall: TextStyle(color: Colors.black54),
        labelLarge: TextStyle(color: slate900),
        labelSmall: TextStyle(color: slate900),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: slate900,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: slate900),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 20,
          letterSpacing: -0.5,
          color: slate900,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.8),
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
        ),
      ),
    );
  }
}
