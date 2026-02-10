import 'package:cloud_firestore/cloud_firestore.dart';

class Mood {
  final String id;
  final String userId;
  final String mood; // gloomy, sad, justokay, fine, happy, cheerful
  final int moodScore; // 0, 20, 40, 60, 80, 100
  final DateTime timestamp;
  final String? note;

  Mood({
    required this.id,
    required this.userId,
    required this.mood,
    required this.moodScore,
    required this.timestamp,
    this.note,
  });

  // Factory constructor to create Mood from Firestore document
  factory Mood.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Mood(
      id: doc.id,
      userId: data['userId'] ?? '',
      mood: data['mood'] ?? 'fine',
      moodScore: data['moodScore'] ?? 60,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      note: data['note'],
    );
  }

  // Convert Mood to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mood': mood,
      'moodScore': moodScore,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }

  // Helper method to get mood score from mood name
  static int getMoodScore(String mood) {
    switch (mood.toLowerCase()) {
      case 'gloomy':
        return 0;
      case 'sad':
        return 20;
      case 'justokay':
        return 40;
      case 'fine':
        return 60;
      case 'happy':
        return 80;
      case 'cheerful':
        return 100;
      default:
        return 60;
    }
  }

  // Helper method to get mood name display
  String getMoodDisplayName() {
    switch (mood) {
      case 'gloomy':
        return 'Gloomy';
      case 'sad':
        return 'Sad';
      case 'justokay':
        return 'Just Okay';
      case 'fine':
        return 'Fine';
      case 'happy':
        return 'Happy';
      case 'cheerful':
        return 'Cheerful';
      default:
        return 'Fine';
    }
  }

  // Copy with method for easy updates
  Mood copyWith({
    String? id,
    String? userId,
    String? mood,
    int? moodScore,
    DateTime? timestamp,
    String? note,
  }) {
    return Mood(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      moodScore: moodScore ?? this.moodScore,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }
}
