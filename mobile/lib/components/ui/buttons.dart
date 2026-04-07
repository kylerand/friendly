import 'package:flutter/material.dart';
import '../../design/theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPress;
  final bool disabled;
  final Widget? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPress,
    this.disabled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final textInverse = isDark ? AppColorsDark.textInverse : AppColors.textInverse;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: SizedBox(
        width: double.infinity,
        child: MaterialButton(
          onPressed: disabled ? null : onPress,
          color: accent,
          disabledColor: accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xl,
          ),
          elevation: 0,
          highlightElevation: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: AppTypography.label.copyWith(color: textInverse),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPress;
  final bool disabled;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPress,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: disabled ? null : onPress,
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.xl,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.label.copyWith(color: accent),
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPress;

  const GhostButton({
    super.key,
    required this.label,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;

    return TextButton(
      onPressed: onPress,
      style: TextButton.styleFrom(
        foregroundColor: accent,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.lg,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(color: accent),
      ),
    );
  }
}
