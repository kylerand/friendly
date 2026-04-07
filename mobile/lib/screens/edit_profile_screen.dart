import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/avatar/avatar_types.dart';
import '../components/avatar/avatar_widget.dart';
import '../components/ui/ui.dart';
import '../constants/friend_language.dart';
import '../design/theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../state/transition_settings.dart';

// ── Contact frequency & preferred method options ─────────────────────────

class _FreqOption {
  final String key;
  final String label;
  const _FreqOption(this.key, this.label);
}

const _freqOptions = [
  _FreqOption('daily', 'Daily'),
  _FreqOption('few_times_week', 'Few/week'),
  _FreqOption('weekly', 'Weekly'),
  _FreqOption('biweekly', 'Biweekly'),
  _FreqOption('monthly', 'Monthly'),
];

class _MethodOption {
  final String key;
  final String emoji;
  final String label;
  const _MethodOption(this.key, this.emoji, this.label);
}

const _methodOptions = [
  _MethodOption('text', '💬', 'Text'),
  _MethodOption('call', '📞', 'Call'),
  _MethodOption('video', '📹', 'Video'),
  _MethodOption('in_person', '🫂', 'In person'),
  _MethodOption('social_media', '📱', 'Social'),
];

// ── Screen ───────────────────────────────────────────────────────────────

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _saving = false;
  bool _initialised = false;
  String? _contactFrequency;
  List<String> _preferredMethods = [];
  bool _pushOptIn = false;
  bool _beaconAlerts = true;
  bool _inviteAlerts = true;
  TimeOfDay _nudgeTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isRestDay = false;
  int _restDaysRemaining = 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      final profile = ref.read(currentProfileProvider);
      _nameController =
          TextEditingController(text: profile?.displayName ?? '');
      _emailController =
          TextEditingController(text: profile?.email ?? '');
      _phoneController =
          TextEditingController(text: profile?.phoneNumber ?? '');
      _contactFrequency =
          profile?.metadata?['contact_frequency'] as String?;
      final methods = profile?.metadata?['preferred_methods'];
      if (methods is List) {
        _preferredMethods = methods.cast<String>().toList();
      }
      _beaconAlerts = profile?.metadata?['beacon_alerts'] != false;
      _inviteAlerts = profile?.metadata?['invite_alerts'] != false;
      _initialised = true;
      // Load nudge preferences asynchronously
      _loadNudgePrefs();
    }
  }

  Future<void> _loadNudgePrefs() async {
    try {
      final prefs = await ApiService.getNudgePreferences();
      if (mounted) {
        setState(() {
          _pushOptIn = prefs['push_opt_in'] == true;
          final timeStr = prefs['preferred_nudge_time'] as String? ?? '18:00';
          final parts = timeStr.split(':');
          _nudgeTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 18,
            minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
          );
        });
      }
      final rest = await ApiService.getRestDayStatus();
      if (mounted) {
        setState(() {
          _isRestDay = rest['is_rest_day'] == true;
          _restDaysRemaining = (rest['rest_days_remaining'] as num?)?.toInt() ?? 2;
        });
      }
    } catch (_) {
      // Non-critical — use defaults
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final profile = ref.read(currentProfileProvider);
      final merged = <String, dynamic>{
        ...?profile?.metadata,
        'contact_frequency': _contactFrequency,
        'preferred_methods': _preferredMethods,
      };
      await ApiService.updateProfile({
        'display_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'metadata': merged,
      });
      await ref.read(appStateProvider.notifier).refresh();
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await AuthService.signOut();
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColorsDark.textMuted : AppColors.textMuted;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.textPrimary.withValues(alpha: 0.05);
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.70);
    final profile = ref.watch(currentProfileProvider);

    // Resolve friendship language from metadata
    final langKey = profile?.metadata?['friend_language'] as String?;
    FriendLanguageInfo? langInfo;
    if (langKey != null) {
      try {
        final lang = FriendLanguage.values.byName(langKey);
        langInfo = getFriendLanguage(lang);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxxl + 20,
          ),
          children: [
            // ── Avatar ──────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: () => context.push('/avatar-editor'),
                child: Column(
                  children: [
                    AvatarWidget(
                      config: AvatarConfig.fromMetadata(profile?.metadata),
                      size: 96,
                      fallbackInitial:
                          (profile?.displayName ?? '?')[0].toUpperCase(),
                      fallbackBg: isDark
                          ? AppColorsDark.link.withValues(alpha: 0.15)
                          : AppColors.link.withValues(alpha: 0.12),
                      fallbackFg: isDark ? AppColorsDark.link : AppColors.link,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Customize avatar',
                      style: AppTypography.body.copyWith(
                        color: isDark ? AppColorsDark.link : AppColors.link,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Name ────────────────────────────────────
            Text('DISPLAY NAME',
                style: AppTypography.caption.copyWith(color: textMuted)),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: TextField(
                controller: _nameController,
                style: AppTypography.body.copyWith(color: textPrimary),
                decoration: InputDecoration.collapsed(
                  hintText: 'Your name',
                  hintStyle: AppTypography.body.copyWith(color: textMuted),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Email ────────────────────────────────────
            Text('EMAIL',
                style: AppTypography.caption.copyWith(color: textMuted)),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTypography.body.copyWith(color: textPrimary),
                decoration: InputDecoration.collapsed(
                  hintText: 'Email address',
                  hintStyle: AppTypography.body.copyWith(color: textMuted),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Phone ────────────────────────────────────
            Text('PHONE',
                style: AppTypography.caption.copyWith(color: textMuted)),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: AppTypography.body.copyWith(color: textPrimary),
                decoration: InputDecoration.collapsed(
                  hintText: 'Phone number',
                  hintStyle: AppTypography.body.copyWith(color: textMuted),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Contact info is only shared with confirmed friends.',
              style: AppTypography.body.copyWith(color: textMuted, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Friendship Language ─────────────────────────────────
            Text('FRIENDSHIP LANGUAGE',
                style: AppTypography.caption.copyWith(color: textMuted)),
            const SizedBox(height: AppSpacing.sm),
            if (langInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppPalette.pink.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                      alignment: Alignment.center,
                      child: Text(langInfo.symbol, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(langInfo.label,
                              style: AppTypography.label
                                  .copyWith(color: textPrimary)),
                          const SizedBox(height: 2),
                          Text('Your primary friendship style',
                              style: AppTypography.body
                                  .copyWith(color: textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            GhostButton(
              label: langInfo != null ? '🔄 Retake quiz' : '✨ Take quiz',
              onPress: () => context.push('/friend-language-quiz'),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Contact Frequency ───────────────────────────────────
            Text('IDEAL CONTACT FREQUENCY',
                style: AppTypography.caption.copyWith(color: textMuted)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _freqOptions.map((opt) {
                final isSelected = _contactFrequency == opt.key;
                return GestureDetector(
                  onTap: () => setState(() => _contactFrequency = opt.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent
                          : cardBg,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: isSelected ? accent : borderColor,
                      ),
                    ),
                    child: Text(
                      opt.label,
                      style: AppTypography.body.copyWith(
                        color: isSelected ? Colors.white : textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Preferred Methods ───────────────────────────────────
            Text('PREFERRED WAYS TO CONNECT',
                style: AppTypography.caption.copyWith(color: textMuted)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _methodOptions.map((opt) {
                final isSelected = _preferredMethods.contains(opt.key);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _preferredMethods.remove(opt.key);
                      } else {
                        _preferredMethods.add(opt.key);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent
                          : cardBg,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: isSelected ? accent : borderColor,
                      ),
                    ),
                    child: Text(
                      '${opt.emoji} ${opt.label}',
                      style: AppTypography.body.copyWith(
                        color: isSelected ? Colors.white : textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Save Button ─────────────────────────────────────────
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg - 2),
                decoration: BoxDecoration(
                  color: _saving ? accent.withValues(alpha: 0.5) : accent,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  boxShadow: _saving ? null : AppShadows.accentGlow(accent),
                ),
                alignment: Alignment.center,
                child: Text(
                  _saving ? 'Saving…' : 'Save',
                  style: AppTypography.label.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // ── Notifications ───────────────────────────────────────
            Text('NOTIFICATIONS',
                style: AppTypography.caption.copyWith(color: textMuted)),
            const SizedBox(height: AppSpacing.sm),

            // 3 granular toggles
            _NotificationToggle(
              label: 'Reminder nudges',
              subtitle: 'Get caring reminders when friends drift',
              value: _pushOptIn,
              onChanged: (val) async {
                setState(() => _pushOptIn = val);
                try {
                  await ApiService.updateNudgePreferences({
                    'push_opt_in': val,
                  });
                } catch (_) {}
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _NotificationToggle(
              label: 'Friend beacons',
              subtitle: 'Know when friends light their beacon',
              value: _beaconAlerts,
              onChanged: (val) async {
                setState(() => _beaconAlerts = val);
                try {
                  await ApiService.updateProfile({
                    'metadata': {
                      ...?ref.read(currentProfileProvider)?.metadata,
                      'beacon_alerts': val,
                    },
                  });
                } catch (_) {}
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _NotificationToggle(
              label: 'Invitation alerts',
              subtitle: 'Get notified about new friend requests',
              value: _inviteAlerts,
              onChanged: (val) async {
                setState(() => _inviteAlerts = val);
                try {
                  await ApiService.updateProfile({
                    'metadata': {
                      ...?ref.read(currentProfileProvider)?.metadata,
                      'invite_alerts': val,
                    },
                  });
                } catch (_) {}
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Preferred time
            if (_pushOptIn)
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _nudgeTime,
                    helpText: 'When should we nudge you?',
                  );
                  if (picked != null && mounted) {
                    setState(() => _nudgeTime = picked);
                    final timeStr =
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    try {
                      await ApiService.updateNudgePreferences({
                        'preferred_nudge_time': timeStr,
                      });
                    } catch (_) {}
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Text('🕐', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Preferred time',
                                style: AppTypography.label
                                    .copyWith(color: textPrimary)),
                            Text(
                              _nudgeTime.format(context),
                              style: AppTypography.body
                                  .copyWith(color: textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: textMuted, size: 20),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),

            // Quiet day
            Text('REST DAY',
                style: AppTypography.caption.copyWith(color: textMuted)),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Text(_isRestDay ? '🫧' : '🌿',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRestDay
                              ? 'Enjoying a quiet day'
                              : 'Take a quiet day',
                          style: AppTypography.label
                              .copyWith(color: textPrimary),
                        ),
                        Text(
                          _isRestDay
                              ? 'Rest is part of caring. See you when you\'re ready.'
                              : '$_restDaysRemaining rest days left this week',
                          style: AppTypography.body
                              .copyWith(color: textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (!_isRestDay && _restDaysRemaining > 0)
                    GestureDetector(
                      onTap: () async {
                        try {
                          final result = await ApiService.takeRestDay();
                          if (mounted) {
                            setState(() {
                              _isRestDay = result['is_rest_day'] == true;
                              _restDaysRemaining =
                                  (result['rest_days_remaining'] as num?)
                                      ?.toInt() ??
                                  0;
                            });
                          }
                        } catch (_) {}
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(
                          'Rest',
                          style: AppTypography.body.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Dev: Transition style picker
            Text('SCREEN TRANSITION',
                style: AppTypography.caption.copyWith(color: textMuted)),
            const SizedBox(height: AppSpacing.sm),
            _TransitionPicker(),

            const SizedBox(height: AppSpacing.xxxl),

            // ── Sign Out ────────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: _signOut,
                child: Text(
                  'Sign out',
                  style: AppTypography.body.copyWith(
                    color: isDark ? AppColorsDark.negative : AppColors.negative,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // ── Delete Account ───────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete account'),
                      content: const Text(
                          'This will permanently delete your account and all data. This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Delete',
                              style: TextStyle(
                                  color: isDark
                                      ? AppColorsDark.negative
                                      : AppColors.negative)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    try {
                      await ApiService.deleteAccount();
                      if (mounted) {
                        await AuthService.signOut();
                        if (mounted) context.go('/');
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Could not delete account. Try again.')),
                        );
                      }
                    }
                  }
                },
                child: Text(
                  'Delete account',
                  style: AppTypography.body.copyWith(
                    color: isDark ? AppColorsDark.textFaint : AppColors.textFaint,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColorsDark.textMuted : AppColors.textMuted;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.textPrimary.withValues(alpha: 0.05);
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.70);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.label.copyWith(color: textPrimary)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.body.copyWith(color: textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppPalette.green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TransitionPicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(transitionSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.textPrimary.withValues(alpha: 0.05);
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.70);

    return Column(
      children: TransitionStyle.values.map((style) {
        final isSelected = style == current;
        return GestureDetector(
          onTap: () =>
              ref.read(transitionSettingsProvider.notifier).set(style),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(
                color: isSelected ? accent : borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? accent : borderColor,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  style.label,
                  style: AppTypography.body.copyWith(color: textPrimary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
