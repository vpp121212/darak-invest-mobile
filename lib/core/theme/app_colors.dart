import 'package:flutter/material.dart';

/// Athletic dark palette — "Nike Training Club / Whoop" identity.
///
/// Deep black background with an electric lime (#CCFF00) primary and a
/// spring-green secondary. Frosted-glass surfaces sit on top of the black.
class AppColors {
  /// Page background — deep black.
  static const Color bg = Color(0xFF0A0A0A);

  /// Solid dark surface (base for frosted glass cards).
  static const Color card = Color(0xFF161616);

  /// Primary — electric lime (neon green).
  static const Color primary = Color(0xFFCCFF00);

  /// Secondary accent — spring green.
  static const Color cyan = Color(0xFF00F0A0);

  /// Lighter lime (badges, hints).
  static const Color primaryLight = Color(0xFFE8FF7A);

  /// Soft lime tint (selected states, icon chips).
  static const Color primarySoft = Color(0x26CCFF00);

  /// Soft spring-green tint.
  static const Color cyanSoft = Color(0x1F00F0A0);

  /// Brand gradient: electric lime → spring green.
  static const List<Color> gradient = [primary, cyan];

  /// Success green.
  static const Color success = Color(0xFF34D399);

  /// Secondary sky blue.
  static const Color blue = Color(0xFF38BDF8);

  /// Danger red.
  static const Color red = Color(0xFFFF4D4F);

  /// Primary text — near-white.
  static const Color textPrimary = Color(0xFFF4F6F5);

  /// Muted text — cool grey.
  static const Color textMuted = Color(0xFF8B9096);

  /// Dark scrim for overlays over images and immersive viewers.
  static const Color scrim = Color(0xFF000000);

  /// Legacy alias — old gold slot maps to the electric lime primary.
  static const Color royal = primary;
  static const Color royalLight = primaryLight;
  static const Color royalSoft = primarySoft;
}
