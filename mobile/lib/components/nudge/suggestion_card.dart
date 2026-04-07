import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../constants/nudge_copy.dart';
import '../../design/theme.dart';

/// A card that gently suggests which friend to reach out to.
///
/// Three states:
///  - **Suggestion** (7-13 days): "{Name}'s avatar + It's been a little while…"
///  - **Warm nudge** (14+ days): "{Name} might appreciate a hello."
///  - **All good**: "All caught up. Your people are close. 💛"
class SuggestionCard extends StatelessWidget {
  /// The suggested friend's display name (null → all-good state).
  final String? friendName;

  /// Days since last contact with this friend.
  final int daysSinceContact;

  /// The friend's ID for navigation.
  final String? friendId;

  /// Current warmth tier for colour theming.
  final WarmthTier warmthTier;

  const SuggestionCard({
    super.key,
    this.friendName,
    this.daysSinceContact = 0,
    this.friendId,
    this.warmthTier = WarmthTier.gentle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final gold = isDark ? AppColorsDark.warm : AppPalette.gold;
    final goldBg = isDark
        ? gold.withValues(alpha: 0.12)
        : AppPalette.gold.withValues(alpha: 0.12);
    final goldBorder = isDark
        ? gold.withValues(alpha: 0.15)
        : AppPalette.gold.withValues(alpha: 0.15);

    // All-good state
    if (friendName == null || friendId == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: goldBg,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(color: goldBorder, width: 1),
        ),
        child: Row(
          children: [
            const Text('💛', style: TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All caught up.',
                    style: AppTypography.subheading.copyWith(color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your people are close.',
                    style: AppTypography.body.copyWith(
                      color: isDark ? AppColorsDark.textTertiary : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Determine copy based on days since contact
    final bool isWarmNudge = daysSinceContact >= 14;
    final String title = isWarmNudge
        ? '$friendName might appreciate a hello.'
        : 'It\'s been a little while since you and $friendName connected.';
    final IconData icon = isWarmNudge
        ? PhosphorIconsBold.heart
        : PhosphorIconsBold.heartHalf;
    final Color cardBg = isDark
        ? (isWarmNudge
            ? accent.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.04))
        : (isWarmNudge
            ? AppPalette.orangeSubtle
            : const Color(0xFFF5F0FF));

    return GestureDetector(
      onTap: () => context.push('/profile/$friendId'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.textPrimary.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Initials circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.15),
              ),
              alignment: Alignment.center,
              child: Text(
                friendName![0].toUpperCase(),
                style: AppTypography.heading.copyWith(
                  color: accent,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.label.copyWith(color: textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isWarmNudge
                        ? 'One small reach-out? 💛'
                        : 'Say hi when you\'re ready.',
                    style:
                        AppTypography.caption.copyWith(color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(icon, color: accent, size: 22),
          ],
        ),
      ),
    );
  }
}
