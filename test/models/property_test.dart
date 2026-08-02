import 'package:flutter_test/flutter_test.dart';
import 'package:darak_wa_hayk/models/property.dart';

void main() {
  group('Property.fromJson', () {
    test('parses a full property matching the live API shape', () {
      final json = <String, dynamic>{
        'id': 12132,
        'title': 'فيلا في حي السلامة',
        'type': 'فيلا',
        'loc': 'جدة',
        'district': 'حي السلامة',
        'city': 'جدة',
        'price': 3500000,
        'rooms': 5,
        'baths': 4,
        'cars': 2,
        'area': 420,
        'year': 2021,
        'age': 3,
        'status': 'active',
        'lat': 21.5775,
        'lng': 39.1443,
        'street': 'شارع الأمير سلطان',
        'streetW': 20,
        'facing': 'شرقي',
        'purpose': 'بيع',
        'desc': 'فيلا فاخرة في حي السلامة',
        'images': <dynamic>[],
        'features': <dynamic>['مسبح', 'حديقة'],
        'trust': 'office',
        'agent': <String, dynamic>{
          'id': 7,
          'name': 'مكتب الأمانة',
          'phone': '0500000000',
        },
      };

      final property = Property.fromJson(json);

      expect(property.id, '12132');
      expect(property.title, 'فيلا في حي السلامة');
      expect(property.city, 'جدة');
      expect(property.price, 3500000);
      expect(property.rooms, 5);
      expect(property.desc, 'فيلا فاخرة في حي السلامة');
      expect(property.features, contains('مسبح'));
      expect(property.agent?.name, 'مكتب الأمانة');
      expect(property.formattedPrice, '3.5 مليون');
      expect(property.trust, 60);
    });

    test('maps trust status strings to scores', () {
      expect(Property.fromJson(const {'trust': 'verified'}).trust, 100);
      expect(Property.fromJson(const {'trust': 'office'}).trust, 60);
      expect(Property.fromJson(const {'trust': 'direct'}).trust, 20);
      expect(Property.fromJson(const {'trust': '85'}).trust, 85);
      expect(Property.fromJson(const {'trust': 50}).trust, 50);
    });

    test('normalises numeric ids from the API to strings', () {
      expect(Property.fromJson(const {'id': 12132}).id, '12132');
      expect(Property.fromJson(const {'_id': 7}).id, '7');
    });

    test('falls back to description when desc is absent', () {
      final json = <String, dynamic>{
        'id': 1,
        'title': 'شقة',
        'description': 'شقة للإيجار',
        'price': 30000,
        'area': 150,
      };

      final property = Property.fromJson(json);
      expect(property.desc, 'شقة للإيجار');
    });

    test('defaults missing fields without crashing', () {
      final property = Property.fromJson(const <String, dynamic>{});
      expect(property.id, '');
      expect(property.title, '');
      expect(property.price, 0);
      expect(property.images, isEmpty);
      expect(property.features, isEmpty);
      expect(property.agent, isNull);
    });
  });

  group('Property.formattedPrice', () {
    test('renders millions and thousands in Arabic', () {
      expect(Property.fromJson(const {'price': 3500000}).formattedPrice, '3.5 مليون');
      expect(Property.fromJson(const {'price': 2000000}).formattedPrice, '2 مليون');
      expect(Property.fromJson(const {'price': 900000}).formattedPrice, '900 ألف');
      expect(Property.fromJson(const {'price': 1500}).formattedPrice, '1.5 ألف');
      expect(Property.fromJson(const {'price': 950}).formattedPrice, '950');
    });
  });

  group('Property round-trip', () {
    test('toJson preserves the important fields', () {
      final json = <String, dynamic>{
        'id': 5,
        'title': 'دوبلكس',
        'type': 'دوبلكس',
        'price': 1800000,
        'images': <dynamic>['/uploads/a.jpg'],
        'features': <dynamic>['حديقة'],
      };
      final property = Property.fromJson(json);
      final out = property.toJson();
      expect(out['_id'], '5');
      expect(out['title'], 'دوبلكس');
      expect(out['images'], contains('/uploads/a.jpg'));
      expect(out['features'], contains('حديقة'));
    });
  });
}
