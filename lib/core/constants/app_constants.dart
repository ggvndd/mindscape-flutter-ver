/// Application-wide constants
class AppConstants {
  static const String appName = 'Mindscape';
  static const String appVersion = '1.0.0';
  
  // Task completion time target (for TSR-CC evaluation)
  static const Duration quickLogTargetDuration = Duration(seconds: 15);
  
  // Mood tracking constants
  static const int maxMoodHistoryDays = 90;
  static const int defaultTrendDays = 7;
  
  // Adaptive behavior thresholds
  static const double highStressThreshold = 0.7;
  static const double moderateStressThreshold = 0.4;
  
  // Crisis detection
  static const List<String> crisisKeywords = [
    'bunuh diri', 'suicide', 'mati aja', 'gak kuat lagi', 'putus asa',
    'depresi berat', 'panic attack', 'self harm', 'cutting'
  ];
}

/// Mood types with emoji representations and colors
enum MoodType {
  veryHappy('😄', 'Sangat Senang', 5),
  happy('😊', 'Senang', 4),
  neutral('😐', 'Biasa Aja', 3),
  sad('😔', 'Sedih', 2),
  verySad('😢', 'Sangat Sedih', 1);

  const MoodType(this.emoji, this.label, this.value);
  final String emoji;
  final String label;
  final int value;
}

/// Stress levels for adaptive behavior
enum StressLevel {
  low(0.0, 'Santai'),
  moderate(0.4, 'Agak Stres'),
  high(0.7, 'Stres Berat'),
  extreme(0.9, 'Burnout');

  const StressLevel(this.value, this.label);
  final double value;
  final String label;
}