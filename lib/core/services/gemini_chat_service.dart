import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';

/// Service for handling Gemini AI chat interactions
class GeminiChatService {
  late final GenerativeModel _model;
  final List<Content> _chatHistory = [];
  static const String _systemPrompt = 
      'Kamu adalah MindBot, teman virtual yang supportive untuk mahasiswa UGM yang punya side gig. '
      'Kamu harus berbicara dengan bahasa Indonesia yang casual, relatable, dan empathetic. '
      'Gunakan kata-kata seperti "nih", "banget", "yuk", "kamu pasti capek ya", dll. '
      'Fokus kamu adalah membantu mereka manage burnout dan mood dengan penuh empati. '
      'Jangan terlalu formal, tapi tetap profesional. Berikan support yang genuine.';

  GeminiChatService() {
    _model = GenerativeModel(
      model: ApiConfig.geminiFlashModel, // Using free tier Gemma model
      apiKey: ApiConfig.geminiApiKey,
      // Note: Gemma models don't support systemInstruction
    );
  }

  /// Start a new chat session
  ChatSession startNewChat() {
    _chatHistory.clear();
    return _model.startChat(history: _chatHistory);
  }

  /// Continue existing chat with history
  ChatSession continueChat(List<Content> history) {
    _chatHistory.clear();
    _chatHistory.addAll(history);
    return _model.startChat(history: _chatHistory);
  }

  /// Send a message and get response
  Future<String> sendMessage(ChatSession chat, String message) async {
    try {
      // For Gemma models, prepend system prompt to first message
      final prompt = chat.history.isEmpty 
          ? '$_systemPrompt\n\n' + '='*50 + '\n\nUser: $message' 
          : message;
      
      final response = await chat.sendMessage(Content.text(prompt));
      return response.text ?? 'Maaf, aku ga bisa kasih response sekarang. Coba lagi ya!';
    } catch (e) {
      return 'Waduh, ada error nih: $e. Mind coba lagi?';
    }
  }

  /// Get chat history
  List<Content> getChatHistory(ChatSession chat) {
    return chat.history.toList();
  }

  /// Clear chat history
  void clearHistory() {
    _chatHistory.clear();
  }
}
