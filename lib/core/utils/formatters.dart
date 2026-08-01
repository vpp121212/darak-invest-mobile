/// Shared number/price formatting helpers (Arabic locale aware).
class Formatters {
  Formatters._();

  /// Formats a number with thousands separators: 1234567 -> 1,234,567
  static String number(num value) {
    final s = value.toStringAsFixed(0);
    return s.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  static String compactPrice(num price) {
    if (price >= 1000000) {
      final v = price / 1000000;
      return '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} مليون';
    }
    if (price >= 1000) {
      final v = price / 1000;
      return '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} ألف';
    }
    return number(price);
  }

  static String price(num price, {bool rent = false}) {
    return '${number(price)} ${rent ? 'ر.س/شهر' : 'ر.س'}';
  }

  static String percent(num? value) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(1)}٪';
  }
}
