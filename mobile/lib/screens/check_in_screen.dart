import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/ui/ui.dart';
import '../constants/copy.dart';
import '../design/theme.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  final String friendshipId;
  final String friendName;

  const CheckInScreen({
    super.key,
    required this.friendshipId,
    required this.friendName,
  });

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  double _rating = 3;
  String _note = '';
  bool _submitting = false;
  bool _submitted = false;

  static const _ratingEmojis = ['😔', '😐', '🙂', '😊', '🥰'];
  static const _ratingLabels = [
    'Not great',
    'Okay',
    'Good',
    'Really good',
    'Amazing',
  ];

  Future<void> _handleSubmit() async {
    setState(() => _submitting = true);
    try {
      await ApiService.createCheckIn(
        comfort: _rating.round(),
        connection: _rating.round(),
        energy: _rating.round(),
        notes: _note.isNotEmpty ? _note : null,
      );
      await ref.read(appStateProvider.notifier).refresh();
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final textTertiary =
        isDark ? AppColorsDark.textTertiary : AppColors.textTertiary;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final accentSubtle =
        isDark ? AppColorsDark.accentSubtle : AppColors.accentSubtle;
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;

    if (_submitted) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: accentSubtle,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('✨',
                        style: TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Check-in saved',
                    style: AppTypography.heading.copyWith(color: textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SecondaryButton(
                    label: 'Back',
                    onPress: () => context.pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final ratingIndex = (_rating.round() - 1).clamp(0, 4);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const Text('🫧', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '${Copy.checkInTitle} with ${widget.friendName}?',
                    style: AppTypography.display.copyWith(color: textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Take a moment to reflect.',
                    style: AppTypography.body.copyWith(color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Emoji indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final isActive = i == ratingIndex;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isActive ? 1.0 : 0.35,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isActive ? 1.3 : 1.0,
                    child: Text(
                      _ratingEmojis[i],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Slider
            GentleSlider(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Rating label
            Center(
              child: Text(
                _ratingLabels[ratingIndex],
                style: AppTypography.label.copyWith(color: accent),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Optional note
            TextField(
              onChanged: (v) => setState(() => _note = v),
              maxLines: null,
              minLines: 3,
              style: AppTypography.body.copyWith(color: textPrimary),
              decoration: InputDecoration(
                hintText: Copy.checkInHint,
                hintStyle: AppTypography.body.copyWith(color: textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  borderSide: BorderSide(color: accent),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Submit
            PrimaryButton(
              label: 'Save check-in',
              onPress: _submitting ? null : _handleSubmit,
              disabled: _submitting,
            ),
            const SizedBox(height: AppSpacing.md),

            // Skip
            Center(
              child: TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Skip',
                  style: AppTypography.label.copyWith(color: textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
