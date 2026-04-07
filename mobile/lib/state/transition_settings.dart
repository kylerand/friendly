import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TransitionStyle {
  slide,
  fade,
  scale,
  slideUp,
  bubble,
  none,
}

extension TransitionStyleLabel on TransitionStyle {
  String get label {
    switch (this) {
      case TransitionStyle.slide:
        return 'Slide (iOS default)';
      case TransitionStyle.fade:
        return 'Fade';
      case TransitionStyle.scale:
        return 'Scale';
      case TransitionStyle.slideUp:
        return 'Slide Up (modal)';
      case TransitionStyle.bubble:
        return 'Bubble';
      case TransitionStyle.none:
        return 'None (instant)';
    }
  }
}

const _prefKey = 'transition_style';

class TransitionSettingsNotifier extends StateNotifier<TransitionStyle> {
  TransitionSettingsNotifier() : super(TransitionStyle.slide) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_prefKey) ?? 0;
    if (index >= 0 && index < TransitionStyle.values.length) {
      state = TransitionStyle.values[index];
    }
  }

  Future<void> set(TransitionStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, style.index);
  }
}

final transitionSettingsProvider =
    StateNotifierProvider<TransitionSettingsNotifier, TransitionStyle>(
  (ref) => TransitionSettingsNotifier(),
);

/// Builds a [CustomTransitionPage] using the current transition style.
CustomTransitionPage<void> buildTransitionPage({
  required LocalKey key,
  required Widget child,
  required TransitionStyle style,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: style == TransitionStyle.none
        ? Duration.zero
        : style == TransitionStyle.bubble
            ? const Duration(milliseconds: 650)
            : const Duration(milliseconds: 300),
    reverseTransitionDuration: style == TransitionStyle.none
        ? Duration.zero
        : style == TransitionStyle.bubble
            ? const Duration(milliseconds: 500)
            : const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (style) {
        case TransitionStyle.fade:
          return FadeTransition(opacity: animation, child: child);
        case TransitionStyle.scale:
          return ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        case TransitionStyle.slideUp:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.25),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        case TransitionStyle.none:
          return child;
        case TransitionStyle.bubble:
          return _BubblePopTransition(animation: animation, child: child);
        case TransitionStyle.slide:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
      }
    },
  );
}

class _BubbleClipper extends CustomClipper<Rect> {
  final double progress;

  _BubbleClipper(this.progress);

  @override
  Rect getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.longestSide * 1.2;
    final radius = maxRadius * progress;
    return Rect.fromCircle(center: center, radius: radius);
  }

  @override
  bool shouldReclip(_BubbleClipper oldClipper) =>
      oldClipper.progress != progress;
}

/// Cartoonish bubble pop transition with splash droplets.
class _BubblePopTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _BubblePopTransition({
    required this.animation,
    required this.child,
  });

  static final _splashes = List.generate(12, (i) {
    final rng = Random(i);
    final angle = (i / 12) * 2 * pi + rng.nextDouble() * 0.3;
    return _SplashDot(
      angle: angle,
      distance: 0.15 + rng.nextDouble() * 0.2,
      size: 8.0 + rng.nextDouble() * 16.0,
      color: [
        const Color(0xFFFF4610), // Brand Red
        const Color(0xFF0066FF), // Brand Blue
        const Color(0xFFFFBF17), // Brand Gold
        const Color(0xFFFF73CA), // Brand Pink
        const Color(0xFF9DA30A), // Refined Olive
      ][i % 5],
    );
  });

  @override
  Widget build(BuildContext context) {
    // Phase 1: 0.0–0.55 bubble grows
    // Phase 2: 0.55–0.7 bubble pops (scale overshoot + splashes appear)
    // Phase 3: 0.7–1.0 splashes fly out and fade

    final growAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    final popAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.55, 0.75, curve: Curves.elasticOut),
    );
    final splashAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );
    final contentFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.45, 0.7, curve: Curves.easeIn),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final grow = growAnimation.value;
        final pop = popAnimation.value;
        final splash = splashAnimation.value;

        // Scale: grows to 0.92, then pops to ~1.05, settles at 1.0
        final baseScale = grow * 0.92;
        final popScale = pop > 0 ? 0.92 + (pop * 0.08) : baseScale;
        final overshoot = pop > 0 && pop < 1.0
            ? sin(pop * pi) * 0.06
            : 0.0;
        final scale = (popScale + overshoot).clamp(0.0, 1.1);

        return Stack(
          fit: StackFit.expand,
          children: [
            // Main content with circular clip and scale
            ClipOval(
              clipper: _BubbleClipper(grow.clamp(0.0, 1.0)),
              child: Opacity(
                opacity: contentFade.value,
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
              ),
            ),
            // Splash droplets
            if (splash > 0 && splash < 1.0)
              ...List.generate(_splashes.length, (i) {
                final dot = _splashes[i];
                final stagger = i * 0.015;
                final dotProgress = ((splash - stagger) / (1.0 - stagger)).clamp(0.0, 1.0);
                if (dotProgress <= 0) return const SizedBox.shrink();

                final dx = cos(dot.angle) * dot.distance * dotProgress;
                final dy = sin(dot.angle) * dot.distance * dotProgress;
                final dotScale = sin(dotProgress * pi);
                // Fade out aggressively in the second half
                final opacity = dotProgress < 0.5
                    ? 1.0
                    : (1.0 - ((dotProgress - 0.5) * 2.0)).clamp(0.0, 1.0);

                return Align(
                  alignment: Alignment(dx * 2, dy * 2),
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: dotScale * 1.2,
                      child: Container(
                        width: dot.size,
                        height: dot.size,
                        decoration: BoxDecoration(
                          color: dot.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _SplashDot {
  final double angle;
  final double distance;
  final double size;
  final Color color;

  const _SplashDot({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
  });
}
