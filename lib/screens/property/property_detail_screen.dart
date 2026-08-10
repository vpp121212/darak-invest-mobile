import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/messages_provider.dart';
import '../../providers/properties_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dollhouse_viewer.dart';
import '../../widgets/property_card.dart';
import '../../widgets/virtual_tour_viewer.dart';

@RoutePage()
class PropertyDetailScreen extends ConsumerStatefulWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  int _currentImage = 0;

  Property get _property => widget.property;

  List<String> get _images {
    if (_property.images.isNotEmpty) return _property.images;
    if (_property.mainImage.isNotEmpty) return [_property.mainImage];
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final similar = ref
        .watch(propertiesProvider)
        .properties
        .where((p) =>
            p.id != _property.id &&
            p.purpose == _property.purpose &&
            p.city == _property.city)
        .take(6)
        .toList();

    final topInset = MediaQuery.paddingOf(context).top;
    final isFav = ref.watch(favoritesProvider).contains(_property.id);

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // صورة العقار العلمية — تمتد خلف الورقة القابلة للسحب.
          Positioned.fill(
            child: RepaintBoundary(child: _buildImageLayer()),
          ),
          // زر العودة
          Positioned(
            top: topInset + 12,
            right: 16,
            child: _buildRoundIconButton(
              icon: Icons.arrow_forward,
              onTap: () => context.pop(),
            ),
          ),
          // المفضلة والمشاركة
          Positioned(
            top: topInset + 12,
            left: 16,
            child: Row(
              children: [
                _buildRoundIconButton(
                  icon: isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? const Color(0xFFE50914) : Colors.white,
                  onTap: () =>
                      ref.read(favoritesProvider.notifier).toggle(_property.id),
                ),
                const SizedBox(width: 10),
                _buildRoundIconButton(
                  icon: Icons.share,
                  onTap: _share,
                ),
              ],
            ),
          ),
          // محتوى التفاصيل — ورقة قابلة للسحب
          DraggableScrollableSheet(
            initialChildSize: 0.62,
            minChildSize: 0.5,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF141416),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  children: [
                    _buildDragHandle(),
                    const SizedBox(height: 8),
                    _buildTitleAndPrice(),
                    const Divider(color: Colors.white24, height: 32),
                    _buildDescription(),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    if (_property.panoramicImage.isNotEmpty ||
                        _property.panoramicImages.isNotEmpty) ...[
                      _buildVirtualTour(),
                      const SizedBox(height: 20),
                    ],
                    if (_property.model3dUrl.isNotEmpty ||
                        _property.model3dUrls.isNotEmpty) ...[
                      _buildDollhouse(),
                      const SizedBox(height: 20),
                    ],
                    _buildAiTools(),
                    const SizedBox(height: 20),
                    if (_property.features.isNotEmpty) ...[
                      _buildFeatures(),
                      const SizedBox(height: 20),
                    ],
                    _buildMapSection(),
                    const SizedBox(height: 20),
                    if (_property.agent != null) ...[
                      _buildAgentCard(),
                      const SizedBox(height: 20),
                    ],
                    if (similar.isNotEmpty) ...[
                      _buildSimilarProperties(similar),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: textMuted.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scrim.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: glassBorder),
        ),
        child: Icon(icon, color: color ?? Colors.white),
      ),
    );
  }

  Widget _buildImageLayer() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: _images.length,
            onPageChanged: (i) => setState(() => _currentImage = i),
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: _images[index],
                fit: BoxFit.cover,
                memCacheWidth: 1600,
                placeholder: (c, _) => Container(
                    color: cardDark,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2))),
                errorWidget: (c, _, __) => Container(
                  color: cardDark,
                  child:  Icon(Icons.home, size: 60, color: textMuted),
                ),
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_images.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentImage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImage == index
                        ? primary
                        : textMuted.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: scrim.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_currentImage + 1} / ${_images.length}',
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleAndPrice() {
    final isRent = _property.purpose == 'إيجار';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _property.title,
                style: GoogleFonts.cairo(
                    color: textLight,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isRent ? cyan : primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Color(0x66E50914), blurRadius: 10),
                ],
              ),
              child: Text(
                _property.purpose,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
             Icon(Icons.location_on, size: 18, color: gold),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${_property.district}، ${_property.city}',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
              ),
            ),
            if (_property.trust > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('موثّق ${_property.trust}%',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '${Formatters.number(_property.price)} ر.س${isRent ? '/شهر' : ''}',
                style: GoogleFonts.cairo(
                    color: primary, fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                Text(
                  ' $_ratingLabel',
                  style: GoogleFonts.cairo(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String get _ratingLabel {
    final score = (_property.trust / 20).clamp(0, 5).toDouble();
    return score.toStringAsFixed(1);
  }

  Widget _buildStatsGrid() {
    final stats = <(IconData, String, String)>[
      (Icons.straighten, 'المساحة', '${Formatters.number(_property.area)} م²'),
      (Icons.king_bed_outlined, 'الغرف', '${_property.rooms} غرف'),
      (Icons.bathtub_outlined, 'الحمامات', '${_property.baths} حمام'),
      (Icons.garage_outlined, 'المواقف', '${_property.cars} مواقف'),
      (Icons.home_outlined, 'النوع', _property.type),
      (Icons.explore_outlined, 'الواجهة', _property.facing),
      (
        Icons.calendar_today_outlined,
        'سنة البناء',
        _property.year > 0 ? '${_property.year}' : '-'
      ),
      (Icons.route_outlined, 'العرض', '${_property.streetW} م'),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: stats.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: glassFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: glassBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(s.$1, color: gold, size: 22),
              const SizedBox(height: 8),
              Text(
                s.$3,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                    color: textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(s.$2,
                  style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVirtualTour() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             Icon(Icons.threesixty, color: gold, size: 20),
            const SizedBox(width: 6),
            Text(
              'جولة 360°',
              style: GoogleFonts.cairo(
                color: textLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              'بانوراما تفاعلية',
              style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        VirtualTourViewer(
          imageUrl: _property.panoramicImage,
          scenes: _property.panoramicImages.isNotEmpty
              ? _property.panoramicImages
              : (_property.panoramicImage.isNotEmpty
                  ? <String>[_property.panoramicImage]
                  : null),
          title: _property.title,
        ),
      ],
    );
  }

  Widget _buildDollhouse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             Icon(Icons.view_in_ar, color: gold, size: 20),
            const SizedBox(width: 6),
            Text(
              'بيت الدمية ثلاثي الأبعاد',
              style: GoogleFonts.cairo(
                color: textLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              'نموذج تفاعلي',
              style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DollhouseViewer(
          modelUrl: _property.model3dUrl,
          scenes: _property.model3dUrls.isNotEmpty
              ? _property.model3dUrls
              : (_property.model3dUrl.isNotEmpty
                  ? <String>[_property.model3dUrl]
                  : null),
        ),
      ],
    );
  }

  Widget _buildAiTools() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Icon(Icons.auto_awesome, color: gold, size: 18),
              const SizedBox(width: 6),
              Text('أدوات الذكاء',
                  style: GoogleFonts.cairo(
                      color: gold, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAiToolButton(
                  icon: Icons.calculate_outlined,
                  label: 'تقدير السعر',
                  onTap: () =>
                      context.pushRoute(EstimateRoute(property: _property)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAiToolButton(
                  icon: Icons.location_city,
                  label: 'نبض الحي',
                  onTap: () => context
                      .pushRoute(PulseRoute(district: _property.district)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAiToolButton(
                  icon: Icons.trending_up,
                  label: 'حاسبة ROI',
                  onTap: () => context.pushRoute(RoiRoute(property: _property)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: gold.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: gold, size: 22),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    color: textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المميزات',
            style: GoogleFonts.cairo(
                color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _property.features
              .map((f) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: glassFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gold.withValues(alpha: 0.35)),
                    ),
                    child: Text(f,
                        style: GoogleFonts.cairo(color: gold, fontSize: 13)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    final desc = _property.desc.isNotEmpty
        ? _property.desc
        : 'عقار مميز في حي ${_property.district} بمدينة ${_property.city}. مساحة ${Formatters.number(_property.area)} م² مع ${_property.rooms} غرف و${_property.baths} حمامات. موقع استراتيجي قريب من جميع الخدمات والمرافق الحيوية.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الوصف',
            style: GoogleFonts.cairo(
                color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          desc,
          style: GoogleFonts.cairo(color: textMuted, fontSize: 15, height: 1.8),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    final hasCoords = _property.lat != 0 || _property.lng != 0;
    final center = LatLng(hasCoords ? _property.lat : 24.7136,
        hasCoords ? _property.lng : 46.6753);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             Icon(Icons.map_outlined, color: gold, size: 20),
             SizedBox(width: 6),
            Text('الموقع على الخريطة',
                style: GoogleFonts.cairo(
                    color: textLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            GestureDetector(
              onTap: () =>
                  context.pushRoute(MapRoute(initialProperty: _property)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('الخريطة الكاملة',
                    style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.darakwaheyk.mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 220,
                          height: 92,
                          alignment: Alignment.bottomCenter,
                          child: _buildAdLabel(_property),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 8,
                  bottom: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scrim.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '© OpenStreetMap © CARTO',
                      style: GoogleFonts.cairo(color: textMuted, fontSize: 9),
                    ),
                  ),
                ),
                if (!hasCoords)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scrim.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: gold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           Icon(Icons.info_outline, size: 12, color: gold),
                           SizedBox(width: 4),
                          Text('موقع تقريبي',
                              style: GoogleFonts.cairo(
                                  color: gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_property.district}، ${_property.city} — ${_property.street.isNotEmpty ? _property.street : 'الموقع على الخريطة'}',
          style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
        ),
      ],
    );
  }

  /// Marker bubble showing the ad name (عنوان الإعلان) above the pin.
  Widget _buildAdLabel(Property p) {
    final isRent = p.purpose == 'إيجار';
    final color = isRent ? cyan : primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          constraints: const BoxConstraints(maxWidth: 200),
          decoration: BoxDecoration(
            color: const Color(0xF0222225),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1.2),
            boxShadow: softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                    color: textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                '${p.district}، ${p.city}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(color: textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 12)
            ],
          ),
          child: Icon(
            isRent ? Icons.real_estate_agent : Icons.home_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildAgentCard() {
    final agent = _property.agent!;
    final hasPhone = agent.phone.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الوكيل العقاري',
              style: GoogleFonts.cairo(
                  color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: gold.withValues(alpha: 0.2),
                child: Text(
                  agent.name.isNotEmpty ? agent.name.substring(0, 1) : '؟',
                  style: GoogleFonts.cairo(
                      color: gold, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name.isNotEmpty ? agent.name : 'وكيل دارك وحيك',
                      style: GoogleFonts.cairo(
                          color: textLight,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text('وكيل عقاري معتمد',
                        style:
                            GoogleFonts.cairo(color: textMuted, fontSize: 13)),
                  ],
                ),
              ),
              if (_property.trust > 50)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('موثق',
                          style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          if (hasPhone) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAgentButton(
                    icon: Icons.phone,
                    label: 'اتصال',
                    color: const Color(0xFF059669),
                    onTap: () => _call(agent.phone),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildAgentButton(
                    icon: Icons.chat,
                    label: 'واتساب',
                    color: const Color(0xFF25D366),
                    onTap: () => _whatsapp(agent.phone),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.cairo(
                    color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarProperties(List<Property> similar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('عقارات مشابهة',
            style: GoogleFonts.cairo(
                color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 256,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = similar[index];
              return SizedBox(
                  width: 240,
                  child: PropertyCard(
                    property: p,
                    compact: true,
                    onTap: () => _openSimilar(p),
                  ));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    final agent = _property.agent;
    final hasPhone = agent != null && agent.phone.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xF00A0A0A),
        border:
            Border(top: BorderSide(color: textMuted.withValues(alpha: 0.15))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    context.pushRoute(BookingRoute(property: _property)),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: glassFill,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: gold.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Icon(Icons.calendar_month, color: gold, size: 18),
                       SizedBox(width: 6),
                      Text(
                        'حجز موعد',
                        style: GoogleFonts.cairo(
                            color: gold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => context.pushRoute(OfferRoute(property: _property)),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient:  LinearGradient(colors: brandGradient),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x66E50914),
                          blurRadius: 16,
                          offset: Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.handshake_outlined,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'عرض شراء',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasPhone) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _whatsapp(agent.phone),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: glassFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF25D366).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.chat,
                      color: Color(0xFF25D366), size: 24),
                ),
              ),
            ],
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _messageAgent(),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: glassFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: gold.withValues(alpha: 0.6)),
                ),
                child:  Icon(Icons.mail_outline, color: gold, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSimilar(Property p) {
    context.pushRoute(PropertyDetailRoute(property: p));
  }

  Future<void> _share() async {
    final text =
        '${_property.title} — ${Formatters.number(_property.price)} ر.س — ${_property.district}، ${_property.city}';
    await Share.share(text);
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri)) {
      _showMessage('تعذّر فتح الاتصال');
    }
  }

  Future<void> _whatsapp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('تعذّر فتح واتساب');
    }
  }

  Future<void> _messageAgent() async {
    final agent = _property.agent;
    final auth = ref.read(authProvider);
    if (agent == null) {
      _showMessage('لا يوجد وسيط لهذا العقار');
      return;
    }
    if (!auth.isLoggedIn) {
      context.pushRoute(const LoginRoute());
      return;
    }
    final conversationId = await ref
        .read(messagesProvider.notifier)
        .startConversation(userId: agent.id, propertyId: _property.id);
    if (conversationId == null) {
      _showMessage('تعذّر بدء المحادثة');
      return;
    }
    if (!mounted) return;
    context.pushRoute(ChatRoute(conversationId: conversationId));
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.cairo())));
  }
}
