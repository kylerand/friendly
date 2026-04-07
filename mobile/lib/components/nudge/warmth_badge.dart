import 'package:flutter/material.dart';

import '../../constants/nudge_copy.dart';
import '../../design/theme.dart';

/// Warmth tier badge for the home screen.
///
/// Shows the current warmth emoji + label in a gold-tinted pill.
class WarmthBadge extends StatelessWidget {
  final WarmthTier tier;

  const WarmthBadge({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = warmthTiers[tier]!;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final gold = isDark ? AppColorsDark.warm : AppPalette.gold;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.full),
        color: gold.withValues(alpha: 0.15),
        border: Border.all(
          color: gold.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(info.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            info.label,
            style: AppTypography.label.copyWith(
              color: textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
