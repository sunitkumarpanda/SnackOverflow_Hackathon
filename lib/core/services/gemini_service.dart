import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

class GeminiService {
  Map<String, dynamic>? _lastMealPlanResponse;
  String? _lastMealPlanPrompt;

  Map<String, dynamic>? _lastFoodAnalysisResponse;
  String? _lastFoodAnalysisPromptKey;

  // ─── Fallbacks ─────────────────────────────────────────────────────────────

  static const Map<String, dynamic> fallbackMealPlan = {
    "breakfast": {
      "name": "Oats with milk",
      "ingredients": ["Oats", "Milk", "Honey"],
      "calories": 300
    },
    "lunch": {
      "name": "Dal + Rice",
      "ingredients": ["Dal", "Rice", "Onion", "Tomato"],
      "calories": 600
    },
    "dinner": {
      "name": "Vegetable Soup",
      "ingredients": ["Carrot", "Beans", "Spinach"],
      "calories": 400
    },
    "snacks": {
      "name": "Almonds",
      "ingredients": ["Almonds"],
      "calories": 150
    },
    "totalCalories": 1450,
    "tips": "Stay hydrated and eat balanced meals"
  };

  static const Map<String, dynamic> fallbackFoodAnalysis = {
    "calories": 250,
    "carbs": 40,
    "protein": 4,
    "fat": 2,
    "glucoseSpike": "low",
    "warning": "Safe consumption",
    "suggestion": "No action needed"
  };

  // ─── Meal Plan ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> generateMealPlan({
    required String contextString,
    required String language,
  }) async {
    final String prompt = '''
You are a professional nutritionist AI.

Context:
\$contextString

Task:
- Generate a full day meal plan: breakfast, lunch, dinner, snacks.
- Each meal MUST include: name, ingredients used, and calories.
- Ensure total calories match user needs (based on weight/height/activity).
- Adjust for diseases and suggest healthy swaps.
- Respond STRICTLY in JSON format.
- Respond in language: \$language

JSON FORMAT:
{
  "breakfast": {
    "name": "",
    "ingredients": [],
    "calories": 0
  },
  "lunch": {
    "name": "",
    "ingredients": [],
    "calories": 0
  },
  "dinner": {
    "name": "",
    "ingredients": [],
    "calories": 0
  },
  "snacks": {
    "name": "",
    "ingredients": [],
    "calories": 0
  },
  "totalCalories": 0,
  "tips": ""
}
''';

    if (_lastMealPlanPrompt == prompt && _lastMealPlanResponse != null) {
      return _lastMealPlanResponse!;
    }

    final result = await _callGemini(prompt, fallbackMealPlan);
    if (result != fallbackMealPlan) {
      _lastMealPlanPrompt = prompt;
      _lastMealPlanResponse = result;
    }
    return result;
  }

  // ─── AI Chatbot ─────────────────────────────────────────────────────────────

  Future<String> chatWithAI({
    required String contextString,
    required String userMessage,
    required String language,
  }) async {
    final prompt = '''
You are a health assistant AI.

User Context:
\$contextString

User Question:
\$userMessage

Task:
- Answer based on the provided user health data.
- Give practical, actionable advice.
- Keep response simple and empathetic.
- Respond strictly in language: \$language
''';

    final result = await _callGeminiRawText(prompt);
    return result ?? "I'm having trouble connecting to my AI core. Please try again later.";
  }

  // ─── Food Nutrition Analysis ────────────────────────────────────────────────

  Future<Map<String, dynamic>> analyzeFoodNutrition({
    required List<String> ingredients,
    required Map<String, dynamic> profile,
    required Map<String, dynamic> healthData,
    required String language,
  }) async {
    final ingredientList = ingredients.join(', ');
    final cacheKey = '\$ingredientList|\$language';

    if (_lastFoodAnalysisPromptKey == cacheKey &&
        _lastFoodAnalysisResponse != null) {
      return _lastFoodAnalysisResponse!;
    }

    final conditions = (profile['conditions'] as List?)?.join(', ') ?? 'None';
    final prompt = '''
You are a professional nutritionist AI.

User Profile:
Age: \${profile['age'] ?? 'unknown'}, Weight: \${profile['weight'] ?? 'unknown'}kg
Conditions: \$conditions

Health Data:
Steps: \${healthData['steps'] ?? 3000}, Calories Burned: \${healthData['caloriesBurned'] ?? 120}

Food Detected:
\$ingredientList

Tasks:
- Calculate total calories
- Calculate carbs, protein, fat in grams
- Predict glucose spike level (low / medium / high)
- If spike is high → include a clear warning
- Suggest a health action.

Rules:
- Respond ONLY in JSON, no extra text.
- Respond in language: \$language

JSON FORMAT:
{
  "calories": 0,
  "carbs": 0,
  "protein": 0,
  "fat": 0,
  "glucoseSpike": "low",
  "warning": "",
  "suggestion": ""
}
''';

    final result = await _callGemini(prompt, fallbackFoodAnalysis);
    if (result != fallbackFoodAnalysis) {
      _lastFoodAnalysisPromptKey = cacheKey;
      _lastFoodAnalysisResponse = result;
    }
    return result;
  }

  void clearFoodAnalysisCache() {
    _lastFoodAnalysisPromptKey = null;
    _lastFoodAnalysisResponse = null;
  }

  // ─── Shared HTTP helper ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _callGemini(
    String prompt,
    Map<String, dynamic> fallback,
  ) async {
    final String? rawText = await _callGeminiRawText(prompt);
    if (rawText == null) return fallback;

    try {
      final cleanJsonStr = _cleanJsonString(rawText);
      return jsonDecode(cleanJsonStr) as Map<String, dynamic>;
    } catch (_) {
      return fallback;
    }
  }

  Future<String?> _callGeminiRawText(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      print('GEMINI ERROR: API Key is missing or invalid!');
      return null;
    }

    print('DEBUG: Gemini API Key peek: \${apiKey.substring(0, 4)}...');
    final endpoint = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

    print('DEBUG: Calling Gemini with prompt: \${prompt.substring(0, 100 > prompt.length ? prompt.length : 100)}...');

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    try {
      final response = await http
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"] as String;
      } else {
        print('GEMINI API ERROR: \${response.statusCode}');
        print('BODY: \${response.body}');
      }
      return null;
    } catch (e) {
      print('GEMINI EXCEPTION: \$e');
      return null;
    }
  }

  String _cleanJsonString(String raw) {
    String clean = raw.trim();
    if (clean.startsWith('```json')) {
      clean = clean.substring(7);
    } else if (clean.startsWith('```')) {
      clean = clean.substring(3);
    }
    if (clean.endsWith('```')) {
      clean = clean.substring(0, clean.length - 3);
    }
    return clean.trim();
  }
}
