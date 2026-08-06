import 'package:darak_wa_hayk/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.number', () {
    test('adds thousands separators', () {
      expect(Formatters.number(1234567), '1,234,567');
      expect(Formatters.number(999), '999');
      expect(Formatters.number(1000), '1,000');
    });
  });

  group('Formatters.compactPrice', () {
    test('renders millions, thousands and plain numbers', () {
      expect(Formatters.compactPrice(3500000), '3.5 مليون');
      expect(Formatters.compactPrice(2000000), '2 مليون');
      expect(Formatters.compactPrice(900000), '900 ألف');
      expect(Formatters.compactPrice(1500), '1.5 ألف');
      expect(Formatters.compactPrice(950), '950');
    });
  });

  group('Formatters.price', () {
    test('appends currency and optional monthly suffix', () {
      expect(Formatters.price(1500000), '1,500,000 ر.س');
      expect(Formatters.price(4500, rent: true), '4,500 ر.س/شهر');
    });
  });

  group('Formatters.percent', () {
    test('formats percentages and null', () {
      expect(Formatters.percent(7.55), '7.5٪');
      expect(Formatters.percent(null), '-');
    });
  });
}
