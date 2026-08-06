import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../data/neighborhoods_data.dart';
import '../../models/property.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/properties_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/property_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _purpose = 'الكل';
  String? _selectedCity;
  String? _selectedType;
  final List<String> _purposes = ['الكل', 'بيع', 'إيجار'];
  static const _cities = ['الرياض', 'جدة', 'مكة', 'الدمام', 'الخبر', 'حائل'];
  static const _types = ['فيلا', 'شقة', 'دوبلكس', 'مكتب', 'استوديو', 'أرض', 'عمارة'];

  @override
  Widget build(BuildContext context) {
    final catalogue = ref.watch(propertiesProvider);

    return Scaffold(
      backgroundColor: bgDark,
      body: RefreshIndicator(
        color: primary,
        backgroundColor: cardDark,
        onRefresh: () => ref.read(propertiesProvider.notifier).load(),
        child: _buildBody(catalogue),
      ),
    );
  }

  Widget _buildBody(PropertyCatalogueState catalogue) {
    final slivers = <Widget>[
      _brandBar(),
    ];
    if (catalogue.isLoading) {
      slivers.add(const SliverToBoxAdapter(child: _HomeSkeleton()));
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 120)));
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      );
    }
    if (catalogue.error != null && catalogue.properties.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: _HomeError(
            message: catalogue.error!,
            onRetry: () => ref.read(propertiesProvider.notifier).load(),
          ),
        ),
      );
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      );
    }

    final filtered = _applyFilters(catalogue.properties);
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        ...slivers,
        SliverToBoxAdapter(child: _buildHero()),
        SliverToBoxAdapter(child: _buildPurposeTabs()),
        SliverToBoxAdapter(child: _buildFilterRow()),
        SliverToBoxAdapter(child: _buildAiToolsGrid()),
        SliverToBoxAdapter(child: _buildNeighborhoodsRail()),
        if (catalogue.error != null) ...[
          SliverToBoxAdapter(child: _buildOfflineBanner(catalogue.error!)),
        ],
        SliverToBoxAdapter(child: _buildHeader('أحدث العقارات', catalogue.properties.length)),
        SliverToBoxAdapter(child: _InfinitePropertyLoop(properties: catalogue.properties)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'جميع العقارات',
                  style: GoogleFonts.cairo(
                    color: textLight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primarySoft,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${filtered.length} عقار',
                    style: GoogleFonts.cairo(color: primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          const SliverToBoxAdapter(child: _EmptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Consumer(
                  builder: (context, ref, _) {
                    final favorites = ref.watch(favoritesProvider);
                    return PropertyCard(
                      property: filtered[index],
                      onTap: () => _openDetail(filtered[index]),
                      onFavorite: () => ref.read(favoritesProvider.notifier).toggle(filtered[index].id),
                      isFavorite: favorites.contains(filtered[index].id),
                    );
                  },
                ),
                childCount: filtered.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _brandBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x66CCFF00), blurRadius: 14, offset: Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.home_work_rounded, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دارك وحيك',
                  style: GoogleFonts.cairo(
                    color: textLight,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'سوقك العقاري الذكي',
                  style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: glassFill,
                shape: BoxShape.circle,
                border: Border.all(color: glassBorder),
                boxShadow: softShadow,
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_outlined, color: textMuted, size: 22),
                onPressed: () => _showComingSoon('الإشعارات'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF161616), Color(0xFF1C1C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: glassBorder),
          boxShadow: const [
            BoxShadow(color: Color(0x4D000000), blurRadius: 26, offset: Offset(0, 12)),
            BoxShadow(color: Color(0x24CCFF00), blurRadius: 30),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cyan.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primarySoft,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'تطوّرك يبدأ من هنا',
                  style: GoogleFonts.cairo(color: primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    'اعثر على بيت أحلامك',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'عقارات موثّقة وأدوات ذكية لتقدير الأسعار والاستثمار',
                    style: GoogleFonts.cairo(
                      color: textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.pushRoute(const SearchRoute()),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                      decoration: BoxDecoration(
                        color: glassFill,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: glassBorder),
                        boxShadow: const [
                          BoxShadow(color: Color(0x4D000000), blurRadius: 14, offset: Offset(0, 6)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: primary, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'ابحث عن عقارك المثالي...',
                            style: GoogleFonts.cairo(color: textMuted, fontSize: 14),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: primary,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'بحث',
                              style: GoogleFonts.cairo(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurposeTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: glassFill,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: glassBorder),
          boxShadow: softShadow,
        ),
        child: Row(
          children: List.generate(_purposes.length, (index) {
            final purpose = _purposes[index];
            final isSelected = _purpose == purpose;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _purpose = purpose),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: isSelected
                        ? const [BoxShadow(color: Color(0x66CCFF00), blurRadius: 12)]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      purpose,
                      style: GoogleFonts.cairo(
                        color: isSelected ? Colors.black : textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              icon: Icons.location_city,
              label: _selectedCity ?? 'المدينة',
              onTap: () => _showPicker('اختر المدينة', _cities, (v) => setState(() => _selectedCity = v)),
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              icon: Icons.home_outlined,
              label: _selectedType ?? 'النوع',
              onTap: () => _showPicker('اختر النوع', _types, (v) => setState(() => _selectedType = v)),
            ),
            if (_selectedCity != null || _selectedType != null) ...[
              const SizedBox(width: 8),
              _buildClearFiltersChip(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: glassFill,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: glassBorder),
          boxShadow: softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: primary),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.cairo(color: textLight, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildClearFiltersChip() {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCity = null;
        _selectedType = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: red.withValues(alpha: 0.35)),
        ),
        child: Text('مسح الفلاتر', style: GoogleFonts.cairo(color: red, fontSize: 13)),
      ),
    );
  }

  void _showPicker(String title, List<String> items, ValueChanged<String> onSelected) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: textMuted, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: GoogleFonts.cairo(color: primary, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...items.map((item) => ListTile(
                title: Text(item, style: GoogleFonts.cairo(color: textLight)),
                trailing: _selectedCity == item || _selectedType == item
                    ? const Icon(Icons.check, color: primary)
                    : null,
                onTap: () {
                  onSelected(item);
                  context.pop();
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAiToolsGrid() {
    final tools = <(String, IconData, VoidCallback)>[
      ('الخريطة', Icons.map_outlined, () => context.pushRoute(MapRoute())),
      ('نبض الحي', Icons.location_city, () => context.pushRoute(PulseRoute())),
      ('تقدير السعر', Icons.calculate_outlined, () => context.pushRoute(EstimateRoute())),
      ('حاسبة ROI', Icons.trending_up, () => context.pushRoute(RoiRoute())),
      ('التمويل', Icons.payments_outlined, () => context.pushRoute(FinanceRoute())),
      ('المقارنة', Icons.compare_arrows, () => context.pushRoute(const CompareRoute())),
      ('تقرير السوق', Icons.insights, () => context.pushRoute(const MarketReportRoute())),
      ('المفضلة', Icons.favorite_border, () => context.pushRoute(const FavoritesRoute())),
      ('الوكلاء', Icons.support_agent, () => context.pushRoute(const AgentsRoute())),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tools.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return GestureDetector(
            onTap: tool.$3,
            child: Container(
              decoration: BoxDecoration(
                color: glassFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: glassBorder),
                boxShadow: softShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(tool.$2, color: Colors.black, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tool.$1,
                    style: GoogleFonts.cairo(
                      color: textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNeighborhoodsRail() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  'الأحياء',
                  style: GoogleFonts.cairo(color: textLight, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  'استكشف بالحي',
                  style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kNeighborhoods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final n = kNeighborhoods[index];
                return GestureDetector(
                  onTap: () => context.pushRoute(NeighborhoodDetailRoute(district: n.name)),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: glassFill,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: glassBorder),
                      boxShadow: softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_city, color: primary, size: 18),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primarySoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '+${n.growth}٪',
                                style: GoogleFonts.cairo(
                                  color: primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          n.name,
                          style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'من ${Formatters.compactPrice(n.avgPrice)}',
                          style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(String error) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: red, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'تعذّر تحديث البيانات — تعرض نسخة محفوظة/تجريبية',
                style: GoogleFonts.cairo(color: red, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(color: textLight, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primarySoft,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text('$count عقار', style: GoogleFonts.cairo(color: primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<Property> _applyFilters(List<Property> all) {
    return all.where((p) {
      if (_purpose != 'الكل' && p.purpose != _purpose) return false;
      if (_selectedCity != null && p.city != _selectedCity) return false;
      if (_selectedType != null && p.type != _selectedType) return false;
      return true;
    }).toList();
  }

  void _openDetail(Property property) {
    context.pushRoute(PropertyDetailRoute(property: property));
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature — قريباً', style: GoogleFonts.cairo())),
    );
  }
}

/// Seamless endless horizontal loop of property cards — scrolls continuously
/// in either direction by wrapping around a repeated set.
class _InfinitePropertyLoop extends StatefulWidget {
  final List<Property> properties;

  const _InfinitePropertyLoop({required this.properties});

  @override
  State<_InfinitePropertyLoop> createState() => _InfinitePropertyLoopState();
}

class _InfinitePropertyLoopState extends State<_InfinitePropertyLoop> {
  static const _cardWidth = 280.0;
  static const _gap = 4.0;
  static const _cycles = 200;

  late final ScrollController _controller;

  double get _cycleExtent => widget.properties.length * (_cardWidth + _gap);

  @override
  void initState() {
    super.initState();
    _controller = ScrollController(initialScrollOffset: _cycleExtent);
    _controller.addListener(_wrap);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_wrap)
      ..dispose();
    super.dispose();
  }

  void _wrap() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final total = position.maxScrollExtent;
    if (total <= 0) return;
    if (position.pixels >= total - _cycleExtent) {
      _controller.jumpTo(position.pixels - _cycleExtent);
    } else if (position.pixels < _cycleExtent) {
      _controller.jumpTo(position.pixels + _cycleExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.properties.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 360,
      child: ListView.separated(
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: widget.properties.length * _cycles,
        separatorBuilder: (_, __) => const SizedBox(width: _gap),
        itemBuilder: (context, index) {
          final p = widget.properties[index % widget.properties.length];
          return SizedBox(
            width: _cardWidth,
            child: Consumer(
              builder: (context, ref, _) {
                final favorites = ref.watch(favoritesProvider);
                return PropertyCard(
                  property: p,
                  onTap: () => context.pushRoute(PropertyDetailRoute(property: p)),
                  onFavorite: () => ref.read(favoritesProvider.notifier).toggle(p.id),
                  isFavorite: favorites.contains(p.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 280,
              decoration: BoxDecoration(
                color: glassFill,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: glassBorder),
                boxShadow: softShadow,
              ),
              child: Center(
                child: CircularProgressIndicator(color: primary.withValues(alpha: 0.4), strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HomeError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off, size: 60, color: textMuted),
        const SizedBox(height: 16),
        Text(
          'تعذّر تحميل العقارات',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 60, color: textMuted),
          const SizedBox(height: 12),
          Text('لا توجد عقارات مطابقة', style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('جرّب تغيير الفلاتر', style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
