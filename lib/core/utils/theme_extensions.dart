import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// Extensions for mood-specific styling and colors
extension MoodTypeExtensions on MoodType {
  /// Get the primary color for this mood type
  Color get primaryColor {
    switch (this) {
      case MoodType.veryHappy:
        return AppColors.moodVeryHappy;
      case MoodType.happy:
        return AppColors.moodHappy;
      case MoodType.neutral:
        return AppColors.moodNeutral;
      case MoodType.sad:
        return AppColors.moodSad;
      case MoodType.verySad:
        return AppColors.moodVerySad;
    }
  }

  /// Get the background color for mood cards
  Color get backgroundColor {
    switch (this) {
      case MoodType.veryHappy:
        return AppColors.yellow40;
      case MoodType.happy:
        return AppColors.green40;
      case MoodType.neutral:
        return AppColors.base40;
      case MoodType.sad:
        return AppColors.orange40;
      case MoodType.verySad:
        return AppColors.brown40;
    }
  }

  /// Get the text color that contrasts well with the background
  Color get textColor {
    switch (this) {
      case MoodType.veryHappy:
        return AppColors.yellow90;
      case MoodType.happy:
        return AppColors.green90;
      case MoodType.neutral:
        return AppColors.base90;
      case MoodType.sad:
        return AppColors.orange90;
      case MoodType.verySad:
        return AppColors.brown90;
    }
  }

  /// Get the border color for mood indicators
  Color get borderColor {
    switch (this) {
      case MoodType.veryHappy:
        return AppColors.yellow70;
      case MoodType.happy:
        return AppColors.green70;
      case MoodType.neutral:
        return AppColors.base60;
      case MoodType.sad:
        return AppColors.orange70;
      case MoodType.verySad:
        return AppColors.brown70;
    }
  }

  /// Get a gradient for mood visualization
  LinearGradient get gradient {
    switch (this) {
      case MoodType.veryHappy:
        return const LinearGradient(
          colors: [AppColors.yellow70, AppColors.yellow40],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case MoodType.happy:
        return const LinearGradient(
          colors: [AppColors.green70, AppColors.green40],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case MoodType.neutral:
        return const LinearGradient(
          colors: [AppColors.base60, AppColors.base40],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case MoodType.sad:
        return const LinearGradient(
          colors: [AppColors.orange70, AppColors.orange40],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case MoodType.verySad:
        return const LinearGradient(
          colors: [AppColors.brown70, AppColors.brown40],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

/// Extensions for stress level styling
extension StressLevelExtensions on StressLevel {
  /// Get the color associated with this stress level
  Color get color {
    switch (this) {
      case StressLevel.low:
        return AppColors.stressLow;
      case StressLevel.moderate:
        return AppColors.stressMedium;
      case StressLevel.high:
        return AppColors.stressHigh;
      case StressLevel.extreme:
        return AppColors.brown80;
    }
  }

  /// Get the background color for stress indicators
  Color get backgroundColor {
    switch (this) {
      case StressLevel.low:
        return AppColors.green50;
      case StressLevel.moderate:
        return AppColors.yellow50;
      case StressLevel.high:
        return AppColors.orange50;
      case StressLevel.extreme:
        return AppColors.brown50;
    }
  }

  /// Get appropriate text color for contrast
  Color get textColor {
    switch (this) {
      case StressLevel.low:
        return AppColors.green90;
      case StressLevel.moderate:
        return AppColors.yellow90;
      case StressLevel.high:
        return AppColors.orange90;
      case StressLevel.extreme:
        return AppColors.brown90;
    }
  }
}

/// Color utilities for adaptive contexts
class AdaptiveColors {
  /// Get calming colors for high-stress situations
  static const Color calmingPrimary = AppColors.green70;
  static const Color calmingBackground = AppColors.green40;
  static const Color calmingAccent = AppColors.calmingAccent;

  /// Get night mode appropriate colors
  static const Color nightPrimary = AppColors.brown60;
  static const Color nightBackground = AppColors.base90;
  static const Color nightAccent = AppColors.nightModeAccent;

  /// Crisis intervention colors (high visibility)
  static const Color crisisBackground = AppColors.error;
  static const Color crisisText = Color(0xFFFFFFFF);
  static const Color crisisButton = AppColors.yellow80;

  /// Get color based on time of day
  static Color getTimeBasedAccent(int hour) {
    if (hour >= 6 && hour < 12) {
      // Morning - energizing yellows
      return AppColors.yellow70;
    } else if (hour >= 12 && hour < 18) {
      // Afternoon - balanced greens
      return AppColors.green70;
    } else if (hour >= 18 && hour < 22) {
      // Evening - warm oranges
      return AppColors.orange60;
    } else {
      // Night - calming browns
      return AppColors.brown60;
    }
  }

  /// Get stress-appropriate color palette
  static ColorScheme getStressColorScheme(StressLevel level, {bool isDark = false}) {
    final baseScheme = isDark ? AppColorSchemes.darkScheme : AppColorSchemes.lightScheme;
    
    switch (level) {
      case StressLevel.low:
        return baseScheme;
      case StressLevel.moderate:
        return baseScheme.copyWith(
          primary: AppColors.yellow70,
          primaryContainer: AppColors.yellow50,
          secondary: AppColors.orange60,
          secondaryContainer: AppColors.orange45,
        );
      case StressLevel.high:
      case StressLevel.extreme:
        return AppColorSchemes.calmScheme;
    }
  }
}