import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/formatters.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payments_provider.dart';
import '../../theme/app_theme.dart';

/// الاشتراكات: اختيار الباقة وإتمام الدفع وعرض السجل.
@RoutePage()
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      ref.read(paymentsProvider.notifier).loadConfig();
      if (ref.read(authProvider).isLoggedIn) {
        ref.read(paymentsProvider.notifier).loadHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(paymentsProvider);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text('الباقات والاشتراك',
            style: GoogleFonts.cairo(color: gold, fontSize: 17, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
      ),
      body: !auth.isLoggedIn
          ? _loggedOut()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _currentPlan(auth.user),
                const SizedBox(height: 20),
                _testModeBanner(state),
                const SizedBox(height: 20),
                ...subscriptionPackages.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _planCard(p, auth.user?.package ?? 'basic', state),
                    )),
                const SizedBox(height: 8),
                _history(auth.user, state),
              ],
            ),
    );
  }

  Widget _loggedOut() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.workspace_premium_outlined, color: textMuted, size: 48),
          const SizedBox(height: 12),
          Text('سجّل دخولك للاطلاع على الباقات والاشتراك',
              style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _currentPlan(User? user) {
    final package = _packageById(user?.package ?? 'basic');
    final expiry = user?.packageExpiry;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: brandGradient),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x40CCFF00), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('باقتك الحالية', style: GoogleFonts.cairo(color: Colors.black87, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.black, size: 26),
              const SizedBox(width: 8),
              Text(package.name,
                  style: GoogleFonts.cairo(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          if (expiry != null && expiry.isAfter(DateTime.now()))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('ساري حتى ${DateFormat('d MMM yyyy').format(expiry)}',
                  style: GoogleFonts.cairo(color: Colors.black87, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _testModeBanner(PaymentState state) {
    if (!state.testMode) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('وضع تجريبي: الدفع يتم محلياً بدون بوابة خارجية.',
                style: GoogleFonts.cairo(color: textLight, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _planCard(SubscriptionPackage p, String currentPackage, PaymentState state) {
    final isCurrent = p.id == currentPackage;
    final isPro = p.id != 'basic';
    final processing = state.processingPackageId == p.id && state.isLoading;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCurrent ? gold.withValues(alpha: 0.1) : glassFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? gold : glassBorder,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.name,
                    style: GoogleFonts.cairo(color: textLight, fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('باقتك الحالية',
                      style: GoogleFonts.cairo(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(p.description, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: p.price == 0 ? 'مجاني' : Formatters.number(p.price),
                  style: GoogleFonts.cairo(color: gold, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (p.price > 0)
                  TextSpan(text: '  ر.س / شهرياً', style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...p.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f, style: GoogleFonts.cairo(color: textLight, fontSize: 13)),
                    ),
                  ],
                ),
              )),
          if (isPro && !isCurrent) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: processing ? null : () => _subscribe(p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: brandGradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: processing
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text('اشترك الآن', style: GoogleFonts.cairo(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _history(User? user, PaymentState state) {
    if (state.history.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('سجل الدفعات', style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...state.history.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: glassFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: glassBorder),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon(p['status'] ?? ''), color: _statusColor(p['status'] ?? ''), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['description']?.toString() ?? 'باقة',
                            style: GoogleFonts.cairo(color: textLight, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(_statusLabel(p['status'] ?? ''),
                            style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('${Formatters.number((p['amount'] ?? 0))} ر.س',
                      style: GoogleFonts.cairo(color: gold, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            )),
      ],
    );
  }

  Future<void> _subscribe(SubscriptionPackage p) async {
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return;
    final res = await ref.read(paymentsProvider.notifier).createIntent(p.id);
    if (res == null) {
      _toast(ref.read(paymentsProvider).error ?? 'تعذّر إنشاء الدفعة');
      return;
    }
    final invoiceUrl = res['invoiceUrl'];
    if (invoiceUrl is String && invoiceUrl.isNotEmpty) {
      final ok = await launchUrl(Uri.parse(invoiceUrl), mode: LaunchMode.externalApplication);
      if (!ok) _toast('تعذّر فتح بوابة الدفع');
      return;
    }
    // وضع اختباري: تأكيد ثم إتمام محلي.
    final paymentId = res['paymentId']?.toString();
    if (paymentId == null || paymentId.isEmpty) {
      _toast('لم يستجب الخادم بفاتورة صالحة');
      return;
    }
    final confirmed = await _confirmDialog(p);
    if (confirmed != true) return;
    final ok = await ref.read(paymentsProvider.notifier).completeTest(paymentId);
    if (ok) {
      await ref.read(authProvider.notifier).refreshProfile();
      if (mounted) _toast('تم تفعيل باقة ${p.name} تجريبياً ✓');
    } else {
      _toast(ref.read(paymentsProvider).error ?? 'فشل إتمام الدفعة');
    }
  }

  Future<bool?> _confirmDialog(SubscriptionPackage p) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('تفعيل ${p.name}', style: GoogleFonts.cairo(color: gold, fontWeight: FontWeight.bold)),
        content: Text(
          'وضع تجريبي — سيتم تفعيل الباقة فوراً بدون خصم. المبلغ: ${Formatters.number(p.price)} ر.س.',
          style: GoogleFonts.cairo(color: textLight, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: gold),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('تفعيل تجريبي', style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  SubscriptionPackage _packageById(String id) {
    for (final p in subscriptionPackages) {
      if (p.id == id) return p;
    }
    return subscriptionPackages.first;
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'paid' => Icons.check_circle,
      'failed' => Icons.cancel,
      _ => Icons.schedule,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'paid' => success,
      'failed' => red,
      _ => gold,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'paid' => 'مدفوع',
      'failed' => 'فشل',
      'pending' => 'قيد الانتظار',
      _ => status,
    };
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
    );
  }
}
