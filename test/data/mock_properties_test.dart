import 'package:flutter_test/flutter_test.dart';
import 'package:darak_wa_hayk/data/mock_properties.dart';
import 'package:darak_wa_hayk/models/property.dart';

void main() {
  group('MockProperties.demo', () {
    final demo = MockProperties.demo;

    test('is flagged as demo', () {
      expect(demo.isDemo, isTrue);
      expect(demo.title, contains('تجريبي'));
    });

    test('has at least one 360 scene and all links are http(s)', () {
      expect(demo.panoramicImage, isNotEmpty);
      expect(demo.panoramicImages, isNotEmpty);
      expect(demo.panoramicImages, contains(demo.panoramicImage));
      for (final url in demo.panoramicImages) {
        expect(url.startsWith('https://'), isTrue, reason: url);
      }
    });

    test('has at least one GLB model and all links are http(s)', () {
      expect(demo.model3dUrl, isNotEmpty);
      expect(demo.model3dUrls, isNotEmpty);
      expect(demo.model3dUrls, contains(demo.model3dUrl));
      for (final url in demo.model3dUrls) {
        expect(url.startsWith('https://'), isTrue, reason: url);
      }
    });

    test('round-trips through Property.toJson', () {
      final restored = Property.fromJson(demo.toJson());
      expect(restored.title, demo.title);
      expect(restored.panoramicImages, demo.panoramicImages);
      expect(restored.model3dUrls, demo.model3dUrls);
      expect(restored.isDemo, isTrue);
    });
  });
}
