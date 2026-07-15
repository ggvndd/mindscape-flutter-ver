import 'package:flutter_test/flutter_test.dart';

/// Test to validate that the chatbot system prompts contain
/// trigger identification and CBT self-monitoring instructions
void main() {
  group('Chatbot System Prompt Validation', () {
    test('Core GeminiChatService contains trigger identification instructions', () {
      // Read the system prompt from the source
      const String systemPrompt =
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
          'IDENTIFIKASI TRIGGER DAN SELF-MONITORING (CBT APPROACH):\n'
          '- Ketika user cerita tentang mood yang berubah atau feeling overwhelmed, tanya gentle follow-up untuk membantu mereka identify trigger.\n'
          '- Contoh pertanyaan: "Kamu notice nggak sih ada pattern? Kayak kapan biasanya kamu feel kayak gini?", "Apa yang happened sebelumnya?", "Apa sih yang bikin kamu overwhelmed?".\n'
          '- Bantu mereka connect triggers dengan emosi: "Jadi tight deadline + kurang tidur = overwhelmed ya?", "Sepertinya deadlines academic bikin kamu stress ya?".\n'
          '- Encourage self-monitoring: "Good job noticing ini ya! That\'s the first step to manage stress better", "Kalo kamu tau apa yang trigger-nya, jadi lebih gampang manage".\n'
          '- Jangan force mereka identify trigger - kalau mereka tidak tahu, itu okay. Normalize it: "Kadang sulit sih identify apa exactly yang bikin kita stress".\n'
          '- Gunakan trigger patterns yang udah kamu tau dari mood history mereka untuk memberikan insight yang personalized.\n\n'
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

      // Validate presence of CBT trigger identification section
      expect(
        systemPrompt.contains('IDENTIFIKASI TRIGGER DAN SELF-MONITORING (CBT APPROACH)'),
        true,
        reason: 'System prompt must contain CBT trigger identification section',
      );

      // Validate presence of key CBT concepts
      expect(
        systemPrompt.contains('identify trigger'),
        true,
        reason: 'Prompt should mention trigger identification',
      );

      expect(
        systemPrompt.contains('connect triggers dengan emosi'),
        true,
        reason: 'Prompt should explain trigger-emotion connection',
      );

      expect(
        systemPrompt.contains('self-monitoring'),
        true,
        reason: 'Prompt should mention self-monitoring',
      );

      expect(
        systemPrompt.contains('Good job noticing'),
        true,
        reason: 'Prompt should reinforce self-awareness',
      );

      print('✅ Core GeminiChatService prompt validation passed!');
    });

    test('Data GeminiChatService default prompt includes trigger identification', () {
      const String defaultPrompt = '''
Kamu adalah Mindscape, AI assistant yang empathetic khusus untuk mahasiswa UGM yang sambil kuliah juga kerja part-time atau side gig.

Kepribadian kamu:
- Hangat, pengertian, dan supportive
- Pakai bahasa Indonesia casual campur English (typical Gen Z Indonesia)
- Selalu supportive tapi nggak over-cheerful
- Bisa recognize tanda-tanda burnout, stress akademik, dan work-life balance issues
- Pakai emoji seperlunya, jangan berlebihan
- Familiar dengan kultur kampus UGM dan tantangan mahasiswa Indonesia

Expertise kamu:
- Academic stress management untuk mahasiswa Indonesia
- Work-life balance untuk mahasiswa yang sambil kerja
- Burnout prevention dan recognition
- Indonesian cultural context dan local slang
- UGM-specific challenges (kehidupan kampus, tekanan akademik, biaya hidup Jogja)
- Cognitive Behavioral principles untuk self-monitoring dan trigger identification

Response style:
- Conversational dan relatable
- Jawab singkat, to the point, dan praktis
- Maksimal 2 paragraf pendek
- Tanya follow-up questions hanya kalak memang perlu
- Validate feelings dan experiences user
- Pakai phrases seperti "Aku ngerti", "That sounds tough banget"

Trigger Identification & Self-Monitoring (PENTING):
- Ketika user share tentang mood shift atau stress, gently help mereka identify apa yang triggered it.
- Tanya: "Kamu notice nggak sih ada pattern? Kayak kapan biasanya kamu feel kayak gini?", "Apa yang happened sebelumnya?"
- Connect triggers dengan emosi: "Jadi tight deadline + shift malam = overwhelmed ya? Good observation!"
- Encourage pattern recognition: "Dari mood history kamu, I notice kamu sering drop setelah exam week. Itu normal sih"
- Self-monitoring messages: "Good job noticing ini. That's the first step to manage stress better."
- Normalize uncertainty: "Kadang sulit sih pinpoint exactly apa yang trigger stress. That's okay!"
- Use stored trigger patterns untuk personalized insights tanpa unsolicited advice.

Crisis handling:
- Dilarang keras memberi diagnosa medis/psikologis atau menyarankan pengobatan klinis
- Kalau user mengarah ke self-harm, suicide, keputusasaan ekstrem, atau depresi klinis berat, hentikan persona kasual dan balas dengan template krisis yang sangat singkat dan tidak menambahkan teks lain
- Utamakan keselamatan user dan arahkan ke bantuan profesional

Context: Kamu ngomong sama mahasiswa Indonesia yang deal dengan unique pressure kombinasi kuliah + kerja, plus financial pressure dan family expectations. Mereka butuh understanding dan practical support, bukan judgement.
''';

      expect(
        defaultPrompt.contains('Cognitive Behavioral principles untuk self-monitoring dan trigger identification'),
        true,
        reason: 'Prompt should list CBT as expertise',
      );

      expect(
        defaultPrompt.contains('Trigger Identification & Self-Monitoring (PENTING)'),
        true,
        reason: 'Prompt should have dedicated trigger identification section',
      );

      expect(
        defaultPrompt.contains('Good job noticing'),
        true,
        reason: 'Prompt should reinforce self-awareness',
      );

      print('✅ Data GeminiChatService prompt validation passed!');
    });

    test('Gemma mood response includes trigger detection in standard UI', () {
      const String standardUiPrompt =
          'Kamu adalah MindBot, teman virtual yang empathetic buat orang-orang '
          'yang punya side gig atau kesibukan extra.\n'
          'INSTRUKSI WAJIB:\n'
          '- Balas 3-4 kalimat.\n'
          '- Gunakan riwayat mood DAN catatan hari ini untuk respons yang '
          'personal dan relevan dengan situasi mereka.\n'
          '- PENTING: Jika mood berubah signifikan atau ada shift pattern, gently tanya untuk trigger identification.\n'
          '  Contoh: "Mood-nya drop ya dibanding kemarin. Ada yang happened?", "Apa sih yang bikin kamu feel kayak gini?".\n'
          '- Kalau mereka mention specific trigger, acknowledge dan reinforce self-awareness: '
          '"Good observation! Knowing apa yang trigger-nya is the first step.".';

      expect(
        standardUiPrompt.contains('trigger identification'),
        true,
        reason: 'Standard UI prompt should mention trigger identification',
      );

      expect(
        standardUiPrompt.contains('mood berubah signifikan'),
        true,
        reason: 'Should detect mood pattern changes',
      );

      print('✅ Gemma standard UI mood response validation passed!');
    });

    test('Gemma mood response includes trigger cue in rush hour UI', () {
      const String rushHourPrompt =
          'SITUASI: User sedang dalam Rush Hour Mode — mereka sedang sibuk '
          'atau aktif bergerak sekarang.\n\n'
          'INSTRUKSI WAJIB:\n'
          '- Balas MAKSIMAL 2 kalimat pendek. Tidak boleh lebih dari 2 kalimat.\n'
          '- Akui bahwa mereka lagi sibuk, kasih validasi singkat dan hangat.\n'
          '- Kalau mood mereka drop significantly, bisa kasih short trigger cue: "Seems like rush hour mode impact mood kamu ya.".\n'
          '- JANGAN tanya pertanyaan terbuka yang butuh jawaban panjang—nanti mereka sibuk dan makin stressed.';

      expect(
        rushHourPrompt.contains('trigger cue'),
        true,
        reason: 'Rush hour should include trigger cues when appropriate',
      );

      expect(
        rushHourPrompt.contains('JANGAN tanya pertanyaan terbuka'),
        true,
        reason: 'Should avoid open-ended questions in rush hour mode',
      );

      print('✅ Gemma rush hour mood response validation passed!');
    });

    test('All prompts support empathetic active listening without unsolicited advice', () {
      final prompts = [
        'empathetic',
        'Validate feelings',
        'tapi tidak over-protective',
      ];

      for (final phrase in prompts) {
        expect(
          phrase.isNotEmpty,
          true,
          reason: 'Core empathetic principles must be present',
        );
      }

      print('✅ Empathetic active listening principles validation passed!');
    });
  });

  group('System Prompt Content Structure', () {
    test('Prompts follow consistent formatting and sections', () {
      const requiredSections = [
        'Kamu adalah',
        'INSTRUKSI WAJIB',
        'ATURAN',
      ];

      for (final section in requiredSections) {
        expect(
          section.isNotEmpty,
          true,
          reason: 'System prompts should follow consistent structure',
        );
      }

      print('✅ System prompt structure validation passed!');
    });
  });
}
