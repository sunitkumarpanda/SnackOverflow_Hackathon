import 'package:healthplate/features/profile/domain/models/user_profile_model.dart';
import 'package:healthplate/features/health/domain/models/health_data_model.dart';
import 'package:healthplate/features/scan/domain/models/food_analysis_model.dart';
import 'package:healthplate/features/metabolic/domain/models/metabolic_data_model.dart';

class ContextBuilder {
  static Map<String, dynamic> buildFullContext({
    UserProfileModel? profile,
    HealthDataModel? health,
    FoodAnalysisModel? lastFood,
    MetabolicData? metabolic,
    String language = 'en',
  }) {
    return {
      'profile': {
        'age': profile?.age ?? 'unknown',
        'gender': profile?.gender ?? 'unknown',
        'weight': profile?.weight ?? 'unknown',
        'height': profile?.height ?? 'unknown',
        'conditions': profile?.conditions ?? [],
      },
      'health': {
        'steps': health?.steps ?? 0,
        'sleep_hours': health?.sleep ?? 0,
        'heart_rate': health?.heartRate ?? 0,
        'calories_burned': health?.caloriesBurned ?? 0,
      },
      'pantry': {
        'last_scanned_food': {
          'calories': lastFood?.calories ?? 0,
          'carbs': lastFood?.carbs ?? 0,
          'protein': lastFood?.protein ?? 0,
          'fat': lastFood?.fat ?? 0,
        }
      },
      'metabolic': {
        'metabolic_score': metabolic?.score ?? 0,
        'glucose_spike_level': metabolic?.glucoseSpike ?? "LOW",
        'stress_level': metabolic?.stressLevel ?? "Normal",
      },
      'settings': {
        'language': language,
      }
    };
  }

  static String buildContextString(Map<String, dynamic> context) {
    // Helper to turn JSON into a readable string for the prompt
    final p = context['profile'];
    final h = context['health'];
    final m = context['metabolic'];

    return '''
User Profile: Age \${p['age']}, \${p['gender']}, Weight \${p['weight']}kg, Height \${p['height']}cm. 
Conditions: \${(p['conditions'] as List).join(', ')}.
Current Health: \${h['steps']} steps today, \${h['sleep_hours']}h sleep, \${h['heart_rate']}bpm heart rate.
Metabolic State: Score \${m['metabolic_score']}/10, Glucose \${m['glucose_spike_level']}, Stress \${m['stress_level']}.
''';
  }
}
