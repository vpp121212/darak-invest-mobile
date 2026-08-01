import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/estimate_result.dart';
import '../services/api_service.dart';

class EstimateNotifier extends StateNotifier<AsyncValue<EstimateResult?>> {
  EstimateNotifier() : super(const AsyncValue.data(null));

  Future<void> estimate({
    required String city,
    required String district,
    required String type,
    required String purpose,
    required num area,
    required int rooms,
    required int baths,
    List<String> features = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiService.estimate({
        'city': city,
        'district': district,
        'type': type,
        'purpose': purpose,
        'area': area,
        'rooms': rooms,
        'baths': baths,
        'features': features,
      });
      final estimation = (res['estimation'] ?? res) as Map<String, dynamic>;
      state = AsyncValue.data(EstimateResult.fromJson(estimation));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final estimateProvider =
    StateNotifierProvider<EstimateNotifier, AsyncValue<EstimateResult?>>((ref) {
  return EstimateNotifier();
});
