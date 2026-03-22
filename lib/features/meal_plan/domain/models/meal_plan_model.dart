class MealPlanModel {
  final MealDetail breakfast;
  final MealDetail lunch;
  final MealDetail dinner;
  final MealDetail snacks;
  final int totalCalories;
  final String tips;

  MealPlanModel({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snacks,
    required this.totalCalories,
    required this.tips,
  });

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    return MealPlanModel(
      breakfast: MealDetail.fromJson(json['breakfast'] as Map<String, dynamic>?),
      lunch: MealDetail.fromJson(json['lunch'] as Map<String, dynamic>?),
      dinner: MealDetail.fromJson(json['dinner'] as Map<String, dynamic>?),
      snacks: MealDetail.fromJson(json['snacks'] as Map<String, dynamic>?),
      totalCalories: (json['totalCalories'] as num?)?.toInt() ?? 0,
      tips: json['tips']?.toString() ?? 'Eat healthy, stay fit.',
    );
  }
}

class MealDetail {
  final String name;
  final List<String> ingredients;
  final int calories;

  MealDetail({
    required this.name,
    required this.ingredients,
    required this.calories,
  });

  factory MealDetail.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MealDetail(name: 'No suggestion', ingredients: [], calories: 0);
    }
    return MealDetail(
      name: json['name']?.toString() ?? 'No suggestion',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      calories: (json['calories'] as num?)?.toInt() ?? 0,
    );
  }
}
