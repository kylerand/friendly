/// Integration test entry point — boots the real app for testing.
///
/// Usage:
///   flutter test integration_test/app_test.dart -d SIMULATOR_ID
///
/// Pass credentials for automated login:
///   --dart-define=TEST_EMAIL=user@example.com --dart-define=TEST_PASSWORD=pass
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:friendly/main.dart' show FriendlyApp;
import 'package:friendly/services/supabase_service.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

late IntegrationTestWidgetsFlutterBinding binding;
int _screenshotIndex = 0;

/// Take a screenshot via the binding; log on failure but don't crash.
Future<void> screenshot(String name) async {
  _screenshotIndex++;
  final label = '${_screenshotIndex.toString().padLeft(2, '0')}_$name';
  try {
    await binding.takeScreenshot(label);
    debugPrint('📸 Screenshot: $label');
  } catch (e) {
    debugPrint('⚠️  Screenshot "$label" failed: $e');
  }
}

Future<void> _initServices() async {
  await SupabaseService.initialize();
  // Skip NotificationService — it triggers a system permission dialog
  // that blocks all touch input on the simulator.
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _initServices();
  });

  group('Pre-deployment smoke test & screenshots', () {
    testWidgets('Full app walkthrough', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: FriendlyApp()),
      );
      // Pump frames to let the app initialize (don't use pumpAndSettle —
      // the app has repeating animations like the beacon glow that never settle).
      // First pump pending microtasks, then pump visual frames.
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // Extra time for async API calls to complete
      await Future<void>.delayed(const Duration(seconds: 3));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Detect current state: auth screen vs already logged in
      // Auth screen uses TextField (not TextFormField)
      final onAuthScreen = find.byType(TextField).evaluate().isNotEmpty;

      if (onAuthScreen) {
        // ── Auth screen ──
        await screenshot('auth_screen');

        // Credentials from --dart-define or environment
        const email = String.fromEnvironment('TEST_EMAIL');
        const password = String.fromEnvironment('TEST_PASSWORD');

        if (email.isEmpty || password.isEmpty) {
          debugPrint(
            '⚠️  On auth screen but no credentials set. '
            'Pass --dart-define=TEST_EMAIL=x --dart-define=TEST_PASSWORD=y',
          );
          return;
        }

        final fields = find.byType(TextField);
        // Email is first, password is second
        await tester.enterText(fields.at(0), email);
        await tester.enterText(fields.at(1), password);
        await _pumpFrames(tester, 5);
        await screenshot('auth_filled');

        // The sign-in button text is lowercase "Sign in"
        final signIn = find.text('Sign in');
        expect(signIn, findsOneWidget);
        await tester.tap(signIn);
        // Wait for auth + data load
        await _pumpFrames(tester, 20);
        await Future<void>.delayed(const Duration(seconds: 5));
        await _pumpFrames(tester, 20);
      } else {
        debugPrint('ℹ️  Already logged in — skipping auth screen');
      }

      // ── Home screen ──
      // Extra wait for friend data to load from API
      await Future<void>.delayed(const Duration(seconds: 3));
      await _pumpFrames(tester, 20);
      await screenshot('home_screen');

      // ── Bottom nav: Invites (icon-based tap since labels are hidden) ──
      final invitesIcon = find.byIcon(PhosphorIconsBold.envelopeSimple);
      if (invitesIcon.evaluate().isNotEmpty) {
        await tester.tap(invitesIcon.first);
        await _pumpFrames(tester, 10);
        await screenshot('invites_screen');
      }

      // ── Bottom nav: Settings ──
      final settingsIcon = find.byIcon(PhosphorIconsBold.gearSix);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon.first);
        await _pumpFrames(tester, 10);
        await screenshot('settings_screen');
      }

      // ── Back to Home ──
      final homeIcon = find.byIcon(PhosphorIconsBold.house);
      if (homeIcon.evaluate().isNotEmpty) {
        await tester.tap(homeIcon.first);
        await _pumpFrames(tester, 10);
      }

      // ── Tap first friend card → Profile ──
      Finder? cardIcon;
      for (final f in [
        find.byIcon(PhosphorIconsFill.fire),
        find.byIcon(PhosphorIconsFill.sun),
        find.byIcon(PhosphorIconsFill.cloudSun),
        find.byIcon(PhosphorIconsFill.snowflake),
      ]) {
        if (f.evaluate().isNotEmpty) {
          cardIcon = f;
          break;
        }
      }

      if (cardIcon != null) {
        await tester.tap(cardIcon.first);
        await _pumpFrames(tester, 15);
        await screenshot('friend_profile');

        // Scroll down for notes/reminders
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.drag(scrollable.first, const Offset(0, -300));
          await _pumpFrames(tester, 5);
          await screenshot('friend_profile_scrolled');
        }
      } else {
        debugPrint('ℹ️  No friend cards found — skipping profile screen');
      }

      debugPrint(
          '✅ Walkthrough complete — $_screenshotIndex screenshots taken');
    });
  });
}

/// Pump N frames at 200ms each (total = N * 200ms).
/// Use instead of pumpAndSettle to avoid hanging on infinite animations.
Future<void> _pumpFrames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}
