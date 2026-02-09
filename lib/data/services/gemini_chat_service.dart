import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/mood_entry.dart';
import '../models/conversation_context.dart';
import '../../core/constants/app_constants.dart';
import '../../core/config/api_config.dart';

/// Google Gemini AI service with Firebase integration
/// Perfect for all-Google-services architecture
class GeminiChatService {
  final GenerativeModel _geminiFlash;
  final GenerativeModel _geminiPro;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _systemPrompt;
  
  GeminiChatService({
    String? customSystemPrompt,
  }) : _geminiFlash = GenerativeModel(
         model: ApiConfig.geminiFlashModel,
         apiKey: ApiConfig.geminiApiKey,
         systemInstruction: Content.text(customSystemPrompt ?? _defaultSystemPrompt),
         generationConfig: GenerationConfig(
           temperature: 0.7,
           topK: 40,
           topP: 0.8,
           maxOutputTokens: 300, // Shorter for quick responses
         ),
         safetySettings: [
           SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
           SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
           SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
           SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
         ],
       ),
       _geminiPro = GenerativeModel(
         model: ApiConfig.geminiProModel,
         apiKey: ApiConfig.geminiApiKey,
         systemInstruction: Content.text(customSystemPrompt ?? _defaultSystemPrompt),
         generationConfig: GenerationConfig(
           temperature: 0.7,
           topK: 40,
           topP: 0.8,
           maxOutputTokens: 500, // Longer for detailed conversations
         ),
         safetySettings: [
           SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
           SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
           SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
           SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
         ],
       ),
       _firestore = FirebaseFirestore.instance,
       _auth = FirebaseAuth.instance,
       _systemPrompt = customSystemPrompt ?? _defaultSystemPrompt;
  
  static const String _defaultSystemPrompt = '''
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

Response style:
- Conversational dan relatable
- Tanya follow-up questions untuk understand better
- Kasih advice yang praktis dan actionable
- Validate feelings dan experiences user
- Pakai phrases seperti "Aku ngerti", "Gimana kabar kamu", "That sounds tough banget"

Crisis handling:
- Kalau user tanda-tanda depresi berat, self-harm, atau suicide ideation, gentle suggest professional help
- Mention UGM counseling services atau Sejiwa kalau perlu
- Never dismiss serious mental health concerns

Context: Kamu ngomong sama mahasiswa Indonesia yang deal dengan unique pressure kombinasi kuliah + kerja, plus financial pressure dan family expectations.
''';

  /// Send message with smart model selection (Flash vs Pro)
  Future<String> sendMessage(
    String message,
    {
      Map<String, dynamic>? metadata,
    }
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Get conversation context from Firestore
      final conversationHistory = await _getConversationHistory(user.uid);
      final recentMoods = await _getRecentMoods(user.uid);
      
      // Smart model selection based on complexity
      final isComplex = _shouldUseProModel(message, recentMoods, metadata);
      final model = isComplex ? _geminiPro : _geminiFlash;
      
      if (ApiConfig.enableLogging) {
        print('Using ${isComplex ? 'Gemma 12B (Quality)' : 'Gemma 4B (Fast)'} for: ${message.substring(0, 50)}...');
      }
      
      // Build context for Gemini
      final contextualPrompt = _buildContextualPrompt(
        message,
        conversationHistory: conversationHistory,
        recentMoods: recentMoods,
      );
      
      // Send to Gemini AI with timeout
      final response = await model.generateContent([
        Content.text(contextualPrompt)
      ]).timeout(ApiConfig.apiTimeout);
      
      final botResponse = response.text ?? 'Maaf, aku lagi nggak bisa respond. Try again ya! 😅';
      
      // Save conversation to Firestore
      await _saveConversationToFirestore(
        user.uid,
        message,
        botResponse,
        metadata: {
          ...?metadata,
          'model_used': isComplex ? 'pro' : 'flash',
          'response_time': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      return botResponse;
      
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('Gemini error: $e');
      }
      return _getFallbackResponse(message);
    }
  }
  
