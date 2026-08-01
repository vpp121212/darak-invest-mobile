import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/property.dart';
import '../services/api_service.dart';

class SearchFilters {
  final String q;
  final String? city;
  final String? district;
  final String? type;
  final String? purpose;
  final String? facing;
  final int? minPrice;
  final int? maxPrice;
  final int? minArea;
  final int? maxArea;
  final int? rooms;
  final String sort;

  const SearchFilters({
    this.q = '',
    this.city,
    this.district,
    this.type,
    this.purpose,
    this.facing,
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.rooms,
    this.sort = 'recent',
  });

  SearchFilters copyWith({
    String? q,
    String? city,
    String? district,
    String? type,
    String? purpose,
    String? facing,
    int? minPrice,
    int? maxPrice,
    int? minArea,
    int? maxArea,
    int? rooms,
    String? sort,
  }) {
    return SearchFilters(
      q: q ?? this.q,
      city: city ?? this.city,
      district: district ?? this.district,
      type: type ?? this.type,
      purpose: purpose ?? this.purpose,
      facing: facing ?? this.facing,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minArea: minArea ?? this.minArea,
      maxArea: maxArea ?? this.maxArea,
      rooms: rooms ?? this.rooms,
      sort: sort ?? this.sort,
    );
  }

  Map<String, dynamic> toParams() {
    final sortValue = switch (sort) {
      'price_asc' => 'price_asc',
      'price_desc' => 'price_desc',
      'area_desc' => 'area_desc',
      _ => null,
    };
    return {
      'q': q.isEmpty ? null : q,
      'city': city,
      'type': type,
      'purpose': purpose,
      'facing': facing,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minArea': minArea,
      'maxArea': maxArea,
      'rooms': rooms,
      'sort': sortValue,
      'limit': 50,
    }..removeWhere((_, v) => v == null || v == '');
  }
}

class SearchState {
  final bool isSearching;
  final List<Property> properties;
  final int total;
  final String? error;

  const SearchState({
    this.isSearching = false,
    this.properties = const [],
    this.total = 0,
    this.error,
  });

  bool get isEmpty => !isSearching && properties.isEmpty && error == null;
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  Timer? _debounce;
  int _requestId = 0;

  void search(SearchFilters filters, {Duration debounce = Duration.zero}) {
    _debounce?.cancel();
    _debounce = Timer(debounce, () => _run(filters));
  }

  Future<void> _run(SearchFilters filters) async {
    final id = ++_requestId;
    state = state.copyWith(isSearching: true, error: null);
    try {
      final res = await ApiService.search(filters.toParams());
      final list = (res['properties'] as List? ?? const [])
          .map((e) {
            final p = Property.fromJson(e as Map<String, dynamic>);
            return p.copyWith(images: p.images.map(ApiService.resolveImage).toList());
          })
          .toList();
      if (id != _requestId) return; // stale response
      state = SearchState(
        isSearching: false,
        properties: list,
        total: res['total'] ?? list.length,
      );
    } catch (e) {
      if (id != _requestId) return;
      state = SearchState(isSearching: false, error: e.toString());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

extension on SearchState {
  SearchState copyWith({
    bool? isSearching,
    List<Property>? properties,
    int? total,
    String? error,
  }) {
    return SearchState(
      isSearching: isSearching ?? this.isSearching,
      properties: properties ?? this.properties,
      total: total ?? this.total,
      error: error ?? this.error,
    );
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) => SearchNotifier());
