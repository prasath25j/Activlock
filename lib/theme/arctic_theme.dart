import 'package:flutter/material.dart';

class ArcticTheme {
  // Arctic Palette
  static const Color iceWhite = Color(0xFFF0F4F8); // Very light grey-blue
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color frostBlue = Color(0xFF38BDF8); // Sky blue 
  static const Color deepNavy = Color(0xFF0F172A); // Slate 900 for text
  static const Color softSlate = Color(0xFF64748B); // Slate 500 for subtext
  static const Color alertRed = Color(0xFFEF4444);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: iceWhite,
      primaryColor: frostBlue,
      colorScheme: const ColorScheme.light(
        primary: frostBlue,
        secondary: deepNavy,
        surface: pureWhite,
        onPrimary: pureWhite,
        onSecondary: pureWhite,
        onSurface: deepNavy,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: deepNavy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          letterSpacing: -0.5,
          color: deepNavy,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: frostBlue,
          foregroundColor: pureWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 10,
        shadowColor: deepNavy.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      fontFamily: 'Inter',
    );
  }

  // Soft Neumorphic-style decoration
  static BoxDecoration get frostDecoration => BoxDecoration(
    color: pureWhite.withOpacity(0.7),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: pureWhite, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: deepNavy.withOpacity(0.03),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
