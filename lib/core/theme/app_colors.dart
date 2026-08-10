import 'package:flutter/material.dart';

/// Color palette definition for a single theme mode (dark or light).
class AppPalette {
  const AppPalette({
    required this.bg,
    required this.card,
    required this.surface,
    required this.glassFill,
    required this.glassBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.scrim,
  });

  /// Page background.
  final Color bg;

  /// Solid surface (base for cards and sheets).
  final Color card;

  /// Slightly elevated surface (popups, dialogs).
  final Color surface;

  /// Frosted-glass fill — translucent white in dark, translucent black in light.
  final Color glassFill;

  /// Frosted-glass border.
  final Color glassBorder;

  /// Primary text.
  final Color textPrimary;

  /// Muted text.
  final Color textMuted;

  /// Overlay scrim over images.
  final Color scrim;
}

/// Theme-agnostic brand colors shared by both dark and light modes.
abstract final class BrandColors {
  /// Primary — deep emerald (identity, CTAs, active states).
  static const Color primary = Color(0xFF10B981);

  /// Secondary accent — royal gold (premium highlights, rent markers).
  static const Color cyan = Color(0xFFD4AF37);

  /// Lighter emerald (badges, hints).
  static const Color primaryLight = Color(0xFF34D399);

  /// Soft emerald tint (selected states, icon chips).
  static const Color primarySoft = Color(0x1A10B981);

  /// Soft gold tint.
  static const Color cyanSoft = Color(0x1AD4AF37);

  /// Brand gradient: bright emerald → deep emerald.
  static const Color gradientA = Color(0xFF10B981);
  static const Color gradientB = Color(0xFF065F46);

  /// Success green.
  static const Color success = Color(0xFF22C55E);

  /// Secondary sky blue.
  static const Color blue = Color(0xFF38BDF8);

  /// Danger red (distinct from the brand red).
  static const Color red = Color(0xFFFF453A);

  /// Amber — demo/preview badges.
  static const Color amber = Color(0xFFFFB020);

  /// Royal gold accent.
  static const Color gold = Color(0xFFD4AF37);
}

/// Emerald + royal gold palette.
///
/// Deep charcoal backgrounds with a premium emerald (#10B981) primary and
/// royal gold (#D4AF37) accents for a luxurious real-estate feel.
class AppColors {
  /// Dark-mode palette.
  static const AppPalette dark = AppPalette(
    bg: Color(0xFF18181A),
    card: Color(0xFF242426),
    surface: Color(0xFF2C2C2E),
    glassFill: Color(0x14FFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFF5F5F7),
    textMuted: Color(0xFFA1A1A6),
    scrim: Color(0xFF000000),
  );

  /// Light-mode palette.
  static const AppPalette light = AppPalette(
    bg: Color(0xFFF5F5F7),
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFF0F0F2),
    glassFill: Color(0x33FFFFFF),
    glassBorder: Color(0x33000000),
    textPrimary: Color(0xFF1D1D1F),
    textMuted: Color(0xFF6E6E73),
    scrim: Color(0xFF000000),
  );

  /// The currently active palette. Swapped at runtime by the theme controller.
  static AppPalette current = dark;

  /// Page background — deep charcoal (dark) / light grey (light).
  static Color get bg => current.bg;

  /// Solid dark surface (base for cards and sheets).
  static Color get card => current.card;

  /// Slightly elevated surface.
  static Color get surface => current.surface;

  /// Primary — emerald.
  static Color get primary => BrandColors.primary;

  /// Secondary accent — royal gold.
  static Color get cyan => BrandColors.cyan;

  /// Lighter emerald (badges, hints).
  static Color get primaryLight => BrandColors.primaryLight;

  /// Soft emerald tint (selected states, icon chips).
  static Color get primarySoft => BrandColors.primarySoft;

  /// Soft gold tint.
  static Color get cyanSoft => BrandColors.cyanSoft;

  /// Brand gradient: bright emerald → deep emerald.
  static List<Color> get gradient =>
      const [BrandColors.gradientA, BrandColors.gradientB];

  /// Success green.
  static Color get success => BrandColors.success;

  /// Secondary sky blue.
  static Color get blue => BrandColors.blue;

  /// Danger red (distinct from the brand red).
  static Color get red => BrandColors.red;

  /// Amber — demo/preview badges.
  static Color get amber => BrandColors.amber;

  /// Royal gold accent.
  static Color get gold => BrandColors.gold;

  /// Primary text — near-white (dark) / near-black (light).
  static Color get textPrimary => current.textPrimary;

  /// Muted text — cool grey.
  static Color get textMuted => current.textMuted;

  /// Dark scrim for overlays over images and immersive viewers.
  static Color get scrim => current.scrim;

  /// Frosted-glass fill.
  static Color get glassFill => current.glassFill;

  /// Frosted-glass border.
  static Color get glassBorder => current.glassBorder;

  /// Legacy aliases — map to the emerald primary and royal gold accent.
  static Color get royal => primary;
  static Color get royalLight => gold;
  static Color get royalSoft => cyanSoft;
}
