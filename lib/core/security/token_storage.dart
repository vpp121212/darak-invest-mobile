import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure persistence for the auth session.
///
/// Uses the OS keychain/keystore on mobile via [FlutterSecureStorage] and
/// degrades to [SharedPreferences] only on web or if the secure backend is
/// unavailable, so auth never breaks on unsupported platforms.
class TokenStorage {
  TokenStorage._();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static bool get _useSecure => !kIsWeb;

  static Future<String?> readToken() async {
    if (_useSecure) {
      try {
        final v = await _secure.read(key: _tokenKey);
        if (v != null && v.isNotEmpty) return v;
      } catch (_) {
        /* fall through to prefs */
      }
    }
    return _prefsGet(_tokenKey);
  }

  static Future<String?> readUser() async {
    if (_useSecure) {
      try {
        final v = await _secure.read(key: _userKey);
        if (v != null && v.isNotEmpty) return v;
      } catch (_) {
        /* fall through to prefs */
      }
    }
    return _prefsGet(_userKey);
  }

  static Future<void> saveSession(String token, String userJson) async {
    if (_useSecure) {
      try {
        await Future.wait([
          _secure.write(key: _tokenKey, value: token),
          _secure.write(key: _userKey, value: userJson),
        ]);
        await _clearPrefs();
        return;
      } catch (_) {
        /* fall through to prefs */
      }
    }
    await _prefsSet(_tokenKey, token);
    await _prefsSet(_userKey, userJson);
  }

  static Future<void> clear() async {
    if (_useSecure) {
      try {
        await Future.wait([
          _secure.delete(key: _tokenKey),
          _secure.delete(key: _userKey),
        ]);
      } catch (_) {
        /* ignore */
      }
    }
    await _clearPrefs();
  }

  static Future<String?> _prefsGet(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> _prefsSet(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
