import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../design/theme.dart';

class HeartHealthBar extends StatelessWidget {
  final double health; // 0–100
  final Color? heartColor;

  const HeartHealthBar({
    super.key,
    required this.health,
    this.heartColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColorsDark.accent : AppColors.accent;
    final color = heartColor ?? defaultColor;
    final filledCount = (health.clamp(0, 100) / 20).round().clamp(0, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < filledCount;
        return Padding(
          padding: EdgeInsets.only(right: i < 4 ? 1 : 0),
          child: Icon(
            filled ? PhosphorIconsFill.heart : PhosphorIconsBold.heart,
            size: 15,
            color: filled ? color : color.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}
