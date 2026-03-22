import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/services/vision/local_vision_service.dart';
import '../../../../core/utils/payload_builder.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../features/health/presentation/providers/health_provider.dart';
import '../../domain/models/food_analysis_model.dart';

/// State class holding the full scan result + detected ingredients.
class FoodAnalysisState {
  final AsyncValue<FoodAnalysisModel?> result;
  final List<String> detectedIngredients;
  final String? imagePath;
  final bool isDetecting; // true during vision mock phase

  const FoodAnalysisState({
    this.result = const AsyncValue.data(null),
    this.detectedIngredients = const [],
    this.imagePath,
    this.isDetecting = false,
  });

  FoodAnalysisState copyWith({
    AsyncValue<FoodAnalysisModel?>? result,
    List<String>? detectedIngredients,
    String? imagePath,
    bool? isDetecting,
  }) {
    return FoodAnalysisState(
      result: result ?? this.result,
      detectedIngredients: detectedIngredients ?? this.detectedIngredients,
      imagePath: imagePath ?? this.imagePath,
      isDetecting: isDetecting ?? this.isDetecting,
    );
  }
}

class FoodAnalysisNotifier extends StateNotifier<FoodAnalysisState> {
  final Ref _ref;
  final ImagePicker _imagePicker = ImagePicker();
  final LocalVisionService _visionService = LocalVisionService();

  FoodAnalysisNotifier(this._ref) : super(const FoodAnalysisState());

  GeminiService get _geminiService => _ref.read(geminiServiceProvider);

  Future<void> pickAndAnalyze(String language) async {
    // 1. Pick image from gallery
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return; // user cancelled

    // 2. Start detecting (show shimmer with image preview)
    state = state.copyWith(
      imagePath: picked.path,
      isDetecting: true,
      detectedIngredients: [],
      result: const AsyncValue.loading(),
    );

    try {
      // 3. Detect ingredients (mock 2s delay)
      final ingredients = await _visionService.detectIngredients(picked.path);

      state = state.copyWith(
        detectedIngredients: ingredients,
        isDetecting: false,
        result: const AsyncValue.loading(),
      );

      // 4. Gather profile + health data
      final profileState = _ref.read(profileProvider);
      final healthState = _ref.read(healthProvider);

      final profile = profileState.valueOrNull;
      final health = healthState.valueOrNull;

      final payload = PayloadBuilder.buildFoodAnalysisPayload(
        profile: profile,
        health: health,
        ingredients: ingredients,
        language: language,
      );

      // 5. Call Gemini
      final raw = await _geminiService.analyzeFoodNutrition(
        ingredients: ingredients,
        profile: payload['profile'] as Map<String, dynamic>,
        healthData: payload['healthData'] as Map<String, dynamic>,
        language: language,
      );

      final analysis = FoodAnalysisModel.fromJson(raw);
      state = state.copyWith(result: AsyncValue.data(analysis));
    } catch (e, st) {
      state = state.copyWith(
        isDetecting: false,
        result: AsyncValue.error(e, st),
      );
    }
  }

  void reset() {
    _geminiService.clearFoodAnalysisCache();
    state = const FoodAnalysisState();
  }
}

final foodAnalysisProvider =
    StateNotifierProvider<FoodAnalysisNotifier, FoodAnalysisState>(
  (ref) => FoodAnalysisNotifier(ref),
);
