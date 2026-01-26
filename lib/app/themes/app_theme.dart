import 'package:flutter/material.dart';
import '../../../domain/entities/adaptive_context.dart';

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
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C63FF), // Purple theme
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
    ),
  );

  static final ThemeData _calmTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF81C784), // Calming green
      brightness: Brightness.light,
    ),
    // Larger touch targets for stressed users
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C63FF),
      brightness: Brightness.dark,
    ),
  );
}