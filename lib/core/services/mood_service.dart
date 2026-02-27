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
    int intervalHours = 3,
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

      // Anchor slots to the first log of the day (or 04:00 if no logs yet on
      // a past date, or the current hour on today-with-no-logs).
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      int anchorHour;
      if (moods.isNotEmpty) {
        // Use the earliest log's hour as anchor so slots line up with reality
        final earliest = moods.reduce(
            (a, b) => a.timestamp.isBefore(b.timestamp) ? a : b);
        anchorHour = earliest.timestamp.hour;
      } else if (isToday) {
        // No logs yet today — show upcoming slots from current hour
        anchorHour = DateTime.now().hour;
      } else {
        // Past date with no logs — fall back to 04:00
        anchorHour = 4;
      }

      // Build the ordered slot list anchored at anchorHour, spanning the full day
      final Set<int> slotHours = {};
      // Walk forward from anchor
      int h = anchorHour;
      while (h <= 23) {
        slotHours.add(h);
        h += intervalHours;
      }
      // Walk backward from anchor
      h = anchorHour - intervalHours;
      while (h >= 0) {
        slotHours.add(h);
        h -= intervalHours;
      }

      final sortedHours = slotHours.toList()..sort();
      Map<String, Mood?> dailyMoods = {
        for (final hour in sortedHours)
          '${hour.toString().padLeft(2, '0')}:00': null,
      };

      // Half-window for matching: moods within ±(interval/2) hours of a slot
      final halfWindow = intervalHours / 2;

      // Find the closest mood for each time slot
      for (var timeSlot in dailyMoods.keys) {
        final hour = int.parse(timeSlot.split(':')[0]);
        final targetHour = hour;

        final closestMood = moods.where((mood) {
          final moodHour = mood.timestamp.hour +
              mood.timestamp.minute / 60.0;
          return (moodHour - targetHour).abs() <= halfWindow;
        }).fold<Mood?>(null, (closest, mood) {
          if (closest == null) return mood;
          final closestDiff =
              (closest.timestamp.hour - targetHour).abs().toDouble();
          final currentDiff =
              (mood.timestamp.hour - targetHour).abs().toDouble();
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
        final hasData = dayMoods.isNotEmpty;
        int averageScore = 0;
        if (hasData) {
          final totalScore = dayMoods.fold<int>(0, (sum, mood) => sum + mood.moodScore);
          averageScore = (totalScore / dayMoods.length).round();
        }

        weeklyData.add({
          'day': _getDayName(currentDate.weekday),
          'score': averageScore,
          'hasData': hasData,
          'date': currentDate,
        });
      }

      return weeklyData;
    } catch (e) {
      throw Exception('Failed to get weekly mood data: $e');
    }
  }

  // Calculate overall mindscore (average of last 30 days)
  Future<int?> calculateMindscore(String userId) async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final moods = await getMoodsByDateRange(
        userId: userId,
        startDate: thirtyDaysAgo,
        endDate: now,
      );

      if (moods.isEmpty) {
        return null; // No data yet
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

  /// Returns the most recent mood logged within [now - intervalHours, now],
  /// or null if no mood has been logged in that window.
  Future<Mood?> getMoodInCurrentWindow(
    String userId,
    int intervalHours,
  ) async {
    final now = DateTime.now();
    final windowStart = now.subtract(Duration(hours: intervalHours));
    final moods = await getMoodsByDateRange(
      userId: userId,
      startDate: windowStart,
      endDate: now,
    );
    if (moods.isEmpty) return null;
    // Return the most recent one in this window
    moods.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return moods.first;
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
