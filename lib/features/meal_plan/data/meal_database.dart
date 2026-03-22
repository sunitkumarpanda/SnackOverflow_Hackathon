import 'meal_data_model.dart';
import 'breakfast_meals.dart';
import 'lunch_meals.dart';
import 'dinner_meals.dart';
import 'snack_meals.dart';

/// Central meal database — provides date-based meal selection from 60 hardcoded meals.
class MealDatabase {
  /// Get a deterministic set of 4 meals (one per type) for a given date.
  /// Uses the day-of-year as seed so the same date always returns the same meals.
  static Map<String, RichMeal> getMealsForDate(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return {
      'breakfast': breakfastMeals[dayOfYear % breakfastMeals.length],
      'lunch': lunchMeals[dayOfYear % lunchMeals.length],
      'dinner': dinnerMeals[dayOfYear % dinnerMeals.length],
      'snack': snackMeals[dayOfYear % snackMeals.length],
    };
  }

  /// Shuffle and get a fresh random set for regeneration.
  static Map<String, RichMeal> getRandomMeals() {
    final shuffledB = List<RichMeal>.from(breakfastMeals)..shuffle();
    final shuffledL = List<RichMeal>.from(lunchMeals)..shuffle();
    final shuffledD = List<RichMeal>.from(dinnerMeals)..shuffle();
    final shuffledS = List<RichMeal>.from(snackMeals)..shuffle();
    return {
      'breakfast': shuffledB.first,
      'lunch': shuffledL.first,
      'dinner': shuffledD.first,
      'snack': shuffledS.first,
    };
  }

  /// Total calories for a day's meals.
  static int totalCalories(Map<String, RichMeal> meals) {
    return meals.values.fold(0, (sum, m) => sum + m.calories);
  }

  /// Get 3 recent meals (hardcoded for dashboard).
  static List<RichMeal> getRecentMeals() {
    return [breakfastMeals[0], lunchMeals[3], dinnerMeals[0]];
  }
}
