import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// Auth state notifier that tracks current Supabase session.
class AuthStateNotifier extends StateNotifier<AsyncValue<Session?>> {
  StreamSubscription<AuthState>? _sub;

  AuthStateNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    state = AsyncValue.data(SupabaseService.currentSession);
    _sub = SupabaseService.client.auth.onAuthStateChange.listen(
      (data) => state = AsyncValue.data(data.session),
      onError: (Object e, StackTrace st) => state = AsyncValue.error(e, st),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<Session?>>((ref) {
  return AuthStateNotifier();
});

/// Whether a user is currently signed in.
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).valueOrNull != null;
});

/// The current user's ID, or null if not signed in.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.user.id;
});
