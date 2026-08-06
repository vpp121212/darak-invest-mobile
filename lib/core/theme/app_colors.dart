import 'package:flutter/material.dart';

/// Bright modern teal/cyan palette — "Gulf water" identity (single source of truth).
class AppColors {
  /// Page background — very light icy-mint white.
  static const Color bg = Color(0xFFF2FAFC);

  /// Card / surface background — white.
  static const Color card = Color(0xFFFFFFFF);

  /// Primary vibrant teal.
  static const Color primary = Color(0xFF00A896);

  /// Bright cyan (secondary brand accent).
  static const Color cyan = Color(0xFF00B4D8);

  /// Lighter teal accent (badges, hints).
  static const Color primaryLight = Color(0xFF5EE0D0);

  /// Soft teal tint (selected states, icon chips).
  static const Color primarySoft = Color(0xFFD9F6F1);

  /// Soft cyan tint.
  static const Color cyanSoft = Color(0xFFD8F1FA);

  /// Brand gradient: teal → cyan.
  static const List<Color> gradient = [primary, cyan];

  /// Success green.
  static const Color success = Color(0xFF12B886);

  /// Secondary sky blue (rent badges).
  static const Color blue = Color(0xFF0EA5E9);

  /// Danger red.
  static const Color red = Color(0xFFEF4444);

  /// Primary text — deep teal-black.
  static const Color textPrimary = Color(0xFF073B3E);

  /// Muted text — cool grey-teal.
  static const Color textMuted = Color(0xFF5A8186);

  /// Dark scrim for overlays over images and immersive viewers.
  static const Color scrim = Color(0xFF052E35);

  /// Legacy alias — royal blue slot now maps to the primary teal.
  static const Color royal = primary;
  static const Color royalLight = primaryLight;
  static const Color royalSoft = primarySoft;
}
