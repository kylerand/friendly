import 'package:flutter/material.dart';

import '../../design/theme.dart';

/// A gentle banner shown when a user returns after 7+ days away.
///
/// Dismissible, warm tone — shown once per return session.
class WelcomeBackBanner extends StatefulWidget {
  final VoidCallback? onDismiss;

  const WelcomeBackBanner({super.key, this.onDismiss});

  @override
  State<WelcomeBackBanner> createState() => _WelcomeBackBannerState();
}

class _WelcomeBackBannerState extends State<WelcomeBackBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss?.call());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFFFFCF0);

    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            const Text('🫧', style: TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back.',
                    style: AppTypography.label.copyWith(color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No rush — your people are right where you left them.',
                    style:
                        AppTypography.caption.copyWith(color: textSecondary),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _dismiss,
              child: Icon(Icons.close, color: textSecondary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
