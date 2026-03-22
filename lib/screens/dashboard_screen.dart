import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../features/health/presentation/providers/health_provider.dart';
import '../features/health/domain/models/health_data_model.dart';
import '../features/meal_plan/presentation/providers/meal_plan_provider.dart';
import '../features/scan/presentation/screens/scan_screen.dart';
import '../features/metabolic/presentation/screens/metabolic_screen.dart';
import '../features/meal_plan/presentation/screens/meal_screen.dart';
import '../features/chat/presentation/screens/chat_screen.dart';
import '../core/services/notification_engine.dart';
import '../features/metabolic/presentation/providers/glucose_provider.dart';
import '../features/meal_plan/data/meal_database.dart';
import '../features/meal_plan/data/meal_data_model.dart';
import '../features/meal_plan/presentation/widgets/meal_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _currentLang = '';
  int _currentIndex = 0;
  int _expandedMealIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(healthProvider.notifier).fetchHealthData();
      
      // Initialize Smart Notifications
      final engine = ref.read(notificationEngineProvider);
      engine.scheduleDailyReminders();
      engine.checkAndTrigger(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Smart Notification Listeners
    ref.listen(healthProvider, (prev, next) {
      if (next is AsyncData) {
        ref.read(notificationEngineProvider).checkAndTrigger(ref);
      }
    });
    ref.listen(glucoseProvider, (prev, next) {
      if (next is AsyncData) {
        ref.read(notificationEngineProvider).checkAndTrigger(ref);
      }
    });

    final locale = context.locale;
    final langStr = locale.languageCode == 'hi'
        ? 'Hindi'
        : (locale.languageCode == 'or' ? 'Odia' : 'English');

    if (_currentLang != langStr) {
      _currentLang = langStr;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mealPlanProvider.notifier).generatePlan(langStr);
      });
    }

    ref.listen<AsyncValue<HealthDataModel>>(healthProvider, (prev, next) {
      if (!mounted) return;
      next.whenData((health) {
        if (health.isFallback &&
            (prev?.value == null || !prev!.value!.isFallback)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Showing demo health data. Health Connect not linked.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
    });

    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        (user?.displayName == null || user!.displayName!.isEmpty)
            ? 'there'
            : user.displayName!;
    final greeting = _getGreeting(context);

    final List<String> tabTitles = [
      'dashboard.title'.tr(),
      'dashboard.todayMeals'.tr(),
      'Scan Food',
      'Metabolic Insights',
      'Health Assistant',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: 'Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_rounded),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTabIcon(_currentIndex),
                color: const Color(0xFF4CAF50),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tabTitles[_currentIndex],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF4CAF50),
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(
                        (displayName.isNotEmpty ? displayName[0] : 'U')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // ─── TAB 0: DASHBOARD ────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$greeting, \$displayName! 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'dashboard.readyTrack'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'dashboard.streak'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section header
                Text(
                  'dashboard.healthStats'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),

                // 4-card health grid
                Consumer(
                  builder: (context, ref, child) {
                    final healthState = ref.watch(healthProvider);
                    return healthState.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                              color: Color(0xFF4CAF50)),
                        ),
                      ),
                      error: (err, st) => Center(child: Text('Error: \$err')),
                      data: (health) {
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                          children: [
                            _HealthCard(
                              icon: '👣',
                              label: 'dashboard.steps'.tr(),
                              value: health.steps.toString(),
                              unit: 'steps',
                              status: health.isLowSteps ? 'Low' : 'Good',
                              statusColor: health.isLowSteps
                                  ? Colors.orange
                                  : const Color(0xFF4CAF50),
                              bgColor: health.isLowSteps
                                  ? const Color(0xFFFFF3E0)
                                  : const Color(0xFFE8F5E9),
                            ),
                            _HealthCard(
                              icon: '❤️',
                              label: 'dashboard.heartRate'.tr(),
                              value: health.heartRate.round().toString(),
                              unit: 'dashboard.bpm'.tr(),
                              status: health.isHighHeartRate ? 'High' : 'Good',
                              statusColor: health.isHighHeartRate
                                  ? Colors.red
                                  : const Color(0xFF4CAF50),
                              bgColor: health.isHighHeartRate
                                  ? const Color(0xFFFFEBEE)
                                  : const Color(0xFFFCE4EC),
                            ),
                            _HealthCard(
                              icon: '⏱️',
                              label: 'Active Time',
                              value: health.activeTime.toString(),
                              unit: 'min',
                              status: health.activeTime < 20 ? 'Low' : 'Good',
                              statusColor: health.activeTime < 20
                                  ? Colors.orange
                                  : const Color(0xFF4CAF50),
                              bgColor: health.activeTime < 20
                                  ? const Color(0xFFFFF3E0)
                                  : const Color(0xFFE8F5E9),
                            ),
                            _HealthCard(
                              icon: '🔥',
                              label: 'Cal. Burned',
                              value: health.caloriesBurned.round().toString(),
                              unit: 'kcal',
                              status: health.isLowCalories ? 'Low' : 'Good',
                              statusColor: health.isLowCalories
                                  ? Colors.deepOrange
                                  : const Color(0xFF4CAF50),
                              bgColor: health.isLowCalories
                                  ? const Color(0xFFFBE9E7)
                                  : const Color(0xFFE8F5E9),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),

                // ── Recent Meals Section ─────────────────────────────
                Text(
                  'planner.recentMeals'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(MealDatabase.getRecentMeals().length, (i) {
                  final meal = MealDatabase.getRecentMeals()[i];
                  final isExpanded = _expandedMealIndex == i;
                  return MealCard(
                    type: meal.type,
                    meal: meal,
                    isExpanded: isExpanded,
                    onTap: () => setState(() => _expandedMealIndex = isExpanded ? -1 : i),
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // ─── TAB 1: MEAL PLAN ─────────────────────────────────────────
          const MealScreen(),

          // ─── TAB 2: SCAN ──────────────────────────────────────────────
          const ScanScreen(),

          // ─── TAB 3: METABOLIC ─────────────────────────────────────────
          const MetabolicScreen(),

          // ─── TAB 4: CHAT ─────────────────────────────────────────────
          const ChatScreen(),
        ],
      ),
    );
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0: return Icons.dashboard_rounded;
      case 1: return Icons.restaurant_menu_rounded;
      case 2: return Icons.camera_alt_rounded;
      case 3: return Icons.analytics_rounded;
      case 4: return Icons.chat_bubble_rounded;
      default: return Icons.dashboard_rounded;
    }
  }

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'dashboard.goodMorning'.tr();
    if (hour < 17) return 'dashboard.goodAfternoon'.tr();
    return 'dashboard.goodEvening'.tr();
  }
}

// ── Health Card ────────────────────────────────────────────────────────────────
class _HealthCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String unit;
  final String status;
  final Color statusColor;
  final Color bgColor;

  const _HealthCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              height: 1.1,
            ),
          ),
          Text(
            unit,
            style: TextStyle(fontSize: 9, color: Colors.grey[500], height: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }
}
