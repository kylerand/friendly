import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/avatar/avatar.dart';
import '../components/ui/ui.dart';
import '../constants/friend_language.dart';
import '../design/theme.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';

enum _OnboardingStep { avatar, contact, quiz }

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _OnboardingStep _step = _OnboardingStep.avatar;
  bool _saving = false;

  // Avatar state
  late AvatarConfig _avatarConfig;
  int _activeCategory = 0;

  // Contact state
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  // Quiz state
  int _quizQuestion = 0;
  final List<FriendLanguage?> _quizAnswers = List.filled(
    quizQuestions.length,
    null,
  );
  bool _showQuizResult = false;

  static const _avatarCategories = [
    ('✨', 'Style'),
    ('💇', 'Hair'),
    ('🖌️', 'Hair Color'),
    ('👀', 'Eyes'),
    ('🤨', 'Brows'),
    ('👄', 'Mouth'),
    ('🧔', 'Facial Hair'),
    ('🎨', 'Beard Color'),
    ('👓', 'Glasses'),
    ('🕶️', 'Frame Color'),
    ('👕', 'Clothes'),
    ('🧵', 'Fabric'),
    ('🖼️', 'Graphic'),
    ('🧑', 'Skin'),
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    _avatarConfig = AvatarConfig.fromMetadata(profile?.metadata);
    _phoneController = TextEditingController(text: profile?.phoneNumber ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  int get _stepIndex => _step.index;

  // ---------------------------------------------------------------------------
  // Avatar helpers
  // ---------------------------------------------------------------------------

  List<TraitOption> _optionsForCategory(int index) {
    switch (index) {
      case 0:
        return styleOptions;
      case 1:
        return topOptions;
      case 2:
        return hairColorOptions;
      case 3:
        return eyeOptions;
      case 4:
        return eyebrowOptions;
      case 5:
        return mouthOptions;
      case 6:
        return facialHairOptions;
      case 7:
        return facialHairColorOptions;
      case 8:
        return accessoriesOptions;
      case 9:
        return accessoriesColorOptions;
      case 10:
        return clothingOptions;
      case 11:
        return clothesColorOptions;
      case 12:
        return clothingGraphicOptions;
      case 13:
        return skinColorOptions;
      default:
        return [];
    }
  }

  String _selectedKeyForCategory(int index) {
    switch (index) {
      case 0:
        return _avatarConfig.style;
      case 1:
        return _avatarConfig.top;
      case 2:
        return _avatarConfig.hairColor;
      case 3:
        return _avatarConfig.eyes;
      case 4:
        return _avatarConfig.eyebrows;
      case 5:
        return _avatarConfig.mouth;
      case 6:
        return _avatarConfig.facialHair;
      case 7:
        return _avatarConfig.facialHairColor;
      case 8:
        return _avatarConfig.accessories;
      case 9:
        return _avatarConfig.accessoriesColor;
      case 10:
        return _avatarConfig.clothing;
      case 11:
        return _avatarConfig.clothesColor;
      case 12:
        return _avatarConfig.clothingGraphic;
      case 13:
        return _avatarConfig.skinColor;
      default:
        return '';
    }
  }

  void _selectAvatarOption(int categoryIndex, String key) {
    setState(() {
      switch (categoryIndex) {
        case 0:
          _avatarConfig = _avatarConfig.copyWith(style: key);
        case 1:
          _avatarConfig = _avatarConfig.copyWith(top: key);
        case 2:
          _avatarConfig = _avatarConfig.copyWith(hairColor: key);
        case 3:
          _avatarConfig = _avatarConfig.copyWith(eyes: key);
        case 4:
          _avatarConfig = _avatarConfig.copyWith(eyebrows: key);
        case 5:
          _avatarConfig = _avatarConfig.copyWith(mouth: key);
        case 6:
          _avatarConfig = _avatarConfig.copyWith(facialHair: key);
        case 7:
          _avatarConfig = _avatarConfig.copyWith(facialHairColor: key);
        case 8:
          _avatarConfig = _avatarConfig.copyWith(accessories: key);
        case 9:
          _avatarConfig = _avatarConfig.copyWith(accessoriesColor: key);
        case 10:
          _avatarConfig = _avatarConfig.copyWith(clothing: key);
        case 11:
          _avatarConfig = _avatarConfig.copyWith(clothesColor: key);
        case 12:
          _avatarConfig = _avatarConfig.copyWith(clothingGraphic: key);
        case 13:
          _avatarConfig = _avatarConfig.copyWith(skinColor: key);
      }
    });
  }

  void _randomiseAvatar() {
    final rng = Random();
    T pick<T>(List<T> list) => list[rng.nextInt(list.length)];

    setState(() {
      _avatarConfig = AvatarConfig(
        style: pick(styleOptions).key,
        top: pick(topOptions).key,
        hairColor: pick(hairColorOptions).key,
        eyes: pick(eyeOptions).key,
        eyebrows: pick(eyebrowOptions).key,
        mouth: pick(mouthOptions).key,
        facialHair: pick(facialHairOptions).key,
        facialHairColor: pick(facialHairColorOptions).key,
        accessories: pick(accessoriesOptions).key,
        accessoriesColor: pick(accessoriesColorOptions).key,
        clothing: pick(clothingOptions).key,
        clothesColor: pick(clothesColorOptions).key,
        clothingGraphic: pick(clothingGraphicOptions).key,
        skinColor: pick(skinColorOptions).key,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Step actions
  // ---------------------------------------------------------------------------

  Future<void> _saveAvatarAndContinue() async {
    setState(() => _saving = true);
    try {
      final profile = ref.read(currentProfileProvider);
      final merged = <String, dynamic>{
        ...?profile?.metadata,
        ..._avatarConfig.toMetadata(),
      };
      await ApiService.updateProfile({'metadata': merged});
      // Advance step BEFORE refreshing app state.  refresh() updates the
      // profile provider which triggers GoRouter's refreshListenable.  Because
      // onboarding_complete is not yet set, the redirect re-evaluates to
      // /onboarding and can remount this widget, resetting _step to avatar.
      // By advancing first and refreshing without awaiting, the UI progresses
      // immediately and the background refresh won't reset us.
      if (mounted) setState(() => _step = _OnboardingStep.contact);
      // Fire-and-forget: update cached profile in the background.
      ref.read(appStateProvider.notifier).refresh();
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

  Future<void> _saveContactAndContinue() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateProfile({
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
      });
      // Advance step before refresh — same reason as _saveAvatarAndContinue.
      if (mounted) setState(() => _step = _OnboardingStep.quiz);
      ref.read(appStateProvider.notifier).refresh();
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

  Future<void> _saveQuizAndFinish() async {
    final answered = _quizAnswers.whereType<FriendLanguage>().toList();
    setState(() => _saving = true);
    try {
      final profile = ref.read(currentProfileProvider);
      final merged = <String, dynamic>{
        ...?profile?.metadata,
        if (answered.isNotEmpty)
          'friend_language': tallyQuizResults(answered).name,
        'onboarding_complete': true,
      };
      await ApiService.updateProfile({'metadata': merged});
      await ref.read(appStateProvider.notifier).refresh();
      if (mounted) widget.onComplete();
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

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final surfaceSubtle =
        isDark ? AppColorsDark.surfaceSubtle : AppColors.surfaceSubtle;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),

            // Step indicator
            _buildStepIndicator(textPrimary, accent, surfaceSubtle),
            const SizedBox(height: AppSpacing.xl),

            // Step content
            Expanded(
              child: switch (_step) {
                _OnboardingStep.avatar => _buildAvatarStep(context),
                _OnboardingStep.contact => _buildContactStep(context),
                _OnboardingStep.quiz => _buildQuizStep(context),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(
    Color textPrimary,
    Color accent,
    Color surfaceSubtle,
  ) {
    const labels = ['Avatar', 'Contact', 'Quiz'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == _stepIndex;
        final isDone = i < _stepIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isActive || isDone ? accent : surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: isActive ? 2 : 1),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                labels[i],
                style: AppTypography.caption.copyWith(
                  color: isActive ? accent : textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Avatar
  // ---------------------------------------------------------------------------

  Widget _buildAvatarStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final accentSubtle =
        isDark ? AppColorsDark.accentSubtle : AppColors.accentSubtle;
    final surfaceSubtle =
        isDark ? AppColorsDark.surfaceSubtle : AppColors.surfaceSubtle;
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;

    final options = _optionsForCategory(_activeCategory);
    final selectedKey = _selectedKeyForCategory(_activeCategory);
    final isColorCategory = options.isNotEmpty && options.first.swatch != null;

    return Column(
      children: [
        Text(
          'Create your avatar',
          style: AppTypography.heading.copyWith(color: textPrimary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(child: AvatarWidget(config: _avatarConfig, size: 100)),
        const SizedBox(height: AppSpacing.sm),
        GhostButton(label: '🎲 Randomise', onPress: _randomiseAvatar),
        const SizedBox(height: AppSpacing.md),

        // Category tabs
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: _avatarCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final isActive = index == _activeCategory;
              final (emoji, label) = _avatarCategories[index];
              return GestureDetector(
                onTap: () => setState(() => _activeCategory = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? accent : surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: isActive ? accent : borderColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$emoji $label',
                    style: AppTypography.caption.copyWith(
                      color:
                          isActive
                              ? (isDark
                                  ? AppColorsDark.textInverse
                                  : AppColors.textInverse)
                              : textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Options
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children:
                    options.map((opt) {
                      final isSelected = opt.key == selectedKey;
                      if (isColorCategory) {
                        final hex = opt.swatch!.replaceFirst('#', '');
                        final color = Color(int.parse('FF$hex', radix: 16));
                        return GestureDetector(
                          onTap:
                              () =>
                                  _selectAvatarOption(_activeCategory, opt.key),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? accent : borderColor,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                          ),
                        );
                      }
                      return GestureDetector(
                        onTap:
                            () => _selectAvatarOption(_activeCategory, opt.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? accentSubtle : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadii.full),
                            border: Border.all(
                              color: isSelected ? accent : borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            opt.label,
                            style: AppTypography.label.copyWith(
                              color: isSelected ? accent : textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ),

        // Save & continue
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PrimaryButton(
            label: 'Save & continue',
            onPress: _saving ? null : _saveAvatarAndContinue,
            disabled: _saving,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Contact
  // ---------------------------------------------------------------------------

  Widget _buildContactStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final textTertiary =
        isDark ? AppColorsDark.textTertiary : AppColors.textTertiary;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;

    InputDecoration inputDeco(String hint) => InputDecoration(
      hintText: hint,
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
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        Text(
          'Contact info',
          style: AppTypography.heading.copyWith(color: textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'So your friends can reach you. Only shared with accepted friends.',
          style: AppTypography.body.copyWith(color: textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),

        Text('Email', style: AppTypography.label.copyWith(color: textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: AppTypography.body.copyWith(color: textPrimary),
          decoration: inputDeco('Email address'),
        ),
        const SizedBox(height: AppSpacing.xl),

        Text('Phone', style: AppTypography.label.copyWith(color: textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: AppTypography.body.copyWith(color: textPrimary),
          decoration: inputDeco('Phone number'),
        ),
        const SizedBox(height: AppSpacing.xxl),

        PrimaryButton(
          label: 'Save & continue',
          onPress: _saving ? null : _saveContactAndContinue,
          disabled: _saving,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Quiz
  // ---------------------------------------------------------------------------

  Widget _buildQuizStep(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final accent = isDark ? AppColorsDark.accent : AppColors.accent;
    final accentSubtle =
        isDark ? AppColorsDark.accentSubtle : AppColors.accentSubtle;
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;

    if (_showQuizResult) {
      final answered = _quizAnswers.whereType<FriendLanguage>().toList();
      final result = tallyQuizResults(answered);
      final info = getFriendLanguage(result);

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          Center(
            child: Text(info.symbol, style: const TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              'Your friendship language is',
              style: AppTypography.body.copyWith(color: textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              info.label,
              style: AppTypography.display.copyWith(color: textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            info.description,
            style: AppTypography.body.copyWith(color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            label: 'Save & enter Friendly',
            onPress: _saving ? null : _saveQuizAndFinish,
            disabled: _saving,
          ),
          const SizedBox(height: AppSpacing.md),
          GhostButton(
            label: 'Retake quiz',
            onPress:
                () => setState(() {
                  _quizQuestion = 0;
                  _quizAnswers.fillRange(0, _quizAnswers.length, null);
                  _showQuizResult = false;
                }),
          ),
        ],
      );
    }

    final question = quizQuestions[_quizQuestion];
    final selectedAnswer = _quizAnswers[_quizQuestion];
    final progress = (_quizQuestion + 1) / quizQuestions.length;

    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.full),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  isDark
                      ? AppColorsDark.surfaceSubtle
                      : AppColors.surfaceSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_quizQuestion + 1} / ${quizQuestions.length}',
              style: AppTypography.caption.copyWith(color: textSecondary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Question
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            question.question,
            style: AppTypography.subheading.copyWith(color: textPrimary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Options
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: question.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final option = question.options[index];
              final isSelected = selectedAnswer == option.language;

              return GestureDetector(
                onTap:
                    () => setState(
                      () => _quizAnswers[_quizQuestion] = option.language,
                    ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isSelected ? accentSubtle : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(
                      color: isSelected ? accent : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    option.text,
                    style: AppTypography.body.copyWith(
                      color: isSelected ? accent : textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Navigation
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              if (_quizQuestion > 0)
                Expanded(
                  child: SecondaryButton(
                    label: 'Back',
                    onPress: () => setState(() => _quizQuestion--),
                  ),
                ),
              if (_quizQuestion > 0) const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label:
                      _quizQuestion < quizQuestions.length - 1
                          ? 'Next'
                          : 'See my result',
                  onPress:
                      selectedAnswer != null
                          ? () {
                            if (_quizQuestion < quizQuestions.length - 1) {
                              setState(() => _quizQuestion++);
                            } else {
                              setState(() => _showQuizResult = true);
                            }
                          }
                          : null,
                  disabled: selectedAnswer == null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
