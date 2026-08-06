import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data' show Float64List;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// جولة بانورامية 360° مفتوحة المصدر 100% (بدون WebView وبدون اشتراكات خارجية).
///
/// يدعم التنقّل داخل المنزل بين الغرف:
/// - عدة مشاهد [scenes] تُمثّل غرفًا مختلفة
/// - أسهم ذهبية على الأرض (مُسقطة إسقاطًا منظوريًا) تظهر باتجاه الباب للانتقال
///   إلى الغرفة التالية/السابقة
/// - مؤشر الغرفة الحالية + انتقال سلس (crossfade) بين الغرف
/// - زر شاشة كاملة للدخول إلى المنزل بعمق
/// - السحب للاستكشاف، القرص للتكبير، وزر إعادة تعيين العرض
///
/// يعمل بتقنية Canvas الأصلية (CustomPainter + ImageShader) عبر كرة
/// مولّدة كشبكة رؤوس، ما يجعله خفيفًا وسريعًا ويعمل دون اتصال بعد
/// تحميل الصورة.
class VirtualTourViewer extends StatefulWidget {
  const VirtualTourViewer({
    super.key,
    required this.imageUrl,
    this.scenes,
    this.sceneTitles,
    this.title,
    this.height = 260,
  });

  /// رابط الصورة البانورامية الأولى (أفقيّ 360° - Equirectangular).
  final String imageUrl;

  /// غرف/مشاهد إضافية للتنقل داخلها. عند غيابها تعرض [imageUrl] فقط.
  final List<String>? scenes;

  /// أسماء اختيارية للغرف (بنفس ترتيب [scenes]).
  final List<String>? sceneTitles;

  /// عنوان اختياري يُعرض كشارة أعلى الجولة.
  final String? title;

  /// ارتفاع صندوق العرض.
  final double height;

  @override
  State<VirtualTourViewer> createState() => _VirtualTourViewerState();
}

