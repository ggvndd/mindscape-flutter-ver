import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_config.dart';

/// Generates a short, empathetic MindBot response immediately after the user
/// logs a mood. The tone and length adapt based on which UI was active
/// (`standard_ui` vs `rush_hour_ui`) and the user's last 7-day mood history.
///
/// This is separate from [GeminiChatService] — it fires a single-shot
/// `generateContent` call, not a multi-turn chat session.
class GemmaMoodResponseService {
  GemmaMoodResponseService._();
  static final GemmaMoodResponseService instance =
      GemmaMoodResponseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Map<String, String> _moodLabels = {
    'gloomy': 'Depresi',
    'sad': 'Sedih',
    'justokay': 'Biasa Aja',
    'fine': 'Senang',
    'happy': 'Sangat Senang',
    'cheerful': 'Ceria',
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Fetches the user's last 7 mood documents, builds a history summary,
  /// then calls the Gemma API and returns an empathetic response string.
  ///
  /// [uiCondition] must be `'standard_ui'` or `'rush_hour_ui'`.
  Future<String> getGemmaResponse({
    required String userId,
    required String currentMood,
    required String? currentNote,
    required String uiCondition,
  }) async {
    final historySummary = await _buildHistorySummary(userId);
    return _callApi(
      currentMood: currentMood,
      currentNote: currentNote,
      uiCondition: uiCondition,
      historySummary: historySummary,
    );
  }

  // ── History summary ────────────────────────────────────────────────────────

  /// Queries the last 7 mood documents and formats them as a count string,
  /// e.g. `"7 hari terakhir: 3x Sedih, 2x Biasa Aja, 1x Senang"`.
  Future<String> _buildHistorySummary(String userId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('moods')
          .orderBy('timestamp', descending: true)
          .limit(7)
          .get();

      if (snapshot.docs.isEmpty) return 'Belum ada riwayat mood.';

      final Map<String, int> counts = {};
      for (final doc in snapshot.docs) {
        final mood = (doc.data()['mood'] as String?) ?? 'justokay';
        counts[mood] = (counts[mood] ?? 0) + 1;
      }

      final parts = counts.entries
          .map((e) => '${e.value}x ${_moodLabels[e.key] ?? e.key}')
          .join(', ');

      return '7 hari terakhir: $parts';
    } catch (_) {
      return 'Riwayat tidak tersedia.';
    }
  }

  // ── API call ───────────────────────────────────────────────────────────────

  Future<String> _callApi({
    required String currentMood,
    required String? currentNote,
    required String uiCondition,
    required String historySummary,
  }) async {
    try {
      final model = GenerativeModel(
        model: ApiConfig.geminiFlashModel,
        apiKey: ApiConfig.geminiApiKey,
      );

      final moodDisplay = _moodLabels[currentMood] ?? currentMood;
      final noteText = (currentNote != null && currentNote.isNotEmpty)
          ? '"$currentNote"'
          : 'tidak ada';

      final String prompt;

      if (uiCondition == 'rush_hour_ui') {
        // ── Rush Hour: max 2 sentences, no open-ended questions ───────────
        prompt =
            'Kamu adalah MindBot, teman virtual yang empathetic buat orang-orang '
            'yang punya side gig atau kesibukan extra.\n'
            '$historySummary\n'
            'User baru saja mencatat mood: $moodDisplay\n'
            'Catatan user: $noteText\n\n'
            'SITUASI: User sedang dalam Rush Hour Mode — mereka sedang sibuk '
            'atau aktif bergerak sekarang.\n\n'
            'INSTRUKSI WAJIB:\n'
            '- Balas MAKSIMAL 2 kalimat pendek. Tidak boleh lebih dari 2 kalimat.\n'
            '- Akui bahwa mereka lagi sibuk, kasih validasi singkat dan hangat.\n'
            '- JANGAN tanya pertanyaan terbuka yang butuh jawaban panjang.\n'
            '- Bahasa Indonesia santai: "nih", "banget", "yuk", "sih", dll.\n'
            '- Teks biasa saja, tidak ada markdown, bold, atau bullet point.\n\n'
            'Balas sekarang:';
      } else {
        // ── Standard UI: 3-4 sentences, gentle follow-up question ─────────
        prompt =
            'Kamu adalah MindBot, teman virtual yang empathetic buat orang-orang '
            'yang punya side gig atau kesibukan extra.\n'
            '$historySummary\n'
            'User baru saja mencatat mood: $moodDisplay\n'
            'Catatan user: $noteText\n\n'
            'INSTRUKSI WAJIB:\n'
            '- Balas 3-4 kalimat.\n'
            '- Gunakan riwayat mood DAN catatan hari ini untuk respons yang '
            'personal dan relevan dengan situasi mereka.\n'
            '- Akhiri dengan SATU pertanyaan lembut yang relevan.\n'
            '- Bahasa Indonesia santai: "nih", "banget", "yuk", "sih", dll.\n'
            '- Teks biasa saja, tidak ada markdown, bold, atau bullet point.\n\n'
            'Balas sekarang:';
      }

      final response = await model
          .generateContent([Content.text(prompt)]).timeout(ApiConfig.apiTimeout);

      final raw = response.text ??
          'Makasih udah cerita ya! MindBot lagi nge-lag dikit, coba lagi nanti.';
      return _normalize(raw);
    } on TimeoutException {
      return 'MindBot mau bales tapi koneksinya lagi lambat. Coba lagi bentar ya!';
    } catch (_) {
      return 'Waduh ada gangguan. Tapi that\'s okay — kamu udah lakuin hal yang bagus dengan nyatet mood hari ini!';
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _normalize(String raw) {
    return raw
        .replaceAll(r'\n\n', '\n\n')
        .replaceAll(r'\n', '\n')
        .trim();
  }
}
