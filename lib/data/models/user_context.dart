import 'package:hive/hive.dart';

part 'user_context.g.dart';

/// Stores user behavioral context for adaptive features
@HiveType(typeId: 5)
class UserContext extends HiveObject {
  @HiveField(0)
  final String userId;
  
  @HiveField(1)
  final List<String> tags; // Current context tags
  
  @HiveField(2)
  final DateTime lastUpdated;
  
  @HiveField(3)
  final UserBehaviorPattern behaviorPattern;
  
  @HiveField(4)
  final Map<String, dynamic> preferences;
  
  UserContext({
    required this.userId,
    required this.tags,
    required this.lastUpdated,
    required this.behaviorPattern,
    this.preferences = const {},
  });
}

/// User behavioral patterns for personalized interactions
@HiveType(typeId: 6)
class UserBehaviorPattern extends HiveObject {
  @HiveField(0)
  final double averageMoodScore;
  
  @HiveField(1)
  final List<int> mostActiveHours; // Hours when user is most active
  
  @HiveField(2)
  final InteractionStyle preferredInteractionStyle;
  
  @HiveField(3)
  final List<String> commonMoodTriggers;
  
  @HiveField(4)
  final ConversationLength conversationLengthPreference;
  
  @HiveField(5)
  final Map<String, double> moodPatterns; // Day patterns, location patterns, etc.
  
  @HiveField(6)
  final DateTime lastAnalyzed;
  
  UserBehaviorPattern({
    required this.averageMoodScore,
    required this.mostActiveHours,
    required this.preferredInteractionStyle,
    required this.commonMoodTriggers,
    required this.conversationLengthPreference,
    this.moodPatterns = const {},
    required this.lastAnalyzed,
  });
  
  /// Generate fine-tuning prompts based on user behavior
  List<Map<String, String>> generateFineTuningData() {
    final prompts = <Map<String, String>>[];
    
    // Personalized greeting based on active hours
    if (mostActiveHours.isNotEmpty) {
      final peakHour = mostActiveHours.first;
      final greeting = peakHour < 12 ? "morning" : peakHour < 17 ? "afternoon" : "evening";
      prompts.add({
        'prompt': 'Generate a casual Indonesian greeting for $greeting time for a UGM student',
        'completion': 'Hai! Gimana kabar kamu ${greeting == "morning" ? "pagi" : greeting == "afternoon" ? "siang" : "malam"} ini? 😊',
      });
    }
    
    // Mood-specific responses based on patterns
    if (averageMoodScore < 2.5) {
      prompts.add({
        'prompt': 'User frequently reports low mood. Respond empathetically in Indonesian casual style',
        'completion': 'Aku notice kamu sering feeling down lately. Want to talk about what\'s been bothering you? Aku di sini to listen 💙',
      });
    }
    
    // Common triggers handling
    for (final trigger in commonMoodTriggers.take(3)) {
      prompts.add({
        'prompt': 'User mentions "$trigger" which often affects their mood negatively',
        'completion': 'I see kamu mention $trigger. That seems to be something yang sering affect mood kamu ya? How are you dealing dengan ini sekarang? 🤔',
      });
    }
    
    return prompts;
  }
}

@HiveType(typeId: 7)
enum InteractionStyle {
  @HiveField(0)
  quick,
  @HiveField(1)
  balanced,
  @HiveField(2)
  detailed;
  
  String get description {
    switch (this) {
      case quick: return 'Prefers quick, one-tap interactions';
      case balanced: return 'Mix of quick and detailed interactions';
      case detailed: return 'Prefers detailed conversations';
    }
  }
}

@HiveType(typeId: 8)
enum ConversationLength {
  @HiveField(0)
  short,
  @HiveField(1)
  medium,
  @HiveField(2)
  long;
  
  int get averageWords {
    switch (this) {
      case short: return 10;
      case medium: return 25;
      case long: return 50;
    }
  }
}