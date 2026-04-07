import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/avatar/avatar_types.dart';
import '../components/avatar/avatar_widget.dart';
import '../constants/connection_preferences.dart';
import '../models/friend.dart';
import '../models/friendship.dart';
import '../models/interaction.dart';
import '../models/profile.dart';
import '../services/api_service.dart';
import 'auth_state.dart';

/// Aggregate app data loaded after authentication.
class AppData {
  final Profile? currentProfile;
  final List<Friend> friends;
  final List<Friendship> pendingInvites;
  final Map<String, String> inviteNames;
  final bool loading;
  final String? error;

  const AppData({
    this.currentProfile,
    this.friends = const [],
    this.pendingInvites = const [],
    this.inviteNames = const {},
    this.loading = true,
    this.error,
  });

  AppData copyWith({
    Profile? currentProfile,
    List<Friend>? friends,
    List<Friendship>? pendingInvites,
    Map<String, String>? inviteNames,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AppData(
      currentProfile: currentProfile ?? this.currentProfile,
      friends: friends ?? this.friends,
      pendingInvites: pendingInvites ?? this.pendingInvites,
      inviteNames: inviteNames ?? this.inviteNames,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AppStateNotifier extends StateNotifier<AppData> {
  final Ref ref;

  AppStateNotifier(this.ref) : super(const AppData()) {
    _hydrate();
    // Re-fetch when auth state changes (e.g. after login)
    ref.listen<AsyncValue<Session?>>(authStateProvider, (prev, next) {
      final wasSignedIn = prev?.valueOrNull != null;
      final isSignedIn = next.valueOrNull != null;
      if (!wasSignedIn && isSignedIn) {
        refresh();
      } else if (wasSignedIn && !isSignedIn) {
        state = const AppData(loading: false);
      }
    });
  }

  Future<void> _hydrate() async {
    final session = ref.read(authStateProvider).valueOrNull;
    if (session == null) {
      state = const AppData(loading: false);
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      // Fetch profile
      debugPrint('[AppState] Fetching profile...');
      final profileJson = await ApiService.getProfile();
      debugPrint('[AppState] Profile response: $profileJson');
      final profile = Profile.fromJson(profileJson);
      debugPrint('[AppState] Current user: ${profile.id} (${profile.displayName})');

      // Fetch friendships (returns List<dynamic> directly)
      debugPrint('[AppState] Fetching friendships...');
      final friendshipsRaw = await ApiService.getFriendships();
      debugPrint('[AppState] Friendships raw (${friendshipsRaw.length} items): $friendshipsRaw');
      final friendshipsList = friendshipsRaw
          .map((e) => Friendship.fromJson(e as Map<String, dynamic>))
          .toList();
      debugPrint('[AppState] Parsed friendships: ${friendshipsList.map((f) => '${f.id}: status=${f.status.name}, userId=${f.userId}, friendId=${f.friendId}').toList()}');

      // Fetch all interactions
      debugPrint('[AppState] Fetching interactions...');
      final interactionsRaw = await ApiService.getInteractions();
      debugPrint('[AppState] Interactions: ${interactionsRaw.length} items');

      final allInteractions = interactionsRaw
          .map((e) => Interaction.fromJson(e as Map<String, dynamic>))
          .toList();

      final currentUserId = profile.id;

      // Separate confirmed friends from pending invites
      final confirmed = friendshipsList
          .where((f) => f.status == FriendshipStatus.confirmed)
          .toList();
      final pending = friendshipsList
          .where((f) => f.status == FriendshipStatus.pending)
          .toList();
      debugPrint('[AppState] Confirmed: ${confirmed.length}, Pending: ${pending.length}');
      debugPrint('[AppState] All statuses: ${friendshipsList.map((f) => f.status.name).toList()}');

      // Build friend list with profile data (deduplicate bidirectional records)
      final seenFriendIds = <String>{};
      final friends = <Friend>[];
      for (final fs in confirmed) {
        final friendId =
            fs.userId == currentUserId ? fs.friendId : fs.userId;

        if (seenFriendIds.contains(friendId)) continue;
        seenFriendIds.add(friendId);

        // Find interactions related to this friend
        final friendInteractions = allInteractions
            .where((i) => i.targetId == friendId)
            .toList();
        final lastInteraction =
            friendInteractions.isNotEmpty ? friendInteractions.first.createdAt : null;
        final heartHealth = ConnectionPreferences.computeHeartHealth(
          lastInteraction,
          ConnectionPreferences.regularFriendDays,
        );

        // Try to fetch friend's profile for display name
        String displayName = 'Friend';
        String? email;
        String? phoneNumber;
        Map<String, dynamic>? metadata;
        try {
          final friendProfile = await ApiService.getProfileById(friendId);
          displayName = (friendProfile['display_name'] as String?) ?? 'Friend';
          email = friendProfile['email'] as String?;
          phoneNumber = friendProfile['phone_number'] as String?;
          metadata = friendProfile['metadata'] as Map<String, dynamic>?;
        } catch (_) {
          // Non-critical — use defaults
        }

        friends.add(Friend(
          friendshipId: fs.id,
          friendId: friendId,
          displayName: displayName,
          email: email,
          phoneNumber: phoneNumber,
          metadata: metadata,
          status: fs.status,
          lastInteraction: lastInteraction,
          heartHealth: heartHealth,
        ));
      }

      // Resolve display names for pending invites
      final inviteNames = <String, String>{};
      for (final inv in pending) {
        final senderId =
            inv.userId == currentUserId ? inv.friendId : inv.userId;
        try {
          final senderProfile = await ApiService.getProfileById(senderId);
          inviteNames[senderId] =
              (senderProfile['display_name'] as String?) ?? senderId;
        } catch (_) {
          inviteNames[senderId] = senderId;
        }
      }

      debugPrint('[AppState] Final friend count: ${friends.length}');
      for (final f in friends) {
        debugPrint('[AppState]   → ${f.displayName} (${f.friendId}), health=${f.heartHealth.toStringAsFixed(0)}');
      }

      // Pre-warm avatar SVG cache in parallel (non-blocking)
      final avatarConfigs = <AvatarConfig?>[
        AvatarConfig.fromMetadata(profile.metadata),
        ...friends.map((f) => AvatarConfig.fromMetadata(f.metadata)),
      ];
      for (final config in avatarConfigs) {
        AvatarWidget.prefetch(config);
      }

      state = AppData(
        currentProfile: profile,
        friends: friends,
        pendingInvites: pending,
        inviteNames: inviteNames,
        loading: false,
      );
    } catch (e, stack) {
      debugPrint('[AppState] ERROR: $e');
      debugPrint('[AppState] Stack: $stack');
      state = state.copyWith(loading: false, error: e.toString());
      // Report to feedback system asynchronously
      ApiService.reportError(
        source: 'AppState.refresh',
        message: e.toString(),
        stackTrace: stack.toString(),
      );
    }
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppData>((ref) {
  return AppStateNotifier(ref);
});

// Derived providers

final currentProfileProvider = Provider<Profile?>((ref) {
  return ref.watch(appStateProvider).currentProfile;
});

final friendsProvider = Provider<List<Friend>>((ref) {
  return ref.watch(appStateProvider).friends;
});

final pendingInvitesProvider = Provider<List<Friendship>>((ref) {
  return ref.watch(appStateProvider).pendingInvites;
});

final inviteNamesProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(appStateProvider).inviteNames;
});

final appLoadingProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider).loading;
});

final appErrorProvider = Provider<String?>((ref) {
  return ref.watch(appStateProvider).error;
});
