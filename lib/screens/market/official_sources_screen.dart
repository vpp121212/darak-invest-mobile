// Hallmark · genre: atmospheric · macrostructure: Stat-Led · theme: locked app tokens (dark #0B2018 · accent #10B981 · Cairo)
// Stamps: display roman, no gradient text, no icon tiles, hairline rules, tabular-nums, single accent.
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../data/official_sources_data.dart';
import '../../theme/app_theme.dart';

@RoutePage()
class OfficialSourcesScreen extends StatelessWidget {
  const OfficialSourcesScreen({super.key});

  static const _months = [
    '',
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  String _formatDate(String iso) {
    final parts = iso.split('-');
    if (parts.length != 3) return iso;
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (month == null || day == null || month < 1 || month > 12) return iso;
    return '$day ${_months[month]} ${parts[0]}';
  }

  TextStyle _tnum(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) {
    return GoogleFonts.cairo(
      color: color ?? textLight,
      fontSize: size,
      fontWeight: weight,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        children: [
          _indexHero(s),
          const SizedBox(height: 18),
          _provenance(),
          const SizedBox(height: 36),
          _ledgerSection(
            title: 'شبكة إيجار',
            caption: 'متوسط الإيجار السنوي ونطاق الأسعار لكل حي',
            children: [for (final r in OfficialSources.rents) _rentRow(r)],
          ),
          const SizedBox(height: 36),
          _ledgerSection(
            title: 'منصة سكني',
            caption: 'المشاريع السكنية المعتمدة ونسبة الإنجاز',
            children: [
              for (final p in OfficialSources.projects) _projectRow(p),
            ],
          ),
          const SizedBox(height: 36),
          _ledgerSection(
            title: 'وزارة العدل',
            caption: 'صفقات مسجلة في السجل العقاري',
            children: [for (final d in OfficialSources.deals) _dealRow(d)],
          ),
          const SizedBox(height: 36),
          _ledgerSection(
            title: 'منصة بلدي',
            caption: 'المخططات وأنظمة البناء المعتمدة',
            children: [for (final p in OfficialSources.plans) _planRow(p)],
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _indexHero(OfficialIndex s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: s.value),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => Text(
                value.toStringAsFixed(1),
                style: _tnum(52, color: gold, weight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    s.period,
                    style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.trending_up, color: primary, size: 16),
            const SizedBox(width: 6),
            Text(
              '+${s.changePercent}٪ — ${s.changeNote}',
              style: GoogleFonts.cairo(color: textLight, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: glassBorder, height: 1),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _heroStat(
                label: 'متوسط سعر المتر',
                value: '${Formatters.number(s.avgPricePerMeter)} ر.س',
              ),
            ),
            Container(width: 1, height: 40, color: glassBorder),
            Expanded(
              child: _heroStat(
                label: 'عدد الصفقات',
                value: Formatters.number(s.dealsCount),
                alignEnd: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _heroStat({required String label, required String value, bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: _tnum(18, color: textLight, weight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _provenance() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: glassBorder),
          bottom: BorderSide(color: glassBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, color: primary, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              OfficialSources.disclaimer,
              style: GoogleFonts.cairo(color: textMuted, fontSize: 11, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ledgerSection({
    required String title,
    required String caption,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }

  Widget _hairlineRow({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: glassBorder)),
      ),
      child: child,
    );
  }

  Widget _rentRow(OfficialRent r) {
    return _hairlineRow(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حي ${r.district}',
                  style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.contractsCount} عقد',
                  style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${Formatters.number(r.avgAnnualRent)} ر.س',
                style: _tnum(16, color: gold),
              ),
              const SizedBox(height: 2),
              Text(
                'سنوي · ${Formatters.compactPrice(r.lowRent)} إلى ${Formatters.compactPrice(r.highRent)}',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _projectRow(OfficialProject p) {
    return _hairlineRow(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              '${p.completion.toStringAsFixed(0)}٪',
              textAlign: TextAlign.end,
              style: _tnum(22, color: primary, weight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${p.area} · ${p.type} · ${p.units} وحدة',
                  style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: p.completion / 100,
                    minHeight: 4,
                    backgroundColor: glassBorder,
                    valueColor: AlwaysStoppedAnimation(primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.compactPrice(p.priceFrom),
                style: _tnum(14, color: gold),
              ),
              const SizedBox(height: 2),
              Text(
                '${p.developer} · يبدأ من',
                textAlign: TextAlign.end,
                style: GoogleFonts.cairo(color: textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dealRow(OfficialDeal d) {
    return _hairlineRow(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حي ${d.district}',
                  style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(d.date),
                  style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${Formatters.number(d.area)} م²',
            style: _tnum(12, color: textMuted, weight: FontWeight.w500),
          ),
          const SizedBox(width: 18),
          Text(
            Formatters.compactPrice(d.value),
            style: _tnum(15, color: gold),
          ),
        ],
      ),
    );
  }

  Widget _planRow(OfficialPlan p) {
    final approved = p.status == 'معتمد';
    return _hairlineRow(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'حي ${p.district}',
                      style: GoogleFonts.cairo(color: textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: approved ? primary : amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    p.status,
                    style: GoogleFonts.cairo(
                      color: approved ? primary : amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _planStat('الارتداد', '${p.setback.toStringAsFixed(1)} م'),
              ),
              Expanded(
                child: _planStat('الأدوار', '${p.floors} أدوار'),
              ),
              Expanded(
                child: _planStat('التصاريح', '${p.permits} تصريح'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: _tnum(14, color: textLight),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.cairo(color: textMuted, fontSize: 10),
        ),
      ],
    );
  }
}
