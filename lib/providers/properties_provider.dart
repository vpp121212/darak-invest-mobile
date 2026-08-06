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
  final String? error;

  const PropertyCatalogueState({
    this.properties = const [],
    this.isLoading = false,
    this.error,
  });

  PropertyCatalogueState copyWith({
    List<Property>? properties,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PropertyCatalogueState(
      properties: properties ?? this.properties,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Loads the property catalogue once and keeps it in memory.
class PropertiesNotifier extends StateNotifier<PropertyCatalogueState> {
  PropertiesNotifier() : super(const PropertyCatalogueState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    List<Property> apiList = const [];
    String? error;
    try {
      apiList = await ApiService.getProperties();
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
      error: fallback ? error : null,
    );
  }
}

final propertiesProvider =
    StateNotifierProvider<PropertiesNotifier, PropertyCatalogueState>((ref) {
  return PropertiesNotifier();
});
