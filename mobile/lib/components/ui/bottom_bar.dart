import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../design/theme.dart';

class BottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int inviteBadgeCount;

  const BottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.inviteBadgeCount = 0,
  });

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  static const _icons = [
    PhosphorIconsBold.house,
    PhosphorIconsBold.envelopeSimple,
    PhosphorIconsBold.gearSix,
  ];

  static const _labels = ['Home', 'Invites', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final inactiveColor = isDark
        ? AppColorsDark.textMuted
        : AppColors.textMuted;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;
    final negative = isDark ? AppColorsDark.negative : AppColors.negative;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.full),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: surface.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: Border.all(color: borderColor, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (i) {
              final isActive = i == widget.currentIndex;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? accent.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon + badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            _icons[i],
                            size: 20,
                            color: isActive ? accent : inactiveColor,
                          ),
                          if (i == 1 && widget.inviteBadgeCount > 0)
                            Positioned(
                              top: -4,
                              right: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xxs,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: negative,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.full,
                                  ),
                                ),
                                child: Text(
                                  widget.inviteBadgeCount > 99
                                      ? '99+'
                                      : widget.inviteBadgeCount.toString(),
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Label always visible
                      Text(
                        _labels[i],
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 9,
                          fontWeight:
                              isActive ? FontWeight.w900 : FontWeight.w700,
                          color: isActive ? accent : inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
