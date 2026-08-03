import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';

/// عارض «بيت الدمية» ثلاثي الأبعاد عبر WebView.
///
/// يعرض نماذج [modelUrl]/[scenes] (GLB/GLTF) باستخدام مكتبة Google
/// `model-viewer` المجانية 100% (كود HTML يُحمَّل داخل WebView).
///
/// يدعم الدخول داخل المنزل والتنقل:
/// - عدة مشاهد/غرف [scenes] مع أسهم التنقل (السابق/التالي) ومؤشر الغرفة
/// - ثلاثة أوضاع عرض: بيت الدمية، المخطط، والتجول الداخلي
/// - تدوير تلقائي وتحكم كامل بالكاميرا (السحب للتدوير والتكبير)
class DollhouseViewer extends StatefulWidget {
  const DollhouseViewer({
    super.key,
    required this.modelUrl,
    this.scenes,
    this.sceneTitles,
    this.height = 260,
  });

  /// رابط النموذج ثلاثي الأبعاد الأول (GLB/GLTF).
  final String modelUrl;

  /// مشاهد/غرف إضافية للتنقل بينها. عند غيابها يعرض [modelUrl] فقط.
  final List<String>? scenes;

  /// أسماء اختيارية للغرف (بنفس ترتيب [scenes]).
  final List<String>? sceneTitles;

  /// ارتفاع صندوق العرض.
  final double height;

  @override
  State<DollhouseViewer> createState() => _DollhouseViewerState();
}

class _DollhouseViewerState extends State<DollhouseViewer> {
  static const String _kDollhouse = 'بيت الدمية';
  static const String _kPlan = 'المخطط';
  static const String _kWalk = 'تجول';

  late final WebViewController _controller;
  late List<String> _scenes;
  bool _loaded = false;
  String? _error;
  int _sceneIndex = 0;
  String _mode = _kDollhouse;

  @override
  void initState() {
    super.initState();
    _scenes = _normalizeScenes();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(bgDark)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loaded = true);
            _applyMode(_mode);
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted) return;
            if (!_loaded) {
              setState(() => _error = 'تعذّر تحميل النموذج ثلاثي الأبعاد');
            }
          },
        ),
      );
    _load();
  }

  @override
  void didUpdateWidget(covariant DollhouseViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _normalizeScenes();
    if (!_sameScenes(_scenes, next)) {
      _scenes = next;
      _sceneIndex = 0;
      _loaded = false;
      _error = null;
      _load();
    }
  }

  List<String> _normalizeScenes() {
    final scenes = widget.scenes;
    if (scenes != null && scenes.isNotEmpty) {
      return scenes.where((s) => s.isNotEmpty).toList();
    }
    if (widget.modelUrl.isNotEmpty) return <String>[widget.modelUrl];
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
    return 'المشهد ${index + 1}';
  }

  void _load() {
    _controller.loadHtmlString(_html(), baseUrl: Uri.parse('https://localhost/'));
  }

  String _html() {
    return '''
<!DOCTYPE html>
<html lang="ar">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <style>
    html, body { margin: 0; padding: 0; width: 100%; height: 100%;
                 overflow: hidden; background: #0a0b10; }
    model-viewer { width: 100%; height: 100%; background: #0a0b10;
                   --poster-color: #0a0b10; }
  </style>
</head>
<body>
  <script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.4.0/model-viewer.min.js"></script>
  <model-viewer
    id="mv"
    src="${_scenes[_sceneIndex]}"
    alt="3D Dollhouse View"
    auto-rotate
    camera-controls
    touch-action="pan-y"
    style="width: 100%; height: 100%;">
  </model-viewer>
</body>
</html>
''';
  }

  void _goToScene(int index) {
    if (index < 0 || index >= _scenes.length || index == _sceneIndex) return;
    setState(() => _sceneIndex = index);
    if (_loaded) {
      _controller.runJavaScript(
        "var mv=document.getElementById('mv');"
        "if(mv){mv.setAttribute('src','${_scenes[index]}');}"
      );
    } else {
      _load();
    }
  }

  void _applyMode(String mode) {
    setState(() => _mode = mode);
    if (!_loaded) return;
    String orbit;
    bool rotate;
    switch (mode) {
      case _kPlan:
        orbit = '0deg 89deg 130%';
        rotate = false;
        break;
      case _kWalk:
        orbit = '0deg 15deg 35%';
        rotate = false;
        break;
      default:
        orbit = '-25deg 72deg 110%';
        rotate = true;
    }
    _controller.runJavaScript(
      "var mv=document.getElementById('mv');"
      "if(mv){"
      "mv.setAttribute('camera-orbit','$orbit');"
      "mv.setAttribute('interpolation-decay','200');"
      "${rotate ? "mv.setAttribute('auto-rotate','');" : "mv.removeAttribute('auto-rotate');"}"
      "}"
    );
  }

  @override
  Widget build(BuildContext context) {
    final multi = _scenes.length > 1;
    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.25)),
      ),
      child: Stack(
        children: [
          if (_error == null)
            WebViewWidget(controller: _controller)
          else
            _buildError(),
          if (!_loaded && _error == null)
            const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: gold),
            ),
          Positioned(
            top: 10,
            left: 10,
            child: _badge('بيت الدمية'),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modeChip(_kDollhouse),
                const SizedBox(width: 6),
                _modeChip(_kPlan),
                const SizedBox(width: 6),
                _modeChip(_kWalk),
              ],
            ),
          ),
          if (_loaded && _error == null) ...[
            if (multi)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _navButton(
                      icon: Icons.arrow_back,
                      enabled: _sceneIndex > 0,
                      onTap: () => _goToScene(_sceneIndex - 1),
                    ),
                    const SizedBox(width: 10),
                    _badge(_sceneCounterLabel()),
                    const SizedBox(width: 10),
                    _navButton(
                      icon: Icons.arrow_forward,
                      enabled: _sceneIndex < _scenes.length - 1,
                      onTap: () => _goToScene(_sceneIndex + 1),
                    ),
                  ],
                ),
              )
            else
              Positioned(
                bottom: 12,
                right: 12,
                child: _hintChip('اسحب للتدوير • قرصة للتكبير'),
              ),
          ],
        ],
      ),
    );
  }

  String _sceneCounterLabel() {
    return '${_sceneLabel(_sceneIndex)} — ${_sceneIndex + 1}/${_scenes.length}';
  }

  Widget _modeChip(String mode) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: () => _applyMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? gold : bgDark.withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gold.withOpacity(0.4)),
        ),
        child: Text(
          mode,
          style: GoogleFonts.cairo(
            color: active ? bgDark : gold,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? gold : textMuted.withOpacity(0.2),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 8),
          ],
        ),
        child: Icon(icon, color: enabled ? bgDark : textMuted, size: 22),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.view_in_ar, color: textMuted, size: 40),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _error = null;
                _loaded = false;
              });
              _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'إعادة المحاولة',
                style: GoogleFonts.cairo(
                  color: bgDark,
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

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgDark.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.4)),
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
        color: bgDark.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.cairo(color: textLight, fontSize: 10),
      ),
    );
  }
}
