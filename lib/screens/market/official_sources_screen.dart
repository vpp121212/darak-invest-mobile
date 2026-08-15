import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../data/official_sources_data.dart';
import '../../theme/app_theme.dart';

@RoutePage()
class OfficialSourcesScreen extends StatelessWidget {
  const OfficialSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const s = OfficialSources.index;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        centerTitle: true,
        title: Text(
          'المصادر الرسمية',
          style: GoogleFonts.cairo(color: gold, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _disclaimer(),
          const SizedBox(height: 14),
          _indexCard(s),
          const SizedBox(height: 18),
          _sectionHeader('شبكة إيجار', 'متوسط الإيجارات لكل حي', Icons.assignment_outlined),
          const SizedBox(height: 8),
          ...OfficialSources.rents.map((r) => _rentCard(r)),
          const SizedBox(height: 18),
          _sectionHeader('منصة سكني', 'المشاريع السكنية المعتمدة', Icons.apartment_outlined),
          const SizedBox(height: 8),
          ...OfficialSources.projects.map((p) => _projectCard(p)),
          const SizedBox(height: 18),
          _sectionHeader('وزارة العدل', 'السجل العقاري — صفقات فعلية', Icons.gavel_outlined),
          const SizedBox(height: 8),
          ...OfficialSources.deals.map((d) => _dealCard(d)),
          const SizedBox(height: 18),
          _sectionHeader('منصة بلدي', 'المخططات وأنظمة البناء المعتمدة', Icons.account_balance_outlined),
          const SizedBox(height: 8),
          ...OfficialSources.plans.map((p) => _planCard(p)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _disclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              OfficialSources.disclaimer,
              style: GoogleFonts.cairo(color: textMuted, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primarySoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _indexCard(OfficialIndex s) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'الهيئة العامة للعقار',
                  style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s.period,
                  style: GoogleFonts.cairo(color: primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${s.title} — ${s.value}',
            style: GoogleFonts.cairo(color: gold, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.trending_up, color: success, size: 18),
              const SizedBox(width: 4),
              Text(
                '+${s.changePercent}٪',
                style: GoogleFonts.cairo(color: success, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.changeNote,
                  style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _stat(
                  'متوسط سعر المتر',
                  '${Formatters.number(s.avgPricePerMeter)} ر.س',
                  Icons.square_foot,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _stat(
                  'عدد الصفقات',
                  Formatters.number(s.dealsCount),
                  Icons.swap_horiz_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
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
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(color: textLight, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(color: textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _rentCard(OfficialRent r) {
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
                child: const Icon(Icons.location_city, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'حي ${r.district}',
                  style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${r.contractsCount} عقد',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('متوسط الإيجار السنوي', style: GoogleFonts.cairo(color: textMuted, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.compactPrice(r.avgAnnualRent),
                      style: GoogleFonts.cairo(color: textLight, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نطاق الأسعار', style: GoogleFonts.cairo(color: textMuted, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.compactPrice(r.lowRent)} – ${Formatters.compactPrice(r.highRent)}',
                      style: GoogleFonts.cairo(color: gold, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _projectCard(OfficialProject p) {
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
                  color: cyan,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.apartment, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      p.area,
                      style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _kv('النوع', p.type),
              ),
              Expanded(
                child: _kv('الوحدات', '${p.units} وحدة'),
              ),
              Expanded(
                child: _kv('يبدأ من', Formatters.compactPrice(p.priceFrom)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: p.completion / 100,
                    minHeight: 6,
                    backgroundColor: glassBorder,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${p.completion.toStringAsFixed(0)}٪',
                style: GoogleFonts.cairo(color: primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dealCard(OfficialDeal d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: amber,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'صفقة — ${d.district}',
                  style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  d.date,
                  style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.compactPrice(d.value),
                style: GoogleFonts.cairo(color: gold, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '${Formatters.number(d.area)} م²',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planCard(OfficialPlan p) {
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
                  color: blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'حي ${p.district}',
                      style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.status == 'معتمد' ? primarySoft : amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  p.status,
                  style: GoogleFonts.cairo(
                    color: p.status == 'معتمد' ? primary : amber,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _kv('الارتداد', '${p.setback} م')),
              Expanded(child: _kv('الأدوار', '${p.floors} أدوار')),
              Expanded(child: _kv('التصاريح', '${p.permits} تصريح')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.cairo(color: textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.cairo(color: textLight, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
