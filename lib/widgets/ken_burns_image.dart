import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'app_image.dart';

/// Wraps [AppImage] with a deep-dive cinematic camera move — a slow loop of
/// marketing zoom (scale 1.06 → 1.3), lateral pan (−2%/−1% → +2%/+1%) and a
/// subtle tilt that gives the image a distinctive diorama angle. Mirrors the
/// CSS `cinematicZoom` keyframes the design asked for.
///
/// Each card can pass a [phase] (via [phaseFor]) so neighbouring cards never
/// move in sync, keeping the grid alive.
class KenBurnsImage extends StatefulWidget {
  const KenBurnsImage({
    super.key,
    required this.src,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.placeholder,
    this.errorWidget,
    this.duration = const Duration(seconds: 8),
    this.minScale = 1.06,
    this.maxScale = 1.30,
    this.panX = 0.02,
    this.panY = 0.01,
    this.rotateAmplitude = 0.015,
    this.phase = 0,
  });

  /// Deterministic phase (radians) for a stable string seed, so cards in the
  /// same grid drift out of sync with each other.
  static double phaseFor(Object seed) => (seed.hashCode.abs() % 628) * 0.01;

  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final Duration duration;

  /// Base zoom. Kept above 1.0 so the tilt/pan never exposes image edges.
  final double minScale;
  final double maxScale;

  /// Horizontal/vertical pan as a fraction of the image size.
  final double panX;
  final double panY;

  /// Tilt amplitude in radians (0.022 ≈ 1.26°).
  final double rotateAmplitude;

  /// Phase offset in radians to desynchronise cards.
  final double phase;

  @override
  State<KenBurnsImage> createState() => _KenBurnsImageState();
}

class _KenBurnsImageState extends State<KenBurnsImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return AnimatedBuilder(
            animation: _controller,
            child: AppImage(
              src: widget.src,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              memCacheWidth: widget.memCacheWidth,
              placeholder: widget.placeholder,
              errorWidget: widget.errorWidget,
            ),
            builder: (context, child) {
              final a = _controller.value * 2 * math.pi + widget.phase;
              final scale = (widget.maxScale - widget.minScale) *
                      0.5 *
                      (1 - math.cos(a)) +
                  widget.minScale;
              final dx = widget.panX * math.sin(a);
              final dy = widget.panY * math.cos(a);
              final rot = widget.rotateAmplitude * math.sin(a);
              final m = Matrix4.identity()
                ..translateByDouble(w * dx, h * dy, 0, 1)
                ..rotateZ(rot)
                ..scaleByDouble(scale, scale, scale, 1);
              return Transform(
                key: const Key('ken-burns-transform'),
                transform: m,
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}
