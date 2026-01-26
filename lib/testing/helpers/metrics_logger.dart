import 'package:flutter/material.dart';

/// TSR-CC Timer for measuring Task Success Rate under Cognitive Constraints
class TSRCCTimer {
  static const Duration targetDuration = Duration(seconds: 15);
  
  DateTime? _startTime;
  String? _currentTaskId;
  
  static final TSRCCTimer _instance = TSRCCTimer._internal();
  factory TSRCCTimer() => _instance;
  TSRCCTimer._internal();

  /// Start timing a task (e.g., mood logging)
  void startTask(String taskId) {
    _startTime = DateTime.now();
    _currentTaskId = taskId;
    
    debugPrint('TSR-CC Timer: Started task $taskId');
    
    // TODO: Log to analytics service
    _logEvent('tsr_task_started', {
      'task_id': taskId,
      'timestamp': _startTime!.millisecondsSinceEpoch,
    });
  }

  /// Complete task and calculate TSR-CC score
  double completeTask(String taskId, bool successful) {
    if (_startTime == null || _currentTaskId != taskId) {
      debugPrint('TSR-CC Timer: Invalid task completion for $taskId');
      return 0.0;
    }
    
    final duration = DateTime.now().difference(_startTime!);
    final withinTarget = duration <= targetDuration;
    final tsrScore = successful && withinTarget ? 1.0 : 0.0;
    
    debugPrint('TSR-CC Timer: Task $taskId completed in ${duration.inSeconds}s'
               ' (target: ${targetDuration.inSeconds}s), success: $successful, TSR: $tsrScore');
    
    // TODO: Log to analytics service
    _logEvent('tsr_task_completed', {
      'task_id': taskId,
      'duration_ms': duration.inMilliseconds,
      'duration_seconds': duration.inSeconds,
      'successful': successful,
      'within_target': withinTarget,
      'tsr_score': tsrScore,
    });
    
    _resetTimer();
    return tsrScore;
  }

  /// Cancel current task timing
  void cancelTask() {
    if (_currentTaskId != null) {
      debugPrint('TSR-CC Timer: Cancelled task $_currentTaskId');
      _logEvent('tsr_task_cancelled', {
        'task_id': _currentTaskId!,
        'partial_duration_ms': _startTime != null 
            ? DateTime.now().difference(_startTime!).inMilliseconds 
            : 0,
      });
    }
    _resetTimer();
  }

  void _resetTimer() {
    _startTime = null;
    _currentTaskId = null;
  }

  /// Get current task duration (for UI feedback)
  Duration? get currentDuration {
    if (_startTime == null) return null;
    return DateTime.now().difference(_startTime!);
  }

  /// Check if current task is within target time
  bool get isWithinTarget {
    final duration = currentDuration;
    if (duration == null) return true;
    return duration <= targetDuration;
  }

  void _logEvent(String eventName, Map<String, dynamic> parameters) {
    // TODO: Implement actual analytics logging
    // For now, just debug print
    debugPrint('Analytics: $eventName - $parameters');
  }
}

/// ERI (Emotional Response Index) evaluation logger
class ERILogger {
  static final ERILogger _instance = ERILogger._internal();
  factory ERILogger() => _instance;
  ERILogger._internal();

  /// Log user's emotional response to chatbot interaction
  Future<void> logERIEvaluation({
    required String sessionId,
    required int empathyScore, // 1-5 Likert scale
    required int helpfulnessScore, // 1-5 Likert scale
    required int overallSatisfaction, // 1-5 Likert scale
    String? feedback,
  }) async {
    final eriData = {
      'session_id': sessionId,
      'empathy_score': empathyScore,
      'helpfulness_score': helpfulnessScore,
      'overall_satisfaction': overallSatisfaction,
      'eri_composite': (empathyScore + helpfulnessScore + overallSatisfaction) / 3,
      'feedback': feedback,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    debugPrint('ERI Evaluation: $eriData');
    
    // TODO: Send to analytics service
    _logEvent('eri_evaluation', eriData);
  }

  /// Log interaction for later ERI evaluation
  void logInteraction({
    required String sessionId,
    required String userMessage,
    required String botResponse,
    required bool wasHelpful,
    int? perceivedEmpathy,
  }) {
    final interactionData = {
      'session_id': sessionId,
      'user_message_length': userMessage.length,
      'bot_response_length': botResponse.length,
      'was_helpful': wasHelpful,
      'perceived_empathy': perceivedEmpathy,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    // TODO: Store for later evaluation
    _logEvent('chat_interaction', interactionData);
  }

  void _logEvent(String eventName, Map<String, dynamic> parameters) {
    debugPrint('Analytics: $eventName - $parameters');
  }
}

/// PEI (Personalization Effectiveness Index) logger
class PEILogger {
  static final PEILogger _instance = PEILogger._internal();
  factory PEILogger() => _instance;
  PEILogger._internal();

  /// Log effectiveness of adaptive/personalized features
  void logAdaptiveFeature({
    required String featureName, // 'adaptive_input', 'theme_switch', 'context_detection'
    required int relevanceScore, // 1-5 Likert scale
    required String userContext,
    Map<String, dynamic>? additionalData,
  }) {
    final peiData = {
      'feature_name': featureName,
      'relevance_score': relevanceScore,
      'user_context': userContext,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...?additionalData,
    };

    debugPrint('PEI Log: $peiData');
    
    // TODO: Send to analytics service
    _logEvent('pei_evaluation', peiData);
  }

  /// Log context-based UI adaptations
  void logContextAdaptation({
    required String adaptationType, // 'input_method_switch', 'theme_change', 'ui_simplification'
    required String fromState,
    required String toState,
    required String trigger, // 'stress_level', 'time_of_day', 'motion_detected'
    required bool userAccepted,
  }) {
    final adaptationData = {
      'adaptation_type': adaptationType,
      'from_state': fromState,
      'to_state': toState,
      'trigger': trigger,
      'user_accepted': userAccepted,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _logEvent('context_adaptation', adaptationData);
  }

  void _logEvent(String eventName, Map<String, dynamic> parameters) {
    debugPrint('Analytics: $eventName - $parameters');
  }
}