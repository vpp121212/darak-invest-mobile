import 'package:flutter/material.dart';

/// Homerch dark palette — Netflix-style red identity.
///
/// Near-black background with a brand red (#E50914) primary, muted grey text
/// and solid dark surfaces (#242426) for a premium real-estate feel.
class AppColors {
  /// Page background — deep charcoal.
  static const Color bg = Color(0xFF18181A);

  /// Solid dark surface (base for cards and sheets).
  static const Color card = Color(0xFF242426);

  /// Primary — Homerch brand red.
  static const Color primary = Color(0xFFE50914);

  /// Secondary accent — lighter coral red.
  static const Color cyan = Color(0xFFFF4757);

  /// Lighter red (badges, hints).
  static const Color primaryLight = Color(0xFFFF5A61);

  /// Soft red tint (selected states, icon chips).
  static const Color primarySoft = Color(0x26E50914);

  /// Soft coral tint.
  static const Color cyanSoft = Color(0x1FFF4757);

  /// Brand gradient: bright red → deep red.
  static const List<Color> gradient = [Color(0xFFFF1F2A), Color(0xFFB20710)];

  /// Success green.
  static const Color success = Color(0xFF34D399);

  /// Secondary sky blue.
  static const Color blue = Color(0xFF38BDF8);

  /// Danger red (distinct from the brand red).
  static const Color red = Color(0xFFFF453A);

  /// Amber — demo/preview badges.
  static const Color amber = Color(0xFFFFB020);

  /// Primary text — near-white.
  static const Color textPrimary = Color(0xFFF5F5F7);

  /// Muted text — cool grey.
  static const Color textMuted = Color(0xFFA1A1A6);

  /// Dark scrim for overlays over images and immersive viewers.
  static const Color scrim = Color(0xFF000000);

  /// Legacy alias — old gold slot maps to the brand red primary.
  static const Color royal = primary;
  static const Color royalLight = primaryLight;
  static const Color royalSoft = primarySoft;
}
