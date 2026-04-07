import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../components/ui/ui.dart';
import '../constants/copy.dart';
import '../design/theme.dart';
import '../models/profile.dart';
import '../services/api_service.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  String _query = '';
  List<Profile> _results = [];
  bool _searching = false;
  final Set<String> _sentIds = {};
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search());
  }

  Future<void> _search() async {
    if (_query.trim().isEmpty) return;
    setState(() => _searching = true);
    try {
      final data = await ApiService.searchProfiles(_query.trim());
      final profiles = data
          .map((e) => Profile.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _results = profiles);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search failed. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _addFriend(Profile profile) async {
    try {
      await ApiService.createFriendship(profile.id);
      if (mounted) {
        setState(() => _sentIds.add(profile.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invite sent to ${profile.displayName ?? profile.email ?? 'friend'}'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send invite. Try again.')),
        );
      }
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          Copy.addFriendTitle,
          style: AppTypography.heading.copyWith(color: textPrimary),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.lg),

              // Search field
              TextField(
                onChanged: _onSearchChanged,
                style: AppTypography.body.copyWith(color: textPrimary),
                decoration: InputDecoration(
                  hintText: Copy.addFriendSearch,
                  hintStyle: AppTypography.body.copyWith(color: textTertiary),
                  prefixIcon: Icon(PhosphorIconsBold.magnifyingGlass,
                      color: textTertiary, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    borderSide: BorderSide(color: accent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Results
              Expanded(
                child: _searching
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty && _query.isNotEmpty
                        ? EmptyState(
                            emoji: '🔍',
                            title: 'No results',
                            subtitle: 'Try a different name or email.',
                          )
                        : _results.isEmpty
                            ? EmptyState(
                                emoji: '👋',
                                title: Copy.addFriendTitle,
                                subtitle: 'Search by name or email to find friends.',
                              )
                            : ListView.separated(
                                itemCount: _results.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final profile = _results[index];
                                  final sent = _sentIds.contains(profile.id);
                                  final initial =
                                      (profile.displayName ?? profile.email ?? '?')
                                          .isNotEmpty
                                      ? (profile.displayName ??
                                              profile.email ??
                                              '?')[0]
                                          .toUpperCase()
                                      : '?';

                                  return AppCard(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: accentSubtle,
                                          child: Text(
                                            initial,
                                            style: AppTypography.label
                                                .copyWith(color: accent),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (profile.displayName !=
                                                  null)
                                                Text(
                                                  profile.displayName!,
                                                  style: AppTypography.label
                                                      .copyWith(
                                                          color: textPrimary),
                                                ),
                                              if (profile.email != null)
                                                Text(
                                                  profile.email!,
                                                  style: AppTypography.caption
                                                      .copyWith(
                                                          color:
                                                              textSecondary),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (sent)
                                          Icon(PhosphorIconsBold.checkCircle,
                                              color: accent, size: 24)
                                        else
                                          GhostButton(
                                            label: 'Add',
                                            onPress: () =>
                                                _addFriend(profile),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
