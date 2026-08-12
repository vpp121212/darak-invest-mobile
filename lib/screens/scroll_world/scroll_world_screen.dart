import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/property.dart';
import '../../providers/properties_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';

/// Immersive multi-mode real-estate exploration system (Immersive Real
/// Estate Diorama) on the royal Emerald + Gold identity.
///
/// Three smoothly switchable viewing modes:
/// 1. **Cinematic Diorama** — the scroll-world carousel with multi-layer
///    parallax + ken-burns zoom and a dark cinematic gradient.
/// 2. **Smart Split-Screen Comparison** — glassmorphic cards comparing
///    area, price and ROI side by side.
/// 3. **Interactive HUD** — ROI gauge with actionable buttons
///    (virtual 360° tour, book a viewing).
@RoutePage()
class ScrollWorldScreen extends ConsumerStatefulWidget {
  const ScrollWorldScreen({super.key});

  @override
  ConsumerState<ScrollWorldScreen> createState() => _ScrollWorldScreenState();
}

enum _DioramaMode { diorama, compare, hud }

class _DioramaProperty {
  const _DioramaProperty({
    required this.title,
    required this.neighborhood,
    required this.type,
    required this.priceValue,
    required this.priceLabel,
    required this.areaValue,
    required this.areaLabel,
    required this.roi,
    required this.monthlyIncome,
    required this.rooms,
    required this.baths,
    required this.year,
    required this.image,
    required this.tag,
    required this.lat,
    required this.lng,
    this.source,
  });

  final String title;
  final String neighborhood;
  final String type;
  final double priceValue;
  final String priceLabel;
  final double areaValue;
  final String areaLabel;
  final double roi;
  final double monthlyIncome;
  final int rooms;
  final int baths;
  final int year;
  final String image;
  final String tag;
  final double lat;
  final double lng;

  /// The live property this entry came from (null for built-in showcase).
  final Property? source;

  double get pricePerMeter => areaValue > 0 ? priceValue / areaValue : 0;

  /// Bridges a live property into the diorama card shape.
  ///
  /// The ROI / expected monthly income are deterministic estimates derived
  /// from the property's trust score — a placeholder until per-property
  /// rental data is available.
  factory _DioramaProperty.fromProperty(Property p) {
    final capRate = 5.5 + (p.trust % 6) * 0.5;
    return _DioramaProperty(
      title: p.title,
      neighborhood: p.loc,
      type: p.type,
      priceValue: p.price,
      priceLabel: p.formattedPrice,
      areaValue: p.area,
      areaLabel: p.area > 0 ? '${p.area.toStringAsFixed(0)} م²' : '—',
      roi: double.parse(capRate.toStringAsFixed(1)),
      monthlyIncome: p.price * capRate / 100 / 12,
      rooms: p.rooms,
      baths: p.baths,
      year: p.year,
      image: p.mainImage,
      tag: _dioramaTag(p),
      lat: p.lat,
      lng: p.lng,
      source: p,
    );
  }

  static String _dioramaTag(Property p) {
    if (p.features.isNotEmpty) return p.features.first;
    if (p.desc.trim().isNotEmpty) return p.desc.trim();
    return 'عرض موثوق';
  }

  /// Returns the live [Property] when available so detail / booking flows keep
  /// the real object, otherwise a bridge built from the showcase entry.
  Property toProperty() => source ?? _bridgeProperty();

  Property _bridgeProperty() {
    return Property(
      id: 'diorama-$title',
      title: title,
      type: type,
      loc: neighborhood,
      district: neighborhood.replaceAll('حي ', '').split('،').first,
      city: 'الرياض',
      price: priceValue,
      rooms: rooms,
      baths: baths,
      cars: 2,
      area: areaValue,
      year: year,
      age: math.max(0, DateTime.now().year - year),
      status: 'active',
      lat: lat,
      lng: lng,
      street: '',
      streetW: 0,
      facing: 'شمالي',
      purpose: 'بيع',
      desc: tag,
      images: [image],
      features: const ['تشطيب فاخر', 'إطلالة مميزة', 'موقع استراتيجي'],
      trust: 92,
      isDemo: true,
    );
  }
}

