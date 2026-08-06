import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../data/neighborhoods_data.dart';
import '../../providers/properties_provider.dart';
import '../../theme/app_theme.dart';

@RoutePage()
class MarketReportScreen extends ConsumerWidget {
  const MarketReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogue = ref.watch(propertiesProvider);
    final properties = catalogue.properties;

    final stats = <String, _DistrictStats>{};
    for (final p in properties) {
      final s = stats.putIfAbsent(p.district, () => _DistrictStats(name: p.district));
      s.total++;
      s.priceSum += p.price;
      s.areaSum += p.area;
    }
    for (final s in stats.values) {
      if (s.total > 0) {
        s.avgPrice = s.priceSum / s.total;
        s.avgArea = s.areaSum / s.total;
      }
    }
    final sorted = stats.values.toList()..sort((a, b) => b.avgPrice.compareTo(a.avgPrice));
    final overallAvg = properties.isEmpty
        ? 0.0
        : properties.fold<double>(0, (sum, p) => sum + p.price) / properties.length;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        centerTitle: true,
        title: Text(
          'تقرير السوق',
          style: GoogleFonts.cairo(color: primary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryRow(properties.length, overallAvg, _topDistrict(sorted)),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'الأحياء المتاحة',
                style: GoogleFonts.cairo(color: textLight, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primarySoft,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '${sorted.length} حي',
                  style: GoogleFonts.cairo(color: primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (sorted.isEmpty) ...[
            _offlineNote(context),
            const SizedBox(height: 12),
            ...kNeighborhoods.map((n) {
              final s = _DistrictStats(name: n.name)
                ..avgPrice = n.avgPrice
                ..avgArea = 0;
              return _marketCard(n, s);
            }),
          ] else
            ...sorted.map((s) {
              final info = kNeighborhoods.where((n) => n.name == s.name).firstOrNull;
              return _marketCard(info, s);
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String? _topDistrict(List<_DistrictStats> sorted) {
    if (sorted.isEmpty) {
      final top = kNeighborhoods.reduce((a, b) => a.growth > b.growth ? a : b);
      return top.name;
    }
    return sorted.first.name;
  }

  Widget _summaryRow(int count, double avg, String? top) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1C1C), Color(0xFF262626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glassBorder),
        boxShadow: softShadow,
      ),
      child: Column(
        children: [
          Text('ملخص سوق العقارات', style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _sum('العقارات', '$count', Icons.home_work_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _sum('متوسط السعر', Formatters.compactPrice(avg), Icons.payments_outlined)),
            ],
          ),
          if (top != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _sum('أعلى حي نمواً', top, Icons.trending_up)),
                const SizedBox(width: 10),
                Expanded(child: _sum('المصدر', 'تجريبي + مباشر', Icons.cloud_sync_outlined)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sum(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: primary, size: 20),
          const SizedBox(height: 6),
          Text(value, textAlign: TextAlign.center, style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.cairo(color: textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _marketCard(NeighborhoodInfo? info, _DistrictStats s) {
    final avg = info?.avgPrice ?? s.avgPrice;
    final roi = info?.roi;
    final growth = info?.growth;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_city, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.name,
                  style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              if (growth != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$growth٪',
                    style: GoogleFonts.cairo(color: primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _bar(label: 'سعر', value: avg),
              const SizedBox(width: 14),
              if (s.avgArea > 0) _bar(label: 'مساحة', value: s.avgArea),
              const SizedBox(width: 14),
              if (roi != null) _bar(label: 'عائد', value: roi),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar({required String label, required double value}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(color: textMuted, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            label == 'مساحة'
                ? '${Formatters.number(value)} م²'
                : label == 'عائد'
                    ? '$value٪'
                    : Formatters.compactPrice(value),
            style: GoogleFonts.cairo(color: textLight, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _offlineNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'لا توجد بيانات مباشرة حالياً — عرض إحصائيات تجريبية للأحياء الرئيسية',
              style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _DistrictStats {
  final String name;
  int total = 0;
  double priceSum = 0;
  double areaSum = 0;
  double avgPrice = 0;
  double avgArea = 0;

  _DistrictStats({required this.name});
}
