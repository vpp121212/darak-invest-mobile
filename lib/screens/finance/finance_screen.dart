import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../theme/app_theme.dart';

/// Mortgage / installment calculator: monthly payment, total interest and
/// the financing amount for a given price, down payment, rate and term.
@RoutePage()
class FinanceScreen extends StatefulWidget {
  final double? initialPrice;

  const FinanceScreen({super.key, this.initialPrice});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  late double _price;
  double _downPercent = 20;
  double _rate = 4.5;
  double _years = 20;

  @override
  void initState() {
    super.initState();
    _price = widget.initialPrice ?? 2000000;
  }

  double get _down => _price * _downPercent / 100;
  double get _loan => _price - _down;

  double get _monthly {
    final r = _rate / 100 / 12;
    final n = _years * 12;
    if (r == 0) return _loan / n;
    return _loan * r * pow(1 + r, n) / (pow(1 + r, n) - 1);
  }

  double get _totalPaid => _monthly * _years * 12;
  double get _totalInterest => _totalPaid - _loan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        centerTitle: true,
        title: Text(
          'حاسبة التمويل',
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
          _slider(
            label: 'سعر العقار',
            value: _price,
            min: 200000,
            max: 20000000,
            step: 50000,
            display: Formatters.price(_price),
            onChanged: (v) => setState(() => _price = v),
          ),
          _slider(
            label: 'الدفعة المقدمة',
            value: _downPercent,
            min: 0,
            max: 80,
            step: 1,
            display: '${_downPercent.toStringAsFixed(0)}٪',
            sub: Formatters.price(_down),
            onChanged: (v) => setState(() => _downPercent = v),
          ),
          _slider(
            label: 'نسبة الفائدة السنوية',
            value: _rate,
            min: 0,
            max: 12,
            step: 0.1,
            display: '${_rate.toStringAsFixed(1)}٪',
            onChanged: (v) => setState(() => _rate = v),
          ),
          _slider(
            label: 'مدة التمويل',
            value: _years,
            min: 1,
            max: 30,
            step: 1,
            display: '${_years.toStringAsFixed(0)} سنة',
            onChanged: (v) => setState(() => _years = v),
          ),
          const SizedBox(height: 16),
          _resultCard(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primarySoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'نتيجة تقريبية لأغراض الاسترشاد — لا تُعد عرض تمويلاً. '
                    'استشر البنك للحصول على العرض الفعلي.',
                    style: GoogleFonts.cairo(color: textMuted, fontSize: 11, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required double step,
    required String display,
    required ValueChanged<double> onChanged,
    String? sub,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Text(label, style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(display, style: GoogleFonts.cairo(color: primary, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(sub, style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
              ],
            ),
          ],
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: primary,
              inactiveTrackColor: textMuted.withValues(alpha: 0.2),
              thumbColor: primary,
              overlayColor: primary.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: ((max - min) / step).round(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            'القسط الشهري التقريبي',
            style: GoogleFonts.cairo(color: textMuted, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '${Formatters.number(_monthly)} ر.س',
            style: GoogleFonts.cairo(
              color: primary,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _result('مبلغ التمويل', Formatters.price(_loan))),
              const SizedBox(width: 10),
              Expanded(child: _result('الدفعة المقدمة', Formatters.price(_down))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _result('إجمالي المدفوعات', Formatters.price(_totalPaid))),
              const SizedBox(width: 10),
              Expanded(child: _result('إجمالي الفوائد', Formatters.price(_totalInterest))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _result(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.cairo(color: textLight, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: GoogleFonts.cairo(color: textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}
