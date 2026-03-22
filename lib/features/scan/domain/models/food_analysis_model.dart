/// Data model for a single food analysis result from the AI.
class FoodAnalysisModel {
  final int calories;
  final double carbs;
  final double protein;
  final double fat;
  final String glucoseSpike; // "low" | "medium" | "high"
  final String warning;
  final String suggestion;

  FoodAnalysisModel({
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.glucoseSpike,
    required this.warning,
    required this.suggestion,
  });

  factory FoodAnalysisModel.fromJson(Map<String, dynamic> json) {
    final carbs = (json['carbs'] as num?)?.toDouble() ?? 40.0;
    return FoodAnalysisModel(
      calories: (json['calories'] as num?)?.toInt() ?? 250,
      carbs: carbs,
      protein: (json['protein'] as num?)?.toDouble() ?? 4.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 2.0,
      glucoseSpike: _resolveGlucoseSpike(json['glucoseSpike']?.toString(), carbs),
      warning: json['warning']?.toString() ?? 'Safe consumption',
      suggestion: json['suggestion']?.toString() ?? 'No action needed',
    );
  }

  /// Local fallback logic if Gemini doesn't classify spike.
  static String _resolveGlucoseSpike(String? fromAI, double carbs) {
    if (fromAI != null &&
        (fromAI == 'low' || fromAI == 'medium' || fromAI == 'high')) {
      return fromAI;
    }
    if (carbs > 60) return 'high';
    if (carbs >= 30) return 'medium';
    return 'low';
  }

  static FoodAnalysisModel get fallback => FoodAnalysisModel(
        calories: 250,
        carbs: 40,
        protein: 4,
        fat: 2,
        glucoseSpike: 'low',
        warning: 'Safe consumption',
        suggestion: 'No action needed',
      );
}
