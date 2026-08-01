import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../models/property.dart';
import '../../providers/properties_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/property_card.dart';
import '../property/property_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'لوحة السوق',
          style: GoogleFonts.cairo(color: gold, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: textMuted),
            onPressed: () {},
          ),
        ],
      ),
      body: propertiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: gold)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 60, color: textMuted),
              const SizedBox(height: 12),
              Text('تعذّر تحميل بيانات السوق', style: GoogleFonts.cairo(color: textMuted, fontSize: 16)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(e.toString(), textAlign: TextAlign.center, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
              ),
            ],
          ),
        ),
        data: (properties) => _DashboardContent(properties: properties),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final List<Property> properties;

  const _DashboardContent({required this.properties});

  @override
  Widget build(BuildContext context) {
    final stats = _computeStats();
    final cheapest = [...properties]
      ..sort((a, b) => a.price.compareTo(b.price));
    final cheapestTop = cheapest.take(4).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildKpiGrid(stats),
        const SizedBox(height: 24),
        if (stats.cityStats.isNotEmpty) ...[
          _buildCityBreakdown(stats.cityStats),
          const SizedBox(height: 24),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('أفضل الأسعار', style: GoogleFonts.cairo(color: textLight, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('${properties.length} عقار', style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        ...cheapestTop.map((p) => PropertyCard(
              property: p,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p))),
            )),
        const SizedBox(height: 24),
      ],
    );
  }

  _Stats _computeStats() {
    final saleProps = properties.where((p) => p.purpose == 'بيع').toList();
    final rentProps = properties.where((p) => p.purpose == 'إيجار').toList();
    final avgSalePrice = saleProps.isNotEmpty
        ? saleProps.fold<double>(0, (sum, p) => sum + p.price.toDouble()) / saleProps.length
        : 0.0;

    final cityMap = <String, int>{};
    for (final p in properties) {
      final key = p.city.isNotEmpty ? p.city : 'غير محدد';
      cityMap[key] = (cityMap[key] ?? 0) + 1;
    }
    final cityStats = cityMap.entries.map((e) => (city: e.key, count: e.value)).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return _Stats(
      total: properties.length,
      saleCount: saleProps.length,
      rentCount: rentProps.length,
      avgSalePrice: avgSalePrice,
      cityCount: cityMap.length,
      cityStats: cityStats.take(5).toList(),
    );
  }

  Widget _buildKpiGrid(_Stats stats) {
    final kpis = <(IconData, String, String, Color)>[
      (Icons.home_work_outlined, 'إجمالي العقارات', Formatters.number(stats.total), gold),
      (Icons.sell_outlined, 'للبيع', Formatters.number(stats.saleCount), const Color(0xFF3B82F6)),
      (Icons.receipt_long_outlined, 'للإيجار', Formatters.number(stats.rentCount), const Color(0xFF10B981)),
      (Icons.attach_money, 'متوسط سعر البيع', Formatters.compactPrice(stats.avgSalePrice), const Color(0xFF8B5CF6)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.7,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) {
        final kpi = kpis[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: textMuted.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: kpi.$4.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(kpi.$1, color: kpi.$4, size: 20),
                  ),
                  const Spacer(),
                  Text(kpi.$2, style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                kpi.$3,
                style: GoogleFonts.cairo(color: textLight, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCityBreakdown(List<({String city, int count})> cityStats) {
    final maxCount = cityStats.isNotEmpty ? cityStats.first.count : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('توزيع العقارات حسب المدينة', style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: textMuted.withOpacity(0.1)),
          ),
          child: Column(
            children: cityStats.map((stat) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(stat.city, style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stat.count / maxCount,
                          minHeight: 8,
                          backgroundColor: bgDark,
                          color: gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 36,
                      child: Text('${stat.count}', textAlign: TextAlign.end, style: GoogleFonts.cairo(color: textLight, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _Stats {
  final int total;
  final int saleCount;
  final int rentCount;
  final double avgSalePrice;
  final int cityCount;
  final List<({String city, int count})> cityStats;

  const _Stats({
    required this.total,
    required this.saleCount,
    required this.rentCount,
    required this.avgSalePrice,
    required this.cityCount,
    required this.cityStats,
  });
}
