import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../providers/brokerage_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';

/// تقديم عرض شراء على عقار معيّن.
@RoutePage()
class OfferScreen extends ConsumerStatefulWidget {
  final Property property;

  const OfferScreen({super.key, required this.property});

  @override
  ConsumerState<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends ConsumerState<OfferScreen> {
  static const _methods = ['نقدي', 'تمويل بنكي', 'إيجار منتهي بالتمليك', 'دفعة واحدة'];

  String _method = 'نقدي';
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  Property get _property => widget.property;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سجّل دخولك أولاً لتقديم عرض', style: GoogleFonts.cairo()),
          action: SnackBarAction(label: 'دخول', onPressed: () => context.pushRoute(const LoginRoute())),
        ),
      );
      return;
    }
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showError('أدخل مبلغ عرض صحيح');
      return;
    }
    if (amount > _property.price * 3) {
      _showError('المبلغ المقدّم أعلى من المتوقع، تأكد من القيمة');
      return;
    }

    final ok = await ref.read(brokerageProvider.notifier).submitOffer(
          propertyId: _property.id,
          amount: amount,
          paymentMethod: _method,
          note: _noteController.text.trim(),
        );
    if (!mounted) return;

    final state = ref.read(brokerageProvider);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال عرضك، وسيراجعه الوسيط', style: GoogleFonts.cairo())),
      );
      context.maybePop();
    } else {
      _showError(state.error ?? 'تعذّر إرسال العرض');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.cairo()), backgroundColor: red.withValues(alpha: 0.9)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(brokerageProvider.select((s) => s.isLoading));

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text('تقديم عرض شراء', style: GoogleFonts.cairo(color: gold, fontSize: 17, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon:  Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _propertyCard(),
          const SizedBox(height: 20),
          Text('مبلغ العرض (ر.س)', style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style:  TextStyle(color: textLight, fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'مثال: ${Formatters.number(_property.price)}',
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'السعر المطلوب: ${Formatters.number(_property.price)} ر.س',
            style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Text('طريقة الدفع', style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _methods.map((m) {
              final selected = _method == m;
              return GestureDetector(
                onTap: () => setState(() => _method = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? gold : glassFill,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: selected ? gold : glassBorder),
                  ),
                  child: Text(
                    m,
                    style: GoogleFonts.cairo(
                      color: selected ? Colors.white : textLight,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('ملاحظات (اختياري)', style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            style:  TextStyle(color: textLight),
            decoration: const InputDecoration(hintText: 'شروط العرض، مواعيد السداد...'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: Text('إرسال العرض', style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            'العرض غير ملزم حتى يقبله الوسيط ويتم توقيع العقد الرسمي',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(color: textMuted, fontSize: 12),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _propertyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 84,
              height: 84,
              child: _property.mainImage.isNotEmpty
                  ? AppImage(src: _property.mainImage, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: cardDark),
                      errorWidget: (_, __, ___) => const _OfferPlaceholder())
                  : const _OfferPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_property.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${_property.district}، ${_property.city}',
                    style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
                const SizedBox(height: 6),
                Text('${_property.formattedPrice} ر.س',
                    style: GoogleFonts.cairo(color: gold, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferPlaceholder extends StatelessWidget {
  const _OfferPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cardDark,
      child:  Center(child: Icon(Icons.home, color: textMuted)),
    );
  }
}