const _dioramaProperties = <_DioramaProperty>[
  _DioramaProperty(
    title: 'فيلا العقيق الفاخرة',
    neighborhood: 'حي العقيق، الرياض',
    type: 'فيلا',
    priceValue: 1850000,
    priceLabel: '1,850,000 ر.س',
    areaValue: 450,
    areaLabel: '450 م²',
    roi: 7.2,
    monthlyIncome: 11100,
    rooms: 6,
    baths: 5,
    year: 2022,
    image:
        'assets/images/prop_villa_pool.jpg',
    tag: 'تجربة ثلاثية الأبعاد سلسة',
    lat: 24.7628,
    lng: 46.6324,
  ),
  _DioramaProperty(
    title: 'شقة الياسمين الذكية',
    neighborhood: 'حي الياسمين، الرياض',
    type: 'شقة',
    priceValue: 680000,
    priceLabel: '680,000 ر.س',
    areaValue: 180,
    areaLabel: '180 م²',
    roi: 9.8,
    monthlyIncome: 5550,
    rooms: 3,
    baths: 2,
    year: 2021,
    image:
        'assets/images/prop_apartment.jpg',
    tag: 'إطلالة بانورامية ذكية',
    lat: 24.7743,
    lng: 46.739,
  ),
  _DioramaProperty(
    title: 'تاون هاوس النرجس',
    neighborhood: 'حي النرجس، الرياض',
    type: 'تاون هاوس',
    priceValue: 1250000,
    priceLabel: '1,250,000 ر.س',
    areaValue: 320,
    areaLabel: '320 م²',
    roi: 8.4,
    monthlyIncome: 8750,
    rooms: 5,
    baths: 4,
    year: 2020,
    image:
        'assets/images/prop_villa_modern.jpg',
    tag: 'تصميم مودرن متكامل',
    lat: 24.861,
    lng: 46.7128,
  ),
];

class _ScrollWorldScreenState extends ConsumerState<ScrollWorldScreen> {
  int _current = 0;
  _DioramaMode _mode = _DioramaMode.diorama;

  /// The active diorama list — real server properties when available,
  /// otherwise the built-in showcase (offline/demo fallback).
  List<_DioramaProperty> _properties = _dioramaProperties;

  _DioramaProperty get _currentProperty => _properties[_current];

  void _next() {
    setState(() => _current = (_current + 1) % _properties.length);
  }

  void _prev() {
    setState(() =>
        _current = (_current - 1 + _properties.length) % _properties.length);
  }

