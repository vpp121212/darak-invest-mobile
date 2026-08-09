import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../models/investment_opportunity.dart';
import '../../models/neighborhood_pulse.dart';
import '../../providers/pulse_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ai_field.dart';
import '../../widgets/neighborhood_radar_card.dart';

@RoutePage()
class PulseScreen extends ConsumerStatefulWidget {
  final String? district;

  const PulseScreen({super.key, this.district});

  @override
  ConsumerState<PulseScreen> createState() => _PulseScreenState();
}

class _PulseScreenState extends ConsumerState<PulseScreen> {
  late final TextEditingController _district;

  @override
  void initState() {
    super.initState();
    _district = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final district = widget.district;
    if (district != null && district.isNotEmpty && _district.text.isEmpty) {
      _district.text = district;
    }
  }

  @override
  void dispose() {
    _district.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulseAsync = ref.watch(pulseProvider);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        centerTitle: true,
        title: Text(
          'نبض الحي',
          style: GoogleFonts.cairo(color: gold, fontSize: 17, fontWeight: FontWeight.bold),
        ),
          leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntro(),
          const SizedBox(height: 16),
          AiField(
            label: 'اسم الحي',
            child: TextField(
              controller: _district,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              style: const TextStyle(color: textLight),
              decoration: aiInputDecoration(hint: 'مثال: حي السلامة', icon: Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _load,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'اعرض نبض الحي',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildRadar(),
          const SizedBox(height: 20),
          _buildResult(pulseAsync),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sensors, color: gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'تحليل شامل للحي: متوسط الأسعار، العائد على الإيجار، المشاريع القريبة، ومؤشرات المشي والخضرة.',
              style: GoogleFonts.cairo(color: textMuted, fontSize: 13, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'رادار الأحياء والفرص الواعدة',
          style: GoogleFonts.cairo(color: gold, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'فرص استثمارية مختارة بناءً على مؤشرات النمو',
          style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ...kInvestmentOpportunities.map((opp) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NeighborhoodRadarCard(
                opportunity: opp,
                onViewDistrict: () {
                  _district.text = opp.district;
                  _load();
                },
                onInvest: () => _snack('الاستثمار الجماعي في ${opp.district} قريباً'),
              ),
            )),
      ],
    );
  }

  void _load() {
    FocusScope.of(context).unfocus();
    final district = _district.text.trim();
    if (district.isEmpty) {
      _snack('أدخل اسم الحي');
      return;
    }
    ref.read(pulseProvider.notifier).load(district);
  }

  Widget _buildResult(AsyncValue<NeighborhoodPulse?> pulseAsync) {
    return pulseAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: gold),
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text(
              'تعذّر تحميل نبض الحي',
              style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              e.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: textMuted, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
      data: (pulse) {
        if (pulse == null) return const SizedBox.shrink();
        return _PulseResultView(pulse: pulse);
      },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.cairo())));
  }
}

class _PulseResultView extends StatelessWidget {
  final NeighborhoodPulse pulse;

  const _PulseResultView({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('متوسط الإيجار', pulse.avgRent, 'ر.س/سنة', Icons.receipt_long_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('متوسط البيع', pulse.avgSale, 'ر.س', Icons.payments_outlined)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('العائد على الإيجار', pulse.roi, '٪', Icons.trending_up)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('نمو القيمة المستقبلي', pulse.futureValueGrowth, '٪', Icons.auto_graph)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _metricCard('مؤشر المشي', pulse.walkScore, '/100', Icons.directions_walk)),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                'الرياض. بوليفارد',
                pulse.sportsBoulevard ? 1 : 0,
                pulse.sportsBoulevard ? 'متاح' : 'غير متاح',
                Icons.emoji_people,
              ),
            ),
          ],
        ),
        if (pulse.metroStations.isNotEmpty) ...[
          const SizedBox(height: 16),
          _listCard('محطات المترو القريبة', pulse.metroStations, Icons.subway_outlined),
        ],
        if (pulse.nearbyProjects.isNotEmpty) ...[
          const SizedBox(height: 12),
          _listCard('المشاريع القريبة', pulse.nearbyProjects, Icons.construction),
        ],
        if (pulse.greenSpaces.isNotEmpty) ...[
          const SizedBox(height: 12),
          _listCard('المساحات الخضراء', pulse.greenSpaces, Icons.park_outlined),
        ],
        if (pulse.dataSource != null && pulse.dataSource!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'المصدر: ${pulse.dataSource}',
            style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2744), Color(0xFF2E3B4E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_city, color: gold, size: 40),
          const SizedBox(height: 8),
          Text(
            pulse.district,
            style: GoogleFonts.cairo(color: textLight, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (pulse.city.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(pulse.city, style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _metricCard(String label, num? value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textMuted.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: gold, size: 22),
          const SizedBox(height: 8),
          Text(
            value != null ? Formatters.number(value) : '-',
            style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(unit, style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _listCard(String title, List<String> items, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textMuted.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: gold, size: 18),
              const SizedBox(width: 6),
              Text(title, style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Text(item, style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
