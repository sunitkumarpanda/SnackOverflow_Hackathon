/// Data model for metabolic insights including glucose and stress data.
class MetabolicData {
  final String glucoseSpike; // "LOW", "MEDIUM", "HIGH"
  final int score; // 1-10 scale
  final String stressLevel; // "Low", "Normal", "High"
  final String reason;
  final String suggestion;
  final List<double> glucoseCurve; // Simulated 2-hour curve values

  MetabolicData({
    required this.glucoseSpike,
    required this.score,
    required this.stressLevel,
    required this.reason,
    required this.suggestion,
    required this.glucoseCurve,
  });

  static MetabolicData get empty => MetabolicData(
        glucoseSpike: "LOW",
        score: 0,
        stressLevel: "Normal",
        reason: "Not enough data recorded yet.",
        suggestion: "Analyze your first meal to see metabolic insights.",
        glucoseCurve: [90, 95, 92, 94, 91],
      );
}
