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
import '../../providers/favorites_provider.dart';
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
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
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

    return Scaffold(
      backgroundColor: bgDark,
      body: CustomScrollView(
        slivers: [
          _buildImageGallery(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildTitleAndPrice(),
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
                  _buildDescription(),
                  const SizedBox(height: 20),
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
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildImageGallery() {
    final isFav = ref.watch(favoritesProvider).contains(_property.id);
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: bgDark,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scrim.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward, color: Colors.white),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => ref.read(favoritesProvider.notifier).toggle(_property.id),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scrim.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : Colors.white,
            ),
          ),
        ),
        GestureDetector(
          onTap: _share,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scrim.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              itemCount: _images.length,
              onPageChanged: (i) => setState(() => _currentImage = i),
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: _images[index],
                  fit: BoxFit.cover,
                  placeholder: (c, _) => Container(color: cardDark, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                  errorWidget: (c, _, __) => Container(
                    color: cardDark,
                    child: const Icon(Icons.home, size: 60, color: textMuted),
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
                      color: _currentImage == index ? gold : textMuted.withValues(alpha: 0.5),
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
                style: GoogleFonts.cairo(color: textLight, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isRent ? cyan : primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Color(0x66CCFF00), blurRadius: 10),
                ],
              ),
              child: Text(
                _property.purpose,
                style: GoogleFonts.cairo(
                  color: Colors.black,
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
            const Icon(Icons.location_on, size: 18, color: gold),
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
                    const Icon(Icons.verified, size: 14, color: Colors.black),
                    const SizedBox(width: 4),
                    Text('موثّق ${_property.trust}%', style: GoogleFonts.cairo(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${Formatters.number(_property.price)} ر.س${isRent ? '/شهر' : ''}',
          style: GoogleFonts.cairo(color: gold, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = <(IconData, String, String)>[
      (Icons.straighten, 'المساحة', '${Formatters.number(_property.area)} م²'),
      (Icons.king_bed_outlined, 'الغرف', '${_property.rooms} غرف'),
      (Icons.bathtub_outlined, 'الحمامات', '${_property.baths} حمام'),
      (Icons.garage_outlined, 'المواقف', '${_property.cars} مواقف'),
      (Icons.home_outlined, 'النوع', _property.type),
      (Icons.explore_outlined, 'الواجهة', _property.facing),
      (Icons.calendar_today_outlined, 'سنة البناء', _property.year > 0 ? '${_property.year}' : '-'),
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
                style: GoogleFonts.cairo(color: textLight, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(s.$2, style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
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
            const Icon(Icons.threesixty, color: gold, size: 20),
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
            const Icon(Icons.view_in_ar, color: gold, size: 20),
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
              const Icon(Icons.auto_awesome, color: gold, size: 18),
              const SizedBox(width: 6),
              Text('أدوات الذكاء', style: GoogleFonts.cairo(color: gold, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAiToolButton(
                  icon: Icons.calculate_outlined,
                  label: 'تقدير السعر',
                  onTap: () => context.pushRoute(EstimateRoute(property: _property)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAiToolButton(
                  icon: Icons.location_city,
                  label: 'نبض الحي',
                  onTap: () => context.pushRoute(PulseRoute(district: _property.district)),
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
            Text(label, textAlign: TextAlign.center, style: GoogleFonts.cairo(color: textLight, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المميزات', style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _property.features.map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: glassFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold.withValues(alpha: 0.35)),
                ),
                child: Text(f, style: GoogleFonts.cairo(color: gold, fontSize: 13)),
              )).toList(),
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
        Text('الوصف', style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
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
    final center = LatLng(hasCoords ? _property.lat : 24.7136, hasCoords ? _property.lng : 46.6753);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الموقع', style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.darakwaheyk.mobile',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      child: const Icon(Icons.location_pin, color: gold, size: 40),
                    ),
                  ],
                ),
              ],
            ),
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
          Text('الوكيل العقاري', style: GoogleFonts.cairo(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: gold.withValues(alpha: 0.2),
                child: Text(
                  agent.name.isNotEmpty ? agent.name.substring(0, 1) : '؟',
                  style: GoogleFonts.cairo(color: gold, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name.isNotEmpty ? agent.name : 'وكيل دارك وحيك',
                      style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text('وكيل عقاري معتمد', style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
                  ],
                ),
              ),
              if (_property.trust > 50)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 14, color: Colors.black),
                      const SizedBox(width: 4),
                      Text('موثق', style: GoogleFonts.cairo(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
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
            Text(label, style: GoogleFonts.cairo(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarProperties(List<Property> similar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('عقارات مشابهة', style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 270,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = similar[index];
              return SizedBox(width: 240, child: PropertyCard(property: p, onTap: () => _openSimilar(p)));
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
        border: Border(top: BorderSide(color: textMuted.withValues(alpha: 0.15))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (hasPhone) {
                    _call(agent.phone);
                  } else {
                    _showMessage('بيانات التواصل غير متوفرة لهذا العقار');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: brandGradient),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(color: Color(0x66CCFF00), blurRadius: 16, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'تواصل مع الوكيل',
                      style: GoogleFonts.cairo(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            if (hasPhone) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _whatsapp(agent.phone),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: glassFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 24),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openSimilar(Property p) {
    context.pushRoute(PropertyDetailRoute(property: p));
  }

  Future<void> _share() async {
    final text = '${_property.title} — ${Formatters.number(_property.price)} ر.س — ${_property.district}، ${_property.city}';
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

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.cairo())));
  }
}
