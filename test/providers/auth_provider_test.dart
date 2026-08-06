import 'package:darak_wa_hayk/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthState', () {
    test('isLoggedIn is false without a token', () {
      expect(const AuthState().isLoggedIn, isFalse);
      expect(const AuthState(token: '').isLoggedIn, isFalse);
    });

    test('isLoggedIn is true with a token', () {
      expect(const AuthState(token: 'abc').isLoggedIn, isTrue);
    });

    test('copyWith updates fields and clears error explicitly', () {
      const state = AuthState(token: 'abc', error: 'فشل');
      final next = state.copyWith(clearError: true);
      expect(next.error, isNull);
      expect(next.token, 'abc');

      final loading = next.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);
    });
  });
}
