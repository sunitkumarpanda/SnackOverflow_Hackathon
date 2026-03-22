import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import '../../features/health/presentation/providers/health_provider.dart';
import '../../features/metabolic/presentation/providers/glucose_provider.dart';
import '../../features/scan/presentation/providers/pantry_provider.dart';

class NotificationEngine {
  final NotificationService _service = NotificationService();

  Future<void> checkAndTrigger(WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    // 1. Fetch Data
    final health = ref.read(healthProvider).valueOrNull;
    final metabolic = ref.read(glucoseProvider).valueOrNull;
    final pantry = ref.read(pantryProvider);

    if (health == null) return;

    // A. LOW ACTIVITY ALERT (Steps < 4000 after 6 PM)
    final now = DateTime.now();
    if (now.hour >= 18 && health.steps < 4000) {
      final key = 'notif_low_activity_\$today';
      if (!(prefs.getBool(key) ?? false)) {
        await _service.showNotification(
          id: 101,
          title: "Low Activity Alert",
          body: "You've walked only \${health.steps} steps today. A 15-minute walk can balance your health.",
        );
        await prefs.setBool(key, true);
      }
    }

    // B. POOR SLEEP ALERT (Sleep < 6)
    if (health.sleep < 6) {
      final key = 'notif_poor_sleep_\$today';
      if (!(prefs.getBool(key) ?? false)) {
        await _service.showNotification(
          id: 102,
          title: "Rest Needed",
          body: "You had poor sleep. Avoid heavy meals and take light food today.",
        );
        await prefs.setBool(key, true);
      }
    }

    // C. HIGH GLUCOSE ALERT
    if (metabolic?.glucoseSpike == "HIGH") {
      final key = 'notif_high_glucose_\$today';
      // Allow multiple times but with 2 hour cooldown
      final lastTime = prefs.getInt(key) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - lastTime > 7200000) {
        await _service.showNotification(
          id: 103,
          title: "Glucose Alert",
          body: "High glucose spike detected. Take a short walk and avoid sugar intake.",
        );
        await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
      }
    }

    // D. HIGH STRESS ALERT (HR > 90)
    if (health.heartRate > 90) {
      final key = 'notif_high_stress_\$today';
      final lastTime = prefs.getInt(key) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - lastTime > 3600000) { // 1 hour cool down
        await _service.showNotification(
          id: 104,
          title: "High Stress Detected",
          body: "Your heart rate is high. Try breathing exercises or rest.",
        );
        await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
      }
    }

    // E. PANTRY EXPIRY ALERT
    for (var item in pantry) {
      if (item.isExpiringSoon) {
        final key = 'notif_expiry_\${item.name}_\$today';
        if (!(prefs.getBool(key) ?? false)) {
          await _service.showNotification(
            id: 200 + pantry.indexOf(item),
            title: "Expiry Alert",
            body: "Your \${item.name} expires soon. Use it today to avoid waste.",
          );
          await prefs.setBool(key, true);
        }
      }
    }
  }

  Future<void> scheduleDailyReminders() async {
    // Breakfast 8 AM
    await _service.scheduleNotification(
      id: 301,
      title: "Breakfast Time 🍳",
      body: "Start your day with a healthy breakfast!",
      scheduledDate: _nextInstance(8),
    );

    // Lunch 1 PM
    await _service.scheduleNotification(
      id: 302,
      title: "Lunch Reminder 🥗",
      body: "Time for a nutritious lunch to fuel your afternoon.",
      scheduledDate: _nextInstance(13),
    );

    // Dinner 8 PM
    await _service.scheduleNotification(
      id: 303,
      title: "Dinner Time 🍽️",
      body: "Keep it light and healthy for a better sleep tonight.",
      scheduledDate: _nextInstance(20),
    );
  }

  DateTime _nextInstance(int hour) {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

final notificationEngineProvider = Provider<NotificationEngine>((ref) {
  return NotificationEngine();
});
