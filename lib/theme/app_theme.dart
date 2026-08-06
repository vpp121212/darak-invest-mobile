import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Backwards-compatible aliases (mapped to the new royal-blue light palette).
const Color bgDark = AppColors.bg;
const Color cardDark = AppColors.card;
const Color gold = AppColors.royal;
const Color goldLight = AppColors.royalLight;
const Color green = AppColors.success;
const Color blue = AppColors.blue;
const Color textLight = AppColors.textPrimary;
const Color textMuted = AppColors.textMuted;

/// Dark scrim used over images and inside immersive 3D viewers.
const Color scrim = AppColors.scrim;

class AppTheme {
  static ThemeData theme = ThemeData(
    scaffoldBackgroundColor: bgDark,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: gold,
      secondary: green,
      surface: cardDark,
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textMuted),
      titleTextStyle: TextStyle(color: textLight),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: textMuted.withValues(alpha: 0.12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardDark,
      hintStyle: const TextStyle(color: textMuted),
      labelStyle: const TextStyle(color: gold),
      prefixIconColor: textMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textMuted.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textMuted.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gold, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: cardDark,
      contentTextStyle: TextStyle(color: textLight),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: DividerThemeData(color: textMuted.withValues(alpha: 0.15)),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: gold),
  );
}
