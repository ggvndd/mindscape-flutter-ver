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

  static const String _crisisResponse =
      'Aku di sini buat dengerin kamu, tapi ini terdengar sangat berat dan kamu berhak mendapat bantuan dari profesional. Tolong jangan lewati ini sendirian. Kamu bisa hubungi layanan darurat atau konseling psikologi terdekat, atau akses Into The Light Indonesia (intothelightid.org) untuk bantuan profesional. Keselamatanmu itu yang paling utama.';

  static const List<String> _crisisKeywords = [
    'bunuh diri',
    'suicide',
    'self harm',
    'self-harm',
    'melukai diri',
    'menyakiti diri',
    'gak kuat lagi',
    'ga kuat lagi',
    'tidak kuat lagi',
    'mati aja',
    'putus asa',
    'depresi berat',
    'depresi klinis',
    'keputusasaan ekstrem',
  ];

  static const String _systemPrompt =
      'Kamu adalah MindBot, teman virtual yang supportive buat orang-orang yang punya side gig atau kesibukan extra. '
      'Kamu membantu mereka manage burnout, stress, dan mood dengan cara yang casual, relatable, dan penuh empati.\n\n'
      'ATURAN FORMAT RESPONSE (WAJIB DIIKUTI):\n'
      '- Maksimal 2 paragraf pendek per response.\n'
      '- Setiap paragraf maksimal 1-2 kalimat.\n'
      '- Pisahkan tiap paragraf dengan satu baris kosong.\n'
      '- Jangan pakai teks bold, italic, bullet point, atau markdown apapun. Fully teks biasa.\n'
      '- Jawab singkat, to the point, dan jangan mengulang ide yang sama.\n\n'
      'ATURAN NANYA PERASAAN (SANGAT PENTING):\n'
      '- DILARANG KERAS menanyakan variasi dari "kamu oke ga?", "gimana kabarmu?", "lu baik-baik aja?", "how are you?", atau sejenisnya di setiap response.\n'
      '- Tanya soal perasaan mereka HANYA kalau SALAH SATU kondisi ini terpenuhi:\n'
      '  1) Ini adalah pesan pertama user di sesi chat ini.\n'
      '  2) User baru cerita sesuatu yang berat atau emosional.\n'
      '  3) Sudah lebih dari 6 pesan tanpa ada check-in sama sekali.\n'
      '- Di luar kondisi itu: langsung kasih respons yang helpful, supportif, atau actionable. Tidak perlu check-in.\n\n'
      'ATURAN KEAMANAN DAN CRISIS INTERVENTION (PRIORITAS TERTINGGI):\n'
      '- Kamu dilarang keras memberikan diagnosa medis, psikologis, atau menyarankan pengobatan klinis.\n'
      '- Jika user mengetik kata kunci atau konteks yang mengarah pada: melukai diri sendiri (self-harm), bunuh diri (suicide), keputusasaan ekstrem, atau depresi klinis berat.\n'
      '- MAKA kamu HARUS menghentikan persona kasualmu dan HANYA membalas dengan template respons krisis berikut, tanpa tambahan teks apapun:\n'
      '"Aku di sini buat dengerin kamu, tapi ini terdengar sangat berat dan kamu berhak mendapat bantuan dari profesional. Tolong jangan lewati ini sendirian. Kamu bisa hubungi layanan darurat atau konseling psikologi terdekat, atau akses Into The Light Indonesia (intothelightid.org) untuk bantuan profesional. Keselamatanmu itu yang paling utama."\n\n'
      'GAYA BAHASA:\n'
      '- Gunakan bahasa Indonesia yang santai: "nih", "banget", "yuk", "sih", "beneran", dll.\n'
      '- Empathetic tapi tidak over-protective atau menggurui.\n'
      '- Kalau user nanya hal di luar topik burnout/mood, tetap jawab dengan santai tapi arahkan balik ke topik.\n'
      '- Jangan terlalu formal, tapi tetap genuine dan helpful.';

  GeminiChatService() {
    _model = GenerativeModel(
      model: ApiConfig.geminiFlashModel,
      apiKey: ApiConfig.geminiApiKey,
      systemInstruction: Content.system(_systemPrompt),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
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

  bool _containsCrisisKeywords(String message) {
    final lowerMessage = message.toLowerCase();
    return _crisisKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

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
      if (_containsCrisisKeywords(message)) {
        return _crisisResponse;
      }

      final String prompt;
      if (chat.history.isEmpty && _moodContext != null) {
        prompt = '$_moodContext\n\n${'=' * 50}\n\nUser: $message';
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

  /// Send a message and stream the response as it arrives.
  Stream<String> sendMessageStream(ChatSession chat, String message) async* {
    try {
      if (_containsCrisisKeywords(message)) {
        yield _crisisResponse;
        return;
      }

      final String prompt;
      if (chat.history.isEmpty && _moodContext != null) {
        prompt = '$_moodContext\n\n${'=' * 50}\n\nUser: $message';
      } else {
        prompt = message;
      }

      final responseStream = chat.sendMessageStream(Content.text(prompt));
      var previousText = '';
      var accumulatedText = '';

      await for (final chunk in responseStream) {
        final currentText = chunk.text ?? '';
        final delta = currentText.startsWith(previousText)
            ? currentText.substring(previousText.length)
            : currentText;
        previousText = currentText;

        if (delta.isEmpty) continue;

        accumulatedText += delta;
        yield _normalizeResponse(accumulatedText);
      }

      if (accumulatedText.isEmpty) {
        yield 'Maaf, aku ga bisa kasih response sekarang. Coba lagi ya!';
      }
    } catch (e) {
      yield 'Waduh, ada error nih: $e. Mind coba lagi?';
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
