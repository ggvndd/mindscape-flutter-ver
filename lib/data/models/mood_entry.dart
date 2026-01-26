import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Data model for mood entries
class MoodEntry {
  final String id;
  final MoodType moodType;
  final String? description;
  final DateTime timestamp;
  final Map<String, dynamic>? context; // User context when mood was logged
  
  const MoodEntry({
    required this.id,
    required this.moodType,
    this.description,
    required this.timestamp,
    this.context,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'],
      moodType: MoodType.values.firstWhere(
        (type) => type.name == json['mood_type'],
        orElse: () => MoodType.neutral,
      ),
      description: json['description'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      context: json['context'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood_type': moodType.name,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'context': context,
    };
  }

  /// Calculate stress level from mood value
  double get stressLevel {
    // Inverse relationship: lower mood value = higher stress
    return (6 - moodType.value) / 5.0;
  }
}