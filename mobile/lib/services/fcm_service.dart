import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// Handles Firebase Cloud Messaging token registration and foreground messages.
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialise FCM: request permission, grab token, listen for refreshes.
  static Future<void> initialize() async {
    // Request permission (iOS only — Android auto-grants)
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Get current token and register with backend
    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Listen for token refresh (e.g. after app restore)
    _messaging.onTokenRefresh.listen(_registerToken);

    // Foreground messages — show as local notification or handle silently
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _registerToken(String token) async {
    try {
      await ApiService.registerPushToken(token);
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
    }
  }

  static void _handleForeground(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
    // Local notification could be shown here if needed;
    // for now we rely on the system notification display.
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('FCM tap: ${message.data}');
    // Deep link handling — data payload may contain friend_id
    // Navigation is handled by GoRouter deep links (friendly://profile/{id})
  }
}
