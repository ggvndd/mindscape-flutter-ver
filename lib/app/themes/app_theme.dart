import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../domain/entities/adaptive_context.dart';

/// Adaptive themes for different user contexts
class AppTheme {
  static ThemeData getTheme(AdaptiveContext context) {
    if (context.isDarkMode || context.isLateNight) {
      return _darkTheme;
    }
    
    if (context.isHighStress) {
      return _calmTheme;
    }
    
    return _defaultTheme;
  }

  static final ThemeData _defaultTheme = ThemeData(
    useMaterial3: true,
    colorScheme: AppColorSchemes.lightScheme,
    textTheme: AppTypography.textTheme,
    fontFamily: AppTypography.fontFamily,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      surfaceTintColor: AppColors.primary,
      titleTextStyle: AppTypography.titleLarge.copyWith(
        color: AppColors.onSurface,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.base50),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.base50),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.base60,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: AppColors.surface,
      surfaceTintColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 6,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.base60,
      elevation: 8,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.base45,
      thickness: 1,
      space: 1,
    ),
  );

  static final ThemeData _calmTheme = ThemeData(
    useMaterial3: true,
    colorScheme: AppColorSchemes.calmScheme,
    textTheme: AppTypography.textTheme,
    fontFamily: AppTypography.fontFamily,
    // Larger touch targets for stressed users
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.green40,
      foregroundColor: AppColors.green90,
      surfaceTintColor: AppColors.green70,
      titleTextStyle: AppTypography.titleLarge.copyWith(
        color: AppColors.green90,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green70,
        foregroundColor: AppColors.onPrimary,
        textStyle: AppTypography.adaptiveLarge,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(120, 56), // Larger for stress situations
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.green70,
        textStyle: AppTypography.adaptiveLarge,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(120, 56),
        side: const BorderSide(color: AppColors.green70, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.green50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.green60),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.green60),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.green80, width: 2),
      ),
      contentPadding: const EdgeInsets.all(20), // More padding for easier touch
      labelStyle: AppTypography.bodyLarge.copyWith(
        color: AppColors.green90,
      ),
      hintStyle: AppTypography.bodyLarge.copyWith(
        color: AppColors.green70,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      color: AppColors.surface,
      surfaceTintColor: AppColors.green70,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.all(16),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: AppColorSchemes.darkScheme,
    textTheme: AppTypography.textTheme,
    fontFamily: AppTypography.fontFamily,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: AppColors.base90,
      foregroundColor: AppColors.base40,
      surfaceTintColor: AppColors.green60,
      titleTextStyle: AppTypography.titleLarge.copyWith(
        color: AppColors.base40,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green60,
        foregroundColor: AppColors.green90,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.green60,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: const BorderSide(color: AppColors.green60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.base70,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.base50),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.base50),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.green60, width: 2),
      ),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.base45,
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.base50,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: AppColors.base80,
      surfaceTintColor: AppColors.green60,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.base90,
      selectedItemColor: AppColors.green60,
      unselectedItemColor: AppColors.base50,
      elevation: 8,
    ),
  );
}