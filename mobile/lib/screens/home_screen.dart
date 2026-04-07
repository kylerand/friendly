import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../components/nudge/suggestion_card.dart';
import '../components/nudge/warmth_badge.dart';
import '../components/nudge/welcome_back_banner.dart';
import '../components/nudge/milestone_toast.dart';
import '../components/ui/ui.dart';
import '../constants/copy.dart';
import '../design/theme.dart';
import '../models/friend.dart';
import '../models/friendship.dart';
import '../services/api_service.dart';
import '../services/warmth_service.dart';
import '../services/widget_service.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';

enum _FriendFilter { all, close, recent }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _FriendFilter _filter = _FriendFilter.all;
  bool _showWelcomeBack = false;
  MilestoneData? _pendingMilestone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkNudgeState());
  }

  Future<void> _checkNudgeState() async {
    try {
      // Check for new milestones
      final result = await ApiService.checkMilestones();
      final newMilestones = result['new_milestones'] as List<dynamic>? ?? [];
      if (newMilestones.isNotEmpty && mounted) {
        final first = newMilestones[0] as Map<String, dynamic>;
        setState(() {
          _pendingMilestone = MilestoneData(
            key: first['milestone_key'] as String? ?? '',
            emoji: first['emoji'] as String? ?? '✨',
            copy: first['copy'] as String? ?? '',
          );
        });
      }

      // Refresh warmth snapshot for widgets
      await ApiService.saveWarmthSnapshot();
      await WidgetService.refresh();
    } catch (_) {
      // Non-critical — silently fail
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(appStateProvider.notifier).refresh();
    // Also refresh widget data in background
    WidgetService.refresh();
  }

  List<Friend> _applyFilter(List<Friend> friends) {
    switch (_filter) {
      case _FriendFilter.all:
        return friends;
      case _FriendFilter.close:
        return friends.where((f) => f.heartHealth >= 70).toList();
      case _FriendFilter.recent:
        final sorted = List<Friend>.from(friends)..sort((a, b) {
          final aTime = a.lastInteraction ?? DateTime(2000);
          final bTime = b.lastInteraction ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });
        return sorted;
    }
  }

  Friend? _getSuggestion(List<Friend> friends) {
    if (friends.isEmpty) return null;
    return friends.reduce((a, b) => a.heartHealth <= b.heartHealth ? a : b);
  }

  Widget _buildErrorState(BuildContext context, bool isDark) {
    final textMuted = isDark ? AppColorsDark.textMuted : AppColors.textMuted;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: accent,
      child: ListView(
        padding: const EdgeInsets.only(top: 56),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😕', style: TextStyle(fontSize: 40)),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Something went wrong',
                  style: AppTypography.label.copyWith(
                    color: isDark ? AppColorsDark.textPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pull down to refresh and try again.',
                  style: AppTypography.body.copyWith(color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = ref.watch(appStateProvider);

    final friends = appData.friends;
    final pendingInvites = appData.pendingInvites;
    final inviteNames = appData.inviteNames;
    final isLoading = appData.loading;
    final error = appData.error;

    final filteredFriends = _applyFilter(friends);
    final suggestion = _getSuggestion(friends);

    // Compute warmth tier from interaction dates
    final interactionDates = friends
        .where((f) => f.lastInteraction != null)
        .map((f) => f.lastInteraction!)
        .toList();
    final weekStreak = WarmthService.computeWeekStreak(interactionDates);
    final warmthTier = WarmthService.computeTier(weekStreak);

    // Compute suggestion details for the SuggestionCard
    int daysSinceSuggestion = 0;
    if (suggestion != null && suggestion.lastInteraction != null) {
      daysSinceSuggestion =
          DateTime.now().difference(suggestion.lastInteraction!).inDays;
    } else if (suggestion != null) {
      daysSinceSuggestion = 999;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? AppColorsDark.background : AppColors.background,
          body: SafeArea(
            child:
                isLoading && friends.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : error != null && friends.isEmpty
                        ? _buildErrorState(context, isDark)
                        : RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: accent,
                      child: ListView(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.xl,
                          right: AppSpacing.xl,
                          top: 56,
                          bottom: AppSpacing.lg,
                        ),
                        children: [
                          // Warmth badge
                          Center(child: WarmthBadge(tier: warmthTier)),
                          const SizedBox(height: AppSpacing.md),

                          // "Your friendships" subtitle
                          Text(
                            Copy.homeGreeting,
                            style: AppTypography.body.copyWith(
                              color: isDark ? AppColorsDark.textTertiary : AppColors.textTertiary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Welcome-back banner
                          if (_showWelcomeBack) ...[
                            WelcomeBackBanner(
                              onDismiss: () =>
                                  setState(() => _showWelcomeBack = false),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          // Status / suggestion card
                          if (friends.isNotEmpty) ...[
                            SuggestionCard(
                              friendName: (suggestion != null &&
                                      suggestion.heartHealth < 50)
                                  ? suggestion.displayName
                                  : null,
                              friendId: (suggestion != null &&
                                      suggestion.heartHealth < 50)
                                  ? suggestion.friendId
                                  : null,
                              daysSinceContact: daysSinceSuggestion,
                              warmthTier: warmthTier,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          // Filter pills
                          _buildFilterPills(context),
                          const SizedBox(height: AppSpacing.md),

                          // Friend list or empty state
                          if (filteredFriends.isEmpty && !isLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                              child: EmptyState(
                                emoji: '👋',
                                title: Copy.homeEmpty,
                                action: PrimaryButton(
                                  label: Copy.addFriendTitle,
                                  onPress: () => context.push('/add-friend'),
                                ),
                              ),
                            )
                          else if (filteredFriends.isEmpty && isLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: AppSpacing.xxxl),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            _buildFriendList(context, filteredFriends),

                          // Pending requests
                          if (pendingInvites.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xl),
                            _buildPendingSection(
                              context,
                              pendingInvites,
                              inviteNames,
                            ),
                          ],

                          // Bottom padding for nav bar
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
          ),
        ),
        // Milestone celebration overlay
        if (_pendingMilestone != null)
          MilestoneToast(
            milestone: _pendingMilestone!,
            onDismiss: () => setState(() => _pendingMilestone = null),
          ),
      ],
    );
  }

  Widget _buildFilterPills(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final textInverse =
        isDark ? AppColorsDark.textInverse : AppColors.textInverse;
    final textMuted = isDark ? AppColorsDark.textMuted : AppColors.textMuted;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.textPrimary.withValues(alpha: 0.08);

    const labels = [
      Copy.homeFilterAll,
      Copy.homeFilterClose,
      Copy.homeFilterRecent,
    ];
    final filters = _FriendFilter.values;

    return Row(
      children: List.generate(filters.length, (i) {
        final isActive = _filter == filters[i];
        return Padding(
          padding: EdgeInsets.only(right: i < filters.length - 1 ? 8 : 0),
          child: GestureDetector(
            onTap: () => setState(() => _filter = filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isActive ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: isActive
                    ? null
                    : Border.all(color: borderColor, width: 1),
                boxShadow: isActive
                    ? AppShadows.accentGlow(accent)
                    : null,
              ),
              child: Text(
                labels[i],
                style: AppTypography.label.copyWith(
                  fontSize: 12,
                  color: isActive ? textInverse : textMuted,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFriendList(BuildContext context, List<Friend> friends) {
    return Column(
      children: friends.map((friend) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: FriendCard(
            name: friend.displayName,
            heartHealth: friend.heartHealth,
            metadata: friend.metadata,
            lastInteraction: friend.lastInteraction,
            onTap: () => context.push('/profile/${friend.friendId}'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPendingSection(
    BuildContext context,
    List<Friendship> pending,
    Map<String, String> names,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final currentUserId = ref.read(currentUserIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Copy.invitesTitle,
          style: AppTypography.subheading.copyWith(color: textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...pending.map((invite) {
          final senderId =
              invite.userId == currentUserId ? invite.friendId : invite.userId;
          final senderName = names[senderId] ?? senderId;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              onTap: () => context.push('/invites'),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsBold.envelopeSimple,
                    color: isDark ? AppColorsDark.accent : AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Friend request from $senderName',
                      style: AppTypography.label.copyWith(color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    PhosphorIconsBold.caretRight,
                    color:
                        isDark
                            ? AppColorsDark.iconSubtle
                            : AppColors.iconSubtle,
                    size: 16,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
