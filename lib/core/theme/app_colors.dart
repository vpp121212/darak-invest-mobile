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
  static const Color primary = Color(0xFFE50914);
  static const Color cyan = Color(0xFFFF4757);
  static const Color primaryLight = Color(0xFFFF5A61);
  static const Color primarySoft = Color(0x26E50914);
  static const Color cyanSoft = Color(0x1FFF4757);
  static const Color gradientA = Color(0xFFFF1F2A);
  static const Color gradientB = Color(0xFFB20710);
  static const Color success = Color(0xFF34D399);
  static const Color blue = Color(0xFF38BDF8);
  static const Color red = Color(0xFFFF453A);
  static const Color amber = Color(0xFFFFB020);
}

/// Homerch palette — Netflix-style red identity.
///
/// Near-black background with a brand red (#E50914) primary, muted grey text
/// and solid dark surfaces (#242426) for a premium real-estate feel.
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

  /// Primary — Homerch brand red.
  static Color get primary => BrandColors.primary;

  /// Secondary accent — lighter coral red.
  static Color get cyan => BrandColors.cyan;

  /// Lighter red (badges, hints).
  static Color get primaryLight => BrandColors.primaryLight;

  /// Soft red tint (selected states, icon chips).
  static Color get primarySoft => BrandColors.primarySoft;

  /// Soft coral tint.
  static Color get cyanSoft => BrandColors.cyanSoft;

  /// Brand gradient: bright red → deep red.
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

  /// Legacy alias — old gold slot maps to the brand red primary.
  static Color get royal => primary;
  static Color get royalLight => primaryLight;
  static Color get royalSoft => primarySoft;
}
