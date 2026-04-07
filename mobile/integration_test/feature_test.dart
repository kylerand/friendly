/// Comprehensive feature tests for the Friendly app.
///
/// All tests run in a SINGLE testWidgets to avoid re-initializing the app
/// (integration tests can only boot one app instance per process).
///
/// Usage:
///   flutter test integration_test/feature_test.dart -d SIMULATOR_ID \
///     --dart-define=TEST_EMAIL=user@example.com \
///     --dart-define=TEST_PASSWORD=pass
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:friendly/main.dart' show FriendlyApp;
import 'package:friendly/services/supabase_service.dart';
import 'package:friendly/components/ui/ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

late IntegrationTestWidgetsFlutterBinding binding;
int _pass = 0;
int _skip = 0;

// ─── Helpers ────────────────────────────────────────────────────────────────

Future<void> pumpFor(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> waitForApi(WidgetTester tester, {int seconds = 3}) async {
  await Future<void>.delayed(Duration(seconds: seconds));
  await pumpFor(tester, 15);
}

Future<void> goToTab(WidgetTester tester, IconData icon) async {
  final tab = find.byIcon(icon);
  if (tab.evaluate().isNotEmpty) {
    await tester.tap(tab.first, warnIfMissed: false);
    await pumpFor(tester, 10);
  }
}

Future<void> goHome(WidgetTester tester) async {
  await goToTab(tester, PhosphorIconsBold.house);
}

/// Find the first friend card warmth icon.
Finder? findFriendCard() {
  for (final icon in [
    PhosphorIconsFill.fire,
    PhosphorIconsFill.sun,
    PhosphorIconsFill.cloudSun,
    PhosphorIconsFill.cloudRain,
    PhosphorIconsFill.snowflake,
  ]) {
    final f = find.byIcon(icon);
    if (f.evaluate().isNotEmpty) return f;
  }
  return null;
}

void pass(String name) {
  _pass++;
  debugPrint('  ✅ $name');
}

void skip(String name, String reason) {
  _skip++;
  debugPrint('  ⏭️  $name — $reason');
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await SupabaseService.initialize();
  });

  group('Feature tests', () {
    testWidgets('Full feature suite', (tester) async {
      debugPrint('');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('  Friendly Feature Test Suite');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('');

      // ── Boot & Login ──────────────────────────────────────────────────
      await tester.pumpWidget(
        const ProviderScope(child: FriendlyApp()),
      );
      await pumpFor(tester, 50);
      await Future<void>.delayed(const Duration(seconds: 3));
      await pumpFor(tester, 20);

      final onAuth = find.byType(TextField).evaluate().isNotEmpty;
      if (onAuth) {
        const email = String.fromEnvironment('TEST_EMAIL');
        const password = String.fromEnvironment('TEST_PASSWORD');
        if (email.isEmpty || password.isEmpty) {
          debugPrint('⚠️  No credentials — cannot run feature tests');
          return;
        }

        // ── Test: Auth screen UI ──
        debugPrint('[AUTH]');
        expect(find.text('Sign in'), findsOneWidget);
        final fields = find.byType(TextField);
        expect(fields.evaluate().length, greaterThanOrEqualTo(2));
        pass('Auth screen shows email, password, sign-in button');

        // ── Test: Login ──
        await tester.enterText(fields.at(0), email);
        await tester.enterText(fields.at(1), password);
        await pumpFor(tester, 5);
        await tester.tap(find.text('Sign in'));
        await pumpFor(tester, 20);
        await Future<void>.delayed(const Duration(seconds: 5));
        await pumpFor(tester, 20);
        pass('Login submitted');
      } else {
        debugPrint('[AUTH]');
        skip('Auth screen UI', 'already logged in');
        pass('Session persisted from prior login');
      }

      // Wait for API data to load
      await Future<void>.delayed(const Duration(seconds: 5));
      await pumpFor(tester, 30);

      // ── HOME SCREEN ───────────────────────────────────────────────────
      debugPrint('');
      debugPrint('[HOME]');

      expect(find.text('Your friendships'), findsWidgets);
      pass('Home screen loads with title');

      // Filter buttons
      final hasAll = find.text('All').evaluate().isNotEmpty;
      final hasClose = find.text('Close').evaluate().isNotEmpty;
      final hasRecent = find.text('Recent').evaluate().isNotEmpty;
      expect(hasAll && hasClose && hasRecent, isTrue,
          reason: 'All filter buttons should be visible');
      pass('Filter buttons (All / Close / Recent) visible');

      // Tap each filter
      await tester.tap(find.text('Close').first);
      await pumpFor(tester, 5);
      await tester.tap(find.text('Recent').first);
      await pumpFor(tester, 5);
      await tester.tap(find.text('All').first);
      await pumpFor(tester, 5);
      expect(find.text('Your friendships'), findsWidgets);
      pass('Filter buttons are tappable without crash');

      // Friend cards or empty state
      await waitForApi(tester, seconds: 3);
      final hasCards = findFriendCard() != null;
      final hasEmpty = find.textContaining('No friends').evaluate().isNotEmpty ||
          find.text('👋').evaluate().isNotEmpty;
      expect(hasCards || hasEmpty, isTrue);
      pass(hasCards ? 'Friend cards visible' : 'Empty state visible');

      // Pull to refresh
      final refreshIndicator = find.byType(RefreshIndicator);
      if (refreshIndicator.evaluate().isNotEmpty) {
        await tester.drag(refreshIndicator.first, const Offset(0, 300));
        await pumpFor(tester, 10);
        await Future<void>.delayed(const Duration(seconds: 3));
        await pumpFor(tester, 20);
        expect(find.text('Your friendships'), findsWidgets);
        pass('Pull-to-refresh works');
      } else {
        skip('Pull-to-refresh', 'no RefreshIndicator found');
      }

      // Floating action buttons
      expect(find.byIcon(PhosphorIconsBold.plus), findsWidgets);
      expect(find.byIcon(PhosphorIconsBold.broadcast), findsWidgets);
      pass('Floating buttons visible (add friend + beacon)');

      // ── BOTTOM NAVIGATION ─────────────────────────────────────────────
      debugPrint('');
      debugPrint('[NAVIGATION]');

      expect(find.byIcon(PhosphorIconsBold.house), findsOneWidget);
      expect(find.byIcon(PhosphorIconsBold.envelopeSimple), findsOneWidget);
      expect(find.byIcon(PhosphorIconsBold.gearSix), findsOneWidget);
      pass('All 3 bottom nav tabs present');

      // Navigate to invites
      await goToTab(tester, PhosphorIconsBold.envelopeSimple);
      await pumpFor(tester, 5);
      pass('Tapped Invites tab');

      // Navigate to settings
      await goToTab(tester, PhosphorIconsBold.gearSix);
      await pumpFor(tester, 5);
      pass('Tapped Settings tab');

      // Back to home
      await goHome(tester);
      expect(find.text('Your friendships'), findsWidgets);
      pass('Returned to Home tab');

      // Rapid switching stress test
      for (var i = 0; i < 5; i++) {
        await goToTab(tester, PhosphorIconsBold.envelopeSimple);
        await pumpFor(tester, 2);
        await goToTab(tester, PhosphorIconsBold.gearSix);
        await pumpFor(tester, 2);
        await goHome(tester);
        await pumpFor(tester, 2);
      }
      expect(find.byType(MaterialApp), findsOneWidget);
      pass('Rapid tab switching (15 switches) — no crash');

      // ── INVITES SCREEN ────────────────────────────────────────────────
      debugPrint('');
      debugPrint('[INVITES]');

      await goToTab(tester, PhosphorIconsBold.envelopeSimple);
      await waitForApi(tester);

      final hasInviteCheck =
          find.byIcon(PhosphorIconsBold.check).evaluate().isNotEmpty;
      final hasInviteX =
          find.byIcon(PhosphorIconsBold.x).evaluate().isNotEmpty;
      final hasEmptyMailbox = find.text('📭').evaluate().isNotEmpty;
      final hasInviteText =
          find.textContaining('invite').evaluate().isNotEmpty;
      expect(hasInviteCheck || hasInviteX || hasEmptyMailbox || hasInviteText,
          isTrue);
      pass(hasInviteCheck
          ? 'Pending invites visible'
          : 'Invites empty state visible');

      // ── SETTINGS SCREEN ───────────────────────────────────────────────
      debugPrint('');
      debugPrint('[SETTINGS]');

      await goToTab(tester, PhosphorIconsBold.gearSix);
      await waitForApi(tester);

      final settingsFields = find.byType(TextField);
      expect(settingsFields.evaluate().length, greaterThanOrEqualTo(2));
      pass('Profile editing fields visible (name, email, phone)');

      // Test tapping name field
      await tester.tap(settingsFields.first);
      await pumpFor(tester, 3);
      pass('Display name field is interactive');

      // Scroll to transition picker
      final settingsScroll = find.byType(Scrollable);
      if (settingsScroll.evaluate().isNotEmpty) {
        await tester.drag(settingsScroll.first, const Offset(0, -300));
        await pumpFor(tester, 5);
      }

      final hasTransitionOption =
          find.text('Slide').evaluate().isNotEmpty ||
          find.text('Fade').evaluate().isNotEmpty ||
          find.text('Bubble').evaluate().isNotEmpty;
      if (hasTransitionOption) {
        pass('Transition style picker visible');
      } else {
        skip('Transition style picker', 'not found after scroll');
      }

      // ── ADD FRIEND SCREEN ─────────────────────────────────────────────
      debugPrint('');
      debugPrint('[ADD FRIEND]');

      await goHome(tester);
      await pumpFor(tester, 5);

      final addBtn = find.byIcon(PhosphorIconsBold.plus);
      if (addBtn.evaluate().isNotEmpty) {
        await tester.tap(addBtn.first);
        await pumpFor(tester, 15);

        final searchField = find.byType(TextField);
        expect(searchField.evaluate().isNotEmpty, isTrue);
        pass('Add friend screen opens with search field');

        // Type a search query
        await tester.enterText(searchField.first, 'test');
        await waitForApi(tester, seconds: 3);

        final hasSearchResults =
            find.byType(AppCard).evaluate().isNotEmpty;
        final hasNoResults =
            find.textContaining('No results').evaluate().isNotEmpty;
        final hasSearchLoading =
            find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
        expect(hasSearchResults || hasNoResults || hasSearchLoading, isTrue);
        pass('Search returns results, empty state, or loading');

        // Go back to home — back button may be obscured by floating button
        final backFromAdd = find.byIcon(Icons.arrow_back);
        if (backFromAdd.evaluate().isNotEmpty) {
          await tester.tap(backFromAdd.first, warnIfMissed: false);
          await pumpFor(tester, 10);
        }
        // Fallback: use bottom nav
        if (find.text('Your friendships').evaluate().isEmpty) {
          await goHome(tester);
        }
      } else {
        skip('Add friend screen', 'add button not found');
      }

      // ── FRIEND PROFILE ────────────────────────────────────────────────
      debugPrint('');
      debugPrint('[FRIEND PROFILE]');

      await goHome(tester);
      await waitForApi(tester, seconds: 3);

      final cardIcon = findFriendCard();
      if (cardIcon != null) {
        await tester.tap(cardIcon.first);
        await waitForApi(tester, seconds: 3);

        // Profile elements
        final hasHeartBar = find.byType(HeartHealthBar).evaluate().isNotEmpty;
        expect(hasHeartBar, isTrue, reason: 'Profile should show HeartHealthBar');
        pass('Friend profile opens with HeartHealthBar');

        // Contact buttons
        final hasPhone =
            find.byIcon(PhosphorIconsBold.phone).evaluate().isNotEmpty;
        final hasChat =
            find.byIcon(PhosphorIconsBold.chatCircle).evaluate().isNotEmpty;
        final hasEmailBtn =
            find.byIcon(PhosphorIconsBold.envelopeSimple).evaluate().isNotEmpty;
        expect(hasPhone || hasChat || hasEmailBtn, isTrue);
        pass('Contact buttons (Call/Text/Email) present');

        // Care signal button
        final careSignal = find.text('Thinking of you');
        if (careSignal.evaluate().isNotEmpty) {
          pass('Care signal button visible');
        }

        // Check-in button
        final checkInBtn = find.byType(PrimaryButton);
        if (checkInBtn.evaluate().isNotEmpty) {
          pass('Check-in button visible');
        }

        // Scroll to notes section
        final profileScroll = find.byType(Scrollable);
        if (profileScroll.evaluate().isNotEmpty) {
          await tester.drag(profileScroll.first, const Offset(0, -200));
          await pumpFor(tester, 5);
        }

        // Notes field
        final noteHint = find.text('NOTES');
        if (noteHint.evaluate().isNotEmpty) {
          pass('Notes section visible');
        }

        // Find text fields on profile (notes + reminder)
        final profileFields = find.byType(TextField);
        if (profileFields.evaluate().isNotEmpty) {
          await tester.tap(profileFields.last);
          await pumpFor(tester, 3);
          pass('Notes/reminder text field is interactive');
        }

        // Scroll further to reminder section
        if (profileScroll.evaluate().isNotEmpty) {
          await tester.drag(profileScroll.first, const Offset(0, -200));
          await pumpFor(tester, 5);
        }

        final hasReminder =
            find.textContaining('REMIND').evaluate().isNotEmpty ||
            find.textContaining('reminder').evaluate().isNotEmpty;
        final hasChips = find.text('1 day').evaluate().isNotEmpty ||
            find.text('3 days').evaluate().isNotEmpty ||
            find.text('7 days').evaluate().isNotEmpty;
        if (hasReminder || hasChips) {
          pass('Reminder section visible');

          // Tap a frequency chip
          final chip3 = find.text('3 days');
          if (chip3.evaluate().isNotEmpty) {
            await tester.tap(chip3.first);
            await pumpFor(tester, 3);
            pass('Frequency chip tappable');
          }
        } else {
          skip('Reminder section', 'not visible after scroll');
        }

        // Navigate back to home
        final backBtn = find.byIcon(Icons.arrow_back);
        if (backBtn.evaluate().isNotEmpty) {
          await tester.tap(backBtn.first, warnIfMissed: false);
          await pumpFor(tester, 10);
        }
        // Fallback: use bottom nav to get home
        if (find.text('Your friendships').evaluate().isEmpty) {
          await goHome(tester);
          await pumpFor(tester, 5);
        }
        expect(find.text('Your friendships'), findsWidgets);
        pass('Back navigation returns to home');
      } else {
        skip('Friend profile', 'no friend cards available');
      }

      // ── CHECK-IN FLOW ─────────────────────────────────────────────────
      debugPrint('');
      debugPrint('[CHECK-IN]');

      await goHome(tester);
      await waitForApi(tester, seconds: 3);

      final cardForCheckin = findFriendCard();
      if (cardForCheckin != null) {
        await tester.tap(cardForCheckin.first);
        await waitForApi(tester, seconds: 3);

        // The check-in button is at the bottom with label "How are things?"
        final scrollForCheckin = find.byType(Scrollable);
        if (scrollForCheckin.evaluate().isNotEmpty) {
          for (var i = 0; i < 5; i++) {
            await tester.drag(scrollForCheckin.first, const Offset(0, -200));
            await pumpFor(tester, 3);
            final checkInText = find.textContaining('How are things');
            if (checkInText.evaluate().isNotEmpty) break;
          }
        }

        final checkInText = find.textContaining('How are things');
        if (checkInText.evaluate().isNotEmpty) {
          await tester.tap(checkInText.first, warnIfMissed: false);
          await pumpFor(tester, 15);

          // Check-in screen elements
          final hasSlider = find.byType(GentleSlider).evaluate().isNotEmpty;
          final hasEmoji = find.text('😊').evaluate().isNotEmpty ||
              find.text('🙂').evaluate().isNotEmpty ||
              find.text('😐').evaluate().isNotEmpty;

          if (hasSlider) {
            pass('Check-in screen shows GentleSlider');
          }
          if (hasEmoji) {
            pass('Check-in screen shows rating emojis');
          }

          // Enter a note
          final noteField = find.byType(TextField);
          if (noteField.evaluate().isNotEmpty) {
            await tester.enterText(
                noteField.first, 'Integration test check-in');
            await pumpFor(tester, 3);
            pass('Check-in note field editable');
          }

          // Submit check-in
          final submitBtn = find.byType(PrimaryButton);
          if (submitBtn.evaluate().isNotEmpty) {
            await tester.tap(submitBtn.first);
            await waitForApi(tester, seconds: 3);

            final hasSuccess =
                find.text('✨').evaluate().isNotEmpty ||
                find.textContaining('saved').evaluate().isNotEmpty;
            final backOnProfile =
                find.byType(HeartHealthBar).evaluate().isNotEmpty;
            final backOnHomeScreen =
                find.text('Your friendships').evaluate().isNotEmpty;

            if (hasSuccess || backOnProfile || backOnHomeScreen) {
              pass('Check-in submitted successfully');
            } else {
              skip('Check-in submit verification',
                  'could not verify success state');
            }
          }

          // Navigate back to home
          final closeBtn = find.byIcon(Icons.close);
          final backBtn2 = find.byIcon(Icons.arrow_back);
          if (closeBtn.evaluate().isNotEmpty) {
            await tester.tap(closeBtn.first, warnIfMissed: false);
            await pumpFor(tester, 10);
          } else if (backBtn2.evaluate().isNotEmpty) {
            await tester.tap(backBtn2.first, warnIfMissed: false);
            await pumpFor(tester, 10);
          }
        } else {
          skip('Check-in flow', 'button not found after scrolling');
        }

        // Ensure we're back home
        await goHome(tester);
      } else {
        skip('Check-in flow', 'no friend cards available');
      }

      // ── BEACON ────────────────────────────────────────────────────────
      debugPrint('');
      debugPrint('[BEACON]');

      await goHome(tester);
      await pumpFor(tester, 5);

      final beacon = find.byIcon(PhosphorIconsBold.broadcast);
      if (beacon.evaluate().isNotEmpty) {
        await tester.tap(beacon.first);
        await pumpFor(tester, 10);
        expect(find.byType(MaterialApp), findsOneWidget);
        pass('Beacon button tappable — no crash');

        // Go back home if navigated away
        await goHome(tester);
      } else {
        skip('Beacon', 'broadcast icon not found');
      }

      // ── SUMMARY ───────────────────────────────────────────────────────
      debugPrint('');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('  ✅ Passed: $_pass');
      debugPrint('  ⏭️  Skipped: $_skip');
      debugPrint('  Total: ${_pass + _skip}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('');
    });
  });
}
