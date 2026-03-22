class HealthDataModel {
  final int steps;
  final double sleep;
  final double heartRate;
  final int activeTime;        // in minutes
  final double caloriesBurned; // kcal (locally estimated)
  final bool isFallback;

  HealthDataModel({
    required this.steps,
    required this.sleep,
    required this.heartRate,
    required this.activeTime,
    required this.caloriesBurned,
    this.isFallback = false,
  });

  // Status helpers
  bool get isLowSteps => steps < 4000;
  bool get isHighHeartRate => heartRate > 90;
  bool get isLowCalories => caloriesBurned < 150;

  Map<String, dynamic> buildHealthPayload() {
    return {
      'steps': steps,
      'sleep': sleep,
      'heartRate': heartRate,
      'activeTime': activeTime,
      'caloriesBurned': caloriesBurned,
    };
  }

  HealthDataModel copyWith({
    int? steps,
    double? sleep,
    double? heartRate,
    int? activeTime,
    double? caloriesBurned,
    bool? isFallback,
  }) {
    return HealthDataModel(
      steps: steps ?? this.steps,
      sleep: sleep ?? this.sleep,
      heartRate: heartRate ?? this.heartRate,
      activeTime: activeTime ?? this.activeTime,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}
