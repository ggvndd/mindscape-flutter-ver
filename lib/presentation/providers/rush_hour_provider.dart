import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

/// Represents a single rush hour time period
class RushHourPeriod {
  TimeOfDay startTime;
  TimeOfDay endTime;

  RushHourPeriod({required this.startTime, required this.endTime});

  factory RushHourPeriod.fromJson(Map<String, dynamic> json) {
    return RushHourPeriod(
      startTime: TimeOfDay(
        hour: (json['start']?['hour'] ?? 9) as int,
        minute: (json['start']?['minute'] ?? 0) as int,
      ),
      endTime: TimeOfDay(
        hour: (json['end']?['hour'] ?? 17) as int,
        minute: (json['end']?['minute'] ?? 0) as int,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': {'hour': startTime.hour, 'minute': startTime.minute},
      'end': {'hour': endTime.hour, 'minute': endTime.minute},
    };
  }
}

/// Provider that manages rush hour state and logic
class RushHourProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  List<RushHourPeriod> _rushHourPeriods = [];
  bool _isLoading = false;

  /// Whether the popup has already been shown this app session
  bool _popupShownForSession = false;

  List<RushHourPeriod> get rushHourPeriods => _rushHourPeriods;
  bool get isLoading => _isLoading;

  /// Returns true if the current clock time falls within any configured rush hour
  bool get isRushHourActive {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    for (final period in _rushHourPeriods) {
      final startMinutes =
          period.startTime.hour * 60 + period.startTime.minute;
      final endMinutes = period.endTime.hour * 60 + period.endTime.minute;
      if (nowMinutes >= startMinutes && nowMinutes < endMinutes) {
        return true;
      }
    }
    return false;
  }

  /// True when rush hour is active AND the popup hasn't been shown yet this session
  bool get shouldShowPopup => isRushHourActive && !_popupShownForSession;

  Future<void> loadRushHours() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userData = await _authService.getUserData();
      final rushHourData = userData?['preferences']?['rushHours'];
      if (rushHourData != null && rushHourData is List) {
        _rushHourPeriods = (rushHourData as List)
            .map((p) =>
                RushHourPeriod.fromJson(Map<String, dynamic>.from(p as Map)))
            .toList();
      }
    } catch (_) {
      // silently fail – user may be offline
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveRushHours(List<RushHourPeriod> periods) async {
    _rushHourPeriods = List.from(periods);
    notifyListeners();

    try {
      await _authService.saveRushHours(
        periods.map((p) => p.toJson()).toList(),
      );
    } catch (_) {
      // silently fail
    }
  }

  /// Call this once the popup has been displayed to prevent it appearing again
  void markPopupShown() {
    _popupShownForSession = true;
    notifyListeners();
  }
}
