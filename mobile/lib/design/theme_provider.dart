import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the current theme mode (light / dark / system).
/// Use with `MaterialApp`'s `themeMode` parameter.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
