import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../components/ui/ui.dart';
import '../constants/copy.dart';
import '../design/theme.dart';
import '../models/friendship.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';

class InvitesScreen extends ConsumerWidget {
  const InvitesScreen({super.key});

  Future<void> _accept(BuildContext context, WidgetRef ref, Friendship invite) async {
    try {
      await ApiService.updateFriendship(invite.id, 'confirmed');
      await ref.read(appStateProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted!')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    }
  }

  Future<void> _decline(BuildContext context, WidgetRef ref, Friendship invite) async {
    try {
      await ApiService.updateFriendship(invite.id, 'archived');
      await ref.read(appStateProvider.notifier).refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation declined.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = ref.watch(pendingInvitesProvider);
    final inviteNames = ref.watch(inviteNamesProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final accentSubtle =
        isDark ? AppColorsDark.accentSubtle : AppColors.accentSubtle;
    final negative = isDark ? AppColorsDark.negative : AppColors.negative;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: invites.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 120),
                child: EmptyState(
                  emoji: '📭',
                  title: Copy.invitesEmpty,
                  subtitle: 'When someone adds you, their invite will appear here.',
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxxl + 20,
                ),
                itemCount: invites.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final invite = invites[index];

                  final senderId = invite.userId == currentUserId
                      ? invite.friendId
                      : invite.userId;
                  final senderName = inviteNames[senderId] ?? senderId;

                  return AppCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: accentSubtle,
                          child: Icon(PhosphorIconsBold.userPlus,
                              color: accent, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Friend request',
                                style: AppTypography.label
                                    .copyWith(color: textPrimary),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'From $senderName',
                                style: AppTypography.body
                                    .copyWith(color: textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          onPressed: () => _decline(context, ref, invite),
                          icon: Icon(PhosphorIconsBold.x,
                              color: negative, size: 20),
                          tooltip: 'Decline',
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          onPressed: () => _accept(context, ref, invite),
                          icon: Icon(PhosphorIconsBold.check,
                              color: accent, size: 20),
                          tooltip: 'Accept',
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
