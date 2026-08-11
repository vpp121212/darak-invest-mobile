import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'app_image.dart';

/// Wraps [AppImage] with the marketing "master animation": a deep-dive camera
/// move (scale 1.0 → 1.15 → 1.28 → 1.35 with pan and a subtle tilt), a
/// brightness/contrast pulse, a diagonal light-sweep (shine) every few
/// seconds, and a hover lift on desktop. Mirrors the CSS
/// `marketingMasterAnimation` / `lightSweep` keyframes the design asked for.
///
/// Each card can pass a [phase] (0..1, via [phaseFor]) so neighbouring cards
/// never move in sync, keeping the grid alive.
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
    this.duration = const Duration(seconds: 9),
    this.sweepDuration = const Duration(seconds: 6),
    this.phase = 0,
  });

  /// Deterministic cycle offset (0..1) for a stable string seed, so cards in
  /// the same grid drift out of sync with each other.
  static double phaseFor(Object seed) => (seed.hashCode.abs() % 100) / 100.0;

  final String src;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;

  /// Duration of one full camera cycle (there and back).
  final Duration duration;

  /// Duration of one full light-sweep cycle.
  final Duration sweepDuration;

  /// Cycle offset 0..1 to desynchronise cards.
  final double phase;

  @override
  State<KenBurnsImage> createState() => _KenBurnsImageState();
}

/// Keyframe curve from `marketingMasterAnimation`:
/// 0% → 35% → 70% → 100%.
const _curve = [0.0, 0.35, 0.70, 1.0];
const _scaleStops = [1.0, 1.15, 1.28, 1.35];
const _panXStops = [0.0, -0.045, 0.035, 0.0];
const _panYStops = [0.0, -0.02, 0.03, 0.0];
const _rotStops = [0.0, -0.0175, 0.0262, 0.0]; // radians (±1° / +1.5°)
const _brightStops = [1.0, 1.03, 1.06, 1.02];
const _contrastStops = [1.0, 1.05, 1.08, 1.02];

class _KenBurnsImageState extends State<KenBurnsImage>
    with TickerProviderStateMixin {
  late final AnimationController _motion;
  late final AnimationController _sweep;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.phase,
    )..repeat(reverse: true);
    _sweep = AnimationController(vsync: this, duration: widget.sweepDuration)
      ..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    _sweep.dispose();
    super.dispose();
  }

  double _interp(List<double> stops, double t) {
    for (var i = 0; i < _curve.length - 1; i++) {
      final a = _curve[i], b = _curve[i + 1];
      if (t <= b) {
        final k = (t - a) / (b - a);
        final e = Curves.easeInOutSine.transform(k.clamp(0.0, 1.0));
        return stops[i] + (stops[i + 1] - stops[i]) * e;
      }
    }
    return stops.last;
  }

  /// Combined brightness + contrast as a 4x5 colour matrix.
  List<double> _colorMatrix(double bright, double contrast) {
    final s = contrast * bright;
    final o = (1 - contrast) * 128 * bright;
    return <double>[
      s, 0, 0, 0, o, //
      0, s, 0, 0, o, //
      0, 0, s, 0, o, //
      0, 0, 0, 1, 0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        key: const Key('ken-burns-hover'),
        scale: _hovering ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _motion,
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
                      final t = _motion.value;
                      final scale = _interp(_scaleStops, t);
                      final tx = _interp(_panXStops, t);
                      final ty = _interp(_panYStops, t);
                      final rot = _interp(_rotStops, t);
                      final bright = _interp(_brightStops, t);
                      final contrast = _interp(_contrastStops, t);
                      final m = Matrix4.identity()
                        ..translateByDouble(w * tx, h * ty, 0, 1)
                        ..rotateZ(rot)
                        ..scaleByDouble(scale, scale, scale, 1);
                      return Transform(
                        key: const Key('ken-burns-transform'),
                        transform: m,
                        alignment: Alignment.center,
                        child: ColorFiltered(
                          colorFilter:
                              ColorFilter.matrix(_colorMatrix(bright, contrast)),
                          child: child,
                        ),
                      );
                    },
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRect(
                        child: AnimatedBuilder(
                          animation: _sweep,
                          builder: (context, _) {
                            final t = _sweep.value;
                            return FractionalTranslation(
                              translation: Offset(0, -1.2 + t * 2.4),
                              child: Center(
                                child: Transform.rotate(
                                  angle: 30 * math.pi / 180,
                                  child: Container(
                                    width: w * 1.7,
                                    height: h * 0.5,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.transparent,
                                          Color(0x26FFFFFF),
                                          Colors.transparent,
                                        ],
                                        stops: [0.3, 0.5, 0.7],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
