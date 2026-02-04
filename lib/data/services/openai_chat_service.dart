import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mood_entry.dart';
import '../models/conversation_context.dart';

/// OpenAI-based chatbot service as alternative to Dialogflow
/// Provides better conversation memory and contextual responses
class OpenAIChatService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _model = 'gpt-3.5-turbo'; // or 'gpt-4' for better quality
  
  final String _apiKey;
  final String _systemPrompt;
  
  OpenAIChatService({
    required String apiKey,
    String? customSystemPrompt,
  }) : _apiKey = apiKey,
       _systemPrompt = customSystemPrompt ?? _defaultSystemPrompt;
  
  static const String _defaultSystemPrompt = '''
You are Mindscape, an empathetic AI assistant specifically designed for UGM (Universitas Gadjah Mada) students who juggle academics with part-time jobs or side gigs.

Your personality:
- Warm, empathetic, and understanding
- Use casual Indonesian mixed with English (typical Indonesian Gen Z style)
- Always supportive but not overly cheerful
- Recognize signs of burnout, academic stress, and work-life balance issues
- Use emojis appropriately but not excessively

Your expertise:
- Academic stress management
- Work-life balance for student workers
- Burnout prevention and recognition
- Indonesian cultural context and local slang
- UGM-specific challenges (campus life, academic pressure)

Response style:
- Keep responses conversational and relatable
- Ask follow-up questions to understand better
- Provide practical, actionable advice when appropriate
- Validate feelings and experiences
- Use phrases like "Aku ngerti", "Gimana kabar kamu", "That sounds tough"

Crisis handling:
- If user shows signs of severe depression, self-harm, or suicide ideation, gently suggest professional help
- Mention UGM counseling services when appropriate
- Never dismiss serious mental health concerns

Remember: You're talking to Indonesian university students who are dealing with unique pressures of combining studies with work.
''';

  /// Send message with full conversation context
  Future<String> sendMessage(
    String message,
    {
      List<ChatMessage>? conversationHistory,
      List<MoodEntry>? recentMoods,
      Map<String, dynamic>? userContext,
    }
  ) async {
    try {
      final messages = _buildMessages(
        message,
        conversationHistory: conversationHistory,
        recentMoods: recentMoods,
        userContext: userContext,
      );
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 500,
          'temperature': 0.7,
          'presence_penalty': 0.1,
          'frequency_penalty': 0.1,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
      
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
  
  /// Generate contextual response for quick mood entries
  Future<String> generateQuickMoodResponse(
    MoodEntry moodEntry,
    {
      List<MoodEntry>? moodHistory,
      Map<String, dynamic>? userContext,
    }
  ) async {
    try {
      final contextualPrompt = _buildMoodContextPrompt(moodEntry, moodHistory, userContext);
      
      final messages = [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': contextualPrompt},
      ];
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 200,
          'temperature': 0.8,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
      
    } catch (e) {
      return _getFallbackMoodResponse(moodEntry);
    }
  }
  
  /// Generate fine-tuning data from user conversations
  List<Map<String, String>> generateFineTuningData(
    List<ChatMessage> conversations,
    List<MoodEntry> moodHistory,
  ) {
    final trainingData = <Map<String, String>>[];
    
    // Group conversations into training pairs
    for (int i = 0; i < conversations.length - 1; i++) {
      final userMessage = conversations[i];
      final botResponse = conversations[i + 1];
      
      if (!userMessage.isBot && botResponse.isBot) {
        // Find relevant mood context for this conversation
        final contextMood = _findRelevantMood(userMessage.timestamp, moodHistory);
        
        String enhancedPrompt = userMessage.content;
        if (contextMood != null) {
          enhancedPrompt += '\n[Context: User recently reported ${contextMood.moodType.displayName} mood]';
        }
        
        trainingData.add({
          'prompt': enhancedPrompt,
          'completion': botResponse.content,
        });
      }
    }
    
    return trainingData;
  }
  
  // Private methods
  
  List<Map<String, String>> _buildMessages(
    String message,
    {
      List<ChatMessage>? conversationHistory,
      List<MoodEntry>? recentMoods,
      Map<String, dynamic>? userContext,
    }
  ) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _buildEnhancedSystemPrompt(recentMoods, userContext)},
    ];
    
    // Add recent conversation history (last 10 messages)
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final recentHistory = conversationHistory.reversed.take(10).toList().reversed;
      
      for (final msg in recentHistory) {
        messages.add({
          'role': msg.isBot ? 'assistant' : 'user',
          'content': msg.content,
        });
      }
    }
    
    // Add current message
    messages.add({'role': 'user', 'content': message});
    
    return messages;
  }
  
  String _buildEnhancedSystemPrompt(
    List<MoodEntry>? recentMoods,
    Map<String, dynamic>? userContext,
  ) {
    final buffer = StringBuffer(_systemPrompt);
    
    if (recentMoods != null && recentMoods.isNotEmpty) {
      buffer.writeln('\nRecent mood context:');
      for (final mood in recentMoods.take(5)) {
        final timeAgo = DateTime.now().difference(mood.timestamp).inHours;
        buffer.writeln(
          '- ${mood.moodType.displayName} (${timeAgo}h ago)${mood.description != null ? ': ${mood.description}' : ''}'
        );
      }
    }
    
    if (userContext != null) {
      buffer.writeln('\nUser context: ${userContext.toString()}');
    }
    
    return buffer.toString();
  }
  
  String _buildMoodContextPrompt(
    MoodEntry moodEntry,
    List<MoodEntry>? moodHistory,
    Map<String, dynamic>? userContext,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('User just registered a quick mood: ${moodEntry.moodType.displayName}');
    
    if (moodEntry.description != null) {
      buffer.writeln('Note: ${moodEntry.description}');
    }
    
    if (moodHistory != null && moodHistory.isNotEmpty) {
      final recentMoods = moodHistory.where(
        (m) => DateTime.now().difference(m.timestamp).inDays <= 7
      ).toList();
      
      if (recentMoods.length > 1) {
        final avgMood = recentMoods.map((m) => m.moodType.value).reduce((a, b) => a + b) / recentMoods.length;
        buffer.writeln('Recent mood pattern: Average ${avgMood.toStringAsFixed(1)}/5');
        
        // Identify trend
        if (recentMoods.length >= 3) {
          final recent3 = recentMoods.reversed.take(3).map((m) => m.moodType.value).toList();
          if (recent3[0] > recent3[2]) {
            buffer.writeln('Mood trend: Improving');
          } else if (recent3[0] < recent3[2]) {
            buffer.writeln('Mood trend: Declining - needs attention');
          }
        }
      }
    }
    
    buffer.writeln('\nGenerate a brief, empathetic response (1-2 sentences) in casual Indonesian style. Be supportive and ask a follow-up question if appropriate.');
    
    return buffer.toString();
  }
  
  String _getFallbackMoodResponse(MoodEntry moodEntry) {
    final responses = <MoodLevel, List<String>>{
      MoodLevel.terrible: [
        'Tough day ya? Aku di sini kalo mau cerita 💙',
        'Kayaknya lagi berat banget nih. Take your time, aku dengerin.',
      ],
      MoodLevel.bad: [
        'Bad mood happens. Ada yang bikin kamu feeling down?',
        'Hmm, not a great day. Want to talk about it?',
      ],
      MoodLevel.okay: [
        'Oke lah ya, so-so day. Hope it gets better! 😊',
        'Biasa aja hari ini? Semoga besok lebih baik.',
      ],
      MoodLevel.good: [
        'Good to hear! Ada yang special hari ini?',
        'Nice! Seneng deh mood kamu good 😊',
      ],
      MoodLevel.great: [
        'Wohoo! Amazing day! Share dong apa yang bikin happy! 🎉',
        'Great mood! Love to see it! ✨',
      ],
    };
    
    final moodResponses = responses[moodEntry.moodType] ?? ['Thanks for sharing!'];
    final randomIndex = DateTime.now().millisecond % moodResponses.length;
    
    return moodResponses[randomIndex];
  }
  
  MoodEntry? _findRelevantMood(DateTime messageTime, List<MoodEntry> moodHistory) {
    for (final mood in moodHistory) {
      // Find mood entry within 2 hours of the message
      if (messageTime.difference(mood.timestamp).abs().inHours <= 2) {
        return mood;
      }
    }
    return null;
  }
}