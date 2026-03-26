import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Singleton service that measures the Time-On-Task (TOT) for mood logging.
///
/// ## Lifecycle
/// ```
/// 1. User taps the "Log Mood" button
///       → caller invokes [startTimer('standard_ui')] or [startTimer('rush_hour_ui')]
/// 2. User fills in the logging screen.
///    – If the user cancels / hits back → caller invokes [cancelTimer]
/// 3. User taps "Submit"
///       → dialog calls [submitAndLog(moodName)]
///         • calculates elapsed milliseconds
///         • builds a structured payload
///         • pushes it to the `evaluation_logs` Firestore collection
///         • resets internal state
/// ```
///
/// Because the service is a singleton, the timer state survives widget
/// rebuilds and is safely accessible from both [MoodTrackerScreen] and
/// [RushHourModeScreen] without any provider or InheritedWidget setup.
class TotMeasurementService {
  TotMeasurementService._internal();

  /// The single, globally accessible instance.
  static final TotMeasurementService instance =
      TotMeasurementService._internal();

  // ── Internal state ────────────────────────────────────────────────────────

  DateTime? _startTime;
  String? _uiCondition;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Starts the stopwatch.
  ///
  /// Must be called in the **onPressed** / **onTap** handler of the button
  /// that opens the mood logging screen – NOT inside `initState` – so that
  /// widget-rendering latency is excluded from the measurement.
  ///
  /// [uiCondition] must be one of:
  ///   * `'standard_ui'`  — logged from [MoodTrackerScreen]
  ///   * `'rush_hour_ui'` — logged from [RushHourModeScreen]
  void startTimer(String uiCondition) {
    _startTime = DateTime.now();
    _uiCondition = uiCondition;
  }

  /// Resets the timer **without** writing any data.
  ///
  /// Call this whenever the user abandons the logging flow (back button,
  /// swipe-to-dismiss, etc.) so that a future attempt starts fresh.
  void cancelTimer() {
    _startTime = null;
    _uiCondition = null;
  }

  /// Returns current elapsed milliseconds for the active timer.
  ///
  /// Useful for temporary debug UI; returns `null` when no timer is active.
  int? getCurrentElapsedMs() {
    if (_startTime == null) return null;
    return DateTime.now().difference(_startTime!).inMilliseconds;
  }

  /// Calculates the elapsed milliseconds, builds the evaluation payload,
  /// persists it to Firestore, and resets the timer state.
  ///
  /// Returns the payload [Map] (useful for unit tests / local debugging).
  /// Returns `null` silently if [startTimer] was never called (guards against
  /// accidental double-calls or submit without a prior start).
  ///
  /// **Fire-and-forget contract**: Firestore errors are caught internally so
  /// that a logging failure never blocks or crashes the mood-saving flow.
  Future<Map<String, dynamic>?> submitAndLog(String moodLogged) async {
    if (_startTime == null || _uiCondition == null) return null;

    // ── 1. Calculate TOT ──────────────────────────────────────────────────
    final int totMs =
        DateTime.now().difference(_startTime!).inMilliseconds;

    // ── 2. Resolve user identity ─────────────────────────────────────────
    final User? user = FirebaseAuth.instance.currentUser;
    final String userId = user?.uid ?? 'anonymous';

    // ── 3. Build structured payload ───────────────────────────────────────
    final Map<String, dynamic> payload = {
      'user_id': userId,
      'ui_condition': _uiCondition, // 'standard_ui' | 'rush_hour_ui'
      'tot_ms': totMs,
      'mood_logged': moodLogged,
      'logged_at': FieldValue.serverTimestamp(),
    };

    // ── 4. Reset state before the async call so a fast double-tap cannot
    //       produce a duplicate entry with the same start time. ──────────
    _startTime = null;
    _uiCondition = null;

    // ── 5. Persist to Firestore ───────────────────────────────────────────
    try {
      await FirebaseFirestore.instance
          .collection('evaluation_logs')
          .add(payload);
    } catch (_) {
      // Evaluation-log failures must never surface to the user or
      // interfere with the primary mood-saving path.
      // Optionally forward to a crash-reporting service (e.g. Crashlytics):
      //   FirebaseCrashlytics.instance.recordError(e, stack);
    }

    return payload;
  }
}
