import 'package:flutter/material.dart';
import '../../../domain/entities/adaptive_context.dart';
import '../../../core/constants/app_constants.dart';

/// Context detector for adaptive behavior based on user state and environment
class ContextDetector {
  static ContextDetector? _instance;
  
  ContextDetector._internal();
  
  static ContextDetector get instance {
    _instance ??= ContextDetector._internal();
    return _instance!;
  }
  
  static Future<void> initialize() async {
    // Initialize sensors and permissions
    await instance._initializeSensors();
  }

  Future<void> _initializeSensors() async {
    // TODO: Initialize motion sensors, device state detection
    // Implementation akan menggunakan sensors_plus package
  }

  /// Detect current user context for adaptive UI behavior
  Future<AdaptiveContext> detectCurrentContext({
    List<MoodEntry>? recentMoodHistory,
    UserProfile? userProfile,
  }) async {
    final timeOfDay = TimeOfDay.now();
    
    // Analyze stress level from recent moods
    final stressLevel = _analyzeStressLevel(recentMoodHistory);
    
    // Detect if user is moving (for voice input preference)
    final isMoving = await _detectMotion();
    
    // Determine if user has time constraints
    final hasTimeConstraint = _checkTimeConstraints(timeOfDay, userProfile);
    
    // Choose optimal input method
    final inputMethod = _determineOptimalInputMethod(
      stressLevel: stressLevel,
      isMoving: isMoving,
      timeOfDay: timeOfDay,
      hasTimeConstraint: hasTimeConstraint,
    );
    
    return AdaptiveContext(
      stressLevel: stressLevel,
      timeOfDay: timeOfDay,
      isMoving: isMoving,
      hasTimeConstraint: hasTimeConstraint,
      preferredInputMethod: inputMethod,
      isDarkMode: _shouldUseDarkMode(timeOfDay, stressLevel),
    );
  }

  StressLevel _analyzeStressLevel(List<MoodEntry>? moods) {
    if (moods == null || moods.isEmpty) return StressLevel.low;
    
    // Calculate average mood value from recent entries
    final recentMoods = moods.take(5); // Last 5 entries
    final averageMoodValue = recentMoods
        .map((m) => m.moodType.value)
        .reduce((a, b) => a + b) / recentMoods.length;
    
    // Convert mood to stress level (inverse relationship)
    if (averageMoodValue <= 2.0) return StressLevel.extreme;
    if (averageMoodValue <= 2.5) return StressLevel.high;
    if (averageMoodValue <= 3.5) return StressLevel.moderate;
    return StressLevel.low;
  }

  Future<bool> _detectMotion() async {
    // TODO: Implement motion detection using accelerometer
    // For now, return false
    return false;
  }

  bool _checkTimeConstraints(TimeOfDay time, UserProfile? profile) {
    // Check if it's typically a busy time based on user's schedule
    final hour = time.hour;
    
    // Common busy times for students with side gigs
    final busyHours = [7, 8, 12, 13, 17, 18, 19]; // Morning rush, lunch, evening
    
    return busyHours.contains(hour);
  }

  InputMethod _determineOptimalInputMethod({
    required StressLevel stressLevel,
    required bool isMoving,
    required TimeOfDay timeOfDay,
    required bool hasTimeConstraint,
  }) {
    // High stress = simplest input (emoji)
    if (stressLevel == StressLevel.extreme || stressLevel == StressLevel.high) {
      return InputMethod.emoji;
    }
    
    // Moving or late night = voice input
    if (isMoving || (timeOfDay.hour >= 22 || timeOfDay.hour <= 6)) {
      return InputMethod.voice;
    }
    
    // Time constraint = fastest input (emoji)
    if (hasTimeConstraint) {
      return InputMethod.emoji;
    }
    
    // Default to text for most expressive input
    return InputMethod.text;
  }

  bool _shouldUseDarkMode(TimeOfDay time, StressLevel stress) {
    // Auto dark mode for late night or high stress
    return (time.hour >= 20 || time.hour <= 7) || 
           stress == StressLevel.high || 
           stress == StressLevel.extreme;
  }
}

// Placeholder classes - these will be defined in their respective files
class MoodEntry {
  final MoodType moodType;
  final DateTime timestamp;
  
  MoodEntry({required this.moodType, required this.timestamp});
}

class UserProfile {
  final List<int> busyHours;
  
  UserProfile({required this.busyHours});
}