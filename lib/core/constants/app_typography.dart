import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system using Urbanist font for both headings and body text
class AppTypography {
  // Base font family
  static const String fontFamily = 'Urbanist';
  
  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  /// Display text styles (largest)
  static TextStyle displayLarge = GoogleFonts.urbanist(
    fontSize: 57,
    fontWeight: regular,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static TextStyle displayMedium = GoogleFonts.urbanist(
    fontSize: 45,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.16,
  );

  static TextStyle displaySmall = GoogleFonts.urbanist(
    fontSize: 36,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.22,
  );

  /// Headline text styles
  static TextStyle headlineLarge = GoogleFonts.urbanist(
    fontSize: 32,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.25,
  );

  static TextStyle headlineMedium = GoogleFonts.urbanist(
    fontSize: 28,
    fontWeight: regular,
    letterSpacing: 0,
    height: 1.29,
  );

  static TextStyle headlineSmall = GoogleFonts.urbanist(
    fontSize: 24,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.33,
  );

  /// Title text styles
  static TextStyle titleLarge = GoogleFonts.urbanist(
    fontSize: 22,
    fontWeight: medium,
    letterSpacing: 0,
    height: 1.27,
  );

  static TextStyle titleMedium = GoogleFonts.urbanist(
    fontSize: 16,
    fontWeight: semiBold,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static TextStyle titleSmall = GoogleFonts.urbanist(
    fontSize: 14,
    fontWeight: semiBold,
    letterSpacing: 0.1,
    height: 1.43,
  );

  /// Label text styles
  static TextStyle labelLarge = GoogleFonts.urbanist(
    fontSize: 14,
    fontWeight: medium,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static TextStyle labelMedium = GoogleFonts.urbanist(
    fontSize: 12,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static TextStyle labelSmall = GoogleFonts.urbanist(
    fontSize: 11,
    fontWeight: medium,
    letterSpacing: 0.5,
    height: 1.45,
  );

  /// Body text styles
  static TextStyle bodyLarge = GoogleFonts.urbanist(
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static TextStyle bodyMedium = GoogleFonts.urbanist(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static TextStyle bodySmall = GoogleFonts.urbanist(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  /// Custom styles for specific use cases

  // Mood entry text
  static TextStyle moodTitle = GoogleFonts.urbanist(
    fontSize: 20,
    fontWeight: semiBold,
    letterSpacing: 0,
    height: 1.20,
  );

  static TextStyle moodDescription = GoogleFonts.urbanist(
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0.15,
    height: 1.50,
  );

  // Button text
  static TextStyle button = GoogleFonts.urbanist(
    fontSize: 14,
    fontWeight: semiBold,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Caption and helper text
  static TextStyle caption = GoogleFonts.urbanist(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Emphasized text for stress/crisis situations
  static TextStyle emphasisLarge = GoogleFonts.urbanist(
    fontSize: 18,
    fontWeight: bold,
    letterSpacing: 0,
    height: 1.44,
  );

  static TextStyle emphasisMedium = GoogleFonts.urbanist(
    fontSize: 16,
    fontWeight: bold,
    letterSpacing: 0.15,
    height: 1.50,
  );

  // For adaptive interfaces with larger touch targets
  static TextStyle adaptiveLarge = GoogleFonts.urbanist(
    fontSize: 18,
    fontWeight: medium,
    letterSpacing: 0.15,
    height: 1.44,
  );

  /// Create complete TextTheme for Material3
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
  );

  /// Create TextTheme with specific color
  static TextTheme textThemeWithColor(Color color) {
    return textTheme.apply(
      bodyColor: color,
      displayColor: color,
    );
  }
}