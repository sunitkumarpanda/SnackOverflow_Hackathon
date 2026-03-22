import '../../features/profile/domain/models/user_profile_model.dart';
import '../../features/health/domain/models/health_data_model.dart';

class PayloadBuilder {
  /// Builds a combined payload ready for the AI nutrition analysis prompt.
  static Map<String, dynamic> buildFoodAnalysisPayload({
    required UserProfileModel? profile,
    required HealthDataModel? health,
    required List<String> ingredients,
    required String language,
  }) {
    return {
      'goal': 'analyze_food_nutrition',
      'language': language,
      'profile': profile != null
          ? {
              'height': profile.height,
              'weight': profile.weight,
              'age': profile.age,
              'gender': profile.gender,
              'conditions': profile.conditions,
            }
          : {'conditions': []},
      'healthData': health != null
          ? {
              'steps': health.steps,
              'heartRate': health.heartRate,
              'caloriesBurned': health.caloriesBurned,
            }
          : {'steps': 3000, 'heartRate': 80, 'caloriesBurned': 120},
      'ingredients': ingredients,
    };
  }
}
