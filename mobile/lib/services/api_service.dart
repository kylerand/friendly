import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import 'supabase_service.dart';

class ApiService {
  static Future<Map<String, dynamic>> _apiFetch(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    var token = SupabaseService.accessToken;
    var uri = Uri.parse('$apiBaseUrl$path');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    var response = await _sendRequest(method, uri, body: body, token: token);

    // Token refresh on 401/403
    if (response.statusCode == 401 || response.statusCode == 403) {
      await SupabaseService.client.auth.refreshSession();
      token = SupabaseService.accessToken;
      response = await _sendRequest(method, uri, body: body, token: token);
    }

    // Retry once on 5xx (cold start)
    if (response.statusCode >= 500) {
      await Future.delayed(const Duration(seconds: 2));
      response = await _sendRequest(method, uri, body: body, token: token);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<http.Response> _sendRequest(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    String? token,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'PATCH':
        return http.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'PUT':
        return http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        return http.get(uri, headers: headers);
    }
  }

  // ── Profile ──

  static Future<Map<String, dynamic>> getProfile() =>
      _apiFetch('GET', '/auth/me');

  static Future<Map<String, dynamic>> updateProfile(
          Map<String, dynamic> body) =>
      _apiFetch('PATCH', '/auth/me', body: body);

  static Future<Map<String, dynamic>> getProfileById(String profileId) =>
      _apiFetch('GET', '/profiles/$profileId');

  // ── Friendships ──

  /// Returns the raw response. The backend returns an array directly.
  static Future<dynamic> _apiFetchRaw(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    var token = SupabaseService.accessToken;
    var uri = Uri.parse('$apiBaseUrl$path');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    var response = await _sendRequest(method, uri, body: body, token: token);

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SupabaseService.client.auth.refreshSession();
      token = SupabaseService.accessToken;
      response = await _sendRequest(method, uri, body: body, token: token);
    }

    if (response.statusCode >= 500) {
      await Future.delayed(const Duration(seconds: 2));
      response = await _sendRequest(method, uri, body: body, token: token);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }

    if (response.body.isEmpty) return {};
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getFriendships() async {
    final result = await _apiFetchRaw('GET', '/friendships/');
    if (result is List) return result;
    return (result as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> createFriendship(
          String friendId) =>
      _apiFetch('POST', '/friendships/', body: {'friend_id': friendId});

  static Future<Map<String, dynamic>> updateFriendship(
          String id, String status) =>
      _apiFetch('PATCH', '/friendships/$id', body: {'status': status});

  // ── Interactions ──

  static Future<List<dynamic>> getInteractions() async {
    final result = await _apiFetchRaw('GET', '/interactions/');
    if (result is List) return result;
    return (result as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> createInteraction(
    String targetId, {
    String? type,
  }) =>
      _apiFetch('POST', '/interactions/', body: {
        'target_id': targetId,
        if (type != null) 'type': type,
      });

  // ── Check-ins ──

  static Future<Map<String, dynamic>> createCheckIn({
    required int comfort,
    required int connection,
    required int energy,
    String? notes,
  }) =>
      _apiFetch('POST', '/check-ins/', body: {
        'comfort': comfort,
        'connection': connection,
        'energy': energy,
        if (notes != null) 'notes': notes,
      });

  // ── Search ──

  static Future<List<dynamic>> searchProfiles(String query) async {
    final result = await _apiFetchRaw(
        'GET', '/profiles/search', queryParams: {'q': query.trim()});
    if (result is List) return result;
    return (result as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
  }

  // ── Signals ──

  static Future<Map<String, dynamic>> sendBeacon() =>
      _apiFetch('POST', '/signals/beacon');

  static Future<Map<String, dynamic>> deactivateBeacon() =>
      _apiFetch('DELETE', '/signals/beacon');

  static Future<Map<String, dynamic>> getMyBeacon() =>
      _apiFetch('GET', '/signals/beacon');

  static Future<Map<String, dynamic>> sendCareSignal(String friendId) =>
      _apiFetch('POST', '/signals/care', body: {'friend_id': friendId});

  static Future<List<dynamic>> getFriendBeacons() async {
    final result = await _apiFetchRaw('GET', '/signals/beacons/friends');
    if (result is List) return result;
    return (result as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
  }

  // ── Friend Notes ──

  static Future<Map<String, dynamic>> getFriendNote(String friendId) =>
      _apiFetch('GET', '/friend-notes/$friendId');

  static Future<Map<String, dynamic>> saveFriendNote(
          String friendId, String content) =>
      _apiFetch('PUT', '/friend-notes/$friendId', body: {'content': content});

  static Future<Map<String, dynamic>> deleteFriendNote(String friendId) =>
      _apiFetch('DELETE', '/friend-notes/$friendId');

  // ── Friend Reminders ──

  static Future<List<dynamic>> listFriendReminders() async =>
      await _apiFetchRaw('GET', '/friend-reminders/') as List<dynamic>;

  static Future<Map<String, dynamic>?> getFriendReminder(
          String friendId) async {
    try {
      return await _apiFetch('GET', '/friend-reminders/$friendId');
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> upsertFriendReminder(
    String friendId, {
    required String text,
    int intervalDays = 3,
  }) =>
      _apiFetch('PUT', '/friend-reminders/$friendId', body: {
        'friend_id': friendId,
        'text': text,
        'interval_days': intervalDays,
      });

  static Future<Map<String, dynamic>> deleteFriendReminder(
          String friendId) =>
      _apiFetch('DELETE', '/friend-reminders/$friendId');

  // ── Nudges / Warmth ──

  static Future<Map<String, dynamic>> getWarmthSnapshot() =>
      _apiFetch('GET', '/nudges/warmth/snapshot');

  static Future<Map<String, dynamic>> saveWarmthSnapshot() =>
      _apiFetch('POST', '/nudges/warmth/snapshot');

  static Future<Map<String, dynamic>> checkMilestones() =>
      _apiFetch('POST', '/nudges/milestones/check');

  static Future<Map<String, dynamic>> getNudgePreferences() =>
      _apiFetch('GET', '/nudges/preferences');

  static Future<Map<String, dynamic>> updateNudgePreferences(
          Map<String, dynamic> body) =>
      _apiFetch('PUT', '/nudges/preferences', body: body);

  static Future<Map<String, dynamic>> registerPushToken(String token) =>
      _apiFetch('POST', '/nudges/register-push-token', body: {'token': token});

  static Future<Map<String, dynamic>> takeRestDay() =>
      _apiFetch('POST', '/nudges/rest-day');

  static Future<Map<String, dynamic>> getRestDayStatus() =>
      _apiFetch('GET', '/nudges/rest-day');

  static Future<Map<String, dynamic>> deleteAccount() =>
      _apiFetch('DELETE', '/auth/me');

  /// Report an API error to the feedback system for monitoring.
  static Future<void> reportError({
    required String source,
    required String message,
    String? stackTrace,
  }) async {
    try {
      await _apiFetch('POST', '/feedback', body: {
        'type': 'error',
        'source': source,
        'message': message,
        if (stackTrace != null) 'stack_trace': stackTrace,
      });
    } catch (_) {
      // Don't let feedback reporting itself cause cascading failures
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
