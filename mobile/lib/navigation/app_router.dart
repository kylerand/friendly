import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/profile.dart';
import '../state/auth_state.dart';
import '../state/app_state.dart';
import '../state/transition_settings.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/check_in_screen.dart';
import '../screens/add_friend_screen.dart';
import '../screens/invites_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/avatar_editor_screen.dart';
import '../screens/friend_language_quiz_screen.dart';
import '../screens/onboarding_screen.dart';
import 'scaffold_with_nav_bar.dart';

/// Pure redirect logic extracted for testability.
///
/// Returns the redirect path, or `null` if no redirect is needed.
String? evaluateRedirect({
  required bool isSignedIn,
  required Profile? profile,
  required String matchedLocation,
}) {
  final meta = profile?.metadata;
  final onboardingComplete =
      meta != null &&
      (meta['onboarding_complete'] == true ||
          meta['onboarding_complete'] == 'true' ||
          meta['friend_language'] != null);

  final loggingIn = matchedLocation == '/auth';
  final onboarding = matchedLocation == '/onboarding';

  if (!isSignedIn) {
    return loggingIn ? null : '/auth';
  }

  if (isSignedIn && profile != null && !onboardingComplete && !onboarding) {
    return '/onboarding';
  }

  if (isSignedIn && loggingIn) {
    return '/';
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final transition = ref.watch(transitionSettingsProvider);

  // Use a ValueNotifier to trigger GoRouter redirect re-evaluation
  // without recreating the entire GoRouter instance. This preserves
  // widget state (e.g. onboarding step) across profile refreshes.
  final refreshNotifier = ValueNotifier<int>(0);

  ref.listen<bool>(isSignedInProvider, (_, __) {
    refreshNotifier.value++;
  });
  ref.listen<Profile?>(currentProfileProvider, (_, __) {
    refreshNotifier.value++;
  });

  ref.onDispose(() => refreshNotifier.dispose());

  Page<void> transitionPage(GoRouterState state, Widget child) =>
      buildTransitionPage(key: state.pageKey, child: child, style: transition);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      return evaluateRedirect(
        isSignedIn: ref.read(isSignedInProvider),
        profile: ref.read(currentProfileProvider),
        matchedLocation: state.matchedLocation,
      );
    },
    routes: [
      // Routes outside the shell (no bottom bar)
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/onboarding',
        builder:
            (context, state) => OnboardingScreen(
              onComplete: () {
                ref.read(appStateProvider.notifier).refresh();
              },
            ),
      ),

      // Shell route: persistent bottom bar on all inner screens
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder:
                (context, state) => transitionPage(state, const HomeScreen()),
            routes: [
              GoRoute(
                path: 'profile/:friendId',
                pageBuilder:
                    (context, state) => transitionPage(
                      state,
                      ProfileScreen(
                        friendId: state.pathParameters['friendId']!,
                      ),
                    ),
              ),
              GoRoute(
                path: 'check-in/:friendshipId',
                pageBuilder:
                    (context, state) => transitionPage(
                      state,
                      CheckInScreen(
                        friendshipId: state.pathParameters['friendshipId']!,
                        friendName:
                            state.uri.queryParameters['name'] ?? 'Friend',
                      ),
                    ),
              ),
              GoRoute(
                path: 'add-friend',
                pageBuilder:
                    (context, state) =>
                        transitionPage(state, const AddFriendScreen()),
              ),
            ],
          ),
          GoRoute(
            path: '/invites',
            pageBuilder:
                (context, state) =>
                    transitionPage(state, const InvitesScreen()),
          ),
          GoRoute(
            path: '/edit-profile',
            pageBuilder:
                (context, state) =>
                    transitionPage(state, const EditProfileScreen()),
          ),
          GoRoute(
            path: '/avatar-editor',
            pageBuilder:
                (context, state) =>
                    transitionPage(state, const AvatarEditorScreen()),
          ),
          GoRoute(
            path: '/friend-language-quiz',
            pageBuilder:
                (context, state) =>
                    transitionPage(state, const FriendLanguageQuizScreen()),
          ),
        ],
      ),
    ],
  );
});
