import 'package:flutter/material.dart';

class ScreenContainer extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;

  const ScreenContainer({
    super.key,
    required this.child,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: useSafeArea ? SafeArea(child: child) : child,
    );
  }
}
