import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/neighborhood_pulse.dart';
import '../services/api_service.dart';

class PulseNotifier extends StateNotifier<AsyncValue<NeighborhoodPulse?>> {
  PulseNotifier() : super(const AsyncValue.data(null));

  Future<void> load(String district) async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiService.getNeighborhoodPulse(district);
      final pulse = (res['pulse'] ?? res) as Map<String, dynamic>;
      state = AsyncValue.data(NeighborhoodPulse.fromJson(pulse));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final pulseProvider =
    StateNotifierProvider<PulseNotifier, AsyncValue<NeighborhoodPulse?>>((ref) {
  return PulseNotifier();
});
