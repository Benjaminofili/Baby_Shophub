import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Colors (Baby-friendly pastel tones)
  static const Color primary = Color(0xFFF4A261); // Soft peach
  static const Color primaryDark = Color(0xFFE68A5C); // Slightly darker peach
  static const Color secondary = Color(0xFFB0C4DE); // Light blue
  static const Color backgroundLight = Color(0xFFF5F5F0); // Cream background
  static const Color backgroundGrey = Color(
    0xFFF7F8FA,
  ); // Light grey for inputs
  static const Color textPrimary = Color(0xFF333333); // Dark grey for main text
  static const Color textSecondary = Color(
    0xFF666666,
  ); // Medium grey for secondary text
  static const Color success = Color(0xFF28C76F); // Green for success messages
  static const Color error = Color(0xFFFF8C8C); // Soft red for errors

  // 🖋 Typography (Legible and accessible)
  static const String fontFamilyPrimary = 'Roboto'; // Clean and readable
  static const String fontFamilySecondary = 'OpenSans';

  static ThemeData get themeData {
    return ThemeData(
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primary,
      fontFamily: fontFamilySecondary,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontFamilyPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontFamilyPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: fontFamilyPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // 🔘 Button Styles (Soft and rounded)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              20.0,
            ), // Rounded for friendliness
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              20.0,
            ), // Rounded for consistency
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0), // Subtle rounding
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF999999)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}
