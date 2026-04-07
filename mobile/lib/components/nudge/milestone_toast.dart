import 'package:flutter/material.dart';

import '../../design/theme.dart';

/// Milestone data passed to the toast.
class MilestoneData {
  final String key;
  final String emoji;
  final String copy;

  const MilestoneData({
    required this.key,
    required this.emoji,
    required this.copy,
  });
}

/// A gentle full-screen overlay celebrating a caring-rhythm milestone.
///
/// Auto-dismisses after 4 seconds or taps to dismiss.
class MilestoneToast extends StatefulWidget {
  final MilestoneData milestone;
  final VoidCallback onDismiss;

  const MilestoneToast({
    super.key,
    required this.milestone,
    required this.onDismiss,
  });

  @override
  State<MilestoneToast> createState() => _MilestoneToastState();
}

class _MilestoneToastState extends State<MilestoneToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;

    return GestureDetector(
      onTap: _dismiss,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          alignment: Alignment.center,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xxxl,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2520)
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.milestone.emoji,
                    style: const TextStyle(fontSize: 56),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    widget.milestone.copy,
                    style: AppTypography.heading.copyWith(
                      color: textPrimary,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Tap to continue',
                    style: AppTypography.caption.copyWith(
                      color: textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
