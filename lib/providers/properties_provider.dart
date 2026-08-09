import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/env_config.dart';
import '../data/mock_properties.dart';
import '../models/property.dart';
import '../services/api_service.dart';
import '../services/local_properties_store.dart';

/// Immutable catalogue state: the real list plus a nullable error.
///
/// When the API fails the notifier still falls back to the demo + locally
/// saved properties so the app stays usable offline, but the [error] field
/// lets the UI tell the user that the live data failed to load instead of
/// silently showing an empty list.
class PropertyCatalogueState {
  final List<Property> properties;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int total;

  const PropertyCatalogueState({
    this.properties = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.total = 0,
  });

  bool get hasMore => properties.length < total;

  PropertyCatalogueState copyWith({
    List<Property>? properties,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? total,
    bool clearError = false,
  }) {
    return PropertyCatalogueState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      total: total ?? this.total,
    );
  }
}

/// Loads the property catalogue one page at a time and keeps it in memory.
class PropertiesNotifier extends StateNotifier<PropertyCatalogueState> {
  PropertiesNotifier() : super(const PropertyCatalogueState(isLoading: true)) {
    load();
  }

  int _page = 0;
  int _totalPages = 1;

  Future<void> load() async {
    _page = 0;
    _totalPages = 1;
    state = state.copyWith(isLoading: true, isLoadingMore: false, clearError: true);

    List<Property> apiList = const [];
    int total = 0;
    String? error;
    try {
      final result = await ApiService.getProperties(page: 1);
      apiList = result.properties;
      total = result.total;
      _page = 1;
      _totalPages = result.pages;
    } catch (e) {
      error = e.toString();
    }

    List<Property> localList = const [];
    try {
      localList = await LocalPropertiesStore.loadLocalProperties();
    } catch (_) {
      // local cache failure is non-fatal
    }

    final fallback = error != null;
    // Demo content appears only when the live API failed (offline fallback)
    // or when explicitly enabled for development — never alongside live data.
    final demo = (fallback || EnvConfig.showDemoProperty)
        ? MockProperties.demoList
        : const <Property>[];

    state = PropertyCatalogueState(
      properties: [
        ...demo,
        ...apiList,
        ...localList,
      ],
      total: fallback ? (demo.length + localList.length) : total,
      error: fallback ? error : null,
    );
  }

  /// Fetches the next page of the catalogue and appends it to the list.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.properties.isEmpty || _page >= _totalPages) return;
    final next = _page + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await ApiService.getProperties(page: next);
      if (next <= _page) return;
      final seen = state.properties.map((p) => p.id).toSet();
      final fresh = result.properties.where((p) => !seen.contains(p.id)).toList();
      _page = next;
      _totalPages = result.pages;
      state = state.copyWith(
        properties: [...state.properties, ...fresh],
        isLoadingMore: false,
        total: result.total,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final propertiesProvider =
    StateNotifierProvider<PropertiesNotifier, PropertyCatalogueState>((ref) {
  return PropertiesNotifier();
});