class _VirtualTourViewerState extends State<VirtualTourViewer>
    with SingleTickerProviderStateMixin {
  // حد أقصى لعرض فك ترميز صور البانوراما (~8× الذاكرة أقل من الصور الخام).
  static const int _maxTextureWidth = 2560;

  late List<String> _scenes;
  ui.Image? _pano;
  bool _loading = true;
  String? _error;

  int _sceneIndex = 0;

  double _yaw = 0;
  double _pitch = 0;
  double _fov = 75;
  double _fovAtStart = 75;

  // زخم (inertia) بعد رفع الإصبع.
  AnimationController? _inertia;
  double _velocityYaw = 0;
  double _velocityPitch = 0;
  DateTime? _lastPan;

  @override
  void initState() {
    super.initState();
    _scenes = _normalizeScenes();
    _load();
  }

  @override
  void didUpdateWidget(covariant VirtualTourViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _normalizeScenes();
    if (!_sameScenes(_scenes, next)) {
      _scenes = next;
      _sceneIndex = 0;
      _load();
    }
  }

  @override
  void dispose() {
    _inertia?.dispose();
    super.dispose();
  }

  List<String> _normalizeScenes() {
    final scenes = widget.scenes;
    if (scenes != null && scenes.isNotEmpty) {
      return scenes.where((s) => s.isNotEmpty).toList();
    }
    if (widget.imageUrl.isNotEmpty) return <String>[widget.imageUrl];
    return const <String>[];
  }

  bool _sameScenes(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _sceneLabel(int index) {
    final titles = widget.sceneTitles;
    if (titles != null && index < titles.length && titles[index].isNotEmpty) {
      return titles[index];
    }
    return 'الغرفة ${index + 1}';
  }

  Future<void> _load() async {
    _inertia?.stop();
    if (_scenes.isEmpty) {
      setState(() {
        _error = 'لا توجد بانوراما لهذا العقار';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final image = await _resolveImage(_scenes[_sceneIndex]);
      if (!mounted) return;
      setState(() {
        _pano = image;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الجولة البانورامية';
        _loading = false;
      });
    }
  }

  Future<void> _goToScene(int index) async {
    if (index < 0 || index >= _scenes.length || index == _sceneIndex) return;
    _inertia?.stop();
    try {
      final image = await _resolveImage(_scenes[index]);
      if (!mounted) return;
      setState(() {
        _pano = image;
        _sceneIndex = index;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر فتح الغرفة';
      });
    }
  }

  Future<ui.Image> _resolveImage(String url) async {
    // تقييد أبعاد فك الترميز حتى لا تستهلك صور البانوراما الضخمة
    // (10k+ بكسل) ذاكرة الجهاز — العرض النهائي لا يتجاوز عرض الشاشة.
    final provider = ResizeImage(
      CachedNetworkImageProvider(url),
      width: _maxTextureWidth,
    );
    final stream = provider.resolve(ImageConfiguration.empty);
    final completer = Completer<ui.Image>();
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image);
      },
      onError: (Object error, StackTrace? stack) {
        if (!completer.isCompleted) completer.completeError(error);
      },
    );
    stream.addListener(listener);
    try {
      return await completer.future;
    } finally {
      stream.removeListener(listener);
    }
  }

  void _reset() {
    _inertia?.stop();
    setState(() {
      _yaw = 0;
      _pitch = 0;
      _fov = 75;
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _inertia?.stop();
    _fovAtStart = _fov;
    _lastPan = null;
    _velocityYaw = 0;
    _velocityPitch = 0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount >= 2) {
      // قرصة للتكبير.
      final target = _fovAtStart / details.scale;
      setState(() {
        _fov = target.clamp(30.0, 110.0).toDouble();
      });
    } else if (details.pointerCount == 1) {
      final dx = details.focalPointDelta.dx;
      final dy = details.focalPointDelta.dy;
      setState(() {
        _yaw += dx * 0.25;
        _pitch = (_pitch - dy * 0.25).clamp(-85.0, 85.0).toDouble();
      });
      final now = DateTime.now();
      final last = _lastPan;
      if (last != null) {
        final dt = now.difference(last).inMilliseconds / 1000;
        if (dt > 0) {
          _velocityYaw = dx * 0.25 / dt;
          _velocityPitch = -dy * 0.25 / dt;
        }
      }
      _lastPan = now;
    }
  }

  void _onScaleEnd(ScaleEndDetails _) {
    _lastPan = null;
    _startInertia();
  }

  void _startInertia() {
    final vYaw = _velocityYaw;
    final vPitch = _velocityPitch;
    _velocityYaw = 0;
    _velocityPitch = 0;
    if (vYaw.abs() < 2 && vPitch.abs() < 2) return;

    _inertia?.stop();
    _inertia ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(_tickInertia);

    _velocityYaw = vYaw;
    _velocityPitch = vPitch;
    _inertia!.forward(from: 0);
  }

  void _tickInertia() {
    final t = _inertia!.value.clamp(0.0, 1.0).toDouble();
    final decay = 1 - t;
    setState(() {
      _yaw += _velocityYaw * decay * 0.016;
      _pitch = (_pitch + _velocityPitch * decay * 0.016)
          .clamp(-85.0, 85.0)
          .toDouble();
    });
    if (t >= 1.0) {
      _velocityYaw = 0;
      _velocityPitch = 0;
    }
  }

  /// إسقاط اتجاه في العالم (ياو/بيتش بالدرجات) على شاشة العرض.
  Offset? _project(double worldYawDeg, double worldPitchDeg, Size size) {
    final yawRad = worldYawDeg * math.pi / 180;
    final pitchRad = worldPitchDeg * math.pi / 180;
    final cosp = math.cos(pitchRad);
    final sinp = math.sin(pitchRad);
    final cosy = math.cos(yawRad);
    final siny = math.sin(yawRad);
    double x = cosp * cosy;
    final y = sinp;
    double z = cosp * siny;

    final yaw0 = _yaw * math.pi / 180;
    final pitch0 = _pitch * math.pi / 180;
    final cosYaw = math.cos(yaw0);
    final sinYaw = math.sin(yaw0);
    final cosPitch = math.cos(pitch0);
    final sinPitch = math.sin(pitch0);

    final x1 = x * cosYaw + z * sinYaw;
    final z1 = -x * sinYaw + z * cosYaw;
    final y2 = y * cosPitch - z1 * sinPitch;
    final z2 = y * sinPitch + z1 * cosPitch;
    x = x1;

    if (z2 <= 0.001) return null;
    final focal = (size.height / 2) / math.tan(_fov * math.pi / 360);
    return Offset(
      size.width / 2 + focal * x / z2,
      size.height / 2 - focal * y2 / z2,
    );
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenTour(
          scenes: _scenes,
          sceneTitles: widget.sceneTitles,
          title: widget.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pano = _pano;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final multi = _scenes.length > 1;
        final showNext = multi && _sceneIndex < _scenes.length - 1;
        final showPrev = multi && _sceneIndex > 0;
        final nextPos = showNext ? _project(0, -12, size) : null;
        final prevPos = showPrev ? _project(180, -12, size) : null;

        return Container(
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scrim,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gold.withValues(alpha: 0.25)),
          ),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildScene(pano),
              ),
              if (!_loading && _error == null) ...[
                Positioned(
                  top: 10,
                  left: 10,
                  child: _badge('360°'),
                ),
                if (widget.title != null && widget.title!.isNotEmpty)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _badge(widget.title!),
                  ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _hintChip(multi ? 'المسّ السهم الذهبي للتنقل' : 'اسحب للاستكشاف'),
                      const SizedBox(width: 6),
                      if (!multi) _hintChip('قرصة للتكبير'),
                    ],
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _roundButton(
                        icon: Icons.fullscreen,
                        onTap: _openFullscreen,
                      ),
                      const SizedBox(width: 8),
                      _roundButton(icon: Icons.refresh, onTap: _reset),
                    ],
                  ),
                ),
                if (multi)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40,
                    child: Center(child: _badge(_sceneCounterLabel())),
                  ),
                if (nextPos != null)
                  _navArrow(
                    position: nextPos,
                    icon: Icons.arrow_forward,
                    label: 'التالي',
                    onTap: () => _goToScene(_sceneIndex + 1),
                  ),
                if (prevPos != null)
                  _navArrow(
                    position: prevPos,
                    icon: Icons.arrow_back,
                    label: 'السابق',
                    onTap: () => _goToScene(_sceneIndex - 1),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _sceneCounterLabel() {
    return '${_sceneLabel(_sceneIndex)} — ${_sceneIndex + 1}/${_scenes.length}';
  }

  Widget _buildScene(ui.Image? pano) {
    if (_loading) {
      return const Center(
        key: ValueKey('vt-loading'),
        child: CircularProgressIndicator(strokeWidth: 2, color: gold),
      );
    }
    if (_error != null) {
      return Center(
        key: const ValueKey('vt-error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.threesixty, color: textMuted, size: 40),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'إعادة المحاولة',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (pano == null) return const SizedBox.shrink();
    return GestureDetector(
      key: ValueKey('vt-pano-$_sceneIndex'),
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: CustomPaint(
        painter: _SpherePainter(
          image: pano,
          yaw: _yaw,
          pitch: _pitch,
          fov: _fov,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: scrim.withValues(alpha: 0.75),
          shape: BoxShape.circle,
          border: Border.all(color: gold.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, size: 17, color: gold),
      ),
    );
  }

  Widget _navArrow({
    required Offset position,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    const arrowSize = 44.0;
    return Positioned(
      left: position.dx - arrowSize / 2,
      top: position.dy - arrowSize / 2 - 4,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: arrowSize,
              height: arrowSize,
              decoration: BoxDecoration(
                color: gold,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: scrim.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scrim.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: gold,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _hintChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scrim.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

/// شاشة كاملة للدخول داخل المنزل بعمق أكبر.
class _FullscreenTour extends StatelessWidget {
  const _FullscreenTour({
    required this.scenes,
    this.sceneTitles,
    this.title,
  });

  final List<String> scenes;
  final List<String>? sceneTitles;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        120;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title ?? 'جولة 360°',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: VirtualTourViewer(
                  imageUrl: scenes.first,
                  scenes: scenes,
                  sceneTitles: sceneTitles,
                  title: title,
                  height: height,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// يرسم كرة بانورامية (شبكة رؤوس) مع تحويل كاميرا (ياو/بيتش/حقل رؤية).
class _SpherePainter extends CustomPainter {
  _SpherePainter({
    required this.image,
    required this.yaw,
    required this.pitch,
    required this.fov,
  });

  final ui.Image image;
  final double yaw;
  final double pitch;
  final double fov;

  @override
  void paint(Canvas canvas, Size size) {
    const nYaw = 90;
    const nPitch = 30;
    const vertCount = (nYaw + 1) * (nPitch + 1);

    final positions = List<Offset>.filled(vertCount, Offset.zero, growable: false);
    final uv = List<Offset>.filled(vertCount, Offset.zero, growable: false);
    final colors = List<Color>.filled(vertCount, const Color(0xFFFFFFFF), growable: false);

    final cx = size.width / 2;
    final cy = size.height / 2;
    final focal = (size.height / 2) / math.tan(fov * math.pi / 360);

    final yawRad = yaw * math.pi / 180;
    final pitchRad = pitch * math.pi / 180;
    final cosYaw = math.cos(yawRad);
    final sinYaw = math.sin(yawRad);
    final cosPitch = math.cos(pitchRad);
    final sinPitch = math.sin(pitchRad);

    var vi = 0;
    for (var i = 0; i <= nYaw; i++) {
      final yawV = (i / nYaw) * 2 * math.pi;
      final u = i / nYaw;
      for (var j = 0; j <= nPitch; j++) {
        final pitchV = ((j / nPitch) - 0.5) * (178 * math.pi / 180);
        final v = 0.5 - pitchV / math.pi;

        // اتجاه النقطة على الكرة.
        final cosp = math.cos(pitchV);
        final sinp = math.sin(pitchV);
        final cosy = math.cos(yawV);
        final siny = math.sin(yawV);
        double x = cosp * cosy;
        final y = sinp;
        double z = cosp * siny;

        // دوران الكاميرا (ياو ثم بيتش).
        final x1 = x * cosYaw + z * sinYaw;
        final z1 = -x * sinYaw + z * cosYaw;
        final y2 = y * cosPitch - z1 * sinPitch;
        final z2 = y * sinPitch + z1 * cosPitch;
        x = x1;

        // عرض منظوري فقط أمام الكاميرا.
        final depth = z2;
        if (depth > 0.001) {
          positions[vi] = Offset(
            cx + focal * x / depth,
            cy - focal * y2 / depth,
          );
        } else {
          const hidden = Offset(-100000, -100000);
          positions[vi] = hidden;
        }

        // شفافية ناعمة عند الأفق لإخفاء النصف الخلفي.
        final alpha = (depth.clamp(0.0, 1.0) * 255).round();
        colors[vi] = Color.fromARGB(alpha, 255, 255, 255);
        uv[vi] = Offset(u, v);
        vi++;
      }
    }

    final indices = <int>[];
    for (var i = 0; i < nYaw; i++) {
      for (var j = 0; j < nPitch; j++) {
        final a = i * (nPitch + 1) + j;
        final b = a + 1;
        final c = (i + 1) * (nPitch + 1) + j;
        final d = c + 1;
        indices
          ..add(a)
          ..add(c)
          ..add(b)
          ..add(b)
          ..add(c)
          ..add(d);
      }
    }

    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: uv,
      colors: colors,
      indices: indices,
    );

    final paint = Paint()
      ..shader = ui.ImageShader(
        image,
        ui.TileMode.clamp,
        ui.TileMode.clamp,
        Float64List.fromList(<double>[
          1, 0, 0, 0,
          0, 1, 0, 0,
          0, 0, 1, 0,
          0, 0, 0, 1,
        ]),
      )
      ..filterQuality = FilterQuality.medium;

    canvas.drawVertices(vertices, BlendMode.modulate, paint);
  }

  @override
  bool shouldRepaint(covariant _SpherePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.fov != fov;
  }
}
