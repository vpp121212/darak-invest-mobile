import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/neighborhoods_data.dart';
import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/properties_provider.dart';
import '../../providers/tab_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ken_burns_image.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _purpose = 'الكل';
  String? _selectedType;
  final List<String> _purposes = ['الكل', 'بيع', 'إيجار'];

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
      _headerBar(),
      _searchBar(),
      _dioramaBanner(),
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
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical &&
            notification.metrics.extentAfter < 800) {
          ref.read(propertiesProvider.notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...slivers,
          SliverToBoxAdapter(
            child: _buildSectionTitle(
              'التصنيفات',
              onSeeAll: () => context.pushRoute(const SearchRoute()),
            ),
          ),
          _buildCategoryChips(),
          _buildPurposeTabs(),
          if (catalogue.error != null) ...[
            _buildOfflineBanner(catalogue.error!),
          ],
          SliverToBoxAdapter(
            child: _buildHeader('أحدث العقارات', filtered.length,
                onSeeAll: () => context.pushRoute(const SearchRoute())),
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
                      final p = filtered[index];
                      return _HeroCard(
                        property: p,
                        isFavorite: favorites.contains(p.id),
                        onTap: () => _openDetail(p),
                        onFavorite: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(p.id),
                      );
                    },
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
          if (catalogue.isLoadingMore)
             SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
            )
          else if (catalogue.hasMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () =>
                        ref.read(propertiesProvider.notifier).loadMore(),
                    icon:  Icon(Icons.expand_more, color: primary),
                    label: Text(
                      'عرض المزيد',
                      style: GoogleFonts.cairo(
                          color: primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(child: _buildAiToolsGrid()),
          SliverToBoxAdapter(child: _buildNeighborhoodsRail()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _headerBar() {
    final auth = ref.watch(authProvider);
    final name = (auth.user?.name ?? '').trim();
    final initial = name.isNotEmpty ? String.fromCharCode(name.runes.first) : 'ز';
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => ref.read(activeTabProvider.notifier).state = 4,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: softShadow,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.cairo(
                        color: onBrand,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دارك وحيك',
                  style: GoogleFonts.cairo(
                    color: gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: brandCard.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: brandCard.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 12, color: primaryLight),
                      const SizedBox(width: 4),
                      Text(
                        'الرياض، السعودية',
                        style: GoogleFonts.cairo(
                            color: textLight, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined,
                      color: primary, size: 24),
                  onPressed: () {
                    final auth = ref.read(authProvider);
                    if (auth.isLoggedIn) {
                      ref.read(notificationsProvider.notifier).load();
                    }
                    context.pushRoute(const NotificationsRoute());
                  },
                ),
                if (ref.watch(notificationsProvider).unreadCount > 0)
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: bgDark, width: 2),
                      ),
                      child: Text(
                        '${ref.watch(notificationsProvider).unreadCount}',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: GestureDetector(
          onTap: () => context.pushRoute(const SearchRoute()),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: primarySoft,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: primary.withValues(alpha: 0.45)),
              boxShadow: softShadow,
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                 Icon(Icons.search, color: primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ابحث عن عقارك المثالي...',
                    style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration:  BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x6610B981),
                          blurRadius: 12,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dioramaBanner() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: GestureDetector(
          onTap: () => context.pushRoute(const ScrollWorldRoute()),
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: whiteCard,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  bottom: -28,
                  child: Icon(
                    Icons.holiday_village_outlined,
                    color: onWhite.withValues(alpha: 0.08),
                    size: 140,
                  ),
                ),
                Positioned(
                  left: -18,
                  top: -24,
                  child: Icon(
                    Icons.home_work_outlined,
                    color: onWhite.withValues(alpha: 0.07),
                    size: 120,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              BrandColors.gradientA,
                              BrandColors.gradientB,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4010B981),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.auto_awesome,
                            color: onBrand, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'عالم العقارات التفاعلي',
                              style: GoogleFonts.cairo(
                                color: onWhite,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'تجربة عرض سينمائية بالتمرير والتنقل بين العقارات الفاخرة',
                              style: GoogleFonts.cairo(
                                color: onWhite.withValues(alpha: 0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
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

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
                color: gold, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'عرض الكل',
                  style: GoogleFonts.cairo(
                      color: primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final all = <(String, IconData)>[
      ('الكل', Icons.grid_view_rounded),
      ('فيلا', Icons.villa_outlined),
      ('شقة', Icons.apartment_rounded),
      ('أرض', Icons.landscape_outlined),
      ('مكتب', Icons.business_outlined),
      ('دوبلكس', Icons.stairs_rounded),
      ('استوديو', Icons.king_bed_outlined),
      ('عمارة', Icons.location_city_outlined),
    ];
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: all.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final c = all[index];
            final isSelected = _selectedType == c.$1;
            return GestureDetector(
              onTap: () => setState(
                  () => _selectedType = c.$1 == 'الكل' ? null : c.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 76,
                decoration: BoxDecoration(
                  color: isSelected ? primary : primarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? primary
                        : primary.withValues(alpha: 0.35),
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                              color: Color(0x6610B981), blurRadius: 14)
                        ]
                      : softShadow,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      c.$2,
                      size: 24,
                      color: isSelected ? onBrand : primary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.$1,
                      style: GoogleFonts.cairo(
                        color: isSelected ? onBrand : textLight,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPurposeTabs() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: primarySoft,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: primary.withValues(alpha: 0.35)),
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
                          ? const [
                              BoxShadow(color: Color(0x6610B981), blurRadius: 12)
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        purpose,
                        style: GoogleFonts.cairo(
                          color: isSelected ? onBrand : textMuted,
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
      ),
    );
  }

  Widget _buildOfflineBanner(String error) {
    return SliverToBoxAdapter(
      child: Padding(
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
               Icon(Icons.cloud_off, color: red, size: 18),
               SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تعذّر تحديث البيانات — تعرض نسخة محفوظة/تجريبية',
                  style: GoogleFonts.cairo(color: red, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, int count, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
                color: gold, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      'عرض الكل',
                      style: GoogleFonts.cairo(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primarySoft,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text('$count عقار',
                    style: GoogleFonts.cairo(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiToolsGrid() {
    final tools = <(String, IconData, VoidCallback)>[
      ('الخريطة', Icons.map_outlined, () => context.pushRoute(MapRoute())),
      ('نبض الحي', Icons.location_city, () => context.pushRoute(PulseRoute())),
      (
        'تقدير السعر',
        Icons.calculate_outlined,
        () => context.pushRoute(EstimateRoute())
      ),
      ('حاسبة ROI', Icons.trending_up, () => context.pushRoute(RoiRoute())),
      (
        'التمويل',
        Icons.payments_outlined,
        () => context.pushRoute(FinanceRoute())
      ),
      (
        'المقارنة',
        Icons.compare_arrows,
        () => context.pushRoute(const CompareRoute())
      ),
      (
        'تقرير السوق',
        Icons.insights,
        () => context.pushRoute(const MarketReportRoute())
      ),
      (
        'المفضلة',
        Icons.favorite_border,
        () => context.pushRoute(const FavoritesRoute())
      ),
      (
        'الوكلاء',
        Icons.support_agent,
        () => context.pushRoute(const AgentsRoute())
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('أدوات ذكية'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    color: brandCard,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: onBrand,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(tool.$2, color: primaryLight, size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tool.$1,
                        style: GoogleFonts.cairo(
                          color: onBrand,
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
        ),
      ],
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
                  style: GoogleFonts.cairo(
                      color: gold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
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
                  onTap: () => context
                      .pushRoute(NeighborhoodDetailRoute(district: n.name)),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primarySoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: primary.withValues(alpha: 0.35)),
                      boxShadow: softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                             Icon(Icons.location_city,
                                color: primary, size: 18),
                             Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
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
                          style: GoogleFonts.cairo(
                              color: textLight,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'من ${Formatters.compactPrice(n.avgPrice)}',
                          style:
                              GoogleFonts.cairo(color: textMuted, fontSize: 11),
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

  List<Property> _applyFilters(List<Property> all) {
    return all.where((p) {
      if (_purpose != 'الكل' && p.purpose != _purpose) return false;
      if (_selectedType != null && p.type != _selectedType) return false;
      return true;
    }).toList();
  }

  void _openDetail(Property property) {
    context.pushRoute(PropertyDetailRoute(property: property));
  }
}

/// Large image-forward property card — the Homerch home hero.
class _HeroCard extends StatelessWidget {
  final Property property;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const _HeroCard({
    required this.property,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  String get _rating {
    final score = (property.trust / 20).clamp(0, 5).toDouble();
    return score.toStringAsFixed(1);
  }

  String get _priceLabel {
    final suffix = property.purpose == 'إيجار' ? '/شهر' : '';
    return '${Formatters.compactPrice(property.price)} ر.س$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 290,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: softShadow,
          color: cardDark,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            KenBurnsImage(
              src: property.mainImage,
              fit: BoxFit.cover,
              memCacheWidth: 900,
              phase: KenBurnsImage.phaseFor(property.title),
              placeholder: (c, _) => Container(
                color: bgDark,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (c, _, __) => Container(
                color: primarySoft,
                child:  Icon(Icons.home_rounded,
                    size: 60, color: textMuted),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 190,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xE6000000),
                      Color(0xFF000000),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x6610B981), blurRadius: 12),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _rating,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (property.isDemo)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 0.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x6610B981), blurRadius: 12),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'عرض محدود!',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 12,
              left: 12,
              child: GestureDetector(
                onTap: onFavorite,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: glassBorder),
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? red : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 48, 52, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Color(0xFFB3B3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${property.district}، ${property.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFFB3B3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w400),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          _priceLabel,
                          style: GoogleFonts.cairo(
                            color: primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        _specItem(Icons.king_bed_outlined, '${property.rooms}'),
                        const SizedBox(width: 12),
                        _specItem(Icons.bathtub_outlined, '${property.baths}'),
                        const SizedBox(width: 12),
                        _specItem(Icons.straighten, '${property.area}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.cairo(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
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
              height: 290,
              decoration: BoxDecoration(
                color: glassFill,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: glassBorder),
                boxShadow: softShadow,
              ),
              child: Center(
                child: CircularProgressIndicator(
                    color: primary.withValues(alpha: 0.4), strokeWidth: 2),
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
         Icon(Icons.cloud_off, size: 60, color: textMuted),
        const SizedBox(height: 16),
        Text(
          'تعذّر تحميل العقارات',
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
              color: textLight, fontSize: 18, fontWeight: FontWeight.bold),
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
              child: Text('إعادة المحاولة',
                  style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
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
           Icon(Icons.search_off, size: 60, color: textMuted),
          const SizedBox(height: 12),
          Text('لا توجد عقارات مطابقة',
              style: GoogleFonts.cairo(
                  color: textLight, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('جرّب تغيير الفلاتر',
              style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
