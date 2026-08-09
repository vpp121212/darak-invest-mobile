import 'package:darak_wa_hayk/models/user.dart';
import 'package:darak_wa_hayk/providers/payments_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionPackage catalogue', () {
    test('offers the three tiers in order', () {
      expect(subscriptionPackages.length, 3);
      expect(subscriptionPackages[0].id, 'basic');
      expect(subscriptionPackages[1].id, 'pro');
      expect(subscriptionPackages[2].id, 'enterprise');
    });

    test('prices match the backend catalogue', () {
      expect(subscriptionPackages[0].price, 0);
      expect(subscriptionPackages[1].price, 99);
      expect(subscriptionPackages[2].price, 299);
    });

    test('pro and enterprise list extra features', () {
      expect(subscriptionPackages[1].features.length, greaterThan(subscriptionPackages[0].features.length));
      expect(subscriptionPackages[2].features.length, greaterThan(subscriptionPackages[1].features.length));
    });
  });

  group('User package', () {
    test('parses package fields from /me', () {
      final user = User.fromJson(const {
        'id': 5,
        'name': 'سارة',
        'email': 's@d.sa',
        'phone': '+9665',
        'role': 'user',
        'package': 'pro',
        'packageExpiry': '2026-09-08',
      });
      expect(user.package, 'pro');
      expect(user.isPro, isTrue);
      expect(user.packageExpiry, DateTime(2026, 9, 8));
    });

    test('defaults to basic when absent', () {
      final user = User.fromJson(const {'id': 1, 'name': 'ع', 'email': 'a@b.c', 'phone': '1'});
      expect(user.package, 'basic');
      expect(user.isPro, isFalse);
      expect(user.packageExpiry, isNull);
    });
  });
}
