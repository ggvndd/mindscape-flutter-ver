import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/adaptive_context.dart';

/// Manages adaptive UI behavior and context awareness
class AdaptiveProvider extends ChangeNotifier {
  AdaptiveContext _currentContext = AdaptiveContext.normal();
  static const String _darkModeKey = 'isDarkMode';

  AdaptiveContext get currentContext => _currentContext;
  bool get isDarkMode => _currentContext.isDarkMode;

  AdaptiveProvider() {
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_darkModeKey) ?? false;
      if (isDark != _currentContext.isDarkMode) {
        _currentContext = AdaptiveContext(
          stressLevel: _currentContext.stressLevel,
          timeOfDay: _currentContext.timeOfDay,
          isMoving: _currentContext.isMoving,
          hasTimeConstraint: _currentContext.hasTimeConstraint,
          preferredInputMethod: _currentContext.preferredInputMethod,
          isDarkMode: isDark,
        );
        notifyListeners();
      }
    } catch (e) {
      // If there's an error loading preferences, just use default
    }
  }

  Future<void> toggleDarkMode() async {
    final newDarkMode = !_currentContext.isDarkMode;
    _currentContext = AdaptiveContext(
      stressLevel: _currentContext.stressLevel,
      timeOfDay: _currentContext.timeOfDay,
      isMoving: _currentContext.isMoving,
      hasTimeConstraint: _currentContext.hasTimeConstraint,
      preferredInputMethod: _currentContext.preferredInputMethod,
      isDarkMode: newDarkMode,
    );
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, newDarkMode);
  }

  void updateContext(AdaptiveContext newContext) {
    if (_shouldUpdateUI(newContext)) {
      _currentContext = newContext;
      notifyListeners();
    }
  }

  bool _shouldUpdateUI(AdaptiveContext newContext) {
    return newContext.stressLevel != _currentContext.stressLevel ||
           newContext.preferredInputMethod != _currentContext.preferredInputMethod ||
           newContext.isDarkMode != _currentContext.isDarkMode;
  }
}