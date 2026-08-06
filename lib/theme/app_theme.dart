import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Backwards-compatible aliases (mapped to the athletic dark palette).
const Color bgDark = AppColors.bg;
const Color cardDark = AppColors.card;
const Color gold = AppColors.primary;
const Color goldLight = AppColors.primaryLight;
const Color green = AppColors.success;
const Color blue = AppColors.blue;
const Color textLight = AppColors.textPrimary;
const Color textMuted = AppColors.textMuted;
const Color scrim = AppColors.scrim;

const Color textPrimary = AppColors.textPrimary;
const Color success = AppColors.success;
const Color red = AppColors.red;

/// New design-token aliases.
const Color primary = AppColors.primary;
const Color cyan = AppColors.cyan;
const Color primaryLight = AppColors.primaryLight;
const Color primarySoft = AppColors.primarySoft;
const Color cyanSoft = AppColors.cyanSoft;
const List<Color> brandGradient = AppColors.gradient;

/// Frosted-glass surface: translucent white fill for glassmorphism cards.
const Color glassFill = Color(0x14FFFFFF);

/// Frosted-glass border: subtle white hairline.
const Color glassBorder = Color(0x1FFFFFFF);

/// Shared soft shadow for dark surfaces — black base with a faint lime glow.
const List<BoxShadow> softShadow = [
  BoxShadow(
    color: Color(0x4D000000),
    blurRadius: 28,
    offset: Offset(0, 10),
  ),
  BoxShadow(
    color: Color(0x14CCFF00),
    blurRadius: 18,
    offset: Offset(0, 0),
  ),
];

class AppTheme {
  static ThemeData theme = ThemeData(
    scaffoldBackgroundColor: bgDark,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: cyan,
      surface: cardDark,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: textLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: textPrimary,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: glassFill,
      hintStyle: const TextStyle(color: textMuted),
      labelStyle: const TextStyle(color: primary),
      prefixIconColor: textMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: textMuted.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: textMuted.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cardDark,
      contentTextStyle: const TextStyle(color: textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(color: textMuted.withValues(alpha: 0.2)),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    sliderTheme: const SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: Color(0x33CCFF00),
      thumbColor: primary,
      overlayColor: Color(0x2BCCFF00),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: cardDark,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
