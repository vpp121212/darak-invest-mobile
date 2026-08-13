import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/token_storage.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthState {
  final String? token;
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isGuest;

  const AuthState({
    this.token,
    this.user,
    this.isLoading = false,
    this.error,
    this.isGuest = false,
  });

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  AuthState copyWith({
    String? token,
    User? user,
    bool? isLoading,
    String? error,
    bool? isGuest,
    bool clearError = false,
  }) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final token = await TokenStorage.readToken();
    if (token == null || token.isEmpty) {
      // وضع الزائر: جلسة تصفح محفوظة بدون حساب.
      final cachedGuest = await TokenStorage.readGuest();
      if (cachedGuest != null && cachedGuest.isNotEmpty) {
        try {
          final guest = User.fromJson(jsonDecode(cachedGuest) as Map<String, dynamic>);
          state = AuthState(user: guest, isGuest: true);
        } catch (_) {
          /* ignore corrupt cache */
        }
      }
      return;
    }

    ApiService.setToken(token);
    final cachedUser = await TokenStorage.readUser();
    if (cachedUser != null) {
      try {

        state = AuthState(token: token, user: User.fromJson(jsonDecode(cachedUser)));
      } catch (_) {
        /* ignore corrupt cache */
      }
    }
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    final token = state.token;
    if (token == null || token.isEmpty) return;
    try {
      final res = await ApiService.getMe();
      final user = User.fromJson((res['user'] ?? res) as Map<String, dynamic>);
      state = state.copyWith(user: user);
      await TokenStorage.saveSession(token, jsonEncode(user.toJson()));
    } catch (_) {
      /* offline: keep cached user */
    }
  }

  /// إعادة تحميل بيانات المستخدم (بعد ترقية الباقة مثلاً).
  Future<void> refreshProfile() => _refreshProfile();

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await TokenStorage.clearGuest();
      final res = await ApiService.login(email, password);
      final token = res['token'] ?? res['accessToken'];
      if (token is! String || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'لم يستجب الخادم بجلسة صالحة، حاول مجدداً',
        );
        return false;
      }
      final user = User.fromJson((res['user'] ?? res) as Map<String, dynamic>);
      ApiService.setToken(token);

      await TokenStorage.saveSession(token, jsonEncode(user.toJson()));

      state = AuthState(token: token, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await TokenStorage.clearGuest();
      final res = await ApiService.register(data);
      final token = res['token'] ?? res['accessToken'];
      if (token is String && token.isNotEmpty) {
        ApiService.setToken(token);
        final user = User.fromJson((res['user'] ?? res) as Map<String, dynamic>);
        await TokenStorage.saveSession(token, jsonEncode(user.toJson()));
        state = AuthState(token: token, user: user);
      } else {
        // Registration succeeded but the server did not auto-login.
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// دخول الزائر — تصفح بدون تسجيل: لا يُنشأ حساب ولا رمز دخول،
  /// فقط جلسة محلية تحفظ في التخزين لاستعادتها عند إعادة الفتح.
  Future<void> enterAsGuest() async {
    await TokenStorage.clear();
    final guest = User(
      id: 'guest',
      name: 'زائر',
      email: '',
      phone: '',
      role: 'guest',
      isVerified: false,
    );
    ApiService.setToken(null);
    await TokenStorage.saveGuest(jsonEncode(guest.toJson()));
    state = AuthState(user: guest, isGuest: true);
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    ApiService.setToken(null);
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
