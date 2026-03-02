import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Singleton service for scheduling and displaying local notifications.
///
/// Two categories:
///   - Mood reminders  : daily scheduled at user-chosen intervals (IDs 100-130)
///   - Rush Hour alert : immediate notification when rush hour starts (ID 1)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int _rushHourNotifId = 1;
  static const int _moodReminderIdStart = 100;
  static const int _moodReminderIdEnd = 130;
  static const int _nextAfterLogId = 99; // dynamic: next reminder after a log

  // Android channel IDs
  static const String _moodChannelId = 'mood_reminders';
  static const String _rushChannelId = 'rush_hour';

  // SharedPreferences keys (also used directly by the settings screen)
  static const String prefIntervalKey = 'moodLogInterval';
  static const String prefMoodRemindersKey = 'moodRemindersEnabled';
  static const String prefRushHourNotifKey = 'rushHourNotifEnabled';

  // ──────────────────────────────────────────────────────────────────────────
  // Initialization
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Setup timezone for Jakarta (WIB – where UGM is located)
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(initSettings);

    // Create Android notification channels
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _moodChannelId,
        'Pengingat Mood',
        description: 'Pengingat harian untuk mencatat mood kamu',
        importance: Importance.high,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _rushChannelId,
        'Rush Hour',
        description: 'Notifikasi ketika mode Rush Hour aktif',
        importance: Importance.high,
      ),
    );

    // Re-schedule reminders on startup if they were previously enabled
    final enabled = await getMoodRemindersEnabled();
    if (enabled) {
      final interval = await getSavedInterval();
      await scheduleMoodReminders(interval);
    }
  }

  /// Request OS-level notification permission from the user.
  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      // Request exact alarm permission (needed for scheduled reminders on API 31+)
      await androidPlugin.requestExactAlarmsPermission();
      return await androidPlugin.requestNotificationsPermission() ?? false;
    }
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Mood Reminders
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the list of reminder hours (24h) for a given interval.
  ///
  /// Always starts at 04:00 and steps forward until 22:00.
  ///   3h → [4, 7, 10, 13, 16, 19, 22]
  ///   4h → [4, 8, 12, 16, 20]
  ///   5h → [4, 9, 14, 19]
  ///   6h → [4, 10, 16, 22]
  static List<int> getMoodReminderHours(int intervalHours) {
    final hours = <int>[];
    int h = 4;
    while (h <= 22) {
      hours.add(h);
      h += intervalHours;
    }
    return hours;
  }

  /// Cancel any existing mood reminders and schedule new ones.
  Future<void> scheduleMoodReminders(int intervalHours) async {
    // Cancel previous
    for (int id = _moodReminderIdStart; id <= _moodReminderIdEnd; id++) {
      await _plugin.cancel(id);
    }

    final hours = getMoodReminderHours(intervalHours);

    for (int i = 0; i < hours.length; i++) {
      final hour = hours[i];
      final now = tz.TZDateTime.now(tz.local);
      var scheduled =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _moodReminderIdStart + i,
        '⏰ Waktunya Log Mood!',
        'Gimana perasaan kamu sekarang? Catat di MindScape.',
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _moodChannelId,
            'Pengingat Mood',
            channelDescription: 'Pengingat harian untuk mencatat mood kamu',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelMoodReminders() async {
    for (int id = _moodReminderIdStart; id <= _moodReminderIdEnd; id++) {
      await _plugin.cancel(id);
    }
  }

  /// Schedule a single "next log" reminder [intervalHours] after [logTime].
  /// Cancels the previous after-log reminder first.
  /// This complements the fixed daily reminders by also firing right after a log.
  Future<void> scheduleNextReminderAfterLog(
    DateTime logTime,
    int intervalHours,
  ) async {
    await _plugin.cancel(_nextAfterLogId);

    final nextTime = logTime.add(Duration(hours: intervalHours));
    final now = DateTime.now();
    if (nextTime.isBefore(now)) return; // already in the past, skip

    final tzNext = tz.TZDateTime.from(nextTime, tz.local);

    await _plugin.zonedSchedule(
      _nextAfterLogId,
      '⏰ Waktunya Log Mood!',
      'Gimana perasaan kamu sekarang? Catat di MindScape.',
      tzNext,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _moodChannelId,
          'Pengingat Mood',
          channelDescription: 'Pengingat harian untuk mencatat mood kamu',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Rush Hour Notification
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> showRushHourNotification() async {
    await _plugin.show(
      _rushHourNotifId,
      '🚀 Rush Hour Aktif!',
      'Kamu lagi dalam jam sibuk. Buka MindScape untuk mode cepat!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _rushChannelId,
          'Rush Hour',
          channelDescription: 'Notifikasi ketika mode Rush Hour aktif',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> cancelRushHourNotification() async {
    await _plugin.cancel(_rushHourNotifId);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SharedPreferences helpers
  // ──────────────────────────────────────────────────────────────────────────

  static Future<int> getSavedInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(prefIntervalKey) ?? 3;
  }

  static Future<void> saveInterval(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefIntervalKey, hours);
  }

  static Future<bool> getMoodRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefMoodRemindersKey) ?? false;
  }

  static Future<void> saveMoodRemindersEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefMoodRemindersKey, value);
  }

  static Future<bool> getRushHourNotifEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefRushHourNotifKey) ?? false;
  }

  static Future<void> saveRushHourNotifEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefRushHourNotifKey, value);
  }
}
