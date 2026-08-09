import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversation.dart';
import '../services/api_service.dart';

class MessagesState {
  final List<Conversation> conversations;
  final List<Message> messages;
  final String? activeConversationId;
  final bool isLoading;
  final bool sending;
  final String? error;

  const MessagesState({
    this.conversations = const [],
    this.messages = const [],
    this.activeConversationId,
    this.isLoading = false,
    this.sending = false,
    this.error,
  });

  MessagesState copyWith({
    List<Conversation>? conversations,
    List<Message>? messages,
    String? activeConversationId,
    bool? isLoading,
    bool? sending,
    String? error,
    bool clearError = false,
  }) {
    return MessagesState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      isLoading: isLoading ?? this.isLoading,
      sending: sending ?? this.sending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  MessagesNotifier() : super(const MessagesState());

  int get totalUnread =>
      state.conversations.fold(0, (sum, c) => sum + c.unread);

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final conversations = await ApiService.getConversations();
      state = state.copyWith(conversations: conversations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> openConversation(String conversationId) async {
    state = state.copyWith(
      activeConversationId: conversationId,
      isLoading: true,
      clearError: true,
    );
    try {
      final messages = await ApiService.getMessages(conversationId);
      final conversations = state.conversations
          .map((c) => c.id == conversationId ? _withUnread(c, 0) : c)
          .toList();
      state = state.copyWith(
        messages: messages,
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> startConversation({
    required String userId,
    String? propertyId,
  }) async {
    try {
      final id = await ApiService.createConversation(
        userId: userId,
        propertyId: propertyId,
      );
      if (id.isNotEmpty) await loadConversations();
      return id.isEmpty ? null : id;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> sendMessage(String body) async {
    final conversationId = state.activeConversationId;
    if (conversationId == null || body.trim().isEmpty) return false;
    state = state.copyWith(sending: true, clearError: true);
    try {
      await ApiService.sendMessage(conversationId: conversationId, body: body);
      await openConversation(conversationId);
      await loadConversations();
      return true;
    } catch (e) {
      state = state.copyWith(sending: false, error: e.toString());
      return false;
    }
  }

  static Conversation _withUnread(Conversation c, int unread) {
    return Conversation(
      id: c.id,
      otherId: c.otherId,
      otherName: c.otherName,
      otherPhone: c.otherPhone,
      propertyId: c.propertyId,
      propertyTitle: c.propertyTitle,
      images: c.images,
      lastMessage: c.lastMessage,
      lastMessageAt: c.lastMessageAt,
      unread: unread,
      createdAt: c.createdAt,
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final messagesProvider =
    StateNotifierProvider<MessagesNotifier, MessagesState>((ref) {
  return MessagesNotifier();
});
