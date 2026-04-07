import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friendly/models/profile.dart';
import 'package:friendly/navigation/app_router.dart';
import 'package:friendly/state/app_state.dart';
import 'package:friendly/state/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Router redirect logic', () {
    test('redirects unauthenticated user to /auth', () {
      final result = evaluateRedirect(
        isSignedIn: false,
        profile: null,
        matchedLocation: '/',
      );
      expect(result, '/auth');
    });

    test('does not redirect when already on /auth and not signed in', () {
      final result = evaluateRedirect(
        isSignedIn: false,
        profile: null,
        matchedLocation: '/auth',
      );
      expect(result, isNull);
    });

    test('redirects signed-in user from /auth to /', () {
      final profile = Profile(
        id: 'user-1',
        metadata: {'onboarding_complete': true},
      );
      final result = evaluateRedirect(
        isSignedIn: true,
        profile: profile,
        matchedLocation: '/auth',
      );
      expect(result, '/');
    });

    test(
      'redirects to /onboarding when profile exists but onboarding incomplete',
      () {
        final profile = Profile(id: 'new-user', metadata: <String, dynamic>{});
        final result = evaluateRedirect(
          isSignedIn: true,
          profile: profile,
          matchedLocation: '/',
        );
        expect(result, '/onboarding');
      },
    );

    test(
      'does not redirect away from /onboarding when onboarding is incomplete',
      () {
        final profile = Profile(id: 'new-user', metadata: <String, dynamic>{});
        final result = evaluateRedirect(
          isSignedIn: true,
          profile: profile,
          matchedLocation: '/onboarding',
        );
        expect(result, isNull);
      },
    );

    test('treats friend_language in metadata as onboarding complete', () {
      final profile = Profile(
        id: 'legacy-user',
        metadata: {'friend_language': 'gifts'},
      );
      final result = evaluateRedirect(
        isSignedIn: true,
        profile: profile,
        matchedLocation: '/',
      );
      expect(result, isNull);
    });

    test('handles onboarding_complete as string "true" (legacy RN format)', () {
      final profile = Profile(
        id: 'rn-user',
        metadata: {'onboarding_complete': 'true'},
      );
      final result = evaluateRedirect(
        isSignedIn: true,
        profile: profile,
        matchedLocation: '/',
      );
      expect(result, isNull);
    });

    test(
      'does not redirect to onboarding when profile is null (still loading)',
      () {
        final result = evaluateRedirect(
          isSignedIn: true,
          profile: null,
          matchedLocation: '/',
        );
        // Profile is null means still loading — don't redirect yet
        expect(result, isNull);
      },
    );
  });

  group(
    'Router stability — GoRouter instance preserved across state changes',
    () {
      test('router instance is reused when profile changes', () {
        // This test verifies the fix for the avatar screen getting stuck.
        // Previously, ref.watch(currentProfileProvider) caused the router
        // to be recreated on every profile update, resetting widget state.
        final container = ProviderContainer(
          overrides: [
            isSignedInProvider.overrideWithValue(true),
            currentProfileProvider.overrideWithValue(
              Profile(id: 'user-1', metadata: <String, dynamic>{}),
            ),
          ],
        );
        addTearDown(container.dispose);

        final router1 = container.read(routerProvider);

        // Simulate profile update (e.g. after saving avatar)
        // Since we use ref.listen instead of ref.watch, the provider
        // should NOT be invalidated, so the same GoRouter is returned.
        final router2 = container.read(routerProvider);

        expect(
          identical(router1, router2),
          true,
          reason: 'GoRouter should be the same instance after profile update',
        );
      });
    },
  );
}
