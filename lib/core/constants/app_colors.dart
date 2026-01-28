import 'package:flutter/material.dart';

/// Application color palette based on brand guidelines
/// Each color family has shades from 90 (darkest) to 40 (lightest)
class AppColors {
  // Brown Family
  static const Color brown90 = Color(0xFF372315);
  static const Color brown80 = Color(0xFF4F3422);
  static const Color brown70 = Color(0xFF704A33);
  static const Color brown60 = Color(0xFF926247);
  static const Color brown50 = Color(0xFFAC836C);
  static const Color brown45 = Color(0xFFD6C2B8);
  static const Color brown40 = Color(0xFFE8DDD9);

  // Base Family (Neutrals)
  static const Color base90 = Color(0xFF161513);
  static const Color base80 = Color(0xFF292723);
  static const Color base70 = Color(0xFF3F3C36);
  static const Color base60 = Color(0xFF5A554E);
  static const Color base50 = Color(0xFF928D86);
  static const Color base45 = Color(0xFFACA9A5);
  static const Color base40 = Color(0xFFE1E0E0);

  // Green Family
  static const Color green90 = Color(0xFF5A6B38);
  static const Color green80 = Color(0xFF9BB167);
  static const Color green70 = Color(0xFFB4C48D);
  static const Color green60 = Color(0xFFCFD9B5);
  static const Color green50 = Color(0xFFE5EAD7);
  static const Color green40 = Color(0xFFF2F4EB);

  // Orange Family
  static const Color orange90 = Color(0xFF894700);
  static const Color orange80 = Color(0xFFAA5500);
  static const Color orange70 = Color(0xFFC96100);
  static const Color orange60 = Color(0xFFED7E1C);
  static const Color orange50 = Color(0xFFF6A360);
  static const Color orange45 = Color(0xFFFFC89E);
  static const Color orange40 = Color(0xFFFFEEE2);

  // Yellow Family
  static const Color yellow90 = Color(0xFFA37A00);
  static const Color yellow80 = Color(0xFFE0A500);
  static const Color yellow70 = Color(0xFFFFBD19);
  static const Color yellow60 = Color(0xFFFFCE5C);
  static const Color yellow50 = Color(0xFFFFDB8F);
  static const Color yellow45 = Color(0xFFFFEBC2);
  static const Color yellow40 = Color(0xFFFFF4E0);

  // Semantic Colors
  static const Color primary = green80;
  static const Color primaryVariant = green90;
  static const Color secondary = orange60;
  static const Color secondaryVariant = orange80;
  static const Color accent = yellow70;
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color warning = orange70;
  static const Color success = green70;
  static const Color info = Color(0xFF1976D2);

  // Surface Colors
  static const Color surface = Color(0xFFFFFBFF);
  static const Color surfaceVariant = base40;
  static const Color background = Color(0xFFFFFBFF);
  static const Color backgroundVariant = green40;

  // Text Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = base90;
  static const Color onSurfaceVariant = base70;
  static const Color onBackground = base90;
  static const Color onError = Color(0xFFFFFFFF);

  // Mood-specific colors
  static const Color moodVeryHappy = yellow60;
  static const Color moodHappy = green70;
  static const Color moodNeutral = base50;
  static const Color moodSad = orange70;
  static const Color moodVerySad = brown70;

  // Adaptive context colors
  static const Color stressHigh = orange80;
  static const Color stressMedium = orange60;
  static const Color stressLow = green60;
  static const Color calmingAccent = green50;
  static const Color nightModeAccent = brown60;
}

/// Color schemes for different themes
class AppColorSchemes {
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.green50,
    onPrimaryContainer: AppColors.green90,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.orange45,
    onSecondaryContainer: AppColors.orange90,
    tertiary: AppColors.accent,
    onTertiary: AppColors.base90,
    tertiaryContainer: AppColors.yellow45,
    onTertiaryContainer: AppColors.yellow90,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: AppColors.background,
    onBackground: AppColors.onBackground,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceVariant: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.base60,
    outlineVariant: AppColors.base45,
    shadow: AppColors.base90,
    scrim: AppColors.base90,
    inverseSurface: AppColors.base80,
    onInverseSurface: AppColors.base40,
    inversePrimary: AppColors.green60,
    surfaceTint: AppColors.primary,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.green60,
    onPrimary: AppColors.green90,
    primaryContainer: AppColors.green90,
    onPrimaryContainer: AppColors.green50,
    secondary: AppColors.orange50,
    onSecondary: AppColors.orange90,
    secondaryContainer: AppColors.orange80,
    onSecondaryContainer: AppColors.orange45,
    tertiary: AppColors.yellow50,
    onTertiary: AppColors.yellow90,
    tertiaryContainer: AppColors.yellow80,
    onTertiaryContainer: AppColors.yellow45,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: AppColors.base90,
    onBackground: AppColors.base40,
    surface: AppColors.base90,
    onSurface: AppColors.base40,
    surfaceVariant: AppColors.base70,
    onSurfaceVariant: AppColors.base45,
    outline: AppColors.base50,
    outlineVariant: AppColors.base70,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: AppColors.base40,
    onInverseSurface: AppColors.base90,
    inversePrimary: AppColors.primary,
    surfaceTint: AppColors.green60,
  );

  static const ColorScheme calmScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.green70,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.green40,
    onPrimaryContainer: AppColors.green90,
    secondary: AppColors.brown60,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.brown40,
    onSecondaryContainer: AppColors.brown90,
    tertiary: AppColors.yellow60,
    onTertiary: AppColors.yellow90,
    tertiaryContainer: AppColors.yellow40,
    onTertiaryContainer: AppColors.yellow90,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: AppColors.green40,
    onBackground: AppColors.green90,
    surface: Color(0xFFFFFBFF),
    onSurface: AppColors.green90,
    surfaceVariant: AppColors.green50,
    onSurfaceVariant: AppColors.green90,
    outline: AppColors.green70,
    outlineVariant: AppColors.green50,
    shadow: AppColors.base90,
    scrim: AppColors.base90,
    inverseSurface: AppColors.green90,
    onInverseSurface: AppColors.green40,
    inversePrimary: AppColors.green50,
    surfaceTint: AppColors.green70,
  );
}