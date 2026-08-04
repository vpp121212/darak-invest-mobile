import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Global palette aliases (single source of truth).
const Color bgDark = AppColors.bgDark;
const Color cardDark = AppColors.cardDark;
const Color gold = AppColors.gold;
const Color goldLight = AppColors.goldLight;
const Color green = AppColors.green;
const Color blue = AppColors.blue;
const Color textLight = AppColors.textLight;
const Color textMuted = AppColors.textMuted;

class AppTheme {
  static ThemeData theme = ThemeData(
    scaffoldBackgroundColor: bgDark,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: green,
      surface: cardDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textMuted),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.white24),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: gold, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: gold,
        foregroundColor: bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: cardDark,
      contentTextStyle: TextStyle(color: textLight),
    ),
  );
}
