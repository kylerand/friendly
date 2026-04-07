import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

/// Keys used in shared storage for native widgets to read.
class WidgetKeys {
  static const warmthTier = 'warmth_tier';
  static const warmthEmoji = 'warmth_emoji';
  static const warmthLabel = 'warmth_label';
  static const weekStreak = 'week_streak';
  static const suggestedFriendName = 'suggested_friend_name';
  static const suggestedFriendId = 'suggested_friend_id';
  static const suggestedFriendInitial = 'suggested_friend_initial';
  static const allCaughtUp = 'all_caught_up';
  static const lastUpdated = 'last_updated';
}

const _tierEmojis = {
  'radiant': '☀️',
  'warm': '🔥',
  'gentle': '🕯️',
  'quiet': '❄️',
};

const _tierLabels = {
  'radiant': 'Radiant',
  'warm': 'Warm',
  'gentle': 'Gentle',
  'quiet': 'Quiet',
};

/// Service that fetches warmth data and writes it to shared storage
/// so native iOS WidgetKit and Android AppWidget can read it.
class WidgetService {
  static const _iOSWidgetName = 'FriendlyWidget';
  static const _androidWidgetName = 'FriendlySmallWidget';

  /// Refresh widget data from the backend and update native widgets.
  static Future<void> refresh() async {
    try {
      // Fetch the latest warmth snapshot from backend
      final snapshot = await ApiService.getWarmthSnapshot();

      final tier = snapshot['warmth_tier'] as String? ?? 'quiet';
      final streak = snapshot['week_streak'] as int? ?? 0;
      final friendName = snapshot['suggested_friend_name'] as String?;
      final friendId = snapshot['suggested_friend_id'] as String?;
      final allGood = friendName == null;

      // Write to home_widget shared storage
      await Future.wait([
        HomeWidget.saveWidgetData(WidgetKeys.warmthTier, tier),
        HomeWidget.saveWidgetData(WidgetKeys.warmthEmoji, _tierEmojis[tier] ?? '❄️'),
        HomeWidget.saveWidgetData(WidgetKeys.warmthLabel, _tierLabels[tier] ?? 'Quiet'),
        HomeWidget.saveWidgetData(WidgetKeys.weekStreak, streak),
        HomeWidget.saveWidgetData(WidgetKeys.suggestedFriendName, friendName ?? ''),
        HomeWidget.saveWidgetData(WidgetKeys.suggestedFriendId, friendId ?? ''),
        HomeWidget.saveWidgetData(
          WidgetKeys.suggestedFriendInitial,
          friendName != null ? friendName[0].toUpperCase() : '',
        ),
        HomeWidget.saveWidgetData(WidgetKeys.allCaughtUp, allGood),
        HomeWidget.saveWidgetData(
          WidgetKeys.lastUpdated,
          DateTime.now().toIso8601String(),
        ),
      ]);

      // Trigger native widget refresh on both platforms
      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );

      // Also cache locally for offline widget reads
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_cache', jsonEncode(snapshot));
    } catch (_) {
      // Widget refresh is non-critical — silently fail
    }
  }

  /// Write cached/offline data so widgets work without network.
  static Future<void> writeFallbackData({
    required String tier,
    required int streak,
    String? friendName,
    String? friendId,
  }) async {
    await Future.wait([
      HomeWidget.saveWidgetData(WidgetKeys.warmthTier, tier),
      HomeWidget.saveWidgetData(WidgetKeys.warmthEmoji, _tierEmojis[tier] ?? '❄️'),
      HomeWidget.saveWidgetData(WidgetKeys.warmthLabel, _tierLabels[tier] ?? 'Quiet'),
      HomeWidget.saveWidgetData(WidgetKeys.weekStreak, streak),
      HomeWidget.saveWidgetData(WidgetKeys.suggestedFriendName, friendName ?? ''),
      HomeWidget.saveWidgetData(WidgetKeys.suggestedFriendId, friendId ?? ''),
      HomeWidget.saveWidgetData(
        WidgetKeys.suggestedFriendInitial,
        friendName != null ? friendName[0].toUpperCase() : '',
      ),
      HomeWidget.saveWidgetData(WidgetKeys.allCaughtUp, friendName == null),
      HomeWidget.saveWidgetData(
        WidgetKeys.lastUpdated,
        DateTime.now().toIso8601String(),
      ),
    ]);
    await HomeWidget.updateWidget(
      iOSName: _iOSWidgetName,
      androidName: _androidWidgetName,
    );
  }

  /// Handle widget tap deep links.
  static Future<Uri?> handleWidgetTap() async {
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }
}
