import 'dart:io';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../features/health/domain/models/health_data_model.dart';
import '../utils/health_calculator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthService {
  final Health _health = Health();

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final activityRecognitionStatus =
          await Permission.activityRecognition.request();
      if (!activityRecognitionStatus.isGranted) {
        throw Exception('Activity Recognition permission denied');
      }
    }

    final types = [
      HealthDataType.STEPS,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.HEART_RATE,
    ];

    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];

    bool? hasPermissions =
        await _health.hasPermissions(types, permissions: permissions);
    if (hasPermissions != true) {
      bool granted =
          await _health.requestAuthorization(types, permissions: permissions);
      if (!granted) {
        throw Exception('Health Connect permissions not granted');
      }
    }
  }

  Future<HealthDataModel> fetchRecentHealthData() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(hours: 24));

    int steps = 0;
    double sleep = 0.0;
    double heartRate = 0.0;

    try {
      // STEPS
      final stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: yesterday,
        endTime: now,
      );
      if (stepsData.isNotEmpty) {
        for (var data in stepsData) {
          steps += _getNumericValue(data.value).toInt();
        }
      }

      // SLEEP
      final sleepData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: yesterday,
        endTime: now,
      );
      if (sleepData.isNotEmpty) {
        double totalSleepMin = 0;
        for (var data in sleepData) {
          totalSleepMin += data.dateTo.difference(data.dateFrom).inMinutes;
        }
        sleep = totalSleepMin / 60.0;
      }

      // HEART RATE
      final hrData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: yesterday,
        endTime: now,
      );
      if (hrData.isNotEmpty) {
        double sumHr = 0;
        for (var data in hrData) {
          sumHr += _getNumericValue(data.value);
        }
        heartRate = sumHr / hrData.length;
      }
    } catch (e) {
      // Silent catch — fallback will be used below
    }

    // FALLBACK
    final fallbackSteps = steps > 0 ? steps : 3000;
    final fallbackSleep = sleep > 0 ? sleep : 5.0;
    final fallbackHr = heartRate > 0 ? heartRate : 80.0;
    final isFallback = steps == 0 || heartRate == 0;

    // LOCAL CALCULATIONS
    final calories = HealthCalculator.caloriesFromSteps(fallbackSteps);
    final activeTime = HealthCalculator.activeTimeMinutes(fallbackSteps);

    final result = HealthDataModel(
      steps: fallbackSteps,
      sleep: double.parse(fallbackSleep.toStringAsFixed(1)),
      heartRate: double.parse(fallbackHr.toStringAsFixed(1)),
      caloriesBurned: calories,
      activeTime: activeTime,
      isFallback: isFallback,
    );

    _saveToFirebase(result);
    return result;
  }

  double _getNumericValue(HealthValue value) {
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }
    return 0.0;
  }

  Future<void> _saveToFirebase(HealthDataModel data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('health_logs')
          .add({
        'steps': data.steps,
        'sleep': data.sleep,
        'heartRate': data.heartRate,
        'caloriesBurned': data.caloriesBurned,
        'activeTime': data.activeTime,
        'isFallback': data.isFallback,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
