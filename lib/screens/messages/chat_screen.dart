import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messages_provider.dart';
import '../../theme/app_theme.dart';

/// شاشة الدردشة: عرض وإرسال رسائل محادثة محددة.
@RoutePage()
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_opened) {
      _opened = true;
      ref.read(messagesProvider.notifier).openConversation(widget.conversationId);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    final ok = await ref.read(messagesProvider.notifier).sendMessage(text);
    _scrollToBottom();
    if (!ok && mounted) {
      final err = ref.read(messagesProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'فشل إرسال الرسالة', style: GoogleFonts.cairo())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesProvider);
    final auth = ref.watch(authProvider);
    final conversation = _find(state.conversations, widget.conversationId);
    final myId = auth.user?.id;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(conversation?.otherName ?? 'المحادثة',
                style: GoogleFonts.cairo(color: textLight, fontSize: 16, fontWeight: FontWeight.bold)),
            if (conversation?.propertyTitle != null)
              Text(conversation!.propertyTitle!,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(color: textMuted, fontSize: 11)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward, color: textLight),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading && state.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _messages(state.messages, myId),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Conversation? _find(List<Conversation> conversations, String id) {
    for (final c in conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  Widget _messages(List<Message> messages, String? myId) {
    if (messages.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 140),
          const Icon(Icons.forum_outlined, color: textMuted, size: 44),
          const SizedBox(height: 12),
          Center(
            child: Text('ابدأ المحادثة — اسأل عن العقار أو تفاوض على السعر',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: textMuted, fontSize: 13)),
          ),
        ],
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final m = messages[index];
        final mine = m.senderId == myId;
        return _bubble(m, mine);
      },
    );
  }

  Widget _bubble(Message m, bool mine) {
    final time = DateFormat('h:mm a').format(m.createdAt);
    return Align(
      alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        decoration: BoxDecoration(
          color: mine ? gold : glassFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mine ? gold : glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(m.body, style: GoogleFonts.cairo(color: mine ? Colors.black : textLight, fontSize: 14, height: 1.4)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: GoogleFonts.cairo(color: mine ? Colors.black54 : textMuted, fontSize: 10)),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(m.isRead ? Icons.done_all : Icons.done, size: 13, color: mine ? Colors.black54 : textMuted),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    final sending = ref.watch(messagesProvider).sending;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: cardDark,
        border: Border(top: BorderSide(color: glassBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              style: GoogleFonts.cairo(color: textLight, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك…',
                hintStyle: GoogleFonts.cairo(color: textMuted, fontSize: 13),
                filled: true,
                fillColor: glassFill,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
