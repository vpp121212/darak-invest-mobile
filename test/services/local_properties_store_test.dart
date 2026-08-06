import 'package:darak_wa_hayk/models/property.dart';
import 'package:darak_wa_hayk/providers/properties_provider.dart';
import 'package:darak_wa_hayk/services/local_properties_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PropertyCatalogueState', () {
    test('starts in a loading state', () {
      const state = PropertyCatalogueState(isLoading: true);
      expect(state.isLoading, isTrue);
      expect(state.properties, isEmpty);
      expect(state.error, isNull);
    });

    test('copyWith preserves unspecified fields and clears error', () {
      final state = PropertyCatalogueState(
        properties: [Property.fromJson(const {'title': 'شقة'})],
        error: 'تعذّر الاتصال',
      );
      final next = state.copyWith(clearError: true);
      expect(next.error, isNull);
      expect(next.properties, hasLength(1));
      expect(next.isLoading, isFalse);
    });
  });

  group('LocalPropertiesStore', () {
    test('returns empty list when nothing is stored', () async {
      expect(await LocalPropertiesStore.loadLocalProperties(), isEmpty);
    });

    test('round-trips a saved property', () async {
      final property = Property.fromJson(const {
        '_id': 'p1',
        'title': 'فيلا',
        'price': 1000000,
      });
      await LocalPropertiesStore.saveLocalProperty(property.toJson());

      final loaded = await LocalPropertiesStore.loadLocalProperties();
      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'p1');
      expect(loaded.first.title, 'فيلا');
    });

    test('clear removes stored properties', () async {
      final property = Property.fromJson(const {'_id': 'p1', 'title': 'فيلا'});
      await LocalPropertiesStore.saveLocalProperty(property.toJson());
      await LocalPropertiesStore.clear();

      expect(await LocalPropertiesStore.loadLocalProperties(), isEmpty);
    });
  });
}
