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

  Map<String, dynamic> toParams({int page = 1}) {
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
      'page': page,
    }..removeWhere((_, v) => v == null || v == '');
  }
}

class SearchState {
  final bool isSearching;
  final bool isLoadingMore;
  final List<Property> properties;
  final int total;
  final String? error;

  const SearchState({
    this.isSearching = false,
    this.isLoadingMore = false,
    this.properties = const [],
    this.total = 0,
    this.error,
  });

  bool get isEmpty => !isSearching && properties.isEmpty && error == null;
  bool get hasMore => properties.length < total;
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  Timer? _debounce;
  int _requestId = 0;
  int _page = 0;
  SearchFilters? _filters;

  void search(SearchFilters filters, {Duration debounce = Duration.zero}) {
    _debounce?.cancel();
    _debounce = Timer(debounce, () => _run(filters));
  }

  Future<void> _run(SearchFilters filters) async {
    final id = ++_requestId;
    _filters = filters;
    _page = 1;
    state = state.copyWith(isSearching: true, isLoadingMore: false, error: null);
    try {
      final res = await ApiService.search(filters.toParams(page: 1));
      final list = _parse(res);
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

  /// Fetches the next results page and appends it to the current list.
  Future<void> loadMore() async {
    final filters = _filters;
    if (filters == null) return;
    if (state.isSearching || state.isLoadingMore || state.properties.isEmpty) return;
    if (!state.hasMore) return;
    final id = _requestId;
    final next = _page + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final res = await ApiService.search(filters.toParams(page: next));
      if (id != _requestId) return;
      final fresh = _parse(res);
      final seen = state.properties.map((p) => p.id).toSet();
      _page = next;
      state = SearchState(
        isSearching: false,
        isLoadingMore: false,
        properties: [...state.properties, ...fresh.where((p) => !seen.contains(p.id))],
        total: res['total'] ?? state.total,
      );
    } catch (_) {
      if (id != _requestId) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  List<Property> _parse(Map<String, dynamic> res) {
    return (res['properties'] as List? ?? const [])
        .map((e) {
          final p = Property.fromJson(e as Map<String, dynamic>);
          return p.copyWith(images: p.images.map(ApiService.resolveImage).toList());
        })
        .toList();
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
    bool? isLoadingMore,
    List<Property>? properties,
    int? total,
    String? error,
  }) {
    return SearchState(
      isSearching: isSearching ?? this.isSearching,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      properties: properties ?? this.properties,
      total: total ?? this.total,
      error: error ?? this.error,
    );
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) => SearchNotifier());
