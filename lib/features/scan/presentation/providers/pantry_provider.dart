import 'package:flutter_riverpod/flutter_riverpod.dart';

class PantryItem {
  final String name;
  final DateTime expiryDate;

  PantryItem({required this.name, required this.expiryDate});

  bool get isExpiringSoon {
    final diff = expiryDate.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 2;
  }
}

class PantryNotifier extends StateNotifier<List<PantryItem>> {
  PantryNotifier() : super([
    PantryItem(name: "Milk", expiryDate: DateTime.now().add(const Duration(days: 1))),
    PantryItem(name: "Eggs", expiryDate: DateTime.now().add(const Duration(days: 5))),
    PantryItem(name: "Bread", expiryDate: DateTime.now().add(const Duration(days: 2))),
  ]);
}

final pantryProvider = StateNotifierProvider<PantryNotifier, List<PantryItem>>((ref) {
  return PantryNotifier();
});
