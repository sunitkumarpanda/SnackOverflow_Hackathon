import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/utils/context_builder.dart';
import '../../domain/models/chat_message.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../health/presentation/providers/health_provider.dart';
import '../../../scan/presentation/providers/food_analysis_provider.dart';
import '../../../metabolic/presentation/providers/glucose_provider.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  return ChatNotifier(geminiService, ref);
});

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;

  ChatState({required this.messages, this.isTyping = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isTyping}) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final GeminiService _geminiService;
  final Ref _ref;

  ChatNotifier(this._geminiService, this._ref)
      : super(ChatState(messages: [
          ChatMessage(
            text: "Hello! I'm your DietRAO Health Assistant. How can I help you reach your goals today?",
            isUser: false,
            timestamp: DateTime.now(),
          )
        ]));

  Future<void> sendMessage(String text, String language) async {
    print('ChatProvider: sending message: \$text');
    final userMsg = ChatMessage(text: text, isUser: true, timestamp: DateTime.now());
    state = state.copyWith(messages: [...state.messages, userMsg], isTyping: true);

    try {
      final profile = _ref.read(profileProvider).valueOrNull;
      final health = _ref.read(healthProvider).valueOrNull;
      final lastFood = _ref.read(foodAnalysisProvider).result.valueOrNull;
      final metabolic = _ref.read(glucoseProvider).valueOrNull;

      final context = ContextBuilder.buildFullContext(
        profile: profile,
        health: health,
        lastFood: lastFood,
        metabolic: metabolic,
        language: language,
      );

      final contextString = ContextBuilder.buildContextString(context);

      final response = await _geminiService.chatWithAI(
        contextString: contextString,
        userMessage: text,
        language: language,
      );

      final aiMsg = ChatMessage(text: response, isUser: false, timestamp: DateTime.now());
      state = state.copyWith(messages: [...state.messages, aiMsg], isTyping: false);
    } catch (e) {
      final errorMsg = ChatMessage(
        text: "I encountered an error. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, errorMsg], isTyping: false);
    }
  }
}
