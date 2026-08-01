import 'dart:async';

import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart';

const Color _bgDark = Color(0xFF020617);
const Color _gold = Color(0xFFD4AF37);
const Color _cardDark = Color(0xFF0F172A);
const Color _textLight = Color(0xFFF8FAFC);

class ArPreviewScreen extends StatefulWidget {
  const ArPreviewScreen({super.key, this.title = ''});

  final String title;

  @override
  State<ArPreviewScreen> createState() => _ArPreviewScreenState();
}

class _ArPreviewScreenState extends State<ArPreviewScreen>
    with SingleTickerProviderStateMixin {
  ARSessionManager? _sessionManager;
  ARObjectManager? _objectManager;
  ARAnchorManager? _anchorManager;

  ARAnchor? _currentAnchor;
  ARNode? _currentRoom;
  bool _showingRoomA = true;
  bool _busy = false;
  String _status = 'وجّه الكاميرا نحو الأرضية المسطحة';

  late final AnimationController _fadeController;
  late final Animation<double> _fadeOpacity;

  static const String _roomAModel = 'assets/ar_models/roomA.gltf';
  static const String _roomBModel = 'assets/ar_models/roomB.gltf';

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _fadeOpacity = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _sessionManager?.dispose();
    super.dispose();
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _sessionManager = sessionManager;
    _objectManager = objectManager;
    _anchorManager = anchorManager;

    _sessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
    );
    _objectManager!.onInitialize();
    _sessionManager!.onPlaneOrPointTap = _onPlaneOrPointTapped;
  }

  Future<void> _onPlaneOrPointTapped(List<ARHitTestResult> hits) async {
    if (hits.isEmpty || _busy) return;

    ARHitTestResult? planeHit;
    for (final h in hits) {
      if (h.type == ARHitTestResultType.plane) {
        planeHit = h;
        break;
      }
    }
    if (planeHit == null) return;

    setState(() => _busy = true);

    if (_currentAnchor == null) {
      // Unity: PlaceRoom(pose, roomA)
      await _placeRoom(planeHit.worldTransform, _roomAModel);
      setState(() {
        _showingRoomA = true;
        _status = 'تم وضع غرفة المعيشة — اضغط على الأرضية للتبديل إلى غرفة النوم';
      });
    } else {
      // Unity: TransitionRoom(pose, switchToB ? roomB : roomA)
      final next = _showingRoomA ? _roomBModel : _roomAModel;
      await _transitionRoom(planeHit.worldTransform, next);
      setState(() {
        _showingRoomA = !_showingRoomA;
        _status = _showingRoomA
            ? 'غرفة المعيشة — اضغط للتبديل إلى غرفة النوم'
            : 'غرفة النوم — اضغط للتبديل إلى غرفة المعيشة';
      });
    }

    if (mounted) setState(() => _busy = false);
  }

  Future<void> _placeRoom(Matrix4 transform, String model) async {
    final anchor = ARPlaneAnchor(transformation: transform);
    final added = await _anchorManager!.addAnchor(anchor);
    if (added != true) return;

    _currentAnchor = anchor;
    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: model,
      scale: Vector3(0.8, 0.8, 0.8),
      position: Vector3.zero(),
    );
    final nodeAdded = await _objectManager!.addNode(node, planeAnchor: anchor);
    if (nodeAdded == true) {
      _currentRoom = node;
    }
  }

  Future<void> _transitionRoom(Matrix4 transform, String nextModel) async {
    // Fade in
    await _fadeController.animateTo(1.0);

    // Remove old room + anchor
    if (_currentRoom != null) {
      await _objectManager!.removeNode(_currentRoom!);
      _currentRoom = null;
    }
    if (_currentAnchor != null) {
      await _anchorManager!.removeAnchor(_currentAnchor!);
      _currentAnchor = null;
    }

    // Place new room at the new pose
    await _placeRoom(transform, nextModel);

    // Fade out
    _fadeController.value = 0.0;
  }

  Future<void> _reset() async {
    if (_busy) return;
    setState(() => _busy = true);
    if (_currentRoom != null) {
      await _objectManager?.removeNode(_currentRoom!);
      _currentRoom = null;
    }
    if (_currentAnchor != null) {
      await _anchorManager?.removeAnchor(_currentAnchor!);
      _currentAnchor = null;
    }
    _showingRoomA = true;
    if (mounted) {
      setState(() {
        _status = 'وجّه الكاميرا نحو الأرضية المسطحة';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal,
          ),
          FadeTransition(
            opacity: _fadeOpacity,
            child: Container(color: _bgDark),
          ),
          _buildTopBar(),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Material(
                color: _bgDark.withOpacity(0.75),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_forward, color: _textLight, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _bgDark.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _gold.withOpacity(0.3)),
                  ),
                  child: Text(
                    widget.title.isEmpty ? 'معاينة AR' : widget.title,
                    style: GoogleFonts.cairo(
                      color: _textLight,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: _bgDark.withOpacity(0.75),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _reset,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.restart_alt, color: _gold, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final roomLabel = _showingRoomA ? 'غرفة المعيشة 🏠' : 'غرفة النوم 🛏️';
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardDark.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _gold.withOpacity(0.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.touch_app, color: _gold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _status,
                        style: GoogleFonts.cairo(
                          color: _textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _gold.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _showingRoomA ? _gold : const Color(0xFF3D7BFF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'الغرفة الحالية: $roomLabel',
                        style: GoogleFonts.cairo(
                          color: _gold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
