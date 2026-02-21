import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/mood.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Log a new mood
  Future<void> logMood({
    required String userId,
    required String mood,
    String? note,
  }) async {
    try {
      final moodScore = Mood.getMoodScore(mood);
      final moodData = Mood(
        id: '', // Firestore will generate this
        userId: userId,
        mood: mood,
        moodScore: moodScore,
        timestamp: DateTime.now(),
        note: note,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('moods')
          .add(moodData.toFirestore());
    } catch (e) {
      throw Exception('Failed to log mood: $e');
    }
  }

  // Get moods for a specific date range
  Future<List<Mood>> getMoodsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('moods')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: false)
          .get();

      return querySnapshot.docs.map((doc) => Mood.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get moods: $e');
    }
  }

  // Get moods for a specific day with hourly breakdown
  Future<Map<String, Mood?>> getDailyMoods({
    required String userId,
    required DateTime date,
  }) async {
    try {
      // Get start and end of the day
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final moods = await getMoodsByDateRange(
        userId: userId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // Create map with 3-hour intervals
      Map<String, Mood?> dailyMoods = {
        '04:00': null,
        '07:00': null,
        '10:00': null,
        '13:00': null,
        '16:00': null,
        '19:00': null,
        '22:00': null,
      };

      // Find the closest mood for each time slot
      for (var timeSlot in dailyMoods.keys) {
        final hour = int.parse(timeSlot.split(':')[0]);
        
        // Find moods within 1.5 hours of this time slot
        final targetHour = hour;
        final closestMood = moods.where((mood) {
          final moodHour = mood.timestamp.hour;
          return (moodHour - targetHour).abs() <= 1.5;
        }).fold<Mood?>(null, (closest, mood) {
          if (closest == null) return mood;
          final closestDiff = (closest.timestamp.hour - targetHour).abs();
          final currentDiff = (mood.timestamp.hour - targetHour).abs();
          return currentDiff < closestDiff ? mood : closest;
        });

        dailyMoods[timeSlot] = closestMood;
      }

      return dailyMoods;
    } catch (e) {
      throw Exception('Failed to get daily moods: $e');
    }
  }

  // Get weekly mood data (7 days with average scores)
  Future<List<Map<String, dynamic>>> getWeeklyMoodData({
    required String userId,
    required DateTime startDate,
  }) async {
    try {
      List<Map<String, dynamic>> weeklyData = [];

      for (int i = 0; i < 7; i++) {
        final currentDate = startDate.add(Duration(days: i));
        final dayStart = DateTime(currentDate.year, currentDate.month, currentDate.day, 0, 0, 0);
        final dayEnd = DateTime(currentDate.year, currentDate.month, currentDate.day, 23, 59, 59);

        final dayMoods = await getMoodsByDateRange(
          userId: userId,
          startDate: dayStart,
          endDate: dayEnd,
        );

        // Calculate average mood score for the day
        int averageScore = 60; // Default to "fine"
        if (dayMoods.isNotEmpty) {
          final totalScore = dayMoods.fold<int>(0, (sum, mood) => sum + mood.moodScore);
          averageScore = (totalScore / dayMoods.length).round();
        }

        weeklyData.add({
          'day': _getDayName(currentDate.weekday),
          'score': averageScore,
          'date': currentDate,
        });
      }

      return weeklyData;
    } catch (e) {
      throw Exception('Failed to get weekly mood data: $e');
    }
  }

  // Calculate overall mindscore (average of last 30 days)
  Future<int> calculateMindscore(String userId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final moods = await getMoodsByDateRange(
        userId: userId,
        startDate: thirtyDaysAgo,
        endDate: now,
      );

      if (moods.isEmpty) {
        return 60; // Default mindscore
      }

      final totalScore = moods.fold<int>(0, (sum, mood) => sum + mood.moodScore);
      return (totalScore / moods.length).round();
    } catch (e) {
      throw Exception('Failed to calculate mindscore: $e');
    }
  }

  // Get monthly mindscore data for the last 12 months
  Future<List<Map<String, dynamic>>> getMonthlyMindscoreData({
    required String userId,
  }) async {
    try {
      final now = DateTime.now();
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      List<Map<String, dynamic>> monthlyData = [];

      for (int i = 11; i >= 0; i--) {
        int targetMonth = now.month - i;
        int targetYear = now.year;
        while (targetMonth <= 0) {
          targetMonth += 12;
          targetYear--;
        }

        final monthStart = DateTime(targetYear, targetMonth, 1, 0, 0, 0);
        final isLastDayNeeded = targetMonth == 12;
        final monthEnd = isLastDayNeeded
            ? DateTime(targetYear + 1, 1, 1).subtract(const Duration(seconds: 1))
            : DateTime(targetYear, targetMonth + 1, 1).subtract(const Duration(seconds: 1));

        final monthMoods = await getMoodsByDateRange(
          userId: userId,
          startDate: monthStart,
          endDate: monthEnd,
        );

        final hasData = monthMoods.isNotEmpty;
        int averageScore = 0;
        if (hasData) {
          final total = monthMoods.fold<int>(0, (sum, m) => sum + m.moodScore);
          averageScore = (total / monthMoods.length).round();
        }

        monthlyData.add({
          'month': monthNames[targetMonth - 1],
          'year': targetYear,
          'score': averageScore,
          'hasData': hasData,
        });
      }

      return monthlyData;
    } catch (e) {
      throw Exception('Failed to get monthly mindscore data: $e');
    }
  }

  // Get the most recent mood
  Future<Mood?> getLatestMood(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('moods')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return Mood.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to get latest mood: $e');
    }
  }

  // Helper method to get day name
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Senin';
    }
  }

  // Delete a mood
  Future<void> deleteMood(String userId, String moodId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('moods')
          .doc(moodId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete mood: $e');
    }
  }

  // Update a mood
  Future<void> updateMood({
    required String userId,
    required String moodId,
    String? mood,
    String? note,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      
      if (mood != null) {
        updates['mood'] = mood;
        updates['moodScore'] = Mood.getMoodScore(mood);
      }
      
      if (note != null) {
        updates['note'] = note;
      }

      if (updates.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('moods')
            .doc(moodId)
            .update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update mood: $e');
    }
  }
}
