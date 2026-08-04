import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../models/property.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ai_field.dart';

@RoutePage()
class RoiScreen extends StatefulWidget {
  final Property? property;

  const RoiScreen({super.key, this.property});

  @override
  State<RoiScreen> createState() => _RoiScreenState();
}

class _RoiScreenState extends State<RoiScreen> {
  late final TextEditingController _price;
  late final TextEditingController _rent;
  late final TextEditingController _costs;
  late final TextEditingController _appreciation;

  double? _roi;
  double? _netAnnual;
  double? _paybackYears;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController();
    _rent = TextEditingController();
    _costs = TextEditingController();
    _appreciation = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    final property = widget.property;
    _prefilled = true;
    _price.text =
        property != null && property.purpose != 'إيجار' ? '${property.price.round()}' : '';
    _rent.text =
        property != null && property.purpose == 'إيجار' ? '${property.price.round()}' : '';
    _appreciation.text = '5';
  }

  @override
  void dispose() {
    _price.dispose();
    _rent.dispose();
    _costs.dispose();
    _appreciation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        centerTitle: true,
        title: Text(
          'حاسبة العائد على الاستثمار',
          style: GoogleFonts.cairo(color: gold, fontSize: 17, fontWeight: FontWeight.bold),
        ),
          leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildIntro(),
            const SizedBox(height: 16),
            AiField(
              label: 'سعر الشراء (ر.س)',
              child: TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: textLight),
                decoration: aiInputDecoration(hint: 'مثال: 3000000', icon: Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            AiField(
              label: 'الإيجار الشهري (ر.س)',
              child: TextField(
                controller: _rent,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: textLight),
                decoration: aiInputDecoration(hint: 'مثال: 15000', icon: Icons.receipt_long_outlined),
              ),
            ),
            const SizedBox(height: 12),
            AiField(
              label: 'التكاليف السنوية (صيانة، ضرائب، إلخ)',
              child: TextField(
                controller: _costs,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: textLight),
                decoration: aiInputDecoration(hint: 'اختياري، مثال: 10000', icon: Icons.build_outlined),
              ),
            ),
            const SizedBox(height: 12),
            AiField(
              label: 'نسبة ارتفاع السعر السنوي المتوقع (%)',
              child: TextField(
                controller: _appreciation,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: textLight),
                decoration: aiInputDecoration(hint: 'اختياري، مثال: 5', icon: Icons.trending_up),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _calculate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'احسب العائد',
                    style: GoogleFonts.cairo(color: bgDark, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_roi != null) _buildResults(),
            const SizedBox(height: 20),
          ],
        ),
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
            child: const Icon(Icons.trending_up, color: gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'احسب العائد السنوي على استثمارك العقاري ومدة استرداد رأس المال بناءً على الإيجار والتكاليف.',
              style: GoogleFonts.cairo(color: textMuted, fontSize: 13, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final price = num.tryParse(_price.text);
    final rent = num.tryParse(_rent.text);
    if (price == null || price <= 0) {
      _snack('أدخل سعر الشراء');
      return;
    }
    if (rent == null || rent <= 0) {
      _snack('أدخل الإيجار الشهري');
      return;
    }
    final costs = num.tryParse(_costs.text) ?? 0;

    final netAnnual = rent * 12 - costs;
    final roi = netAnnual / price * 100;
    final paybackYears = netAnnual > 0 ? price / netAnnual : null;

    setState(() {
      _netAnnual = netAnnual.toDouble();
      _roi = roi.toDouble();
      _paybackYears = paybackYears?.toDouble();
    });
  }

  Widget _buildResults() {
    final appreciation = num.tryParse(_appreciation.text) ?? 0;
    final totalReturn = (_roi ?? 0) + appreciation.toDouble();
    final isGood = (_roi ?? 0) >= 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isGood ? green : gold).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isGood ? Icons.emoji_events_outlined : Icons.info_outline, color: isGood ? green : gold),
              const SizedBox(width: 6),
              Text('نتيجة الحساب', style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _resultRow('الدخل السنوي الصافي', _netAnnual!, 'ر.س/سنة'),
          const SizedBox(height: 8),
          _roiRow(),
          if (_paybackYears != null) ...[
            const SizedBox(height: 8),
            _resultRow('فترة استرداد رأس المال', _paybackYears!, 'سنة'),
          ],
          if (appreciation > 0) ...[
            const SizedBox(height: 8),
            _resultRow('العائد الإجمالي المتوقع', totalReturn, '٪ سنوياً'),
          ],
          const SizedBox(height: 14),
          Text(
            isGood
                ? 'عائد ممتاز — استثمار مجزٍ وفق معايير السوق العقاري.'
                : 'العائد ضمن المتوسط، يمكن تحسينه بزيادة الإيجار أو تقليل التكاليف.',
            style: GoogleFonts.cairo(color: textMuted, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, num value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
        Text(
          '${Formatters.number(value)} $unit',
          style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _roiRow() {
    final roi = _roi ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('العائد على الاستثمار (ROI)', style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
        Text(
          '${roi.toStringAsFixed(2)}٪ سنوياً',
          style: GoogleFonts.cairo(color: gold, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.cairo())));
  }
}
