import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messages_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_image.dart';

/// قائمة المحادثات مع الوسطاء والمشترين.
@RoutePage()
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      if (ref.read(authProvider).isLoggedIn) {
        ref.read(messagesProvider.notifier).loadConversations();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final state = ref.watch(messagesProvider);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Text('الرسائل', style: GoogleFonts.cairo(color: gold, fontSize: 17, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon:  Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
      ),
      body: !auth.isLoggedIn
          ? _loggedOut()
          : RefreshIndicator(
              onRefresh: () => ref.read(messagesProvider.notifier).loadConversations(),
              child: _body(state),
            ),
    );
  }

  Widget _loggedOut() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Icon(Icons.chat_bubble_outline, color: textMuted, size: 48),
          const SizedBox(height: 12),
          Text('سجّل دخولك لمراسلة الوسطاء', style: GoogleFonts.cairo(color: textMuted, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pushRoute(const LoginRoute()),
            child: Text('دخول', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _body(MessagesState state) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.conversations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
           Icon(Icons.mark_chat_unread_outlined, color: textMuted, size: 48),
          const SizedBox(height: 12),
          Center(child: Text('لا توجد محادثات', style: GoogleFonts.cairo(color: textMuted, fontSize: 14))),
          const SizedBox(height: 4),
          Center(
            child: Text('راسل وسيطًا من صفحة أي عقار أو من قائمة الوسطاء',
                style: GoogleFonts.cairo(color: textMuted, fontSize: 12)),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = state.conversations[index];
        return _conversationCard(c);
      },
    );
  }

  Widget _conversationCard(Conversation c) {
    final avatarChar = c.otherName.isNotEmpty ? c.otherName.characters.first : '؟';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await ref.read(messagesProvider.notifier).openConversation(c.id);
        if (!mounted) return;
        context.pushRoute(ChatRoute(conversationId: c.id));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: glassFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.unread > 0 ? gold.withValues(alpha: 0.4) : glassBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: gold.withValues(alpha: 0.15),
              child: Text(avatarChar, style: GoogleFonts.cairo(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.otherName,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                                color: textLight, fontSize: 14,
                                fontWeight: c.unread > 0 ? FontWeight.bold : FontWeight.w600)),
                      ),
                      Text(DateFormat('d MMM').format(c.lastMessageAt),
                          style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMessage.isEmpty
                              ? 'بدء محادثة'
                              : c.lastMessage,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                              color: c.unread > 0 ? textLight : textMuted,
                              fontSize: 12,
                              fontWeight: c.unread > 0 ? FontWeight.bold : FontWeight.normal),
                        ),
                      ),
                      if (c.unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration:  BoxDecoration(color: gold, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text('${c.unread}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  if (c.propertyTitle != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                         Icon(Icons.home_work_outlined, color: textMuted, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(c.propertyTitle!,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _thumb(c.images),
          ],
        ),
      ),
    );
  }

  Widget _thumb(List<String> images) {
    final url = images.isNotEmpty ? ApiService.resolveImage(images.first) : '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 48,
        height: 48,
        child: url.isEmpty
            ? Container(color: cardDark, child:  Icon(Icons.home, color: textMuted, size: 20))
            : AppImage(src: url, fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: cardDark),
                errorWidget: (_, __, ___) =>
                    Container(color: cardDark, child:  Icon(Icons.home, color: textMuted, size: 20))),
      ),
    );
  }
}
