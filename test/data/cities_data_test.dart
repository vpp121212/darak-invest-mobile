import 'package:flutter_test/flutter_test.dart';

import 'package:darak_wa_hayk/data/cities_data.dart';
import 'package:darak_wa_hayk/models/property.dart';

void main() {
  group('cities data', () {
    test('lists all main cities in order', () {
      expect(kCityNames, contains('الرياض'));
      expect(kCityNames, contains('جدة'));
      expect(kCityNames.length, greaterThanOrEqualTo(10));
    });

    test('Riyadh has four directions with real neighborhoods', () {
      final riyadh = cityByName('الرياض');
      expect(riyadh, isNotNull);
      expect(riyadh!.directions.length, 4);
      expect(
        riyadh.directions.map((d) => d.name),
        containsAll(['شمال الرياض', 'شرق الرياض', 'غرب الرياض', 'جنوب الرياض']),
      );
      for (final dir in riyadh.directions) {
        expect(dir.neighborhoods.length, greaterThanOrEqualTo(10));
      }
      expect(riyadh.allNeighborhoods, contains('الياسمين'));
      expect(riyadh.allNeighborhoods, contains('العريجاء'));
    });

    test('every city exposes neighborhoods', () {
      for (final city in kCities) {
        expect(city.allNeighborhoods, isNotEmpty,
            reason: '${city.name} must list neighborhoods');
      }
    });

    test('nearestCity picks the nearest city from coordinates', () {
      expect(nearestCity(24.7136, 46.6753), 'الرياض');
      expect(nearestCity(21.4858, 39.1925), 'جدة');
      expect(nearestCity(26.4207, 50.0888), 'الدمام');
    });

    test('unknown city is resolved to the nearest known city', () {
      // وسط المملكة يبعد عن جميع المراكز؛ يجب أن يرجع أحد المدن المسجلة.
      final result = nearestCity(23.8859, 45.0792);
      expect(kCityNames, contains(result));
    });
  });

  group('property sector fields', () {
    test('fromJson parses sector, floors and units', () {
      final property = Property.fromJson(const {
        'title': 'فيلا',
        'type': 'فيلا',
        'sector': 'استثماري',
        'floors': 2,
        'units': 3,
      });
      expect(property.sector, 'استثماري');
      expect(property.floors, 2);
      expect(property.units, 3);
    });

    test('toJson round-trips sector, floors and units', () {
      final property = Property.fromJson(const {
        'title': 'فيلا',
        'type': 'فيلا',
        'sector': 'تجاري',
        'floors': 3,
        'units': 4,
      });
      final roundTrip = Property.fromJson(property.toJson());
      expect(roundTrip.sector, 'تجاري');
      expect(roundTrip.floors, 3);
      expect(roundTrip.units, 4);
    });

    test('data: image URIs survive the resolve pipeline', () {
      final property = Property.fromJson(const {
        'title': 'x',
        'images': ['data:image/jpeg;base64,AAAA'],
      });
      expect(property.images, ['data:image/jpeg;base64,AAAA']);
    });
  });
}
