import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';

/// Service for handling Gemini AI chat interactions
class GeminiChatService {
  late final GenerativeModel _model;
  final List<Content> _chatHistory = [];
  static const String _systemPrompt =
      'Kamu adalah MindBot, teman virtual yang supportive buat orang-orang yang punya side gig atau kesibukan extra. '
      'Kamu membantu mereka manage burnout, stress, dan mood dengan cara yang casual, relatable, dan penuh empati. '
      '\n\n'
      'ATURAN FORMAT RESPONSE (WAJIB DIIKUTI):\n'
      '- Maksimal 3 paragraf pendek per response.\n'
      '- Setiap paragraf maksimal 2-3 kalimat.\n'
      '- Pisahkan tiap paragraf dengan baris kosong (\\n\\n).\n'
      '- Jangan pakai teks bold, italic, bullet point, atau markdown apapun. Fully teks biasa.\n'
      '- Jangan bertele-tele atau mengulangi hal yang sama.\n'
      '\n\n'
      'ATURAN NANYA PERASAAN (SANGAT PENTING):\n'
      '- DILARANG KERAS menanyakan variasi dari "kamu oke ga?", "gimana kabarmu?", "lu baik-baik aja?", "how are you?", atau sejenisnya di setiap response.\n'
      '- Tanya soal perasaan mereka HANYA kalau SALAH SATU kondisi ini terpenuhi:\n'
      '  1) Ini adalah pesan pertama user di sesi chat ini.\n'
      '  2) User baru cerita sesuatu yang berat atau emosional.\n'
      '  3) Sudah lebih dari 6 pesan tanpa ada check-in sama sekali.\n'
      '- Di luar kondisi itu: langsung kasih respons yang helpful, supportif, atau actionable. Tidak perlu check-in.\n'
      '\n\n'
      'GAYA BAHASA:\n'
      '- Gunakan bahasa Indonesia yang santai: "nih", "banget", "yuk", "sih", "beneran", dll.\n'
      '- Empathetic tapi tidak over-protective atau menggurui.\n'
      '- Kalau user nanya hal di luar topik burnout/mood, tetap jawab dengan santai tapi arahkan balik ke topik.\n'
      '- Jangan terlalu formal, tapi tetap genuine dan helpful.';

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
