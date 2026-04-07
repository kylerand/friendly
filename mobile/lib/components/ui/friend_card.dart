import 'package:flutter/material.dart';
import '../../components/avatar/avatar_types.dart';
import '../../components/avatar/avatar_widget.dart';
import '../../design/theme.dart';
import 'heart_health_bar.dart';

class FriendCard extends StatelessWidget {
  final String name;
  final double heartHealth;
  final String? avatarInitial;
  final Map<String, dynamic>? metadata;
  final bool hasBeacon;
  final DateTime? lastInteraction;
  final VoidCallback? onTap;

  const FriendCard({
    super.key,
    required this.name,
    required this.heartHealth,
    this.avatarInitial,
    this.metadata,
    this.hasBeacon = false,
    this.lastInteraction,
    this.onTap,
  });

  Color _avatarBgColor(bool isDark) {
    if (heartHealth >= 80) return isDark ? const Color(0xFF1A3366) : AppPalette.blue;
    if (heartHealth >= 60) return isDark ? const Color(0xFF66264A) : AppPalette.pink;
    if (heartHealth >= 40) return isDark ? const Color(0xFF4E5105) : AppPalette.green;
    if (heartHealth >= 20) return isDark ? const Color(0xFF002966) : AppPalette.blueDark;
    return isDark ? const Color(0xFF665000) : AppPalette.gold;
  }

  Color _cardBgColor(bool isDark) {
    if (isDark) {
      if (heartHealth >= 80) return const Color(0xFF1A2A40);
      if (heartHealth >= 60) return const Color(0xFF301A28);
      if (heartHealth >= 40) return const Color(0xFF282A18);
      if (heartHealth >= 20) return const Color(0xFF182030);
      return const Color(0xFF302818);
    }
    if (heartHealth >= 80) return AppPalette.blueSubtle;
    if (heartHealth >= 60) return AppPalette.pinkSubtle;
    if (heartHealth >= 40) return AppPalette.greenSubtle;
    if (heartHealth >= 20) return AppPalette.blueDarkSubtle;
    return AppPalette.goldSubtle;
  }

  Color _heartColor(bool isDark) {
    if (isDark) {
      if (heartHealth >= 80) return const Color(0xFF7AACF7);
      if (heartHealth >= 60) return const Color(0xFFF29AD6);
      if (heartHealth >= 40) return const Color(0xFFB5BB4A);
      if (heartHealth >= 20) return const Color(0xFF6E9BE0);
      return const Color(0xFFE8C85C);
    }
    if (heartHealth >= 80) return const Color(0xFF7AACF7);
    if (heartHealth >= 60) return const Color(0xFFF29AD6);
    if (heartHealth >= 40) return const Color(0xFFB5BB4A);
    if (heartHealth >= 20) return const Color(0xFF6E9BE0);
    return const Color(0xFFE8C85C);
  }

  String _circleLabel() {
    if (heartHealth >= 60) return 'Close';
    return 'Recent';
  }

  String _lastSeenText() {
    if (lastInteraction == null) return 'No check-ins yet';
    final diff = DateTime.now().difference(lastInteraction!);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 30}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColorsDark.textMuted : AppColors.textMuted;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : AppColors.textPrimary.withValues(alpha: 0.04);
    final bgColor = _cardBgColor(isDark);
    final avatarBg = _avatarBgColor(isDark);

    final initial = (avatarInitial ?? name).isNotEmpty
        ? (avatarInitial ?? name)[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarWidget(
                  config: AvatarConfig.fromMetadata(metadata),
                  size: 56,
                  fallbackInitial: initial,
                  fallbackBg: avatarBg,
                  fallbackFg: Colors.white,
                ),
                if (hasBeacon)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppPalette.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgColor, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md + 2),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Text(
                    name,
                    style: AppTypography.subheading.copyWith(color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Hearts row
                  HeartHealthBar(health: heartHealth, heartColor: _heartColor(isDark)),
                  const SizedBox(height: 4),
                  // Circle label + last seen
                  Row(
                    children: [
                      Text(
                        _circleLabel().toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: textMuted,
                          fontSize: 10,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '·',
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        _lastSeenText(),
                        style: AppTypography.caption.copyWith(
                          color: textMuted,
                          fontSize: 10,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
