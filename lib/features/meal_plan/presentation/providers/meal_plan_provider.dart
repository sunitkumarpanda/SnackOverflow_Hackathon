import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/utils/context_builder.dart';
import '../../domain/models/meal_plan_model.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../health/presentation/providers/health_provider.dart';
import '../../../scan/presentation/providers/food_analysis_provider.dart';
import '../../../metabolic/presentation/providers/glucose_provider.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final mealPlanProvider = StateNotifierProvider<MealPlanNotifier, AsyncValue<MealPlanModel>>(
  (ref) {
    return MealPlanNotifier(
      ref.watch(geminiServiceProvider),
      ref,
    );
  },
);

class MealPlanNotifier extends StateNotifier<AsyncValue<MealPlanModel>> {
  final GeminiService _geminiService;
  final Ref _ref;

  MealPlanNotifier(this._geminiService, this._ref) : super(const AsyncValue.loading());

  Future<void> generatePlan(String language) async {
    try {
      state = const AsyncValue.loading();
      
      final profile = _ref.read(profileProvider).valueOrNull;
      final health = _ref.read(healthProvider).valueOrNull;
      final fastScan = _ref.read(foodAnalysisProvider).result.valueOrNull;
      final metabolic = _ref.read(glucoseProvider).valueOrNull;

      final context = ContextBuilder.buildFullContext(
        profile: profile,
        health: health,
        lastFood: fastScan,
        metabolic: metabolic,
        language: language,
      );

      final contextString = ContextBuilder.buildContextString(context);

      final payload = await _geminiService.generateMealPlan(
        contextString: contextString,
        language: language,
      );

      final mealPlan = MealPlanModel.fromJson(payload);
      state = AsyncValue.data(mealPlan);

    } catch (e) {
      state = AsyncValue.data(MealPlanModel.fromJson(GeminiService.fallbackMealPlan));
    }
  }
}
