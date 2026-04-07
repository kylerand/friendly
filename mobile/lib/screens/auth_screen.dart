import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/ui/ui.dart';
import '../constants/copy.dart';
import '../design/theme.dart';
import '../services/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _isMagicLink = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _nameController.text.trim();

    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return;
    }

    if (!_isMagicLink && password.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isMagicLink) {
        await AuthService.signInWithMagicLink(email: email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check your email for the magic link!')),
          );
        }
      } else if (_isSignUp) {
        await AuthService.signUp(
          email: email,
          password: password,
          displayName: displayName.isNotEmpty ? displayName : null,
        );
      } else {
        await AuthService.signIn(email: email, password: password);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _submitLabel {
    if (_isMagicLink) return Copy.magicLink;
    return _isSignUp ? Copy.signUp : Copy.signIn;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final negative = isDark ? AppColorsDark.negative : AppColors.negative;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;

    return ScreenContainer(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Image.asset(
                isDark
                    ? 'assets/friendly_logo_bw.png'
                    : 'assets/friendly_logo_color.png',
                height: 80,
              ),
              const SizedBox(height: AppSpacing.lg),
              // App name + tagline
              Text(
                Copy.appName,
                style: AppTypography.display.copyWith(color: textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                Copy.tagline,
                style: AppTypography.body.copyWith(color: textSecondary),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction:
                    _isMagicLink ? TextInputAction.done : TextInputAction.next,
                decoration: InputDecoration(
                  hintText: Copy.emailPlaceholder,
                  filled: true,
                  fillColor: surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                ),
              ),
              if (!_isMagicLink) ...[
                const SizedBox(height: AppSpacing.md),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction:
                      _isSignUp ? TextInputAction.next : TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: Copy.passwordPlaceholder,
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                  ),
                ),
              ],
              if (!_isMagicLink && _isSignUp) ...[
                const SizedBox(height: AppSpacing.md),

                // Display name
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: Copy.namePlaceholder,
                    filled: true,
                    fillColor: surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // Submit
              PrimaryButton(
                label: _submitLabel,
                onPress: _isLoading ? null : _handleSubmit,
                disabled: _isLoading,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Magic link toggle
              GhostButton(
                label: _isMagicLink
                    ? 'Use password instead'
                    : 'Send magic link instead',
                onPress: () => setState(() {
                  _isMagicLink = !_isMagicLink;
                  _error = null;
                }),
              ),

              // Sign in / sign up toggle
              GhostButton(
                label: _isSignUp
                    ? 'Already have an account? ${Copy.signIn}'
                    : 'Don\'t have an account? ${Copy.signUp}',
                onPress: () => setState(() {
                  _isSignUp = !_isSignUp;
                  _error = null;
                }),
              ),

              // Error display
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: AppTypography.caption.copyWith(color: negative),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
