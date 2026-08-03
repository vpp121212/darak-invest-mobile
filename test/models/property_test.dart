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

  group('Property 360°/3D fields', () {
    test('parses panoramicImage and its aliases', () {
      expect(
        Property.fromJson(const {'panoramicImage': '/uploads/p1.jpg'}).panoramicImage,
        '/uploads/p1.jpg',
      );
      expect(
        Property.fromJson(const {'panoUrl': '/uploads/p2.jpg'}).panoramicImage,
        '/uploads/p2.jpg',
      );
      expect(
        Property.fromJson(const {'panorama': 'https://x.example/p.jpg'}).panoramicImage,
        'https://x.example/p.jpg',
      );
    });

    test('parses panoramicImages and the scenes alias', () {
      final property = Property.fromJson(const {
        'panoramicImages': ['/r1.jpg', '/r2.jpg', '/r3.jpg'],
      });
      expect(property.panoramicImages, hasLength(3));
      expect(property.panoramicImages, containsAll(['/r1.jpg', '/r3.jpg']));

      final scenes = Property.fromJson(const {
        'scenes': ['/s1.jpg', '/s2.jpg'],
      });
      expect(scenes.panoramicImages, hasLength(2));
    });

    test('parses model3dUrl and its aliases', () {
      expect(
        Property.fromJson(const {'model3dUrl': '/models/villa.glb'}).model3dUrl,
        '/models/villa.glb',
      );
      expect(
        Property.fromJson(const {'modelUrl': '/m.gltf'}).model3dUrl,
        '/m.gltf',
      );
      expect(
        Property.fromJson(const {'model3d': '/x.glb'}).model3dUrl,
        '/x.glb',
      );
    });

    test('parses model3dUrls and the models alias', () {
      final property = Property.fromJson(const {
        'model3dUrls': ['/r1.glb', '/r2.glb'],
      });
      expect(property.model3dUrls, hasLength(2));

      final models = Property.fromJson(const {
        'models': ['/a.glb'],
      });
      expect(models.model3dUrls, ['/a.glb']);
    });

    test('defaults new tour fields to empty when absent', () {
      final property = Property.fromJson(const <String, dynamic>{});
      expect(property.panoramicImage, '');
      expect(property.panoramicImages, isEmpty);
      expect(property.model3dUrl, '');
      expect(property.model3dUrls, isEmpty);
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

    test('toJson preserves panoramic and 3D fields', () {
      final property = Property.fromJson(const {
        'panoramicImage': '/p.jpg',
        'panoramicImages': ['/p1.jpg', '/p2.jpg'],
        'model3dUrl': '/m.glb',
        'model3dUrls': ['/m1.glb'],
      });
      final out = property.toJson();
      expect(out['panoramicImage'], '/p.jpg');
      expect(out['panoramicImages'], ['/p1.jpg', '/p2.jpg']);
      expect(out['model3dUrl'], '/m.glb');
      expect(out['model3dUrls'], ['/m1.glb']);
    });

    test('copyWith updates panoramic and 3D fields', () {
      final property = Property.fromJson(const <String, dynamic>{});
      final updated = property.copyWith(
        panoramicImage: '/p.jpg',
        panoramicImages: const ['/a.jpg'],
        model3dUrl: '/m.glb',
        model3dUrls: const ['/m1.glb'],
      );
      expect(updated.panoramicImage, '/p.jpg');
      expect(updated.panoramicImages, ['/a.jpg']);
      expect(updated.model3dUrl, '/m.glb');
      expect(updated.model3dUrls, ['/m1.glb']);
    });
  });
}
