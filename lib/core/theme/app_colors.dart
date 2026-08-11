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
  /// Primary — bronze (identity, CTAs, active states).
  static const Color primary = Color(0xFFC5A077);

  /// Secondary accent — lighter bronze (premium highlights, rent markers).
  static const Color cyan = Color(0xFFA88B68);

  /// Lighter bronze (badges, hints).
  static const Color primaryLight = Color(0xFFD9BC94);

  /// Soft bronze tint (selected states, icon chips).
  static const Color primarySoft = Color(0x26C5A077);

  /// Soft bronze tint.
  static const Color cyanSoft = Color(0x26A88B68);

  /// Brand gradient: light bronze → deep bronze.
  static const Color gradientA = Color(0xFFD9BC94);
  static const Color gradientB = Color(0xFFA88B68);

  /// Text/icons placed on bronze cards — deep green for high contrast.
  static const Color onBrand = Color(0xFF0B3C34);

  /// Bronze card background (secondary surfaces).
  static const Color brandCard = Color(0xFFA88B68);

  /// White pop-out card (elevated highlight surfaces).
  static const Color whiteCard = Color(0xFFFFFFFF);

  /// Text/icons placed on white cards — deep green.
  static const Color onWhite = Color(0xFF0B3C34);

  /// Success green.
  static const Color success = Color(0xFF34D399);

  /// Secondary sky blue.
  static const Color blue = Color(0xFF38BDF8);

  /// Danger red (distinct from the brand red).
  static const Color red = Color(0xFFFF453A);

  /// Amber — demo/preview badges.
  static const Color amber = Color(0xFFFFB020);

  /// Bronze accent.
  static const Color gold = Color(0xFFC5A077);
}

/// Deep green + bronze palette.
///
/// Dark green (#0B3C34) backgrounds with bronze (#C5A077 / #A88B68) accents
/// for a luxurious, business-focused feel.
class AppColors {
  /// Dark-mode palette.
  static const AppPalette dark = AppPalette(
    bg: Color(0xFF0B3C34),
    card: Color(0xFF11473D),
    surface: Color(0xFF17544A),
    glassFill: Color(0x14FFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFF2E9DD),
    textMuted: Color(0xFFBCAB90),
    scrim: Color(0xFF000000),
  );

  /// Light-mode palette.
  static const AppPalette light = AppPalette(
    bg: Color(0xFFF4EFE6),
    card: Color(0xFFFFFFFF),
    surface: Color(0xFFEDE6D8),
    glassFill: Color(0x33FFFFFF),
    glassBorder: Color(0x33000000),
    textPrimary: Color(0xFF123F36),
    textMuted: Color(0xFF7A6A51),
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

  /// Text/icons placed on bronze cards — deep green for high contrast.
  static Color get onBrand => BrandColors.onBrand;

  /// Bronze card background (secondary surfaces).
  static Color get brandCard => BrandColors.brandCard;

  /// White pop-out card (elevated highlight surfaces).
  static Color get whiteCard => BrandColors.whiteCard;

  /// Text/icons placed on white cards — deep green.
  static Color get onWhite => BrandColors.onWhite;

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
