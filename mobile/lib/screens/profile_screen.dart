import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/avatar/avatar.dart';
import '../components/ui/ui.dart';
import '../constants/copy.dart';
import '../design/theme.dart';
import '../models/friend.dart';
import '../models/profile.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String friendId;

  const ProfileScreen({super.key, required this.friendId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Profile? _friendProfile;
  AvatarConfig? _avatarConfig;
  bool _profileLoaded = false;

  // Notes
  String _noteContent = ''; // ignore: unused_field — set by _handleNoteChange
  bool _noteSaving = false;
  Timer? _noteSaveTimer;
  final _noteController = TextEditingController();

  // Care signal
  bool _careSent = false;
  bool _careSending = false;

  // Reminder
  String _reminderText = '';
  int _reminderDays = 3;
  bool _hasReminder = false;
  bool _reminderSaving = false;
  final _reminderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriendProfile();
    _loadNote();
    _loadReminder();
  }

  @override
  void dispose() {
    _noteSaveTimer?.cancel();
    _noteController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  Friend? get _friend {
    final friends = ref.read(friendsProvider);
    try {
      return friends.firstWhere((f) => f.friendId == widget.friendId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFriendProfile() async {
    try {
      final profileJson = await ApiService.getProfileById(widget.friendId);
      if (profileJson.isNotEmpty) {
        final profile = Profile.fromJson(profileJson);
        setState(() {
          _friendProfile = profile;
          _avatarConfig = AvatarConfig.fromMetadata(profile.metadata);
          _profileLoaded = true;
        });
      } else {
        setState(() => _profileLoaded = true);
      }
    } catch (_) {
      setState(() => _profileLoaded = true);
    }
  }

  void _handleNoteChange(String text) {
    setState(() => _noteContent = text);
    _noteSaveTimer?.cancel();
    _noteSaveTimer = Timer(const Duration(milliseconds: 800), () async {
      final friend = _friend;
      if (friend == null) return;
      setState(() => _noteSaving = true);
      try {
        await ApiService.saveFriendNote(friend.friendId, text);
      } catch (_) {}
      finally {
        if (mounted) setState(() => _noteSaving = false);
      }
    });
  }

  Future<void> _handleCall() async {
    final friend = _friend;
    if (friend == null) return;
    final phone = _friendProfile?.phoneNumber ?? friend.phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      await launchUrl(Uri.parse('tel:$phone'));
    }
    try {
      await ApiService.createInteraction(friend.friendId, type: 'call');
      await ref.read(appStateProvider.notifier).refresh();
    } catch (_) {}
  }

  Future<void> _handleText() async {
    final friend = _friend;
    if (friend == null) return;
    final phone = _friendProfile?.phoneNumber ?? friend.phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      await launchUrl(Uri.parse('sms:$phone'));
    }
    try {
      await ApiService.createInteraction(friend.friendId, type: 'text');
      await ref.read(appStateProvider.notifier).refresh();
    } catch (_) {}
  }

  Future<void> _handleEmail() async {
    final friend = _friend;
    if (friend == null) return;
    final email = _friendProfile?.email ?? friend.email;
    if (email != null && email.isNotEmpty) {
      await launchUrl(Uri.parse('mailto:$email'));
    }
    try {
      await ApiService.createInteraction(friend.friendId, type: 'email');
      await ref.read(appStateProvider.notifier).refresh();
    } catch (_) {}
  }

  Future<void> _handleCareSignal() async {
    if (_careSent || _careSending) return;
    setState(() => _careSending = true);
    try {
      await ApiService.sendCareSignal(widget.friendId);
      if (mounted) setState(() => _careSent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t send that. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _careSending = false);
    }
  }

  Future<void> _loadNote() async {
    try {
      final json = await ApiService.getFriendNote(widget.friendId);
      final content = json['content'] as String? ?? '';
      if (mounted) {
        setState(() => _noteContent = content);
        _noteController.text = content;
      }
    } catch (_) {}
  }

  Future<void> _loadReminder() async {
    final r = await NotificationService.getReminder(widget.friendId);
    if (r != null && mounted) {
      setState(() {
        _reminderText = r.text;
        _reminderDays = r.intervalDays;
        _hasReminder = true;
        _reminderController.text = r.text;
      });
    }
  }

  Future<void> _saveReminder() async {
    if (_reminderText.trim().isEmpty || _reminderSaving) return;
    final friend = _friend;
    final name =
        _friendProfile?.displayName ?? friend?.displayName ?? 'Friend';
    setState(() => _reminderSaving = true);
    try {
      await NotificationService.setReminder(
        friendId: widget.friendId,
        friendName: name,
        text: _reminderText.trim(),
        intervalDays: _reminderDays,
      );
      if (mounted) {
        setState(() {
          _hasReminder = true;
          _reminderSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Reminder set — you\'ll be notified every $_reminderDays day${_reminderDays == 1 ? '' : 's'}'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _reminderSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t save reminder. Try again.')),
        );
      }
    }
  }

  Future<void> _clearReminder() async {
    await NotificationService.clearReminder(widget.friendId);
    if (mounted) {
      setState(() {
        _hasReminder = false;
        _reminderText = '';
        _reminderController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final friend = _friend;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final textMuted = isDark ? AppColorsDark.textMuted : AppColors.textMuted;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final pink = isDark ? const Color(0xFFFF8AD6) : AppPalette.pink;
    final warmSurface =
        isDark ? AppColorsDark.warmSurface : AppColors.warmSurface;
    final warm = isDark ? AppColorsDark.warm : AppColors.warm;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.textPrimary.withValues(alpha: 0.05);
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.70);

    final displayName =
        _friendProfile?.displayName ?? friend?.displayName ?? 'Someone';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final heartHealth = friend?.heartHealth ?? 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: friend == null
            ? Center(
                child: _profileLoaded
                    ? Text('Friend not found',
                        style: AppTypography.body.copyWith(color: textSecondary))
                    : const CircularProgressIndicator(),
              )
            : Column(
                children: [
                  // Header with back button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chevron_left,
                                color: accent,
                                size: 22,
                              ),
                              Text(
                                'Back',
                                style: AppTypography.label.copyWith(
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      children: [
                        const SizedBox(height: 56),
                        // 1. Large avatar
                        Center(
                          child: AvatarWidget(
                            config: _avatarConfig,
                            size: 100,
                            fallbackInitial: initial,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 2. Display name
                        Center(
                          child: Text(
                            displayName,
                            style: AppTypography.heading.copyWith(
                              color: textPrimary,
                              fontSize: 24,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // 3. Heart health row
                        Center(
                          child: HeartHealthBar(health: heartHealth),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Circle label + check-in text
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                heartHealth >= 60 ? 'CLOSE' : 'RECENT',
                                style: AppTypography.caption.copyWith(
                                  color: textMuted,
                                  fontSize: 10,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text('·', style: TextStyle(color: textMuted, fontWeight: FontWeight.w900, fontSize: 10)),
                              ),
                              Text(
                                _lastSeenText(friend),
                                style: AppTypography.caption.copyWith(
                                  color: textMuted,
                                  fontSize: 10,
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 4. Beacon banner
                        if (friend.metadata?['beacon_active'] == true) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: warmSurface,
                              borderRadius: BorderRadius.circular(AppRadii.xl),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                const Text('🕯️', style: TextStyle(fontSize: 24)),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$displayName could use some warmth',
                                        style: AppTypography.label.copyWith(color: warm),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        'Reach out however feels right.',
                                        style: AppTypography.body.copyWith(color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xl),

                        // 5. Notes section
                        Text(
                          'NOTES',
                          style: AppTypography.caption.copyWith(
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(AppRadii.xl),
                            border: Border.all(color: borderColor),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                onChanged: _handleNoteChange,
                                controller: _noteController,
                                maxLines: null,
                                minLines: 3,
                                style: AppTypography.body.copyWith(color: textPrimary),
                                decoration: InputDecoration.collapsed(
                                  hintText: 'Coffee order, reminders, things to ask about…',
                                  hintStyle: AppTypography.body.copyWith(color: textMuted),
                                ),
                              ),
                              if (_noteSaving)
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                                  child: Text(
                                    'saving…',
                                    style: AppTypography.caption.copyWith(
                                      color: textMuted,
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Only you can see this. Your friend won\'t know.',
                          style: AppTypography.body.copyWith(
                            color: textMuted,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // 6. Remind me about
                        Text(
                          'REMIND ME ABOUT',
                          style: AppTypography.caption.copyWith(
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(AppRadii.xl),
                            border: Border.all(color: borderColor),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: TextField(
                            controller: _reminderController,
                            onChanged: (t) => setState(() => _reminderText = t),
                            maxLines: null,
                            minLines: 2,
                            style: AppTypography.body.copyWith(color: textPrimary),
                            decoration: InputDecoration.collapsed(
                              hintText: 'Add a reminder note...',
                              hintStyle: AppTypography.body.copyWith(color: textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Frequency selector
                        Row(
                          children: [
                            Text('Every',
                                style: AppTypography.label.copyWith(
                                  color: textMuted,
                                  fontSize: 12,
                                )),
                            const SizedBox(width: AppSpacing.sm),
                            _FrequencyChip(
                              label: '1 day',
                              selected: _reminderDays == 1,
                              onTap: () => setState(() => _reminderDays = 1),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _FrequencyChip(
                              label: '3 days',
                              selected: _reminderDays == 3,
                              onTap: () => setState(() => _reminderDays = 3),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _FrequencyChip(
                              label: '7 days',
                              selected: _reminderDays == 7,
                              onTap: () => setState(() => _reminderDays = 7),
                            ),
                            if (_hasReminder) ...[
                              const Spacer(),
                              GestureDetector(
                                onTap: _clearReminder,
                                child: Icon(
                                  PhosphorIconsBold.trash,
                                  size: 16,
                                  color: isDark ? AppColorsDark.negative : AppColors.negative,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GestureDetector(
                          onTap: _reminderText.trim().isEmpty || _reminderSaving
                              ? null
                              : _saveReminder,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: _reminderText.trim().isEmpty
                                  ? pink.withValues(alpha: 0.4)
                                  : pink,
                              borderRadius: BorderRadius.circular(AppRadii.full),
                              boxShadow: _reminderText.trim().isNotEmpty
                                  ? AppShadows.accentGlow(pink)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _reminderSaving
                                  ? 'Saving…'
                                  : _hasReminder
                                      ? 'Update reminder'
                                      : 'Set reminder',
                              style: AppTypography.label.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        if (_hasReminder) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'You\'ll get a notification every $_reminderDays day${_reminderDays == 1 ? '' : 's'}.',
                            style: AppTypography.body.copyWith(
                              color: textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xl),

                        // 7. Contact action buttons: Call | Text | Email
                        Row(
                          children: [
                            Expanded(
                              child: _HandoffButton(
                                icon: PhosphorIconsBold.phone,
                                label: Copy.profileCall,
                                onTap: _handleCall,
                                color: accent,
                                textColor: textMuted,
                                borderColor: borderColor,
                                cardBg: cardBg,
                                enabled: (_friendProfile?.phoneNumber ?? friend.phoneNumber)?.isNotEmpty == true,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Expanded(
                              child: _HandoffButton(
                                icon: PhosphorIconsBold.chatCircle,
                                label: Copy.profileText,
                                onTap: _handleText,
                                color: accent,
                                textColor: textMuted,
                                borderColor: borderColor,
                                cardBg: cardBg,
                                enabled: (_friendProfile?.phoneNumber ?? friend.phoneNumber)?.isNotEmpty == true,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Expanded(
                              child: _HandoffButton(
                                icon: PhosphorIconsBold.envelopeSimple,
                                label: Copy.profileEmail,
                                onTap: _handleEmail,
                                color: accent,
                                textColor: textMuted,
                                borderColor: borderColor,
                                cardBg: cardBg,
                                enabled: (_friendProfile?.email ?? friend.email)?.isNotEmpty == true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // 8. "Thinking of you" care signal
                        GestureDetector(
                          onTap: (_careSent || _careSending) ? null : _handleCareSignal,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadii.full),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.20),
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(PhosphorIconsBold.heart, size: 16, color: accent),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  _careSent ? '${Copy.thinkingOfYou} ✓' : Copy.thinkingOfYou,
                                  style: AppTypography.label.copyWith(color: accent),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 9. Check in button
                        GestureDetector(
                          onTap: () => context.push(
                            '/check-in/${friend.friendshipId}?name=$displayName',
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg - 2),
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(AppRadii.full),
                              boxShadow: AppShadows.accentGlow(accent),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              Copy.checkInTitle,
                              style: AppTypography.label.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _lastSeenText(Friend friend) {
    if (friend.lastInteraction == null) return 'No check-ins yet';
    final diff = DateTime.now().difference(friend.lastInteraction!);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 30}mo ago';
  }
}

/// Small tappable card for hand-off actions (Call, Text, Email).
class _HandoffButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final Color cardBg;
  final bool enabled;

  const _HandoffButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.textColor,
    required this.borderColor,
    required this.cardBg,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.body.copyWith(
                  color: textColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FrequencyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.textPrimary.withValues(alpha: 0.10);
    final textColor =
        isDark ? AppColorsDark.textMuted : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.full),
          border: Border.all(
            color: selected ? accent : borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: selected ? accent : textColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
