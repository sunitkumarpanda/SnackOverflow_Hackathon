/// Local health calculation utilities
class HealthCalculator {
  /// Estimate calories burned from step count (approx 0.04 kcal per step)
  static double caloriesFromSteps(int steps) {
    return (steps * 0.04).roundToDouble();
  }

  /// Estimate active time in minutes from step count
  /// Assuming ~100 steps per minute of moderate activity
  static int activeTimeMinutes(int steps) {
    return (steps / 100).round();
  }
}
