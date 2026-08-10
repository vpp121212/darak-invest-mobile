import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Controls the app theme mode (system / light / dark), persists the choice
/// and swaps [AppColors.current] so the theme-agnostic color aliases follow.
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system) {
    _load();
    _apply();
  }

  static const _key = 'darak_theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    ThemeMode mode = ThemeMode.system;
    if (saved == 'light') {
      mode = ThemeMode.light;
    } else if (saved == 'dark') {
      mode = ThemeMode.dark;
    }
    if (mode != state) {
      state = mode;
      _apply();
    }
  }

  void _apply() {
    switch (state) {
      case ThemeMode.light:
        AppColors.current = AppColors.light;
      case ThemeMode.dark:
        AppColors.current = AppColors.dark;
      case ThemeMode.system:
      // resolved at build time from MediaQuery.platformBrightness
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    _apply();
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_key, value);
  }

  /// Resolves the effective brightness for the current mode.
  Brightness brightness(Brightness platform) {
    switch (state) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return platform;
    }
  }

  /// Re-applies the palette after a system brightness change.
  void resolveSystem(Brightness platform) {
    if (state != ThemeMode.system) return;
    final wasDark = AppColors.current == AppColors.dark;
    final wantDark = platform == Brightness.dark;
    if (wasDark != wantDark) _apply();
  }
}

final themeProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController();
});

/// Builds the ThemeData for the given mode + platform brightness.
ThemeData darakTheme(ThemeMode mode, Brightness platform) {
  final brightness =
      mode == ThemeMode.system ? platform : (mode == ThemeMode.light
          ? Brightness.light
          : Brightness.dark);
  final palette =
      brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  return AppTheme.build(palette, brightness);
}

/// Resolves the effective brightness for the given mode + platform.
Brightness darakThemeBrightness(ThemeMode mode, Brightness platform) {
  return mode == ThemeMode.system
      ? platform
      : (mode == ThemeMode.light ? Brightness.light : Brightness.dark);
}
