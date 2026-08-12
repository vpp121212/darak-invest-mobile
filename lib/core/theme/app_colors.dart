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

  /// Frosted-glass fill — translucent white in dark, translucent tint in light.
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
  /// Primary — emerald (identity, CTAs, active states).
  static const Color primary = Color(0xFF10B981);

  /// Secondary accent — deeper emerald (premium highlights, rent markers).
  static const Color cyan = Color(0xFF059669);

  /// Lighter emerald (badges, hints).
  static const Color primaryLight = Color(0xFF34D399);

  /// Soft emerald tint (selected states, icon chips).
  static const Color primarySoft = Color(0x1A10B981);

  /// Soft emerald tint.
  static const Color cyanSoft = Color(0x1A059669);

  /// Brand gradient: light emerald → deep emerald.
  static const Color gradientA = Color(0xFF34D399);
  static const Color gradientB = Color(0xFF059669);

  /// Text/icons placed on emerald surfaces — deep emerald for high contrast.
  static const Color onBrand = Color(0xFF065F46);

  /// Emerald-tinted card background (secondary surfaces).
  static const Color brandCard = Color(0xFFE8F6F1);

  /// White pop-out card (elevated highlight surfaces).
  static const Color whiteCard = Color(0xFFFFFFFF);

  /// Text/icons placed on white cards — deep emerald.
  static const Color onWhite = Color(0xFF065F46);

  /// Success green.
  static const Color success = Color(0xFF10B981);

  /// Secondary sky blue.
  static const Color blue = Color(0xFF38BDF8);

  /// Danger red (distinct from the brand red).
  static const Color red = Color(0xFFFF453A);

  /// Amber — demo/preview badges.
  static const Color amber = Color(0xFFFFB020);

  /// Accent alias — maps to emerald.
  static const Color gold = Color(0xFF10B981);
}

/// Emerald + white palette.
///
/// White backgrounds with emerald (#10B981 / #059669) accents for a fresh,
/// clean, premium real-estate feel.
class AppColors {
  /// Light-mode palette (default) — white with emerald accents.
  static const AppPalette light = AppPalette(
    bg: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFF0FAF6),
    glassFill: Color(0x0F059669),
    glassBorder: Color(0x1A059669),
    textPrimary: Color(0xFF0B2018),
    textMuted: Color(0xFF5C756C),
    scrim: Color(0xFF000000),
  );

  /// Dark-mode palette — deep emerald with white text.
  static const AppPalette dark = AppPalette(
    bg: Color(0xFF0B2018),
    card: Color(0xFF102B23),
    surface: Color(0xFF17382E),
    glassFill: Color(0x14FFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textMuted: Color(0xFFA3BCB3),
    scrim: Color(0xFF000000),
  );

  /// The currently active palette. Swapped at runtime by the theme controller.
  static AppPalette current = light;

  /// Page background.
  static Color get bg => current.bg;

  /// Solid surface (base for cards and sheets).
  static Color get card => current.card;

  /// Slightly elevated surface.
  static Color get surface => current.surface;

  /// Primary — emerald.
  static Color get primary => BrandColors.primary;

  /// Secondary accent — deep emerald.
  static Color get cyan => BrandColors.cyan;

  /// Lighter emerald (badges, hints).
  static Color get primaryLight => BrandColors.primaryLight;

  /// Soft emerald tint (selected states, icon chips).
  static Color get primarySoft => BrandColors.primarySoft;

  /// Soft emerald tint.
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

  /// Accent alias — emerald.
  static Color get gold => BrandColors.gold;

  /// Text/icons placed on emerald surfaces — deep emerald.
  static Color get onBrand => BrandColors.onBrand;

  /// Emerald-tinted card background (secondary surfaces).
  static Color get brandCard => BrandColors.brandCard;

  /// White pop-out card (elevated highlight surfaces).
  static Color get whiteCard => BrandColors.whiteCard;

  /// Text/icons placed on white cards — deep emerald.
  static Color get onWhite => BrandColors.onWhite;

  /// Primary text.
  static Color get textPrimary => current.textPrimary;

  /// Muted text.
  static Color get textMuted => current.textMuted;

  /// Dark scrim for overlays over images and immersive viewers.
  static Color get scrim => current.scrim;

  /// Frosted-glass fill.
  static Color get glassFill => current.glassFill;

  /// Frosted-glass border.
  static Color get glassBorder => current.glassBorder;

  /// Legacy aliases — map to the emerald primary.
  static Color get royal => primary;
  static Color get royalLight => gold;
  static Color get royalSoft => cyanSoft;
}
