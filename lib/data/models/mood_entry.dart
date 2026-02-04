import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

part 'mood_entry.g.dart';

/// Enhanced data model for mood entries with adaptive features
@HiveType(typeId: 2)
class MoodEntry extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final MoodType moodType;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final DateTime timestamp;
  
  @HiveField(4)
  final Map<String, dynamic>? context; // User context when mood was logged
  
  /// Whether this was a quick entry (rush hour mode)
  @HiveField(5)
  final bool isQuickEntry;
  
  /// Context tags for ML training
  @HiveField(6)
  final List<String> contextTags;
  
  /// Location context if available
  @HiveField(7)
  final LocationContext? location;
  
  /// Activity being done (studying, working, etc.)
  @HiveField(8)
  final String? activity;
  
  /// Stress level (1-10) - separate from mood
  @HiveField(9)
  final int? stressLevel;
  
  /// Energy level (1-10)
  @HiveField(10)
  final int? energyLevel;
  
  MoodEntry({
    required this.id,
    required this.moodType,
    this.description,
    required this.timestamp,
    this.context,
    this.isQuickEntry = false,
    this.contextTags = const [],
    this.location,
    this.activity,
    this.stressLevel,
    this.energyLevel,
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
      isQuickEntry: json['is_quick_entry'] ?? false,
      contextTags: List<String>.from(json['context_tags'] ?? []),
      location: json['location'] != null ? 
        LocationContext.fromJson(json['location']) : null,
      activity: json['activity'],
      stressLevel: json['stress_level'],
      energyLevel: json['energy_level'],
    );
  }

  factory MoodEntry.fromFirestore(Map<String, dynamic> data, String id) {
    return MoodEntry(
      id: id,
      moodType: MoodType.values.firstWhere(
        (type) => type.name == data['mood_type'],
        orElse: () => MoodType.neutral,
      ),
      description: data['description'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      context: data['context'],
      isQuickEntry: data['is_quick_entry'] ?? false,
      contextTags: List<String>.from(data['context_tags'] ?? []),
      location: data['location'] != null ? 
        LocationContext.fromJson(Map<String, dynamic>.from(data['location'])) : null,
      activity: data['activity'],
      stressLevel: data['stress_level'],
      energyLevel: data['energy_level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood_type': moodType.name,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'context': context,
      'is_quick_entry': isQuickEntry,
      'context_tags': contextTags,
      'location': location?.toJson(),
      'activity': activity,
      'stress_level': stressLevel,
      'energy_level': energyLevel,
    };
  }

  /// Convert to training data for ML models and chatbot fine-tuning
  Map<String, dynamic> toTrainingData() {
    return {
      'mood_numeric': moodType.value,
      'mood_label': moodType.label.toLowerCase(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'hour_of_day': timestamp.hour,
      'day_of_week': timestamp.weekday,
      'is_weekend': timestamp.weekday >= 6,
      'note_sentiment': description != null ? _analyzeSentiment(description!) : 0.0,
      'note_length': description?.length ?? 0,
      'context_tags': contextTags,
      'is_quick_entry': isQuickEntry,
      'stress_level': stressLevel,
      'energy_level': energyLevel,
      'activity': activity,
      'location_type': location?.type,
      'calculated_stress': calculatedStressLevel,
    };
  }

  /// Calculate stress level from mood value (existing logic)
  double get calculatedStressLevel {
    // Inverse relationship: lower mood value = higher stress
    return (6 - moodType.value) / 5.0;
  }
  
  /// Simple sentiment analysis for fine-tuning data
  double _analyzeSentiment(String text) {
    final positiveWords = ['good', 'great', 'happy', 'excited', 'awesome', 'better', 'baik', 'senang', 'keren', 'suka'];
    final negativeWords = ['bad', 'terrible', 'sad', 'angry', 'stress', 'tired', 'buruk', 'sedih', 'capek', 'lelah', 'bosan'];
    
    final lowerText = text.toLowerCase();
    int positive = 0;
    int negative = 0;
    
    for (final word in positiveWords) {
      if (lowerText.contains(word)) positive++;
    }
    
    for (final word in negativeWords) {
      if (lowerText.contains(word)) negative++;
    }
    
    if (positive + negative == 0) return 0.0;
    return (positive - negative) / (positive + negative);
  }
}

/// Location context for better mood analysis
@HiveType(typeId: 4)
class LocationContext extends HiveObject {
  @HiveField(0)
  final String type; // "home", "campus", "work", "public"
  
  @HiveField(1)
  final String? name; // "UGM", "Perpustakaan", etc.
  
  @HiveField(2)
  final double? latitude;
  
  @HiveField(3)
  final double? longitude;
  
  LocationContext({
    required this.type,
    this.name,
    this.latitude,
    this.longitude,
  });
  
  factory LocationContext.fromJson(Map<String, dynamic> json) {
    return LocationContext(
      type: json['type'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}