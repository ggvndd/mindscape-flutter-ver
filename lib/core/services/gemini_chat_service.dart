import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../../domain/entities/mood.dart';

/// Service for handling Gemini AI chat interactions
class GeminiChatService {
  late final GenerativeModel _model;
  final List<Content> _chatHistory = [];

  /// Optional mood-history block injected before the first user message.
  String? _moodContext;

  static const String _systemPrompt =
      'Kamu adalah MindBot, teman virtual yang supportive buat orang-orang yang punya side gig atau kesibukan extra. '
      'Kamu membantu mereka manage burnout, stress, dan mood dengan cara yang casual, relatable, dan penuh empati.\n\n'
      'ATURAN FORMAT RESPONSE (WAJIB DIIKUTI):\n'
      '- Maksimal 3 paragraf pendek per response.\n'
      '- Setiap paragraf maksimal 2-3 kalimat.\n'
      '- Pisahkan tiap paragraf dengan satu baris kosong.\n'
      '- Jangan pakai teks bold, italic, bullet point, atau markdown apapun. Fully teks biasa.\n'
      '- Jangan bertele-tele atau mengulangi hal yang sama.\n\n'
      'ATURAN NANYA PERASAAN (SANGAT PENTING):\n'
      '- DILARANG KERAS menanyakan variasi dari "kamu oke ga?", "gimana kabarmu?", "lu baik-baik aja?", "how are you?", atau sejenisnya di setiap response.\n'
      '- Tanya soal perasaan mereka HANYA kalau SALAH SATU kondisi ini terpenuhi:\n'
      '  1) Ini adalah pesan pertama user di sesi chat ini.\n'
      '  2) User baru cerita sesuatu yang berat atau emosional.\n'
      '  3) Sudah lebih dari 6 pesan tanpa ada check-in sama sekali.\n'
      '- Di luar kondisi itu: langsung kasih respons yang helpful, supportif, atau actionable. Tidak perlu check-in.\n\n'
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

  // ── Mood context ─────────────────────────────────────────────────────────

  /// Build and cache a plain-text mood-history block from [recentMoods].
  /// Call this once per chat session, before [sendMessage] is invoked.
  void setMoodContext(List<Mood> recentMoods) {
    if (recentMoods.isEmpty) {
      _moodContext = null;
      return;
    }

    final df = DateFormat('EEEE, d MMM yyyy HH:mm', 'id_ID');
    final buf = StringBuffer();
    buf.writeln('[KONTEKS MOOD USER - 7 HARI TERAKHIR]');
    buf.writeln(
        'Berikut adalah riwayat mood yang sudah dicatat user di Mindscape. '
        'Gunakan sebagai konteks untuk respons yang lebih personal. '
        'Jangan sebut data ini secara eksplisit kecuali user yang tanya.');
    buf.writeln();

    // Map internal mood names to display labels
    final moodLabel = {
      'gloomy': 'Depresi',
      'sad': 'Sedih',
      'justokay': 'Biasa Aja',
      'fine': 'Senang',
      'happy': 'Sangat Senang',
      'cheerful': 'Ceria',
    };

    for (final m in recentMoods) {
      final label = moodLabel[m.mood] ?? m.mood;
      final note = (m.note != null && m.note!.isNotEmpty) ? ' — "${m.note}"' : '';
      buf.writeln('- ${df.format(m.timestamp)}: $label (skor ${m.moodScore}/100)$note');
    }

    // Average score
    final avg =
        (recentMoods.map((m) => m.moodScore).reduce((a, b) => a + b) /
                recentMoods.length)
            .round();
    buf.writeln();
    buf.writeln('Mindscore rata-rata: $avg/100');

    _moodContext = buf.toString().trim();
  }

  // ── Chat sessions ─────────────────────────────────────────────────────────

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

  // ── Messaging ─────────────────────────────────────────────────────────────

  /// Post-process the model response: convert any literal escape sequences
  /// (e.g. the 4-char string \n\n) the model echoes back into real newlines.
  String _normalizeResponse(String raw) {
    return raw
        .replaceAll(r'\n\n', '\n\n') // literal \n\n → two real newlines
        .replaceAll(r'\n', '\n')      // literal \n  → one real newline
        .trim();
  }

  /// Send a message and get response
  Future<String> sendMessage(ChatSession chat, String message) async {
    try {
      // For Gemma models, prepend system prompt (and optional mood context)
      // to the very first message of the session.
      final String prompt;
      if (chat.history.isEmpty) {
        final moodBlock =
            _moodContext != null ? '\n\n$_moodContext\n\n${'=' * 50}' : '';
        prompt = '$_systemPrompt$moodBlock\n\n${'=' * 50}\n\nUser: $message';
      } else {
        prompt = message;
      }

      final response = await chat.sendMessage(Content.text(prompt));
      final raw = response.text ?? 'Maaf, aku ga bisa kasih response sekarang. Coba lagi ya!';
      return _normalizeResponse(raw);
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
