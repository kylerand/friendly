import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/avatar/avatar.dart';
import '../components/ui/ui.dart';
import '../design/theme.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';

class AvatarEditorScreen extends ConsumerStatefulWidget {
  const AvatarEditorScreen({super.key});

  @override
  ConsumerState<AvatarEditorScreen> createState() =>
      _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends ConsumerState<AvatarEditorScreen> {
  late AvatarConfig _config;
  int _activeCategory = 0;
  bool _saving = false;

  // Category definitions: (emoji, label, inputType)
  // inputType: 'color' = color swatches, 'toggle' = segmented,
  //            'pill' = pill buttons, 'expression' = large icon grid
  static const _categories = [
    ('✨', 'Style', 'toggle'),
    ('💇', 'Hair', 'pill'),
    ('🖌️', 'Hair Color', 'color'),
    ('👀', 'Eyes', 'expression'),
    ('🤨', 'Brows', 'expression'),
    ('👄', 'Mouth', 'expression'),
    ('🧔', 'Facial Hair', 'pill'),
    ('🎨', 'Beard Color', 'color'),
    ('👓', 'Glasses', 'pill'),
    ('🕶️', 'Frame Color', 'color'),
    ('👕', 'Clothes', 'pill'),
    ('🧵', 'Fabric', 'color'),
    ('🖼️', 'Graphic', 'pill'),
    ('🧑', 'Skin', 'color'),
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    // Always show SVG in editor preview, even for uncustomised avatars
    _config = AvatarConfig.fromMetadata(profile?.metadata)
        .copyWith(hasCustomConfig: true);
  }

  List<TraitOption> _optionsForCategory(int index) {
    switch (index) {
      case 0: return styleOptions;
      case 1: return topOptions;
      case 2: return hairColorOptions;
      case 3: return eyeOptions;
      case 4: return eyebrowOptions;
      case 5: return mouthOptions;
      case 6: return facialHairOptions;
      case 7: return facialHairColorOptions;
      case 8: return accessoriesOptions;
      case 9: return accessoriesColorOptions;
      case 10: return clothingOptions;
      case 11: return clothesColorOptions;
      case 12: return clothingGraphicOptions;
      case 13: return skinColorOptions;
      default: return [];
    }
  }

  String _selectedKeyForCategory(int index) {
    switch (index) {
      case 0: return _config.style;
      case 1: return _config.top;
      case 2: return _config.hairColor;
      case 3: return _config.eyes;
      case 4: return _config.eyebrows;
      case 5: return _config.mouth;
      case 6: return _config.facialHair;
      case 7: return _config.facialHairColor;
      case 8: return _config.accessories;
      case 9: return _config.accessoriesColor;
      case 10: return _config.clothing;
      case 11: return _config.clothesColor;
      case 12: return _config.clothingGraphic;
      case 13: return _config.skinColor;
      default: return '';
    }
  }

  void _selectOption(int categoryIndex, String key) {
    setState(() {
      switch (categoryIndex) {
        case 0: _config = _config.copyWith(style: key);
        case 1: _config = _config.copyWith(top: key);
        case 2: _config = _config.copyWith(hairColor: key);
        case 3: _config = _config.copyWith(eyes: key);
        case 4: _config = _config.copyWith(eyebrows: key);
        case 5: _config = _config.copyWith(mouth: key);
        case 6: _config = _config.copyWith(facialHair: key);
        case 7: _config = _config.copyWith(facialHairColor: key);
        case 8: _config = _config.copyWith(accessories: key);
        case 9: _config = _config.copyWith(accessoriesColor: key);
        case 10: _config = _config.copyWith(clothing: key);
        case 11: _config = _config.copyWith(clothesColor: key);
        case 12: _config = _config.copyWith(clothingGraphic: key);
        case 13: _config = _config.copyWith(skinColor: key);
      }
    });
  }

  void _randomise() {
    final rng = Random();
    T pick<T>(List<T> list) => list[rng.nextInt(list.length)];

    setState(() {
      _config = AvatarConfig(
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final profile = ref.read(currentProfileProvider);
      final merged = <String, dynamic>{
        ...?profile?.metadata,
        ..._config.toMetadata(),
      };
      await ApiService.updateProfile({'metadata': merged});
      await ref.read(appStateProvider.notifier).refresh();
      if (mounted) context.pop();
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

  @override
  Widget build(BuildContext context) {
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
    final (_, _, inputType) = _categories[_activeCategory];

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
          'Edit avatar',
          style: AppTypography.heading.copyWith(color: textPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),

            // Avatar preview — larger
            Center(
              child: AvatarWidget(config: _config, size: 180),
            ),
            const SizedBox(height: AppSpacing.md),

            // Randomise
            GhostButton(label: '🎲 Randomise', onPress: _randomise),
            const SizedBox(height: AppSpacing.md),

            // Category tabs
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _categories.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final isActive = index == _activeCategory;
                  final (emoji, label, _) = _categories[index];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _activeCategory = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? accent : surfaceSubtle,
                        borderRadius:
                            BorderRadius.circular(AppRadii.full),
                        border: Border.all(
                          color: isActive ? accent : borderColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$emoji $label',
                        style: AppTypography.caption.copyWith(
                          color: isActive
                              ? (isDark
                                  ? AppColorsDark.textInverse
                                  : AppColors.textInverse)
                              : textSecondary,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Options — type varies by category
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SingleChildScrollView(
                  child: _buildOptionsForType(
                    inputType, options, selectedKey,
                    accent, accentSubtle, surfaceSubtle,
                    textPrimary, textSecondary, borderColor, isDark,
                  ),
                ),
              ),
            ),

            // Save button — extra padding so it clears the floating bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 80,
              ),
              child: PrimaryButton(
                label: 'Save avatar',
                onPress: _saving ? null : _save,
                disabled: _saving,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsForType(
    String inputType,
    List<TraitOption> options,
    String selectedKey,
    Color accent,
    Color accentSubtle,
    Color surfaceSubtle,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
    bool isDark,
  ) {
    switch (inputType) {
      case 'color':
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: options.map((opt) {
            return _buildColorSwatch(opt, opt.key == selectedKey, accent, borderColor);
          }).toList(),
        );

      case 'toggle':
        // Segmented control for binary choices (Style)
        return Row(
          children: options.map((opt) {
            final isSelected = opt.key == selectedKey;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _selectOption(_activeCategory, opt.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? accent : surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: isSelected ? accent : borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      opt.label,
                      style: AppTypography.label.copyWith(
                        color: isSelected
                            ? (isDark ? AppColorsDark.textInverse : AppColors.textInverse)
                            : textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );

      case 'expression':
        // Larger grid cells for eyes, mouth, brows — easier to tap
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: options.map((opt) {
            final isSelected = opt.key == selectedKey;
            return GestureDetector(
              onTap: () => _selectOption(_activeCategory, opt.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 90,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? accentSubtle : surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: isSelected ? accent : borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt.label,
                  textAlign: TextAlign.center,
                  style: AppTypography.label.copyWith(
                    color: isSelected ? accent : textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        );

      default: // 'pill'
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: options.map((opt) {
            return _buildPillButton(
              opt, opt.key == selectedKey, accent, accentSubtle,
              textPrimary, textSecondary, borderColor);
          }).toList(),
        );
    }
  }

  Widget _buildColorSwatch(
    TraitOption opt,
    bool isSelected,
    Color accent,
    Color borderColor,
  ) {
    final hex = opt.swatch!.replaceFirst('#', '');
    final color = Color(int.parse('FF$hex', radix: 16));

    return GestureDetector(
      onTap: () => _selectOption(_activeCategory, opt.key),
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

  Widget _buildPillButton(
    TraitOption opt,
    bool isSelected,
    Color accent,
    Color accentSubtle,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    return GestureDetector(
      onTap: () => _selectOption(_activeCategory, opt.key),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? accentSubtle : Colors.transparent,
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
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
