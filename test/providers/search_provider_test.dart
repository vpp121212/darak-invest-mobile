import 'package:darak_wa_hayk/providers/search_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchFilters.toParams', () {
    test('omits empty and null values', () {
      const filters = SearchFilters(q: 'فيلا');
      final params = filters.toParams();
      expect(params['q'], 'فيلا');
      expect(params.containsKey('city'), isFalse);
      expect(params.containsKey('minPrice'), isFalse);
    });

    test('keeps provided filters', () {
      const filters = SearchFilters(
        q: '',
        city: 'الرياض',
        purpose: 'بيع',
        minPrice: 500000,
        maxPrice: 2000000,
        rooms: 4,
      );
      final params = filters.toParams();
      expect(params['city'], 'الرياض');
      expect(params['purpose'], 'بيع');
      expect(params['minPrice'], 500000);
      expect(params['maxPrice'], 2000000);
      expect(params['rooms'], 4);
      expect(params.containsKey('q'), isFalse);
    });

    test('maps sort aliases', () {
      expect(const SearchFilters(sort: 'price_asc').toParams()['sort'], 'price_asc');
      expect(const SearchFilters(sort: 'recent').toParams().containsKey('sort'), isFalse);
    });
  });

  group('SearchState', () {
    test('isEmpty is true only for untouched state', () {
      expect(const SearchState().isEmpty, isTrue);
      expect(const SearchState(isSearching: true).isEmpty, isFalse);
      expect(const SearchState(error: 'فشل الاتصال').isEmpty, isFalse);
    });
  });
}
