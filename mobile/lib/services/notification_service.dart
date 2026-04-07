import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

/// Simple recurring-reminder model.
class Reminder {
  final String friendId;
  final String friendName;
  final String text;
  final int intervalDays;
  final DateTime createdAt;

  const Reminder({
    required this.friendId,
    required this.friendName,
    required this.text,
    this.intervalDays = 3,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'friendId': friendId,
        'friendName': friendName,
        'text': text,
        'intervalDays': intervalDays,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        friendId: json['friendId'] as String? ?? json['friend_id'] as String,
        friendName: json['friendName'] as String? ?? '',
        text: json['text'] as String,
        intervalDays:
            json['intervalDays'] as int? ?? json['interval_days'] as int? ?? 3,
        createdAt: DateTime.tryParse(
                json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

// ---------------------------------------------------------------------------
// Local notification scheduling cache key
// ---------------------------------------------------------------------------

const _localCacheKey = 'friend_reminder_schedule';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Call once at app startup.
  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(settings);

    if (Platform.isIOS || Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // ---------------------------------------------------------------------------
  // API-backed persistence
  // ---------------------------------------------------------------------------

  /// Load reminder for a friend from the API.
  static Future<Reminder?> getReminder(String friendId) async {
    try {
      final json = await ApiService.getFriendReminder(friendId);
      if (json == null) return null;
      return Reminder.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Create or update a reminder via the API, and schedule the
  /// local notification.
  static Future<void> setReminder({
    required String friendId,
    required String friendName,
    required String text,
    int intervalDays = 3,
  }) async {
    await ApiService.upsertFriendReminder(
      friendId,
      text: text,
      intervalDays: intervalDays,
    );

    final reminder = Reminder(
      friendId: friendId,
      friendName: friendName,
      text: text,
      intervalDays: intervalDays,
      createdAt: DateTime.now(),
    );
    await _cacheReminder(reminder);
    try {
      await _scheduleNotification(reminder);
    } catch (_) {
      // Local notification scheduling can fail on simulator or without
      // permission — the server-side reminder is already saved.
    }
  }

  /// Delete a reminder via the API and cancel the local notification.
  static Future<void> clearReminder(String friendId) async {
    try {
      await ApiService.deleteFriendReminder(friendId);
    } catch (_) {}
    await _removeCached(friendId);
    await _plugin.cancel(_notificationId(friendId));
  }

  // ---------------------------------------------------------------------------
  // Local notification scheduling cache (SharedPreferences)
  // ---------------------------------------------------------------------------

  static Future<Map<String, Reminder>> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localCacheKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map(
        (k, v) => MapEntry(k, Reminder.fromJson(v as Map<String, dynamic>)));
  }

  static Future<void> _cacheReminder(Reminder r) async {
    final all = await _loadCached();
    all[r.friendId] = r;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localCacheKey,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  static Future<void> _removeCached(String friendId) async {
    final all = await _loadCached();
    all.remove(friendId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localCacheKey,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  /// Deterministic notification id from friendId.
  static int _notificationId(String friendId) =>
      friendId.hashCode.abs() % 0x7FFFFFFF;

  static Future<void> _scheduleNotification(Reminder r) async {
    final id = _notificationId(r.friendId);
    await _plugin.cancel(id);

    await _plugin.periodicallyShow(
      id,
      'Reminder about ${r.friendName}',
      r.text,
      _repeatInterval(r.intervalDays),
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'friend_reminders',
          'Friend Reminders',
          channelDescription: 'Recurring reminders about your friends',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static RepeatInterval _repeatInterval(int days) {
    if (days <= 1) return RepeatInterval.daily;
    if (days <= 7) return RepeatInterval.weekly;
    return RepeatInterval.weekly;
  }

  /// Re-schedule all locally cached reminders (call at app startup).
  static Future<void> rescheduleAll() async {
    final all = await _loadCached();
    for (final r in all.values) {
      await _scheduleNotification(r);
    }
  }
}
