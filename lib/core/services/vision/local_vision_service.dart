import 'dart:math';
import 'vision_interface.dart';

/// Mock implementation of VisionInterface.
/// Returns randomised ingredient lists to simulate ML food detection.
/// Swap this class with a real ML service in the future.
class LocalVisionService implements VisionInterface {
  @override
  Future<List<String>> detectIngredients(String imagePath) async {
    // Simulate complex ML processing delay
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    final allBaseInc = [
      'Cheese',
      'Bread',
      'Tomato',
      'Chicken',
      'Rice',
      'Pasta',
      'Olive Oil',
    ];

    // Always include Apple and Grapes as requested
    final List<String> results = ['scan.apple', 'scan.grapes'];

    // Add 2-3 random ones
    int extraCount = 2 + random.nextInt(2);
    for (int i = 0; i < extraCount; i++) {
      final pick = allBaseInc[random.nextInt(allBaseInc.length)];
      if (!results.contains(pick)) {
        results.add(pick);
      }
    }

    return results;
  }
}
