import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../models/realestate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/management_provider.dart';
import '../../theme/app_theme.dart';

/// إدارة العقارات: العقود والفواتير والرخص والصكوك.
@RoutePage()
class ManagementScreen extends ConsumerStatefulWidget {
  const ManagementScreen({super.key});

  @override
  ConsumerState<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      if (ref.read(authProvider).isLoggedIn) {
        ref.read(managementProvider.notifier).load();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(managementProvider);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text('إدارة العقارات',
            style: GoogleFonts.cairo(color: gold, fontSize: 17, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: gold,
          labelColor: gold,
          unselectedLabelColor: textMuted,
          isScrollable: true,
          labelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'نظرة عامة'),
            Tab(text: 'العقود'),
            Tab(text: 'الفواتير'),
            Tab(text: 'الرخص'),
            Tab(text: 'الصكوك'),
          ],
        ),
      ),
      body: !auth.isLoggedIn
          ? _loggedOut()
          : RefreshIndicator(
              onRefresh: () => ref.read(managementProvider.notifier).load(),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _overview(state),
                  _contracts(state),
                  _invoices(state),
                  _licenses(state),
                  _deeds(state),
                ],
              ),
            ),
    );
  }

  Widget _loggedOut() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.admin_panel_settings_outlined, color: textMuted, size: 48),
          const SizedBox(height: 12),
          Text('سجّل دخولك لإدارة عقاراتك', style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pushRoute(const LoginRoute()),
            child: Text('دخول', style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── نظرة عامة ────────────────────────────────────────────────
  Widget _overview(ManagementState state) {
    if (state.isLoading && state.contracts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final s = state.stats;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _kpi('العقود', s.contracts, Icons.description_outlined, cyan),
            _kpi('المصدقة', s.contractsAuthenticated, Icons.verified_outlined, success),
            _kpi('الفواتير', s.invoices, Icons.receipt_long_outlined, gold),
            _kpi('الرخص', s.licenses, Icons.badge_outlined, blue),
            _kpi('الصكوك', s.deeds, Icons.balance_outlined, success),
            _kpi('نماذج التسليم', s.deliveryForms, Icons.assignment_outlined, textMuted),
          ],
        ),
        const SizedBox(height: 20),
        if (s.invoiceTotal > 0)
          _invoiceSummary(state.invoiceTotals),
        const SizedBox(height: 20),
        Text('إجراءات سريعة', style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _quickAction(Icons.description_outlined, 'عقد جديد', () => _addContract()),
        _quickAction(Icons.receipt_long_outlined, 'إصدار فاتورة', () => _addInvoice()),
        _quickAction(Icons.badge_outlined, 'طلب ترخيص', () => _addLicense()),
        _quickAction(Icons.balance_outlined, 'تسجيل صك', () => _addDeed()),
      ],
    );
  }

  Widget _kpi(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text('$value', style: GoogleFonts.cairo(color: textLight, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _invoiceSummary(InvoiceTotals t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إيرادات الإيجار', style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _totalsChip('مدفوعة', t.paid, success),
              _totalsChip('معلّقة', t.pending, gold),
              _totalsChip('متأخرة', t.overdue, red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalsChip(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
            const SizedBox(height: 4),
            Text('${Formatters.compactPrice(amount)} ر.س',
                style: GoogleFonts.cairo(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cardDark,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: gold, size: 20),
          ),
          title: Text(label, style: GoogleFonts.cairo(color: textLight, fontSize: 14)),
          trailing: const Icon(Icons.add_circle_outline, color: gold, size: 22),
          onTap: onTap,
        ),
      ),
    );
  }

  // ─── العقود ──────────────────────────────────────────────────
  Widget _contracts(ManagementState state) {
    if (state.isLoading && state.contracts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.contracts.isEmpty) return _empty('لا توجد عقود بعد', 'أنشئ عقداً من الزر أدناه');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: state.contracts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _contractCard(state.contracts[index]),
    );
  }

  Widget _contractCard(RealEstateContract c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.propertyDesc.isEmpty ? c.contractNumber : c.propertyDesc,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              _badge(c.statusLabel, _contractColor(c)),
            ],
          ),
          const SizedBox(height: 6),
          Text('${c.contractType} • ${c.contractNumber}', style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Text('الطرفان: ${c.firstParty} ← ${c.secondParty}', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
          if (c.amount > 0) ...[
            const SizedBox(height: 4),
            Text('${Formatters.number(c.amount)} ر.س',
                style: GoogleFonts.cairo(color: gold, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (c.isDraft)
                _actionBtn('توثيق', success, () => _run(() => ref.read(managementProvider.notifier).authenticateContract(c.id), 'تم توثيق العقد'))
              else if (c.isActive)
                _actionBtn('إنهاء', blue, () => _run(() => ref.read(managementProvider.notifier).updateContract(c.id, {'status': 'completed'}), 'تم إنهاء العقد')),
              if (c.isDraft || c.isActive)
                _actionBtn('إلغاء', red, () => _run(() => ref.read(managementProvider.notifier).updateContract(c.id, {'status': 'cancelled'}), 'تم إلغاء العقد')),
              if (c.isAuthenticated) ...[
                const SizedBox(width: 8),
                const Icon(Icons.verified, color: success, size: 18),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── الفواتير ────────────────────────────────────────────────
  Widget _invoices(ManagementState state) {
    if (state.isLoading && state.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.invoices.isEmpty) return _empty('لا توجد فواتير بعد', 'أصدر فاتورة إيجار من الزر أدناه');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: state.invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _invoiceCard(state.invoices[index]),
    );
  }

  Widget _invoiceCard(RentalInvoice v) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(v.tenantName.isEmpty ? v.invoiceNumber : v.tenantName,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              _badge(v.statusLabel, _invoiceColor(v.status)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${v.invoiceNumber} • ${v.propertyTitle.isEmpty ? 'بدون عقار' : v.propertyTitle}',
              style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('${Formatters.number(v.totalAmount)} ر.س',
                    style: GoogleFonts.cairo(color: gold, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              if (!v.isPaid)
                _actionBtn('تسجيل دفع', success, () => _run(() => ref.read(managementProvider.notifier).payInvoice(v.id), 'تم تسجيل الدفع')),
            ],
          ),
        ],
      ),
    );
  }

  // ─── الرخص ───────────────────────────────────────────────────
  Widget _licenses(ManagementState state) {
    if (state.isLoading && state.licenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.licenses.isEmpty) return _empty('لا توجد رخص بعد', 'قدّم طلب ترخيص من الزر أدناه');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: state.licenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final l = state.licenses[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: glassFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: glassBorder),
          ),
          child: Row(
            children: [
              Icon(l.isActive ? Icons.verified_user : Icons.badge_outlined,
                  color: l.isActive ? success : gold, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.holderName.isEmpty ? l.licenseNumber : l.holderName,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${l.licenseType} • ${l.licenseNumber}${l.city.isNotEmpty ? ' • ${l.city}' : ''}',
                        style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
                  ],
                ),
              ),
              _badge(l.statusLabel, l.isActive ? success : gold),
            ],
          ),
        );
      },
    );
  }

  // ─── الصكوك ──────────────────────────────────────────────────
  Widget _deeds(ManagementState state) {
    if (state.isLoading && state.deeds.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.deeds.isEmpty) return _empty('لا توجد صكوك مسجلة', 'سجّل صك ملكية من الزر أدناه');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: state.deeds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final d = state.deeds[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: glassFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: glassBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.balance_outlined, color: success, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.ownerName.isEmpty ? d.deedNumber : d.ownerName,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${d.deedType} • ${d.deedNumber}',
                        style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
                    if (d.area > 0)
                      Text('${Formatters.number(d.area)} م²',
                          style: GoogleFonts.cairo(color: gold, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── أدوات مساعدة ────────────────────────────────────────────
  Widget _empty(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, color: textMuted, size: 48),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label, style: GoogleFonts.cairo(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(label, style: GoogleFonts.cairo(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Color _contractColor(RealEstateContract c) {
    if (c.isCancelled) return red;
    if (c.isAuthenticated) return success;
    return c.isDraft ? gold : blue;
  }

  Color _invoiceColor(String status) {
    return switch (status) {
      'paid' => success,
      'overdue' => red,
      _ => gold,
    };
  }

  Future<void> _run(Future<bool> Function() action, String successMsg) async {
    final ok = await action();
    _toast(ok ? successMsg : (ref.read(managementProvider).error ?? 'فشلت العملية'));
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
    );
  }

  // ─── نماذج الإنشاء ───────────────────────────────────────────
  Future<void> _addContract() async {
    final data = await _showFormSheet('عقد جديد', [
      _field('contract_type', 'نوع العقد', initial: 'إيجار', options: const ['إيجار', 'بيع', 'تمويل']),
      _field('first_party', 'الطرف الأول (المالك)', required: true),
      _field('second_party', 'الطرف الثاني (المستفيد)', required: true),
      _field('property_desc', 'وصف العقار'),
      _field('property_city', 'المدينة'),
      _field('property_district', 'الحي'),
      _field('amount', 'قيمة العقد (ر.س)', numeric: true),
      _field('payment_terms', 'شروط الدفع'),
      _field('duration', 'المدة'),
    ]);
    if (data == null) return;
    final ok = await ref.read(managementProvider.notifier).addContract(data);
    _toast(ok ? 'تم إنشاء العقد' : (ref.read(managementProvider).error ?? 'فشل الإنشاء'));
  }

  Future<void> _addInvoice() async {
    final data = await _showFormSheet('إصدار فاتورة إيجار', [
      _field('tenant_name', 'اسم المستأجر', required: true),
      _field('period_from', 'من الفترة', hint: '2026-09-01'),
      _field('period_to', 'إلى الفترة', hint: '2027-08-31'),
      _field('rent_amount', 'الإيجار الشهري (ر.س)', numeric: true, required: true),
      _field('services_fee', 'رسوم الخدمات (ر.س)', numeric: true),
      _field('tax_amount', 'الضريبة (ر.س)', numeric: true),
      _field('payment_method', 'طريقة الدفع', initial: 'نقدي', options: const ['نقدي', 'تحويل بنكي', 'شيك', 'بطاقة ائتمان']),
    ]);
    if (data == null) return;
    final ok = await ref.read(managementProvider.notifier).addInvoice(data);
    _toast(ok ? 'تم إصدار الفاتورة' : (ref.read(managementProvider).error ?? 'فشل الإنشاء'));
  }

  Future<void> _addLicense() async {
    final data = await _showFormSheet('طلب ترخيص عقاري', [
      _field('license_type', 'نوع الترخيص', initial: 'وساطة عقارية', options: const ['وساطة عقارية', 'تقييم عقاري', 'إدارة أملاك', 'تطوير عقاري']),
      _field('holder_name', 'اسم الحامل', required: true),
      _field('holder_id', 'رقم الهوية'),
      _field('city', 'المدينة'),
      _field('notes', 'ملاحظات'),
    ]);
    if (data == null) return;
    final ok = await ref.read(managementProvider.notifier).addLicense(data);
    _toast(ok ? 'تم تقديم طلب الترخيص' : (ref.read(managementProvider).error ?? 'فشل الطلب'));
  }

  Future<void> _addDeed() async {
    final data = await _showFormSheet('تسجيل صك ملكية', [
      _field('owner_name', 'اسم المالك', required: true),
      _field('property_desc', 'وصف العقار'),
      _field('property_city', 'المدينة'),
      _field('property_district', 'الحي'),
      _field('area', 'المساحة (م²)', numeric: true),
      _field('deed_type', 'نوع الصك', initial: 'صك ملكية', options: const ['صك ملكية', 'صك إفراغ', 'صك رهن']),
      _field('issuing_court', 'المحكمة المُصدِّرة', initial: 'المحكمة العامة'),
      _field('issue_date', 'تاريخ الإصدار', hint: '2026-01-01'),
    ]);
    if (data == null) return;
    final ok = await ref.read(managementProvider.notifier).addDeed(data);
    _toast(ok ? 'تم تسجيل الصك' : (ref.read(managementProvider).error ?? 'فشل التسجيل'));
  }

  _FieldSpec _field(String key, String label,
      {String? initial, String? hint, bool numeric = false, bool required = false, List<String>? options}) {
    return _FieldSpec(
      key: key,
      label: label,
      initial: initial,
      hint: hint,
      numeric: numeric,
      required: required,
      options: options,
    );
  }

  Future<Map<String, dynamic>?> _showFormSheet(String title, List<_FieldSpec> specs) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final controllers = <String, TextEditingController>{};
        final selections = <String, String>{};
        for (final s in specs) {
          controllers[s.key] = TextEditingController(text: s.initial ?? '');
          if (s.options != null) selections[s.key] = s.initial ?? s.options!.first;
        }
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: StatefulBuilder(
            builder: (ctx, setSheet) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: textMuted, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: GoogleFonts.cairo(color: gold, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: specs.map((s) {
                        if (s.options != null) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DropdownButtonFormField<String>(
                              initialValue: selections[s.key],
                              dropdownColor: cardDark,
                              style: GoogleFonts.cairo(color: textLight, fontSize: 13),
                              decoration: _decoration(s.label),
                              items: s.options!.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                              onChanged: (v) => setSheet(() => selections[s.key] = v ?? ''),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: controllers[s.key],
                            keyboardType: s.numeric ? TextInputType.number : TextInputType.text,
                            style: GoogleFonts.cairo(color: textLight, fontSize: 13),
                            decoration: _decoration(s.label, hint: s.hint),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      final data = <String, dynamic>{};
                      for (final s in specs) {
                        final value = s.options != null
                            ? (selections[s.key] ?? s.initial ?? '')
                            : (controllers[s.key]?.text.trim() ?? '');
                        if (value.isEmpty && s.required) {
                          _toast('الرجاء تعبئة ${s.label}');
                          return;
                        }
                        if (s.numeric) {
                          data[s.key] = double.tryParse(value) ?? 0;
                        } else {
                          data[s.key] = value;
                        }
                      }
                      Navigator.pop(ctx, data);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: brandGradient),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text('حفظ', style: GoogleFonts.cairo(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.cairo(color: textMuted, fontSize: 12),
      hintStyle: GoogleFonts.cairo(color: textMuted, fontSize: 12),
      filled: true,
      fillColor: glassFill,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _FieldSpec {
  final String key;
  final String label;
  final String? initial;
  final String? hint;
  final bool numeric;
  final bool required;
  final List<String>? options;

  const _FieldSpec({
    required this.key,
    required this.label,
    this.initial,
    this.hint,
    this.numeric = false,
    this.required = false,
    this.options,
  });
}
