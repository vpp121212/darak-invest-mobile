import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../data/neighborhoods_data.dart';
import '../../models/investment_opportunity.dart';
import '../../providers/properties_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neighborhood_radar_card.dart';
import '../../widgets/property_card.dart';

@RoutePage()
class NeighborhoodDetailScreen extends ConsumerWidget {
  final String district;

  const NeighborhoodDetailScreen({super.key, required this.district});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogue = ref.watch(propertiesProvider);
    final info = kNeighborhoods.firstWhere(
      (n) => n.name == district,
      orElse: () => kNeighborhoods.first,
    );
    final properties = catalogue.properties
        .where((p) => p.district == district)
        .toList();
    final opportunity = kInvestmentOpportunities
        .where((o) => o.district == 'حي $district' || o.district == district)
        .toList();

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        centerTitle: true,
        title: Text(
          district,
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
          _buildHeader(info),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _metric('متوسط البيع', Formatters.compactPrice(info.avgPrice), Icons.payments_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _metric('متوسط الإيجار', '${Formatters.compactPrice(info.avgRent)}/سنة', Icons.receipt_long_outlined)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _metric('العائد', '${info.roi}٪', Icons.trending_up)),
              const SizedBox(width: 10),
              Expanded(child: _metric('النمو', '+${info.growth}٪ سنوياً', Icons.auto_graph)),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.pushRoute(MapRoute()),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x4DCCFF00), blurRadius: 14),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'عرض عقارات $district على الخريطة',
                    style: GoogleFonts.cairo(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (opportunity.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'فرصة استثمارية',
              style: GoogleFonts.cairo(color: primary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            NeighborhoodRadarCard(
              opportunity: opportunity.first,
              onViewDistrict: () {},
              onInvest: () => _snack(context, 'الاستثمار الجماعي في $district قريباً'),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'عقارات في $district (${properties.length})',
            style: GoogleFonts.cairo(color: textLight, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (properties.isEmpty)
            _emptyState()
          else
            ...properties.map((p) => PropertyCard(
                  property: p,
                  onTap: () => context.pushRoute(PropertyDetailRoute(property: p)),
                )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(NeighborhoodInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1C1C), Color(0xFF262626)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glassBorder),
        boxShadow: softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0x66CCFF00), blurRadius: 16),
              ],
            ),
            child: const Icon(Icons.location_city, color: Colors.black, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            info.name,
            style: GoogleFonts.cairo(color: textLight, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(info.city, style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
          const SizedBox(height: 10),
          Text(
            info.tagline,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(color: primary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: primary, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.home_work_outlined, size: 40, color: textMuted),
          const SizedBox(height: 8),
          Text(
            'لا توجد عقارات مسجّلة في $district حالياً',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
    );
  }
}
