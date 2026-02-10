import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to seed dummy mood data for testing
/// Run this once to populate the database with sample mood entries
class MoodDataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  
  MoodDataSeeder(this.userId);

  final List<String> moods = [
    'gloomy',
    'sad', 
    'justokay',
    'fine',
    'happy',
    'cheerful',
  ];

  final List<String?> sampleNotes = [
    'Hari yang melelahkan di kampus',
    'Tugas menumpuk banget',
    'Alhamdulillah hari ini produktif',
    'Ngobrol sama temen, jadi lebih baik',
    'Presentasi lancar!',
    'Capek tapi puas',
    'Lagi stress mikirin deadline',
    'Santai aja hari ini',
    'Semangat buat besok!',
    null,
    null,
    null, // Some moods without notes
  ];

  int getMoodScore(String mood) {
    switch (mood) {
      case 'gloomy': return 0;
      case 'sad': return 20;
      case 'justokay': return 40;
      case 'fine': return 60;
      case 'happy': return 80;
      case 'cheerful': return 100;
      default: return 60;
    }
  }

  Future<void> seedData() async {
    print('🌱 Starting to seed mood data for user: $userId');
    
    final random = Random();
    final now = DateTime.now();
    int totalEntries = 0;

    try {
      // Generate data for the past 30 days
      for (int daysAgo = 30; daysAgo >= 0; daysAgo--) {
        final date = now.subtract(Duration(days: daysAgo));
        
        // Generate 2-4 mood entries per day at different times
        final entriesPerDay = 2 + random.nextInt(3);
        
        for (int i = 0; i < entriesPerDay; i++) {
          // Spread entries throughout the day (6am to 11pm)
          final hour = 6 + random.nextInt(17);
          final minute = random.nextInt(60);
          
          final timestamp = DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          );

          // Bias towards positive moods (60% positive, 30% neutral, 10% negative)
          String selectedMood;
          final moodRoll = random.nextInt(100);
          if (moodRoll < 10) {
            // 10% negative
            selectedMood = moods[random.nextInt(2)]; // gloomy or sad
          } else if (moodRoll < 40) {
            // 30% neutral
            selectedMood = moods[2 + random.nextInt(2)]; // justokay or fine
          } else {
            // 60% positive
            selectedMood = moods[4 + random.nextInt(2)]; // happy or cheerful
          }

          final note = sampleNotes[random.nextInt(sampleNotes.length)];

          final moodData = {
            'userId': userId,
            'mood': selectedMood,
            'moodScore': getMoodScore(selectedMood),
            'timestamp': Timestamp.fromDate(timestamp),
            'note': note,
          };

          await _firestore
              .collection('users')
              .doc(userId)
              .collection('moods')
              .add(moodData);
          totalEntries++;
          
          // Small delay to avoid overwhelming Firestore
          await Future.delayed(const Duration(milliseconds: 50));
        }
        
        print('📅 Added moods for ${date.day}/${date.month}/${date.year}');
      }

      print('✅ Successfully seeded $totalEntries mood entries!');
      print('📊 You can now view the mood tracker with real data visualization');
      
    } catch (e) {
      print('❌ Error seeding data: $e');
    }
  }

  /// Add specific moods for today at common intervals
  Future<void> seedTodayData() async {
    print('🌱 Adding mood data for today...');
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final todayMoods = [
      {'time': 7, 'mood': 'fine', 'note': 'Bangun pagi, siap untuk hari ini'},
      {'time': 10, 'mood': 'happy', 'note': 'Kelas pagi berjalan lancar'},
      {'time': 13, 'mood': 'cheerful', 'note': 'Makan siang bareng temen'},
      {'time': 16, 'mood': 'justokay', 'note': 'Mulai agak capek'},
      {'time': 19, 'mood': 'fine', 'note': 'Santai di kos'},
      {'time': 22, 'mood': 'happy', 'note': 'Nonton series favorit'},
    ];

    try {
      for (var entry in todayMoods) {
        final timestamp = today.add(Duration(hours: entry['time'] as int));
        
        final moodData = {
          'userId': userId,
          'mood': entry['mood'] as String,
          'moodScore': getMoodScore(entry['mood'] as String),
          'timestamp': Timestamp.fromDate(timestamp),
          'note': entry['note'] as String?,
        };

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('moods')
            .add(moodData);
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      print('✅ Successfully added ${todayMoods.length} moods for today!');
    } catch (e) {
      print('❌ Error seeding today\'s data: $e');
    }
  }
}

// Helper function to run the seeder
Future<void> seedMoodDataForUser(String userId, {bool todayOnly = false}) async {
  final seeder = MoodDataSeeder(userId);
  
  if (todayOnly) {
    await seeder.seedTodayData();
  } else {
    await seeder.seedData();
  }
}
