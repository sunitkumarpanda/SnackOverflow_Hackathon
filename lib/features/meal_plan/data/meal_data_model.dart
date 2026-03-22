/// Rich meal model with recipe steps, per-ingredient nutrition, glucose spike.
class RichMeal {
  final String name;
  final String emoji;
  final String type; // breakfast, lunch, dinner, snack
  final int calories;
  final int carbs;
  final int protein;
  final int fat;
  final String glucoseSpike; // LOW, MEDIUM, HIGH
  final List<RichIngredient> ingredients;
  final List<String> steps;
  final String tip;

  const RichMeal({
    required this.name,
    required this.emoji,
    required this.type,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.glucoseSpike,
    required this.ingredients,
    required this.steps,
    this.tip = '',
  });
}

class RichIngredient {
  final String name;
  final String quantity;
  final String timing;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;

  const RichIngredient({
    required this.name,
    required this.quantity,
    this.timing = '',
    this.calories = 0,
    this.carbs = 0,
    this.protein = 0,
    this.fat = 0,
  });
}
