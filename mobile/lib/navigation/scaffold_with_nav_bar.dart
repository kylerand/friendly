import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../components/ui/bottom_bar.dart';
import '../design/theme.dart';
import '../state/app_state.dart';
import '../state/beacon_state.dart';

/// Shell widget that wraps child routes with a persistent bottom navigation bar.
class ScaffoldWithNavBar extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingInvitesProvider).length;
    final location = GoRouterState.of(context).matchedLocation;
    final profile = ref.watch(currentProfileProvider);

    // Map current location to tab index (3 tabs: Home, Invites, Settings)
    int currentIndex;
    if (location == '/' || location.startsWith('/profile') || location.startsWith('/check-in') || location.startsWith('/add-friend')) {
      currentIndex = 0;
    } else if (location == '/invites') {
      currentIndex = 1;
    } else if (location == '/edit-profile' || location == '/avatar-editor' || location == '/friend-language-quiz') {
      currentIndex = 2;
    } else {
      currentIndex = 0;
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine if we're on the home screen (shows greeting) or another screen (shows title)
    final isHome = location == '/';
    final isFriendProfile = location.startsWith('/profile');

    // Screen title for non-home screens
    String screenTitle = '';
    if (location == '/invites') {
      screenTitle = 'Invitations';
    } else if (location == '/edit-profile') {
      screenTitle = 'Edit profile';
    }

    // Greeting for home
    final greeting = profile?.displayName != null
        ? 'Hey, ${profile!.displayName}!'
        : 'Hey!';

    return Scaffold(
      body: Stack(
        children: [
          child,
          // Header bar with add-friend + title/greeting + beacon
          if (!isFriendProfile)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: topPadding + AppSpacing.sm,
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColorsDark.background : AppColors.background,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Add friend button
                    GestureDetector(
                      onTap: () => context.push('/add-friend'),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColorsDark.link : AppPalette.blue,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.accentGlow(
                            isDark ? AppColorsDark.link : AppPalette.blue,
                          ),
                        ),
                        child: const Icon(
                          PhosphorIconsBold.plus,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Title / greeting
                    Text(
                      isHome ? greeting : screenTitle,
                      style: AppTypography.heading.copyWith(
                        color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
                      ),
                    ),
                    // Beacon button
                    GestureDetector(
                      onTap: () => _showBeaconDialog(context, ref),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? AppColorsDark.accent : AppPalette.orange,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.accentGlow(
                            isDark ? AppColorsDark.accent : AppPalette.orange,
                          ),
                        ),
                        child: const Icon(
                          PhosphorIconsBold.broadcast,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Bottom bar
          Positioned(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: bottomPadding + AppSpacing.md,
            child: BottomBar(
              currentIndex: currentIndex,
              inviteBadgeCount: pendingCount,
              onTap: (index) => _onTap(context, ref, index),
            ),
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/invites');
      case 2:
        context.go('/edit-profile');
    }
  }

  void _showBeaconDialog(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColorsDark.accent : AppPalette.orange;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColorsDark.textMuted : AppColors.textMuted;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xxl),
        ),
        backgroundColor: isDark ? AppColorsDark.surface : AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Beacon icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIconsBold.broadcast,
                  size: 22,
                  color: accent,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Activate Beacon',
                style: AppTypography.heading.copyWith(color: textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Let your friends know you\'re available to connect right now.',
                style: AppTypography.body.copyWith(
                  color: textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              // Activate button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    ref.read(beaconStateProvider.notifier).sendBeacon();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Beacon activated!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      boxShadow: AppShadows.accentGlow(accent),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Activate',
                      style: AppTypography.label.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    alignment: Alignment.center,
                    child: Text(
                      'Cancel',
                      style: AppTypography.label.copyWith(
                        color: textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