  /// Test Gemini API connectivity
  Future<Map<String, dynamic>> testConnectivity() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'project': ApiConfig.geminiProjectName,
      'flash_test': {'success': false, 'response_time': 0, 'error': null},
      'pro_test': {'success': false, 'response_time': 0, 'error': null},
    };
    
    // Test Gemma 4B (Fast model)
    try {
      final stopwatch = Stopwatch()..start();
      final flashResponse = await _geminiFlash.generateContent([
        Content.text('Test connectivity dengan response singkat dalam bahasa Indonesia.')
      ]).timeout(const Duration(seconds: 10));
      
      stopwatch.stop();
      
      results['flash_test'] = {
        'success': true,
        'response_time': stopwatch.elapsedMilliseconds,
        'response': flashResponse.text?.substring(0, 100),
        'error': null,
      };
      
      if (ApiConfig.enableLogging) {
        print('✅ Gemma 4B connectivity test passed (${stopwatch.elapsedMilliseconds}ms)');
      }
      
    } catch (e) {
      results['flash_test']['error'] = e.toString();
      if (ApiConfig.enableLogging) {
        print('❌ Gemma 4B connectivity test failed: $e');
      }
    }
    
    // Test Gemma 12B (Quality model)
    try {
      final stopwatch = Stopwatch()..start();
      final proResponse = await _geminiPro.generateContent([
        Content.text('Test connectivity untuk model Pro. Respond dengan empati dalam bahasa Indonesia casual.')
      ]).timeout(const Duration(seconds: 30));
      
      stopwatch.stop();
      
      results['pro_test'] = {
        'success': true,
        'response_time': stopwatch.elapsedMilliseconds,
        'response': proResponse.text?.substring(0, 100),
        'error': null,
      };
      
      if (ApiConfig.enableLogging) {
        print('✅ Gemma 12B connectivity test passed (${stopwatch.elapsedMilliseconds}ms)');
      }
      
    } catch (e) {
      results['pro_test']['error'] = e.toString();
      if (ApiConfig.enableLogging) {
        print('❌ Gemma 12B connectivity test failed: $e');
      }
    }
    
    return results;
  }
  
  /// Determine which model to use based on message complexity
  bool _shouldUseProModel(
    String message, 
    List<MoodEntry> recentMoods, 
    Map<String, dynamic>? metadata
  ) {
    // Use Pro model for complex scenarios
    if (message.length > 100) return true; // Long messages
    if (_containsCrisisKeywords(message)) return true; // Crisis detection
    if (metadata?['requires_empathy'] == true) return true; // Explicit empathy request
    
    // Check if user has concerning mood pattern
    if (recentMoods.length >= 2) {
      final recentMoodValues = recentMoods.take(3).map((m) => m.moodType.value).toList();
      final avgMood = recentMoodValues.reduce((a, b) => a + b) / recentMoodValues.length;
      if (avgMood <= 2.0) return true; // Low mood pattern needs Pro model
    }
    
    // Check for emotional complexity indicators
    final emotionalKeywords = ['stress', 'depresi', 'cemas', 'takut', 'sedih', 'marah', 'bingung', 'overwhelmed'];
    if (emotionalKeywords.any((keyword) => message.toLowerCase().contains(keyword))) {
      return true;
    }
    
    // Default to Flash for simple interactions
    return false;
  }
  
  /// Check if message contains crisis-related keywords
  bool _containsCrisisKeywords(String message) {
    final crisisKeywords = [
      'bunuh diri', 'suicide', 'mati aja', 'gak kuat lagi', 'putus asa',
      'depresi berat', 'panic attack', 'self harm', 'cutting', 'menyakiti diri'
    ];
    
    final lowerMessage = message.toLowerCase();
    return crisisKeywords.any((keyword) => lowerMessage.contains(keyword));
  }
  /// Generate contextual response for quick mood entries
  Future<String> generateQuickMoodResponse(
    MoodEntry moodEntry,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Get mood history from Firestore
      final moodHistory = await _getMoodHistory(user.uid);
      
      // Build mood-specific prompt
      final moodPrompt = _buildMoodContextPrompt(moodEntry, moodHistory);
      
      // Always use Flash for quick mood responses (cost optimization)
      final response = await _geminiFlash.generateContent([
        Content.text(moodPrompt)
      ]).timeout(ApiConfig.apiTimeout);
      
      final botResponse = response.text ?? _getFallbackMoodResponse(moodEntry);
      
      // Save mood and response to Firestore
      await _saveMoodToFirestore(user.uid, moodEntry);
      await _saveConversationToFirestore(
        user.uid,
        'Quick mood: ${moodEntry.moodType.label}${moodEntry.description != null ? ' - ${moodEntry.description}' : ''}',
        botResponse,
        metadata: {
          'type': 'quick_mood', 
          'mood_level': moodEntry.moodType.value,
          'model_used': 'flash',
        },
      );
      
      return botResponse;
      
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('Quick mood response error: $e');
      }
      return _getFallbackMoodResponse(moodEntry);
    }
  }
  
  /// Get conversation history from Firestore with real-time updates
  Stream<List<ChatMessage>> getConversationStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('conversations')
        .orderBy('timestamp', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          content: data['content'] ?? '',
          isBot: data['isBot'] ?? false,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          isQuickEntry: data['isQuickEntry'] ?? false,
          metadata: data['metadata'],
        );
      }).toList();
    });
  }
  
  /// Get mood history stream from Firestore
  Stream<List<MoodEntry>> getMoodHistoryStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MoodEntry.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }
  
  /// Analyze user behavior patterns using Firebase data
  Future<Map<String, dynamic>> analyzeUserBehavior() async {
    final user = _auth.currentUser;
    if (user == null) return {};
    
    // Get aggregated data from Firestore
    final moodSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('moods')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 30))
        ))
        .get();
    
    final conversationSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('conversations')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 30))
        ))
        .get();
    
    // Analyze patterns
    final moodData = moodSnapshot.docs.map((doc) => doc.data()).toList();
    final conversationData = conversationSnapshot.docs.map((doc) => doc.data()).toList();
    
    return {
      'averageMoodScore': _calculateAverageMood(moodData),
      'mostActiveHours': _findActiveHours(moodData, conversationData),
      'moodTrends': _analyzeMoodTrends(moodData),
      'conversationStyle': _analyzeConversationStyle(conversationData),
      'totalEntries': moodData.length,
      'totalConversations': conversationData.length,
    };
  }
  
  // Private methods
  
  Future<List<ChatMessage>> _getConversationHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          content: data['content'] ?? '',
          isBot: data['isBot'] ?? false,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          isQuickEntry: data['isQuickEntry'] ?? false,
        );
      }).toList().reversed.toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<List<MoodEntry>> _getRecentMoods(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('moods')
          .orderBy('timestamp', descending: true)
          .limit(7)
          .get();
      
      return snapshot.docs.map((doc) {
        return MoodEntry.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<List<MoodEntry>> _getMoodHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('moods')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 30))
          ))
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return MoodEntry.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  String _buildContextualPrompt(
    String message,
    {
      List<ChatMessage>? conversationHistory,
      List<MoodEntry>? recentMoods,
    }
  ) {
    final buffer = StringBuffer();
    
    // Add recent mood context
    if (recentMoods != null && recentMoods.isNotEmpty) {
      buffer.writeln('\n=== Recent Mood Context ===');
      for (final mood in recentMoods.take(3)) {
        final daysAgo = DateTime.now().difference(mood.timestamp).inDays;
        buffer.writeln('${daysAgo} days ago: ${mood.moodType.label}${mood.description != null ? ' - "${mood.description}"' : ''}');
      }
    }
    
    // Add conversation history
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      buffer.writeln('\n=== Recent Conversation ===');
      for (final msg in conversationHistory.take(6)) {
        buffer.writeln('${msg.isBot ? 'Mindscape' : 'User'}: ${msg.content}');
      }
    }
    
    buffer.writeln('\n=== Current Message ===');
    buffer.writeln('User: $message');
    buffer.writeln('\nRespond naturally in your characteristic Indonesian casual style. Keep it concise but empathetic.');
    
    return buffer.toString();
  }
  
  String _buildMoodContextPrompt(MoodEntry moodEntry, List<MoodEntry> moodHistory) {
    final buffer = StringBuffer();
    
    buffer.writeln('User just registered quick mood: ${moodEntry.moodType.label}');
    if (moodEntry.description != null) {
      buffer.writeln('Note: ${moodEntry.description}');
    }
    
    if (moodHistory.isNotEmpty) {
      final recentMoods = moodHistory.take(5);
      buffer.writeln('\nRecent mood pattern:');
      for (final mood in recentMoods) {
        final daysAgo = DateTime.now().difference(mood.timestamp).inDays;
        buffer.writeln('- ${mood.moodType.label} (${daysAgo}d ago)');
      }
      
      // Analyze trend
      if (moodHistory.length >= 3) {
        final recent3 = moodHistory.take(3).map((m) => m.moodType.value).toList();
        final avgRecent = recent3.reduce((a, b) => a + b) / 3;
        final avgPrevious = moodHistory.skip(3).take(3).map((m) => m.moodType.value).fold(0.0, (a, b) => a + b) / 3;
        
        if (avgRecent > avgPrevious + 0.5) {
          buffer.writeln('Trend: Improving mood ↗️');
        } else if (avgRecent < avgPrevious - 0.5) {
          buffer.writeln('Trend: Declining mood - needs attention ↘️');
        } else {
          buffer.writeln('Trend: Stable');
        }
      }
    }
    
    buffer.writeln('\nGenerate brief empathetic response (1-2 sentences max) in casual Indonesian. Be supportive and maybe ask follow-up if appropriate.');
    
    return buffer.toString();
  }
  
  Future<void> _saveConversationToFirestore(
    String userId,
    String userMessage,
    String botResponse,
    {
      Map<String, dynamic>? metadata,
    }
  ) async {
    final batch = _firestore.batch();
    final conversationRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('conversations');
    
    // Save user message
    batch.set(conversationRef.doc(), {
      'content': userMessage,
      'isBot': false,
      'timestamp': FieldValue.serverTimestamp(),
      'isQuickEntry': metadata?['type'] == 'quick_mood',
      'metadata': metadata,
    });
    
    // Save bot response
    batch.set(conversationRef.doc(), {
      'content': botResponse,
      'isBot': true,
      'timestamp': FieldValue.serverTimestamp(),
      'isQuickEntry': metadata?['type'] == 'quick_mood',
      'metadata': metadata,
    });
    
    await batch.commit();
  }
  
  Future<void> _saveMoodToFirestore(String userId, MoodEntry moodEntry) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('moods')
        .doc(moodEntry.id)
        .set({
      'moodType': moodEntry.moodType.name,
      'description': moodEntry.description,
      'timestamp': Timestamp.fromDate(moodEntry.timestamp),
      'isQuickEntry': moodEntry.isQuickEntry,
      'contextTags': moodEntry.contextTags,
      'stressLevel': moodEntry.stressLevel,
      'energyLevel': moodEntry.energyLevel,
      'activity': moodEntry.activity,
    });
  }
  
  String _getFallbackResponse(String message) {
    final responses = [
      'Maaf ya, aku lagi loading. Tapi aku di sini buat dengerin kamu! 😊',
      'Hmm, connection lagi trouble nih. But I hear you. Want to try again?',
      'Aku ngerti kamu lagi share something important. Give me a sec ya!',
    ];
    
    final randomIndex = DateTime.now().millisecond % responses.length;
    return responses[randomIndex];
  }
  
  String _getFallbackMoodResponse(MoodEntry moodEntry) {
    switch (moodEntry.moodType) {
      case MoodType.verySad:
        return 'Tough day banget ya? Aku di sini kalau mau cerita 💙';
      case MoodType.sad:
        return 'Not a good day. Ada yang bikin mood drop?';
      case MoodType.neutral:
        return 'Oke lah hari ini. Semoga bisa jadi better! 😊';
      case MoodType.happy:
        return 'Good to hear! Ada yang bikin happy today?';
      case MoodType.veryHappy:
        return 'Amazing mood! Love to see it! ✨';
    }
  }
  
  // Analytics helper methods
  double _calculateAverageMood(List<Map<String, dynamic>> moodData) {
    if (moodData.isEmpty) return 2.5;
    final total = moodData.map((data) => MoodType.values
        .firstWhere((type) => type.name == data['moodType'])
        .value).reduce((a, b) => a + b);
    return total / moodData.length;
  }
  
  List<int> _findActiveHours(List<Map<String, dynamic>> moodData, List<Map<String, dynamic>> conversationData) {
    final hourCounts = <int, int>{};
    
    for (final data in [...moodData, ...conversationData]) {
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final hour = timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedHours.take(3).map((e) => e.key).toList();
  }
  
  Map<String, double> _analyzeMoodTrends(List<Map<String, dynamic>> moodData) {
    // Implement mood trend analysis
    return {'weekly_trend': 0.0, 'monthly_trend': 0.0};
  }
  
  String _analyzeConversationStyle(List<Map<String, dynamic>> conversationData) {
    final quickEntries = conversationData.where((d) => d['isQuickEntry'] == true).length;
    final total = conversationData.length;
    
    if (total == 0) return 'balanced';
    final quickRatio = quickEntries / total;
    
    if (quickRatio > 0.7) return 'quick';
    if (quickRatio < 0.3) return 'detailed';
    return 'balanced';
  }
}

/// Extension to create MoodEntry from Firestore data
extension MoodEntryFromFirestore on MoodEntry {
  static MoodEntry fromFirestore(Map<String, dynamic> data, String id) {
    return MoodEntry(
      id: id,
      moodType: MoodType.values.firstWhere(
        (type) => type.name == data['moodType'],
        orElse: () => MoodType.neutral,
      ),
      description: data['description'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isQuickEntry: data['isQuickEntry'] ?? false,
      contextTags: List<String>.from(data['contextTags'] ?? []),
      stressLevel: data['stressLevel'],
      energyLevel: data['energyLevel'],
      activity: data['activity'],
    );
  }
}