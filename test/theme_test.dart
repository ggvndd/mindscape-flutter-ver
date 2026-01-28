import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindscape_flutter/core/constants/constants.dart';
import 'package:mindscape_flutter/core/utils/utils.dart';
import 'package:mindscape_flutter/app/themes/app_theme.dart';
import 'package:mindscape_flutter/domain/entities/adaptive_context.dart';

void main() {
  group('Theme System Tests', () {
    test('Color constants are properly defined', () {
      // Test that colors are valid
      expect(AppColors.primary.value, isA<int>());
      expect(AppColors.green90.value, equals(0xFF5A6B38));
      expect(AppColors.green40.value, equals(0xFFF2F4EB));
      expect(AppColors.brown90.value, equals(0xFF372315));
      expect(AppColors.yellow70.value, equals(0xFFFFBD19));
      expect(AppColors.orange60.value, equals(0xFFED7E1C));
    });

    test('Typography uses Urbanist font family', () {
      expect(AppTypography.fontFamily, equals('Urbanist'));
      expect(AppTypography.bodyLarge.fontFamily, contains('Urbanist'));
      expect(AppTypography.headlineSmall.fontFamily, contains('Urbanist'));
      expect(AppTypography.titleMedium.fontFamily, contains('Urbanist'));
    });

    test('Mood type extensions work correctly', () {
      expect(MoodType.veryHappy.primaryColor, equals(AppColors.moodVeryHappy));
      expect(MoodType.happy.primaryColor, equals(AppColors.moodHappy));
      expect(MoodType.neutral.primaryColor, equals(AppColors.moodNeutral));
      expect(MoodType.sad.primaryColor, equals(AppColors.moodSad));
      expect(MoodType.verySad.primaryColor, equals(AppColors.moodVerySad));
    });

    test('Stress level extensions work correctly', () {
      expect(StressLevel.low.color, equals(AppColors.stressLow));
      expect(StressLevel.moderate.color, equals(AppColors.stressMedium));
      expect(StressLevel.high.color, equals(AppColors.stressHigh));
      expect(StressLevel.extreme.color, equals(AppColors.brown80));
    });

    test('Color schemes are properly defined', () {
      expect(AppColorSchemes.lightScheme.primary, equals(AppColors.primary));
      expect(AppColorSchemes.darkScheme.brightness, equals(Brightness.dark));
      expect(AppColorSchemes.calmScheme.primary, equals(AppColors.green70));
    });

    test('Adaptive themes work correctly', () {
      final defaultContext = AdaptiveContext(
        stressLevel: StressLevel.low,
        timeOfDay: const TimeOfDay(hour: 14, minute: 0),
        isMoving: false,
        hasTimeConstraint: false,
        preferredInputMethod: InputMethod.emoji,
        isDarkMode: false,
      );

      final darkContext = AdaptiveContext(
        stressLevel: StressLevel.low,
        timeOfDay: const TimeOfDay(hour: 23, minute: 0),
        isMoving: false,
        hasTimeConstraint: false,
        preferredInputMethod: InputMethod.emoji,
        isDarkMode: true,
      );

      final stressContext = AdaptiveContext(
        stressLevel: StressLevel.high,
        timeOfDay: const TimeOfDay(hour: 14, minute: 0),
        isMoving: false,
        hasTimeConstraint: false,
        preferredInputMethod: InputMethod.emoji,
        isDarkMode: false,
      );

      final defaultTheme = AppTheme.getTheme(defaultContext);
      final darkTheme = AppTheme.getTheme(darkContext);
      final calmTheme = AppTheme.getTheme(stressContext);

      expect(defaultTheme.colorScheme.brightness, equals(Brightness.light));
      expect(darkTheme.colorScheme.brightness, equals(Brightness.dark));
      expect(calmTheme.colorScheme.primary, equals(AppColors.green70));
    });

    test('Typography scale factors are reasonable', () {
      expect(AppTypography.displayLarge.fontSize, greaterThan(40));
      expect(AppTypography.bodyMedium.fontSize, greaterThan(12));
      expect(AppTypography.bodyMedium.fontSize, lessThan(20));
      expect(AppTypography.labelSmall.fontSize, greaterThan(8));
    });
  });
}