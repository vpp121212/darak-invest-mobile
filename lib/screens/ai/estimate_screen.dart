import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/formatters.dart';
import '../../models/estimate_result.dart';
import '../../models/property.dart';
import '../../providers/estimate_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ai_field.dart';

@RoutePage()
class EstimateScreen extends ConsumerStatefulWidget {
  final Property? property;

  const EstimateScreen({super.key, this.property});

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen> {
  static const _types = ['فيلا', 'شقة', 'دوبلكس', 'مكتب', 'استوديو', 'أرض', 'عمارة'];
  static const _purposes = ['بيع', 'إيجار'];

  late final TextEditingController _city;
  late final TextEditingController _district;
  late final TextEditingController _area;
  late final TextEditingController _rooms;
  late final TextEditingController _baths;

  String _type = '';
  String _purpose = 'بيع';
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _city = TextEditingController();
    _district = TextEditingController();
    _area = TextEditingController();
    _rooms = TextEditingController();
    _baths = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    final property = widget.property;
    _prefilled = true;
    _city.text = property?.city ?? '';
    _district.text = property?.district ?? '';
    _area.text = property != null ? '${property.area.round()}' : '';
    _rooms.text = property != null ? '${property.rooms}' : '';
    _baths.text = property != null ? '${property.baths}' : '';
    _type = property?.type ?? '';
    _purpose = property?.purpose ?? 'بيع';
  }

  @override
  void dispose() {
    _city.dispose();
    _district.dispose();
    _area.dispose();
    _rooms.dispose();
    _baths.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estimateAsync = ref.watch(estimateProvider);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        centerTitle: true,
        title: Text(
          'تقدير السعر بالذكاء الاصطناعي',
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
            Form(
              child: Column(
                children: [
                  AiField(
                    label: 'المدينة',
                    child: TextField(
                      controller: _city,
                      style: const TextStyle(color: textLight),
                      decoration: aiInputDecoration(hint: 'مثال: الرياض', icon: Icons.location_city_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AiField(
                    label: 'الحي',
                    child: TextField(
                      controller: _district,
                      style: const TextStyle(color: textLight),
                      decoration: aiInputDecoration(hint: 'مثال: حي النرجس', icon: Icons.map_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AiField(
                          label: 'نوع العقار',
                          child: AiDropdown(
                            value: _type,
                            hint: 'اختر النوع',
                            items: _types,
                            onSelected: (v) => setState(() => _type = v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AiField(
                          label: 'الغرض',
                          child: AiDropdown(
                            value: _purpose,
                            hint: 'اختر الغرض',
                            items: _purposes,
                            onSelected: (v) => setState(() => _purpose = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AiField(
                          label: 'المساحة (م²)',
                          child: TextField(
                            controller: _area,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: textLight),
                            decoration: aiInputDecoration(hint: 'مثال: 500', icon: Icons.straighten),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AiField(
                          label: 'عدد الغرف',
                          child: TextField(
                            controller: _rooms,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: textLight),
                            decoration: aiInputDecoration(hint: 'مثال: 6', icon: Icons.king_bed_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AiField(
                    label: 'عدد الحمامات',
                    child: TextField(
                      controller: _baths,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: textLight),
                      decoration: aiInputDecoration(hint: 'مثال: 5', icon: Icons.bathtub_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSubmitButton(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildResult(estimateAsync),
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
            child: const Icon(Icons.auto_awesome, color: gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'خوارزمية ذكية تحلل بيانات السوق الفعلية لتقدير سعر عادل لعقارك مع احتمالية البيع.',
              style: GoogleFonts.cairo(color: textMuted, fontSize: 13, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _submit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: gold,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            'احسب التقدير',
            style: GoogleFonts.cairo(color: bgDark, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final area = num.tryParse(_area.text);
    final rooms = int.tryParse(_rooms.text);
    final baths = int.tryParse(_baths.text);
    if (_city.text.trim().isEmpty) {
      _snack('أدخل المدينة');
      return;
    }
    if (_district.text.trim().isEmpty) {
      _snack('أدخل الحي');
      return;
    }
    if (_type.isEmpty) {
      _snack('اختر نوع العقار');
      return;
    }
    if (area == null || area <= 0) {
      _snack('أدخل مساحة صحيحة');
      return;
    }
    if (rooms == null || rooms <= 0) {
      _snack('أدخل عدد الغرف');
      return;
    }
    ref.read(estimateProvider.notifier).estimate(
          city: _city.text.trim(),
          district: _district.text.trim(),
          type: _type,
          purpose: _purpose,
          area: area,
          rooms: rooms,
          baths: baths ?? 0,
        );
  }

  Widget _buildResult(AsyncValue<EstimateResult?> estimateAsync) {
    return estimateAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: gold),
        ),
      ),
      error: (e, _) => _ResultError(message: e.toString()),
      data: (result) {
        if (result == null || result.isEmpty) return const SizedBox.shrink();
        if (result.sampleSize == null || result.sampleSize == 0) {
          return _NoData(message: result.message);
        }
        return _EstimateResultView(result: result);
      },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.cairo())));
  }
}

class _EstimateResultView extends StatelessWidget {
  final EstimateResult result;

  const _EstimateResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final expected = result.expected;
    final suitable = result.suitable;
    final maximum = result.maximum;
    final saleChance = result.saleChance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: gold),
              const SizedBox(width: 6),
              Text('نتيجة التقدير', style: GoogleFonts.cairo(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (expected != null) _resultRow('السعر المتوقع', expected),
          if (suitable != null) _resultRow('السعر المناسب', suitable),
          if (maximum != null) _resultRow('السعر الأقصى', maximum),
          if (saleChance != null) ...[
            const SizedBox(height: 8),
            _saleChanceBar(saleChance),
          ],
          if (result.sampleSize != null) ...[
            const SizedBox(height: 12),
            Text(
              'بناءً على ${result.sampleSize} عينة مشابهة في السوق',
              style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(String label, num value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
          Text(
            '${Formatters.number(value)} ر.س',
            style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _saleChanceBar(num chance) {
    final value = (chance).clamp(0, 100).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('احتمالية البيع', style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
            Text('${Formatters.number(chance)}٪', style: GoogleFonts.cairo(color: gold, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: bgDark,
            color: value >= 70 ? green : value >= 40 ? gold : Colors.red,
          ),
        ),
      ],
    );
  }
}

class _NoData extends StatelessWidget {
  final String? message;

  const _NoData({this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textMuted.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, size: 40, color: textMuted),
          const SizedBox(height: 10),
          Text(
            message ?? 'لا توجد بيانات كافية لتقدير السعر في هذه المنطقة، جرّب حياً آخر أو عدّل المدخلات.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(color: textMuted, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _ResultError extends StatelessWidget {
  final String message;

  const _ResultError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'تعذّر إتمام التقدير',
            style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(color: textMuted, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}
