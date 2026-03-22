import '../models/metabolic_data_model.dart';

class GlucoseEngine {
  /// Calculates metabolic insights based on health and food data.
  static MetabolicData calculate({
    required double carbs,
    required int steps,
    required double sleep,
    required int heartRate,
    required List<String> conditions,
  }) {
    int score = 0;
    List<String> reasons = [];

    // 1. Carb impact
    if (carbs > 60) {
      score += 3;
      reasons.add("High carb intake");
    } else if (carbs >= 30) {
      score += 2;
      reasons.add("Moderate carb intake");
    } else if (carbs > 0) {
      score += 1;
    }

    // 2. Activity impact (Inverse: low activity increases spike risk)
    if (steps < 4000) {
      score += 2;
      reasons.add("Low physical activity");
    } else if (steps < 8000) {
      score += 1;
    }

    // 3. Sleep impact
    if (sleep < 6.0) {
      score += 2;
      reasons.add("Insufficient sleep");
    }

    // 4. Heart rate impact (Metabolic stress)
    if (heartRate > 90) {
      score += 2;
      reasons.add("Elevated heart rate");
    }

    // 5. Special conditions (e.g., Diabetes increases sensitivity)
    if (conditions.contains("Diabetes")) {
      score += 1;
      reasons.add("Diabetes sensitivity");
    }

    // Determine spike level
    String spike;
    if (score >= 6) {
      spike = "HIGH";
    } else if (score >= 3) {
      spike = "MEDIUM";
    } else {
      spike = "LOW";
    }

    // Stress calculation
    String stress;
    if (heartRate > 90) {
      stress = "High";
    } else if (heartRate >= 70) {
      stress = "Normal";
    } else {
      stress = "Low";
    }

    // Suggestions
    String suggestion;
    if (spike == "HIGH") {
      suggestion = "Walk for 20 minutes and drink plenty of water.";
    } else if (spike == "MEDIUM") {
      suggestion = "Avoid further sugar today and stay active.";
    } else {
      suggestion = "Great balance! Keep maintaining your current routine.";
    }

    // Simulated 2-hour curve (9 snapshots)
    final List<double> curve = _generateCurve(spike, carbs);

    return MetabolicData(
      glucoseSpike: spike,
      score: score.clamp(1, 10),
      stressLevel: stress,
      reason: reasons.isEmpty ? "All metrics within healthy range." : reasons.join(" + "),
      suggestion: suggestion,
      glucoseCurve: curve,
    );
  }

  static List<double> _generateCurve(String spike, double carbs) {
    // Base fasting glucose (mock)
    double base = 90.0;
    double peakIncrease;
    
    if (spike == "HIGH") peakIncrease = 70.0;
    else if (spike == "MEDIUM") peakIncrease = 40.0;
    else peakIncrease = 15.0;

    // Simulate 2-hour curve: Fasting -> Rise -> Peak -> Fall
    return [
      base, 
      base + (peakIncrease * 0.4), 
      base + (peakIncrease * 0.8), 
      base + peakIncrease, 
      base + (peakIncrease * 0.9), 
      base + (peakIncrease * 0.7), 
      base + (peakIncrease * 0.4), 
      base + (peakIncrease * 0.2), 
      base + 5
    ];
  }
}
