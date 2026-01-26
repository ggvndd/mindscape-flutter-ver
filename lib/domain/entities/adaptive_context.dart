import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Adaptive context that determines UI behavior
class AdaptiveContext {
  final StressLevel stressLevel;
  final TimeOfDay timeOfDay;
  final bool isMoving;
  final bool hasTimeConstraint;
  final InputMethod preferredInputMethod;
  final bool isDarkMode;

  const AdaptiveContext({
    required this.stressLevel,
    required this.timeOfDay,
    required this.isMoving,
    required this.hasTimeConstraint,
    required this.preferredInputMethod,
    required this.isDarkMode,
  });

  factory AdaptiveContext.normal() {
    return AdaptiveContext(
      stressLevel: StressLevel.low,
      timeOfDay: TimeOfDay.now(),
      isMoving: false,
      hasTimeConstraint: false,
      preferredInputMethod: InputMethod.emoji,
      isDarkMode: false,
    );
  }

  bool get isHighStress => stressLevel.value >= AppConstants.highStressThreshold;
  bool get isLateNight => timeOfDay.hour >= 22 || timeOfDay.hour <= 6;
  bool get shouldUseSimpleUI => isHighStress || hasTimeConstraint;
}

/// Input methods for mood logging
enum InputMethod {
  emoji,
  voice,
  text
}