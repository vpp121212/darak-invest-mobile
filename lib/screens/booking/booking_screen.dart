import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../models/property.dart';
import '../../providers/auth_provider.dart';
import '../../providers/brokerage_provider.dart';
import '../../theme/app_theme.dart';

/// حجز موعد معاينة/استشارة/توقيع عقد مع وسيط العقار.
@RoutePage()
class BookingScreen extends ConsumerStatefulWidget {
  final Property property;

  const BookingScreen({super.key, required this.property});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  static const _types = ['معاينة', 'استشارة', 'توقيع عقد'];

  String _type = 'معاينة';
  DateTime? _date;
  TimeOfDay? _time;
  final _noteController = TextEditingController();

  Property get _property => widget.property;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'اختر يوم المعاينة',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 17, minute: 0),
      helpText: 'اختر وقت الموعد',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked != null) setState(() => _time = picked);
  }

  DateTime? get _scheduled {
    final d = _date;
    final t = _time;
    if (d == null || t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _submit() async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('سجّل دخولك أولاً لحجز الموعد', style: GoogleFonts.cairo()),
          action: SnackBarAction(label: 'دخول', onPressed: () => context.pushRoute(const LoginRoute())),
        ),
      );
      return;
    }
    final scheduled = _scheduled;
    if (scheduled == null) {
      _showError('اختر يوم ووقت الموعد');
      return;
    }
    if (scheduled.isBefore(DateTime.now())) {
      _showError('لا يمكن حجز موعد في الماضي');
      return;
    }

    final ok = await ref.read(brokerageProvider.notifier).book(
          propertyId: _property.id,
          scheduledAt: scheduled,
          type: _type,
          note: _noteController.text.trim(),
        );
    if (!mounted) return;

    final state = ref.read(brokerageProvider);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال طلب الحجز، وسيؤكده الوسيط', style: GoogleFonts.cairo())),
      );
      context.maybePop();
    } else {
      _showError(state.error ?? 'تعذّر إرسال الطلب');
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
        title: Text('حجز موعد معاينة', style: GoogleFonts.cairo(color: gold, fontSize: 17, fontWeight: FontWeight.bold)),
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
          _sectionTitle('نوع الموعد'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: _types.map((t) {
              final selected = _type == t;
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? gold : glassFill,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: selected ? gold : glassBorder),
                  ),
                  child: Text(
                    t,
                    style: GoogleFonts.cairo(
                      color: selected ? Colors.white : textLight,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('الموعد'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _pickTile(
                  icon: Icons.calendar_month,
                  label: _date == null ? 'اليوم' : DateFormat('EEEE d MMMM y').format(_date!),
                  hint: 'اختر اليوم',
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pickTile(
                  icon: Icons.schedule,
                  label: _time == null ? 'الوقت' : _time!.format(context),
                  hint: 'اختر الوقت',
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('ملاحظات (اختياري)'),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 3,
            style:  TextStyle(color: textLight),
            decoration: const InputDecoration(hintText: 'أي تفاصيل تود إخبار الوسيط بها...'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: Text('إرسال طلب الحجز', style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            'سيتم التواصل معك لتأكيد الموعد — يمكنك إدارة حجوزاتك من صفحة «وساطتي»',
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
                  ? CachedNetworkImage(imageUrl: _property.mainImage, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: cardDark),
                      errorWidget: (_, __, ___) => const _PlaceholderIcon())
                  : const _PlaceholderIcon(),
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

  Widget _sectionTitle(String title) {
    return Text(title, style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _pickTile({
    required IconData icon,
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: glassFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: glassBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: gold, size: 22),
            const SizedBox(height: 8),
            Text(
              label == hint ? hint : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(color: label == hint ? textMuted : textLight, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cardDark,
      child:  Center(child: Icon(Icons.home, color: textMuted)),
    );
  }
}
