import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/health_service.dart';
import '../../domain/models/health_data_model.dart';

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService();
});

final healthProvider = StateNotifierProvider<HealthNotifier, AsyncValue<HealthDataModel>>((ref) {
  return HealthNotifier(ref.watch(healthServiceProvider));
});

class HealthNotifier extends StateNotifier<AsyncValue<HealthDataModel>> {
  final HealthService _healthService;
  HealthDataModel? _cachedData;

  HealthNotifier(this._healthService) : super(const AsyncValue.loading());

  Future<void> fetchHealthData({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedData != null) {
      state = AsyncValue.data(_cachedData!);
      return;
    }

    try {
      state = const AsyncValue.loading();
      await _healthService.requestPermissions();
      final data = await _healthService.fetchRecentHealthData();
      _cachedData = data;
      state = AsyncValue.data(data);
    } catch (e) {
      // If permission format fails gracefully, fallback manually
      print('Permission or API error: $e');
      final fallbackData = HealthDataModel(
        steps: 3000,
        sleep: 5.0,
        heartRate: 80.0,
        activeTime: 30,
        caloriesBurned: 100.0,
        isFallback: true,
      );
      _cachedData = fallbackData;
      state = AsyncValue.data(fallbackData);
    }
  }
}
