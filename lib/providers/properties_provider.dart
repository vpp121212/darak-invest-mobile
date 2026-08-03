import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_properties.dart';
import '../models/property.dart';
import '../services/api_service.dart';
import '../services/local_properties_store.dart';

/// Loads the property catalogue once and keeps it in memory.
///
/// The list always starts with the bundled [MockProperties.demo] so the 360°
/// tour and the 3D dollhouse are reachable immediately on first run, then
/// merges the API result and any locally-saved (offline) properties. An API
/// failure is tolerated — the demo and local data keep the app usable.
class PropertiesNotifier extends StateNotifier<AsyncValue<List<Property>>> {
  PropertiesNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    final List<Property> apiList;
    try {
      apiList = await ApiService.getProperties();
    } catch (_) {
      apiList = const [];
    }
    List<Property> localList = const [];
    try {
      localList = await LocalPropertiesStore.loadLocalProperties();
    } catch (_) {
      localList = const [];
    }
    state = AsyncValue.data([
      ...MockProperties.demoList,
      ...apiList,
      ...localList,
    ]);
  }
}

final propertiesProvider =
    StateNotifierProvider<PropertiesNotifier, AsyncValue<List<Property>>>((ref) {
  return PropertiesNotifier();
});
