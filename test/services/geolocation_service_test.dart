import 'package:darak_wa_hayk/services/geolocation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeolocationService (non-web)', () {
    test('isSupported is false outside the browser', () {
      expect(GeolocationService.isSupported, isFalse);
    });

    test('locate fails gracefully with a clear message', () async {
      final result = await GeolocationService.locate();
      expect(result.success, isFalse);
      expect(result.point, isNull);
      expect(result.message, isNotNull);
      expect(result.message, isNotEmpty);
    });
  });

  group('GeoResult', () {
    test('success is true only when a point is present', () {
      const success = GeoResult(
        point: GeoPoint(latitude: 24.7, longitude: 46.6),
      );
      expect(success.success, isTrue);
      expect(const GeoResult().success, isFalse);
    });
  });
}
