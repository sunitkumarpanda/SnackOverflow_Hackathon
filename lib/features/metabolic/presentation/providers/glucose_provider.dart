import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:healthplate/features/health/presentation/providers/health_provider.dart';
import 'package:healthplate/features/scan/presentation/providers/food_analysis_provider.dart';
import 'package:healthplate/features/profile/presentation/providers/profile_provider.dart';
import 'package:healthplate/features/metabolic/domain/models/metabolic_data_model.dart';
import 'package:healthplate/features/metabolic/domain/services/glucose_engine.dart';

final glucoseProvider = Provider<AsyncValue<MetabolicData>>((ref) {
  final healthAsync = ref.watch(healthProvider);
  final foodScanState = ref.watch(foodAnalysisProvider);
  final profileAsync = ref.watch(profileProvider);

  // We need all data types to be ready, but we can fall back to defaults if not.
  final healthData = healthAsync.valueOrNull;
  final profile = profileAsync.valueOrNull;
  
  // Latest scanned food carbs
  final foodData = foodScanState.result.valueOrNull;
  final carbs = foodData?.carbs ?? 0.0;

  // Use defaults if health data is missing
  final steps = healthData?.steps ?? 3000;
  final heartRate = healthData?.heartRate.toInt() ?? 80;
  final sleep = healthData?.sleep ?? 7.0;
  final conditions = profile?.conditions ?? [];

  // Calculate insights
  final insights = GlucoseEngine.calculate(
    carbs: carbs,
    steps: steps,
    sleep: sleep,
    heartRate: heartRate,
    conditions: List<String>.from(conditions),
  );

  return AsyncValue.data(insights);
});
