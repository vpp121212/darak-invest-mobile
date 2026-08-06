import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/router/app_router.dart';
import '../../models/property.dart';
import '../../providers/properties_provider.dart';
import '../../theme/app_theme.dart';

/// Real interactive map (OpenStreetMap data, dark CARTO tiles) with the
/// catalogue pinned. Tapping a pin opens a mini property card.
@RoutePage()
class MapScreen extends ConsumerStatefulWidget {
  final Property? initialProperty;

  const MapScreen({super.key, this.initialProperty});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const _riyadh = LatLng(24.7136, 46.6753);

  final MapController _mapController = MapController();
  Property? _selected;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(propertiesProvider);
    var properties = catalogue.properties;
    if (properties.isEmpty && widget.initialProperty != null) {
      properties = [widget.initialProperty!];
    }

    final initial = widget.initialProperty;
    final center = initial != null
        ? LatLng(initial.lat, initial.lng)
        : _riyadh;
    final zoom = initial != null ? 13.5 : 11.0;

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: zoom,
              minZoom: 5,
              maxZoom: 18,
              backgroundColor: const Color(0xFF0A0A0A),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.darak_wa_hayk',
              ),
              MarkerLayer(
                markers: properties.map((p) => _buildMarker(p)).toList(),
              ),
            ],
          ),
          _buildTopBar(context),
          if (_selected != null) _buildBottomSheet(context, _selected!),
          Positioned(
            left: 12,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: scrim.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: glassBorder),
              ),
              child: Text(
                '© OpenStreetMap © CARTO',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 9),
              ),
            ),
          ),
          if (_selected != null)
            Positioned(
              right: 12,
              bottom: 16,
              child: _roundButton(
                icon: Icons.close,
                onTap: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
    );
  }

  Marker _buildMarker(Property p) {
    final isRent = p.purpose == 'إيجار';
    final isSelected = _selected?.id == p.id;
    final color = isRent ? cyan : primary;
    return Marker(
      point: LatLng(p.lat, p.lng),
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => setState(() => _selected = p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.black.withValues(alpha: 0.4),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: isSelected ? 16 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isRent ? Icons.real_estate_agent : Icons.home_rounded,
            color: Colors.black,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 12,
          right: 12,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            _roundButton(
              icon: Icons.arrow_forward,
              onTap: () => context.pop(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'الخريطة',
                style: GoogleFonts.cairo(
                  color: textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _roundButton(
              icon: Icons.my_location,
              onTap: () => _mapController.move(_riyadh, 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        shape: BoxShape.circle,
        border: Border.all(color: glassBorder),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: textLight, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context, Property p) {
    final isRent = p.purpose == 'إيجار';
    return Positioned(
      left: 12,
      right: 12,
      bottom: 70,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: glassFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: glassBorder),
          boxShadow: softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isRent ? cyan : primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isRent ? Icons.real_estate_agent : Icons.home_rounded,
                      color: Colors.black,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            color: textLight,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: primary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${p.district}، ${p.city}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRent ? cyan : primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      p.purpose,
                      style: GoogleFonts.cairo(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_num(p.price)} ر.س${isRent ? '/شهر' : ''}',
                    style: GoogleFonts.cairo(
                      color: primary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      context.pushRoute(PropertyDetailRoute(property: p));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'التفاصيل',
                        style: GoogleFonts.cairo(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _num(num value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