  void _setMode(_DioramaMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(propertiesProvider);
    final live = catalogue.properties
        .map(_DioramaProperty.fromProperty)
        .toList(growable: false);
    _properties = live.isEmpty ? _dioramaProperties : live;
    if (_current >= _properties.length) {
      _current = _properties.isEmpty ? 0 : _current % _properties.length;
    }
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: _DioramaBackdrop(
              images: [for (final p in _properties) p.image],
            ),
          ),
          Positioned.fill(child: _modeContent(context)),
          _identityHeader(context),
          _modeSwitcher(context),
          _closeButton(context),
        ],
      ),
    );
  }

  /// Mode-specific overlay (diorama info / comparison / HUD).
  Widget _modeContent(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey(_mode),
        // The overlay builders return Positioned widgets that must sit directly
        // inside a Stack; the AnimatedSwitcher otherwise wraps them in a
        // FadeTransition and layout crashes with a ParentData error.
        child: Stack(
          fit: StackFit.expand,
          children: [
            switch (_mode) {
              _DioramaMode.diorama => _dioramaOverlay(context),
              _DioramaMode.compare => _compareOverlay(context),
              _DioramaMode.hud => _hudOverlay(context),
            },
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mode 1 — Cinematic Diorama
  // ---------------------------------------------------------------------------

  Widget _dioramaOverlay(BuildContext context) {
    final property = _currentProperty;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 36,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _neighborhoodBadge(property),
              const SizedBox(height: 10),
              Text(
                property.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  property.tag,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statChip(Icons.maximize, property.areaLabel),
                  const SizedBox(width: 12),
                  _statChip(
                    Icons.payments_outlined,
                    property.priceLabel,
                    highlighted: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _navControls(context),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mode 2 — Smart Split-Screen Comparison
  // ---------------------------------------------------------------------------

  Widget _compareOverlay(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      top: 0,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 130),
                    Text(
                      'مقارنة ذكية',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 10)
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'المساحة · السعر · العائد المتوقع',
                      style: GoogleFonts.cairo(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 380,
                      child: PageView(
                        controller: PageController(viewportFraction: 0.82),
                        onPageChanged: (index) {
                          if (index != _current) {
                            setState(() => _current = index);
                          }
                        },
                        children: [
                          for (final p in _dioramaProperties)
                            _compareCard(context, p),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _navControls(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _compareCard(BuildContext context, _DioramaProperty p) {
    final selected = p.title == _currentProperty.title;
    final maxPrice = _dioramaProperties
        .map((e) => e.priceValue)
        .reduce((a, b) => math.max(a, b));
    final maxArea = _dioramaProperties
        .map((e) => e.areaValue)
        .reduce((a, b) => math.max(a, b));
    final maxRoi = _dioramaProperties
        .map((e) => e.roi)
        .reduce((a, b) => math.max(a, b));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? [
                  Colors.white.withValues(alpha: 0.16),
                  Colors.white.withValues(alpha: 0.08),
                ]
              : [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.14),
          width: selected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'محدد',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFFF5D98B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.gold),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  p.neighborhood,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AppImage(
              src: p.image,
              height: 96,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                height: 96,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [BrandColors.gradientA, BrandColors.gradientB],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _compareBar(
            label: 'المساحة',
            value: p.areaValue,
            ratio: p.areaValue / maxArea,
            unit: 'م²',
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _compareBar(
            label: 'السعر',
            value: p.priceValue,
            ratio: p.priceValue / maxPrice,
            unit: 'ر.س',
            color: AppColors.gold,
            compact: true,
          ),
          const SizedBox(height: 10),
          _compareBar(
            label: 'العائد',
            value: p.roi,
            ratio: p.roi / maxRoi,
            unit: '%',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _compareBar({
    required String label,
    required num value,
    required double ratio,
    required String unit,
    required Color color,
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 11),
            ),
            Text(
              compact
                  ? '${(value / 1000).toStringAsFixed(0)} ألف $unit'
                  : '$value $unit',
              style: GoogleFonts.cairo(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: t,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mode 3 — Interactive HUD
  // ---------------------------------------------------------------------------

  Widget _hudOverlay(BuildContext context) {
    final p = _currentProperty;
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 130, left: 20, right: 20),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _roiGauge(p),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _hudStatRow(
                                  Icons.payments_outlined,
                                  'الإيجار السنوي المتوقع',
                                  '${(p.monthlyIncome * 12).toStringAsFixed(0)} ر.س',
                                  AppColors.gold,
                                ),
                                const SizedBox(height: 10),
                                _hudStatRow(
                                  Icons.percent,
                                  'العائد على الاستثمار',
                                  '${p.roi}% سنوياً',
                                  AppColors.success,
                                ),
                                const SizedBox(height: 10),
                                _hudStatRow(
                                  Icons.square_foot,
                                  'السعر للمتر المربع',
                                  '${p.pricePerMeter.toStringAsFixed(0)} ر.س/م²',
                                  AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _hudChips(p),
                      const SizedBox(height: 14),
                      _hudActions(context, p),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roiGauge(_DioramaProperty p) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (p.roi / 12.0).clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          width: 116,
          height: 116,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: t,
                strokeWidth: 9,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${p.roi.toStringAsFixed(1)}%',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFFF5D98B),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'العائد',
                      style: GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _hudStatRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(color: Colors.white60, fontSize: 11),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hudChips(_DioramaProperty p) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _hudChip(Icons.king_bed_outlined, '${p.rooms} غرف'),
        _hudChip(Icons.bathtub_outlined, '${p.baths} حمام'),
        _hudChip(Icons.calendar_today_outlined, '${p.year}'),
        _hudChip(Icons.verified_outlined, 'مباع موثوق'),
      ],
    );
  }

  Widget _hudChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _hudActions(BuildContext context, _DioramaProperty p) {
    final property = p.toProperty();
    return Row(
      children: [
        Expanded(
          child: _hudActionButton(
            icon: Icons.threesixty_rounded,
            label: 'جولة 360°',
            gradient: const [
              BrandColors.gradientA,
              BrandColors.gradientB,
            ],
            onTap: () =>
                context.pushRoute(PropertyDetailRoute(property: property)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _hudActionButton(
            icon: Icons.event_available_outlined,
            label: 'حجز معاينة',
            gradient: const [Color(0xFF34D399), Color(0xFF059669)],
            onTap: () => context.pushRoute(BookingRoute(property: property)),
          ),
        ),
      ],
    );
  }

  Widget _hudActionButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared UI
  // ---------------------------------------------------------------------------

  Widget _neighborhoodBadge(_DioramaProperty property) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, size: 14, color: AppColors.gold),
          const SizedBox(width: 4),
          Text(
            property.neighborhood,
            style: GoogleFonts.cairo(
              color: const Color(0xFFF5D98B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, {bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: highlighted ? AppColors.gold : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: highlighted ? const Color(0xFFF5D98B) : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _navButton(Icons.arrow_forward_rounded, _prev, 'العقار السابق'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '0${_current + 1} / 0${_dioramaProperties.length}',
              style: GoogleFonts.cairo(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _navButton(Icons.arrow_back_rounded, _next, 'العقار التالي'),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header / Mode switcher / Close
  // ---------------------------------------------------------------------------

  Widget _identityHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 16,
          right: 56,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF34D399), Color(0xFF10B981)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.home_rounded,
                  color: Color(0xFF065F46), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دارك وحيك',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'عالم العقارات التفاعلي',
                  style: GoogleFonts.cairo(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Material(
              color: Colors.white.withValues(alpha: 0.08),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () =>
                    ref.read(propertiesProvider.notifier).load(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeSwitcher(BuildContext context) {
    const labels = <_DioramaMode, (IconData, String)>{
      _DioramaMode.diorama: (Icons.movie_filter_outlined, 'سينمائي'),
      _DioramaMode.compare: (Icons.compare_arrows, 'مقارنة'),
      _DioramaMode.hud: (Icons.speed_rounded, 'HUD'),
    };
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 76,
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in labels.entries) ...[
                if (entry.key != labels.keys.first)
                  Container(width: 1, height: 22, color: Colors.white12),
                _modeTab(
                  entry.key,
                  entry.value.$1,
                  entry.value.$2,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTab(_DioramaMode mode, IconData icon, String label) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => _setMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [BrandColors.gradientA, BrandColors.gradientB],
                )
              : null,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: selected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _closeButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      right: 16,
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.pop(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.close_rounded, color: textLight, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Cinematic backdrop for the diorama: a smooth code-rendered Ken Burns
/// crossfade reel over the showcase images. Rendered in Flutter (not video)
/// so the motion is perfectly smooth — no decoder jitter, no upscale shimmer
/// — with a slow continuous zoom/pan and soft image-to-image dissolves.
class _DioramaBackdrop extends StatelessWidget {
  const _DioramaBackdrop({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _CinematicBackdrop(images: images),
        const _BackdropOverlays(),
      ],
    );
  }
}

/// Smooth Ken Burns crossfade reel.
///
/// Two image layers share the *same* continuous transform (slow sinusoidal
/// zoom + pan, rounded to whole pixels to avoid subpixel shimmer) while the
/// opacity crossfades linearly between consecutive frames. Because both layers
/// move identically, the dissolve is seamless and the combined transform never
/// jumps — the whole loop is a single continuous camera move.
class _CinematicBackdrop extends StatefulWidget {
  const _CinematicBackdrop({required this.images});

  final List<String> images;

  @override
  State<_CinematicBackdrop> createState() => _CinematicBackdropState();
}

class _CinematicBackdropState extends State<_CinematicBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _layer(String src, double opacity) {
    return Opacity(
      opacity: opacity,
      child: AppImage(
        src: src,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [BrandColors.gradientA, BrandColors.gradientB],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.home_work_outlined,
              color: Colors.white, size: 56),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final n = images.length;
        final t = _controller.value * n;
        final from = t.floor() % n;
        final to = (t.floor() + 1) % n;
        final u = t - t.floor();

        // One shared, continuous camera move for both layers.
        final w = _controller.value * 2 * math.pi * 2;
        final zoom = 1.03 + 0.10 * ((math.sin(w) + 1) / 2);
        final panX = math.sin(w) * 10.0;
        final panY = math.cos(w) * 6.0;

        return Transform.scale(
          scale: zoom,
          child: Transform.translate(
            offset: Offset(panX.roundToDouble(), panY.roundToDouble()),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _layer(images[from], 1 - u),
                _layer(images[to], u),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Cinematic vignette + bottom gradient + royal gold/emerald ambient glows.
class _BackdropOverlays extends StatelessWidget {
  const _BackdropOverlays();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black54,
                Colors.black26,
                Colors.transparent,
                Colors.transparent,
                Colors.black54,
                Colors.black87,
              ],
              stops: [0.0, 0.18, 0.4, 0.62, 0.85, 1.0],
            ),
          ),
        ),
        Positioned(
          right: -80,
          top: -60,
          child: _OverlayGlow(
            color: AppColors.gold.withValues(alpha: 0.14),
            size: 240,
          ),
        ),
        Positioned(
          left: -70,
          bottom: -50,
          child: _OverlayGlow(
            color: AppColors.primary.withValues(alpha: 0.16),
            size: 220,
          ),
        ),
      ],
    );
  }
}

class _OverlayGlow extends StatelessWidget {
  const _OverlayGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}
