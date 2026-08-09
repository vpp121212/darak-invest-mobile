import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking.dart';
import '../../models/offer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/brokerage_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// إدارة الوساطة: مواعيد المعاينة وعروض الشراء.
@RoutePage()
class MyBrokerageScreen extends ConsumerStatefulWidget {
  const MyBrokerageScreen({super.key});

  @override
  ConsumerState<MyBrokerageScreen> createState() => _MyBrokerageScreenState();
}

class _MyBrokerageScreenState extends ConsumerState<MyBrokerageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      final auth = ref.read(authProvider);
      if (auth.isLoggedIn) {
        ref.read(brokerageProvider.notifier).load();
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
    final state = ref.watch(brokerageProvider);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text('وساطتي', style: GoogleFonts.cairo(color: gold, fontSize: 17, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: gold,
          labelColor: gold,
          unselectedLabelColor: textMuted,
          labelStyle: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: 'المواعيد (${state.bookings.length})'),
            Tab(text: 'العروض (${state.offers.length})'),
          ],
        ),
      ),
      body: !auth.isLoggedIn
          ? _loggedOut()
          : TabBarView(
              controller: _tabController,
              children: [
                _bookingsList(state),
                _offersList(state),
              ],
            ),
    );
  }

  Widget _loggedOut() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: textMuted, size: 48),
          const SizedBox(height: 12),
          Text('سجّل دخولك لعرض حجوزاتك وعروضك', style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pushRoute(const LoginRoute()),
            child: Text('دخول', style: GoogleFonts.cairo(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _bookingsList(BrokerageState state) {
    if (state.isLoading && state.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.bookings.isEmpty) {
      return _empty('لا توجد مواعيد بعد', 'احجز موعد معاينة من صفحة أي عقار');
    }
    final myId = ref.read(authProvider).user?.id;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = state.bookings[index];
        final isAgent = myId != null && b.agentUserId == myId;
        return _bookingCard(b, isAgent: isAgent, myId: myId);
      },
    );
  }

  Widget _offersList(BrokerageState state) {
    if (state.isLoading && state.offers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.offers.isEmpty) {
      return _empty('لا توجد عروض بعد', 'قدّم عرض شراء على عقار يناسبك');
    }
    final myId = ref.read(authProvider).user?.id;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final o = state.offers[index];
        final isAgent = myId != null && o.propertyAgentUserId == myId;
        return _offerCard(o, isAgent: isAgent);
      },
    );
  }

  Widget _empty(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, color: textMuted, size: 48),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.cairo(color: textLight, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _bookingCard(Booking b, {required bool isAgent, String? myId}) {
    final canCancel = (isAgent && (b.isPending || b.isConfirmed)) ||
        (!isAgent && b.isPending);
    final canConfirm = isAgent && b.isPending;
    final canComplete = isAgent && b.isConfirmed;

    return Container(
      padding: const EdgeInsets.all(14),
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
              _thumb(b.images),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.propertyTitle ?? 'عقار',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${b.type} • ${DateFormat('d MMM yyyy — h:mm a').format(b.scheduledAt)}',
                        style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    _StatusBadge(label: b.statusLabel, color: _statusColor(b.status)),
                  ],
                ),
              ),
            ],
          ),
          if (isAgent && b.buyerName != null) ...[
            const SizedBox(height: 10),
            Text('الطالب: ${b.buyerName} ${b.buyerPhone ?? ''}',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
          ],
          if (b.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(b.note, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
          ],
          if (canCancel || canConfirm || canComplete) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (canConfirm)
                  _actionBtn('تأكيد', success, () => _setBooking(b, 'confirmed')),
                if (canComplete)
                  _actionBtn('إنهاء', success, () => _setBooking(b, 'completed')),
                if (canCancel)
                  _actionBtn('إلغاء', red, () => _setBooking(b, 'cancelled')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _offerCard(Offer o, {required bool isAgent}) {
    final canCancel = !isAgent && o.isPending;
    final canAccept = isAgent && o.isPending;
    final canReject = isAgent && o.isPending;

    return Container(
      padding: const EdgeInsets.all(14),
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
              _thumb(o.images),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.propertyTitle ?? 'عقار',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(color: textLight, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${Formatters.number(o.amount)} ر.س • ${o.paymentMethod}',
                        style: GoogleFonts.cairo(color: gold, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _StatusBadge(label: o.statusLabel, color: _statusColor(o.status)),
                  ],
                ),
              ),
            ],
          ),
          if (isAgent && o.buyerName != null) ...[
            const SizedBox(height: 10),
            Text('المشترِي: ${o.buyerName} ${o.buyerPhone ?? ''}',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
          ],
          if (o.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(o.note, style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
          ],
          if (canAccept || canReject || canCancel) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (canAccept)
                  _actionBtn('قبول', success, () => _setOffer(o, 'accepted')),
                if (canReject)
                  _actionBtn('رفض', red, () => _setOffer(o, 'rejected')),
                if (canCancel)
                  _actionBtn('إلغاء', red, () => _setOffer(o, 'cancelled')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _thumb(List<String> images) {
    final url = images.isNotEmpty ? ApiService.resolveImage(images.first) : '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 60,
        height: 60,
        child: url.isEmpty
            ? Container(color: cardDark, child: const Icon(Icons.home, color: textMuted))
            : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
                Container(color: cardDark, child: const Icon(Icons.home, color: textMuted))),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(label, style: GoogleFonts.cairo(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _setBooking(Booking b, String status) async {
    final ok = await ref.read(brokerageProvider.notifier).updateBookingStatus(b.id, status);
    _toast(ok ? 'تم تحديث الموعد' : (ref.read(brokerageProvider).error ?? 'فشل التحديث'));
  }

  Future<void> _setOffer(Offer o, String status) async {
    final ok = await ref.read(brokerageProvider.notifier).updateOfferStatus(o.id, status);
    _toast(ok ? 'تم تحديث العرض' : (ref.read(brokerageProvider).error ?? 'فشل التحديث'));
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'pending' => gold,
      'confirmed' => blue,
      'completed' || 'accepted' => success,
      'cancelled' || 'rejected' => red,
      _ => textMuted,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
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
}
