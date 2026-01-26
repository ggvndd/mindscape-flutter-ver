import 'package:flutter/material.dart';
import '../../../domain/entities/adaptive_context.dart';

/// Manages adaptive UI behavior and context awareness
class AdaptiveProvider extends ChangeNotifier {
  AdaptiveContext _currentContext = AdaptiveContext.normal();
  
  AdaptiveContext get currentContext => _currentContext;
  
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