import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/meal_database.dart';
import '../../data/meal_data_model.dart';
import '../widgets/meal_card.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late Map<String, RichMeal> _meals;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _meals = MealDatabase.getMealsForDate(_selectedDate);
  }

  void _changeDate(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
      _meals = MealDatabase.getMealsForDate(_selectedDate);
      _expandedIndex = -1;
    });
  }

  void _regenerate() {
    setState(() {
      _meals = MealDatabase.getRandomMeals();
      _expandedIndex = -1;
    });
  }

  String _dateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (sel == today) return 'planner.today'.tr();
    if (sel == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (sel == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('dd MMM').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final totalCal = MealDatabase.totalCalories(_meals);
    final entries = [
      MapEntry('breakfast', _meals['breakfast']!),
      MapEntry('lunch', _meals['lunch']!),
      MapEntry('dinner', _meals['dinner']!),
      MapEntry('snack', _meals['snack']!),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date Navigation ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeDate(-1),
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  color: const Color(0xFF2E7D32),
                ),
                Text(
                  _dateLabel(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
                IconButton(
                  onPressed: () => _changeDate(1),
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  color: const Color(0xFF2E7D32),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Calorie Summary Card ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('planner.totalCalorie'.tr(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85))),
                      const SizedBox(height: 2),
                      Text('planner.dailyPlan'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 6),
                      Text('$totalCal kcal', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Suggested Meals Header ──────────────────────────
            Text('planner.suggestedMeals'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 12),

            // ── Meal Cards ──────────────────────────────────────
            ...List.generate(entries.length, (i) {
              final type = entries[i].key;
              final meal = entries[i].value;
              final isExpanded = _expandedIndex == i;
              return MealCard(
                type: type,
                meal: meal,
                isExpanded: isExpanded,
                onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : i),
              );
            }),

            const SizedBox(height: 20),
            // ── Regenerate Button ────────────────────────────────
            Center(
              child: TextButton.icon(
                onPressed: _regenerate,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('planner.regenerate'.tr()),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF4CAF50)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
