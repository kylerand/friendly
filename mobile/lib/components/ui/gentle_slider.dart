import 'package:flutter/material.dart';
import '../../design/theme.dart';

class GentleSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int divisions;

  const GentleSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 5,
    this.divisions = 4,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final accentSubtle = isDark ? AppColorsDark.accentSubtle : AppColors.accentSubtle;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: accent,
        inactiveTrackColor: accentSubtle,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.15),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}
