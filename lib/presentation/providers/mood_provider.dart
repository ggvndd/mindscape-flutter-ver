import 'package:flutter/material.dart';

/// Manages mood tracking state and quick logging functionality
class MoodProvider extends ChangeNotifier {
  Future<void> logMoodQuickly(String moodData) async {
    notifyListeners();
  }
}