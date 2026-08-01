import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';

class AuthState {
  final String? token;
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.token,
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  AuthState copyWith({
    String? token,
    User? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return;

    ApiService.setToken(token);
    final cachedUser = prefs.getString(_userKey);
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
    try {
      final res = await ApiService.getMe();
      final user = User.fromJson((res['user'] ?? res) as Map<String, dynamic>);
      state = state.copyWith(user: user);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (_) {
      /* offline: keep cached user */
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiService.login(email, password);
      final token = (res['token'] ?? res['accessToken']) as String;
      final user = User.fromJson((res['user'] ?? res) as Map<String, dynamic>);
      ApiService.setToken(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));

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
      final res = await ApiService.register(data);
      final token = (res['token'] ?? res['accessToken']) as String?;
      if (token != null) {
        ApiService.setToken(token);
        final user = User.fromJson((res['user'] ?? res) as Map<String, dynamic>);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
        state = AuthState(token: token, user: user);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    ApiService.setToken(null);
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
