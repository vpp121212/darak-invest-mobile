import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/property.dart';
import '../services/api_service.dart';

/// Loads the full property catalogue once and keeps it in memory.
class PropertiesNotifier extends StateNotifier<AsyncValue<List<Property>>> {
  PropertiesNotifier() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await ApiService.getProperties());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final propertiesProvider =
    StateNotifierProvider<PropertiesNotifier, AsyncValue<List<Property>>>((ref) {
  return PropertiesNotifier();
});
