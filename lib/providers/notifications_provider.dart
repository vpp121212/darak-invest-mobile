import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_item.dart';
import '../services/api_service.dart';

class NotificationsState {
  final List<AppNotification> items;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await ApiService.getNotifications();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markRead(String id) async {
    try {
      await ApiService.markNotificationRead(id);
      final items = state.items
          .map((n) => n.id == id ? _asRead(n) : n)
          .toList();
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllRead() async {
    try {
      await ApiService.markAllNotificationsRead();
      final items = state.items.map(_asRead).toList();
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  static AppNotification _asRead(AppNotification n) {
    return AppNotification(
      id: n.id,
      title: n.title,
      message: n.message,
      type: n.type,
      isRead: true,
      createdAt: n.createdAt,
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});
