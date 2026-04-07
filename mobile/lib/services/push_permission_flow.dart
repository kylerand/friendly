import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design/theme.dart';

/// Manages the "ask for push notification permission" flow.
///
/// Per NUDGE_SYSTEM.md: don't ask on first launch — ask after
/// the user's first successful outreach action.
class PushPermissionFlow {
  static const _askedKey = 'push_permission_asked';
  static const _outreachCountKey = 'outreach_count';

  /// Call this after each successful outreach (interaction, check-in, etc.).
  /// Returns true if the permission dialog should be shown.
  static Future<bool> shouldAskPermission() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_askedKey) == true) return false;

    // Increment outreach count
    final count = (prefs.getInt(_outreachCountKey) ?? 0) + 1;
    await prefs.setInt(_outreachCountKey, count);

    // Ask after first successful outreach
    return count >= 1;
  }

  /// Mark that we've shown the permission dialog (don't ask again).
  static Future<void> markAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
  }

  /// Show a soft-ask dialog before the system permission prompt.
  /// Returns true if user wants to proceed, false if they decline.
  static Future<bool> showSoftAskDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Stay connected 💛',
          style: AppTypography.heading.copyWith(color: textPrimary),
        ),
        content: Text(
          'Friendly can send you gentle reminders when a friend might '
          'appreciate hearing from you. At most once a day, never pushy.',
          style: AppTypography.body.copyWith(color: textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Not now', style: TextStyle(color: textPrimary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Enable', style: TextStyle(color: accent)),
          ),
        ],
      ),
    );

    await markAsked();
    return result == true;
  }
}
