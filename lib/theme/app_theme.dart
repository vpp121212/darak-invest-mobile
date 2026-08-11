import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Backwards-compatible aliases (follow the active palette).
Color get bgDark => AppColors.bg;
Color get cardDark => AppColors.card;
Color get gold => AppColors.gold;
Color get goldLight => AppColors.gold;
Color get green => AppColors.success;
Color get blue => AppColors.blue;
Color get textLight => AppColors.textPrimary;
Color get textMuted => AppColors.textMuted;
Color get scrim => AppColors.scrim;

Color get textPrimary => AppColors.textPrimary;
Color get success => AppColors.success;
Color get red => AppColors.red;
Color get amber => AppColors.amber;

/// New design-token aliases.
Color get primary => AppColors.primary;
Color get cyan => AppColors.cyan;
Color get primaryLight => AppColors.primaryLight;
Color get primarySoft => AppColors.primarySoft;
Color get cyanSoft => AppColors.cyanSoft;
Color get onBrand => AppColors.onBrand;
Color get brandCard => AppColors.brandCard;
Color get whiteCard => AppColors.whiteCard;
Color get onWhite => AppColors.onWhite;
List<Color> get brandGradient => AppColors.gradient;

/// Frosted-glass surface: translucent white fill for glassmorphism cards.
Color get glassFill => AppColors.glassFill;

/// Frosted-glass border: subtle white hairline.
Color get glassBorder => AppColors.glassBorder;

/// Shared soft shadow — black base with a faint bronze glow.
List<BoxShadow> get softShadow => [
      BoxShadow(
        color: AppColors.scrim.withValues(alpha: 0.3),
        blurRadius: 28,
        offset: const Offset(0, 10),
      ),
      const BoxShadow(
        color: Color(0x1FFFD700),
        blurRadius: 18,
        offset: Offset(0, 0),
      ),
    ];

class AppTheme {
  /// Builds the ThemeData for a given palette and brightness.
  static ThemeData build(AppPalette palette, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      scaffoldBackgroundColor: palette.bg,
      brightness: brightness,
      colorScheme: brightness == Brightness.dark
          ? const ColorScheme.dark(
              primary: BrandColors.primary,
              secondary: BrandColors.cyan,
              surface: Color(0xFF17544A),
              onPrimary: Colors.white,
              onSecondary: Color(0xFF0B3C34),
              onSurface: Color(0xFFF2E9DD),
            )
          : const ColorScheme.light(
              primary: BrandColors.primary,
              secondary: BrandColors.cyan,
              surface: Color(0xFFFFFFFF),
              onPrimary: Colors.white,
              onSecondary: Color(0xFF0B3C34),
              onSurface: Color(0xFF123F36),
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: palette.textPrimary,
        iconTheme: IconThemeData(color: palette.textPrimary),
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.glassFill,
        hintStyle: TextStyle(color: palette.textMuted),
        labelStyle: const TextStyle(color: BrandColors.primary),
        prefixIconColor: palette.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: palette.textMuted.withValues(alpha: 0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: palette.textMuted.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BrandColors.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.card,
        contentTextStyle: TextStyle(color: palette.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme:
          DividerThemeData(color: palette.textMuted.withValues(alpha: 0.2)),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: BrandColors.primary),
      sliderTheme: SliderThemeData(
        activeTrackColor: BrandColors.primary,
        inactiveTrackColor: const Color(0x33FFD700),
        thumbColor: BrandColors.primary,
        overlayColor: const Color(0x2BFFD700),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.card,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      shadowColor: isDark ? const Color(0x66000000) : const Color(0x33000000),
    );
  }

  /// Dark theme (default).
  static ThemeData get theme =>
      build(AppColors.dark, Brightness.dark);

  /// Light theme.
  static ThemeData get lightTheme =>
      build(AppColors.light, Brightness.light);
}
