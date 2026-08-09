import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../models/notification_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../theme/app_theme.dart';

/// مركز الإشعارات: تأكيدات المواعيد والعروض والرسائل.
@RoutePage()
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      if (ref.read(authProvider).isLoggedIn) {
        ref.read(notificationsProvider.notifier).load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text('الإشعارات', style: GoogleFonts.cairo(color: gold, fontSize: 17, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (auth.isLoggedIn && state.unreadCount > 0)
            IconButton(
              tooltip: 'تعليم الكل كمقروء',
              icon: const Icon(Icons.done_all, color: textMuted, size: 20),
              onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
            ),
        ],
      ),
      body: !auth.isLoggedIn
          ? _loggedOut()
          : RefreshIndicator(
              onRefresh: () => ref.read(notificationsProvider.notifier).load(),
              child: _body(state),
            ),
    );
  }

  Widget _loggedOut() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, color: textMuted, size: 48),
          const SizedBox(height: 12),
          Text('سجّل دخولك لعرض إشعاراتك', style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pushRoute(const LoginRoute()),
            child: Text('دخول', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _body(NotificationsState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.notifications_none, color: textMuted, size: 48),
          const SizedBox(height: 12),
          Center(child: Text('لا توجد إشعارات', style: GoogleFonts.cairo(color: textMuted, fontSize: 14))),
          const SizedBox(height: 4),
          Center(
            child: Text('ستصلك تحديثات مواعيدك وعروضك ورسائلك هنا',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final n = state.items[index];
        return _notificationCard(n);
      },
    );
  }

  Widget _notificationCard(AppNotification n) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: n.isRead
          ? null
          : () => ref.read(notificationsProvider.notifier).markRead(n.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? glassFill : gold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: n.isRead ? glassBorder : gold.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _typeColor(n.type).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(_typeIcon(n.type), color: _typeColor(n.type), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(n.title,
                            style: GoogleFonts.cairo(
                                color: textLight, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                      Text(DateFormat('d MMM — h:mm a').format(n.createdAt),
                          style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(n.message, style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
                ],
              ),
            ),
            if (!n.isRead) ...[
              const SizedBox(width: 8),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: gold, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'booking' => Icons.event_available,
      'offer' => Icons.request_quote,
      'message' => Icons.chat_bubble_outline,
      'payment' => Icons.payments_outlined,
      _ => Icons.info_outline,
    };
  }

  Color _typeColor(String type) {
    return switch (type) {
      'booking' => cyan,
      'offer' => gold,
      'message' => blue,
      'payment' => success,
      _ => textMuted,
    };
  }
}
