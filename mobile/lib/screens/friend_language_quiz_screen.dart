import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/ui/ui.dart';
import '../constants/friend_language.dart';
import '../design/theme.dart';
import '../services/api_service.dart';
import '../state/app_state.dart';

class FriendLanguageQuizScreen extends ConsumerStatefulWidget {
  const FriendLanguageQuizScreen({super.key});

  @override
  ConsumerState<FriendLanguageQuizScreen> createState() =>
      _FriendLanguageQuizScreenState();
}

class _FriendLanguageQuizScreenState
    extends ConsumerState<FriendLanguageQuizScreen> {
  int _currentQuestion = 0;
  final List<FriendLanguage?> _answers =
      List.filled(quizQuestions.length, null);
  bool _showResult = false;
  bool _saving = false;

  void _selectAnswer(FriendLanguage language) {
    setState(() => _answers[_currentQuestion] = language);
  }

  void _next() {
    if (_currentQuestion < quizQuestions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      setState(() => _showResult = true);
    }
  }

  void _back() {
    if (_currentQuestion > 0) {
      setState(() => _currentQuestion--);
    }
  }

  void _retake() {
    setState(() {
      _currentQuestion = 0;
      _answers.fillRange(0, _answers.length, null);
      _showResult = false;
    });
  }

  Future<void> _saveResult() async {
    final answered = _answers.whereType<FriendLanguage>().toList();
    if (answered.isEmpty) return;

    final result = tallyQuizResults(answered);
    setState(() => _saving = true);
    try {
      final profile = ref.read(currentProfileProvider);
      final merged = <String, dynamic>{
        ...?profile?.metadata,
        'friend_language': result.name,
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
    final borderColor =
        isDark ? AppColorsDark.borderSubtle : AppColors.borderSubtle;

    if (_showResult) {
      return _buildResultScreen(
        context, textPrimary, textSecondary, accent, accentSubtle);
    }

    final question = quizQuestions[_currentQuestion];
    final selectedAnswer = _answers[_currentQuestion];
    final progress = (_currentQuestion + 1) / quizQuestions.length;

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
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.full),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark
                      ? AppColorsDark.surfaceSubtle
                      : AppColors.surfaceSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_currentQuestion + 1} / ${quizQuestions.length}',
                  style:
                      AppTypography.caption.copyWith(color: textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Question
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                question.question,
                style:
                    AppTypography.subheading.copyWith(color: textPrimary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Options
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: question.options.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final option = question.options[index];
                  final isSelected =
                      selectedAnswer == option.language;

                  return GestureDetector(
                    onTap: () => _selectAnswer(option.language),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? accentSubtle : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppRadii.lg),
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

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (_currentQuestion > 0)
                    Expanded(
                      child: SecondaryButton(
                        label: 'Back',
                        onPress: _back,
                      ),
                    ),
                  if (_currentQuestion > 0)
                    const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: _currentQuestion < quizQuestions.length - 1
                          ? 'Next'
                          : 'See my result',
                      onPress:
                          selectedAnswer != null ? _next : null,
                      disabled: selectedAnswer == null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    Color accent,
    Color accentSubtle,
  ) {
    final answered = _answers.whereType<FriendLanguage>().toList();
    final result = tallyQuizResults(answered);
    final info = getFriendLanguage(result);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxl,
          ),
          children: [
            Center(
              child: Text(info.symbol,
                  style: const TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'Your friendship language is',
                style:
                    AppTypography.body.copyWith(color: textSecondary),
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
            const SizedBox(height: AppSpacing.xl),

            // Examples
            ...info.examples.map((example) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ',
                          style: AppTypography.body
                              .copyWith(color: accent)),
                      Expanded(
                        child: Text(
                          example,
                          style: AppTypography.body
                              .copyWith(color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: AppSpacing.xxl),

            PrimaryButton(
              label: 'Save & finish',
              onPress: _saving ? null : _saveResult,
              disabled: _saving,
            ),
            const SizedBox(height: AppSpacing.md),
            GhostButton(label: 'Retake quiz', onPress: _retake),
          ],
        ),
      ),
    );
  }
}
