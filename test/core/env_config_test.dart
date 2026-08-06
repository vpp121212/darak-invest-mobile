import 'package:darak_wa_hayk/core/config/env_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvConfig', () {
    test('exposes a non-empty production default base URL', () {
      expect(EnvConfig.apiBaseUrl, isNotEmpty);
      expect(EnvConfig.apiBaseUrl.startsWith('https://'), isTrue);
    });

    test('marks the default URL as production', () {
      expect(EnvConfig.isProduction, isTrue);
    });

    test('uses a positive request timeout', () {
      expect(EnvConfig.apiTimeout, greaterThan(Duration.zero));
    });
  });
}
