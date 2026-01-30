import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import '../../core/config/api_keys.dart';

/// Dialogflow ES service for chatbot integration
class DialogflowService {
  final String projectId;
  final String languageCode;
  late auth.ServiceAccountCredentials _credentials;
  late auth.AuthClient _authClient;
  
  DialogflowService({
    String? projectId,
    this.languageCode = 'id', // Indonesian
  }) : projectId = projectId ?? ApiKeys.dialogflowProjectId;

  /// Initialize service with credentials
  Future<void> initialize() async {
    try {
      // Load service account credentials
      final credentialsFile = File(ApiKeys.serviceAccountKeyPath);
      if (!credentialsFile.existsSync()) {
        throw Exception('Dialogflow credentials file not found. Please add your service account JSON file.');
      }
      
      final credentialsJson = await credentialsFile.readAsString();
      final credentialsMap = jsonDecode(credentialsJson);
      
      _credentials = auth.ServiceAccountCredentials.fromJson(credentialsMap);
      
      // Get authenticated client
      _authClient = await auth.clientViaServiceAccount(
        _credentials,
        ['https://www.googleapis.com/auth/cloud-platform'],
      );
      
      print('✅ Dialogflow service initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Dialogflow service: $e');
      rethrow;
    }
  }

  /// Send message to Dialogflow and get empathetic response  
  Future<ChatResponse> sendMessage(String message, String sessionId) async {
    try {
      if (!_isInitialized) {
        await initialize(); // Auto-initialize if not done
      }

      final sessionPath = 'projects/$projectId/agent/sessions/$sessionId';
      // Using global endpoint as agent resources are in 'global' location
      final endpoint = 'https://dialogflow.googleapis.com/v2/$sessionPath:detectIntent';
      
      final requestBody = {
        'queryInput': {
          'text': {
            'text': message,
            'languageCode': languageCode,
          },
        },
        'queryParams': {
          'contexts': await _buildContexts(),
          'timeZone': 'Asia/Jakarta',
        },
      };

      print('🤖 Sending to Dialogflow: $message');
      
      final response = await _authClient.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authClient.credentials.accessToken.data}',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 Dialogflow response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _parseDialogflowResponse(responseData, message);
      } else {
        print('❌ Dialogflow API error: ${response.statusCode} - ${response.body}');
        throw Exception('Dialogflow API error: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Dialogflow error: $e');
      return ChatResponse(
        text: 'Maaf, lagi ada masalah koneksi nih 😅 Coba lagi ya!',
        isEmpathetic: true,
        confidence: 0.0,
        suggestedActions: [ChatAction.logMood],
        shouldEscalate: false,
      );
    }
  }

  bool get _isInitialized => _authClient != null;
  
  /// Public getter to check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Build context from user mood history for personalized responses
  Future<List<Map<String, dynamic>>> _buildContexts() async {
    // TODO: Get mood history from MoodProvider
    return [
      {
        'name': 'mood-context',
        'lifespanCount': 5,
        'parameters': {
          'recent_mood_trend': 'stressed', // Dynamic from actual data
          'time_of_day': _getTimeOfDay(),
          'user_type': 'mahasiswa_side_gig',
        },
      },
    ];
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'pagi';
    if (hour < 17) return 'siang';
    if (hour < 21) return 'sore';
    return 'malam';
  }

  /// Parse Dialogflow response and enhance with app-specific logic
  ChatResponse _parseDialogflowResponse(Map<String, dynamic> response, String originalMessage) {
    final queryResult = response['queryResult'] ?? {};
    final fulfillmentText = queryResult['fulfillmentText'] ?? '';
    final confidence = (queryResult['intentDetectionConfidence'] ?? 0.0).toDouble();
    final intentName = queryResult['intent']?['displayName'] ?? '';
    
    // Crisis detection
    final shouldEscalate = _detectCrisis(originalMessage, intentName);
    
    // Extract suggested actions from parameters
    final parameters = queryResult['parameters'] ?? {};
    final suggestedActions = _extractSuggestedActions(parameters, intentName);
    
    return ChatResponse(
      text: fulfillmentText.isNotEmpty 
          ? fulfillmentText 
          : _generateFallbackResponse(originalMessage),
      isEmpathetic: _isEmpatheticResponse(intentName, fulfillmentText),
      confidence: confidence,
      suggestedActions: suggestedActions,
      shouldEscalate: shouldEscalate,
    );
  }

  bool _detectCrisis(String message, String intentName) {
    return intentName.toLowerCase().contains('crisis') ||
           ApiKeys.crisisKeywords.any((keyword) => 
               message.toLowerCase().contains(keyword));
  }

  List<ChatAction> _extractSuggestedActions(Map<String, dynamic> parameters, String intentName) {
    final List<ChatAction> actions = [];
    
    // Based on intent, suggest relevant actions
    if (intentName.contains('mood') || intentName.contains('feeling')) {
      actions.add(ChatAction.logMood);
    }
    
    if (intentName.contains('stress') || intentName.contains('burnout')) {
      actions.addAll([
        ChatAction.breathingExercise,
        ChatAction.takeBreak,
      ]);
    }
    
    if (intentName.contains('happy') || intentName.contains('celebration')) {
      actions.add(ChatAction.shareWin);
    }
    
    // Default action
    if (actions.isEmpty) {
      actions.add(ChatAction.viewTrends);
    }
    
    return actions;
  }

  bool _isEmpatheticResponse(String intentName, String responseText) {
    final empatheticIndicators = [
      'ngerasain', 'understand', 'banget', 'tough', 'susah',
      '💙', '🤗', '😊', '🫂'
    ];
    
    return empatheticIndicators.any((indicator) => 
        responseText.toLowerCase().contains(indicator));
  }

  String _generateFallbackResponse(String originalMessage) {
    // Try mock response first for development/testing
    return _generateMockResponse(originalMessage).text;
  }

  /// Generate mock responses for testing and development
  ChatResponse _generateMockResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Crisis detection
    if (_containsCrisisKeywords(lowerMessage)) {
      return ChatResponse(
        text: 'Aku perhatiin kamu lagi butuh dukungan yang lebih dari yang bisa aku kasih. '
              'Ada konselor UGM yang siap bantu kamu 24/7. Mau aku arahin ke sana? 💙',
        isEmpathetic: true,
        confidence: 0.95,
        suggestedActions: [
          ChatAction.contactCounselor,
          ChatAction.callHotline,
          ChatAction.talkToFriend,
        ],
        shouldEscalate: true,
      );
    }
    
    // Stress/burnout responses
    if (lowerMessage.contains('capek') || lowerMessage.contains('burnout') || lowerMessage.contains('stres')) {
      return ChatResponse(
        text: 'Kedengarannya kamu lagi overwhelmed banget nih 😔 '
              'Wajar banget sih, kuliah sambil kerja side gig emang challenging. '
              'Udah coba istirahat sebentar? Even 5 menit mindfulness bisa ngebantu lho! ✨',
        isEmpathetic: true,
        confidence: 0.85,
        suggestedActions: [
          ChatAction.breathingExercise,
          ChatAction.takeBreak,
          ChatAction.logMood,
        ],
        shouldEscalate: false,
      );
    }
    
    // Positive responses
    if (lowerMessage.contains('senang') || lowerMessage.contains('bahagia') || lowerMessage.contains('happy')) {
      return ChatResponse(
        text: 'Wah seneng banget dengernya! 😊 '
              'Kamu emang keren bisa balance kuliah sama side gig. '
              'Momen-momen bahagia kayak gini yang bikin semua perjuangan worth it ya! ✨',
        isEmpathetic: true,
        confidence: 0.90,
        suggestedActions: [
          ChatAction.logMood,
          ChatAction.shareWin,
        ],
        shouldEscalate: false,
      );
    }
    
    // Default empathetic response
    return ChatResponse(
      text: 'Makasih udah sharing sama aku 💙 '
            'Aku di sini buat dengerin kamu kapan aja. '
            'Ada yang bisa aku bantu atau mau cerita lebih lanjut?',
      isEmpathetic: true,
      confidence: 0.70,
      suggestedActions: [
        ChatAction.logMood,
        ChatAction.viewTrends,
      ],
      shouldEscalate: false,
    );
  }

  /// Dispose resources
  void dispose() {
    _authClient.close();
  }
}

  ChatResponse _generateMockResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Crisis detection
    if (_containsCrisisKeywords(lowerMessage)) {
      return ChatResponse(
        text: 'Aku perhatiin kamu lagi butuh dukungan yang lebih dari yang bisa aku kasih. '
              'Ada konselor UGM yang siap bantu kamu 24/7. Mau aku arahin ke sana? 💙',
        isEmpathetic: true,
        confidence: 0.95,
        suggestedActions: [
          ChatAction.contactCounselor,
          ChatAction.callHotline,
          ChatAction.talkToFriend,
        ],
        shouldEscalate: true,
      );
    }
    
    // Stress/burnout responses
    if (lowerMessage.contains('capek') || lowerMessage.contains('burnout') || lowerMessage.contains('stres')) {
      return ChatResponse(
        text: 'Kedengarannya kamu lagi overwhelmed banget nih 😔 '
              'Wajar banget sih, kuliah sambil kerja side gig emang challenging. '
              'Udah coba istirahat sebentar? Even 5 menit mindfulness bisa ngebantu lho! ✨',
        isEmpathetic: true,
        confidence: 0.85,
        suggestedActions: [
          ChatAction.breathingExercise,
          ChatAction.takeBreak,
          ChatAction.logMood,
        ],
        shouldEscalate: false,
      );
    }
    
    // Positive responses
    if (lowerMessage.contains('senang') || lowerMessage.contains('bahagia') || lowerMessage.contains('happy')) {
      return ChatResponse(
        text: 'Wah seneng banget dengernya! 😊 '
              'Kamu emang keren bisa balance kuliah sama side gig. '
              'Momen-momen bahagia kayak gini yang bikin semua perjuangan worth it ya! ✨',
        isEmpathetic: true,
        confidence: 0.90,
        suggestedActions: [
          ChatAction.logMood,
          ChatAction.shareWin,
        ],
        shouldEscalate: false,
      );
    }
    
    // Default empathetic response
    return ChatResponse(
      text: 'Makasih udah sharing sama aku 💙 '
            'Aku di sini buat dengerin kamu kapan aja. '
            'Ada yang bisa aku bantu atau mau cerita lebih lanjut?',
      isEmpathetic: true,
      confidence: 0.70,
      suggestedActions: [
        ChatAction.logMood,
        ChatAction.viewTrends,
      ],
      shouldEscalate: false,
    );
  }

  bool _containsCrisisKeywords(String message) {
    const crisisKeywords = [
      'bunuh diri', 'suicide', 'mati aja', 'gak kuat lagi', 'putus asa',
      'depresi berat', 'panic attack', 'self harm', 'cutting'
    ];
    
    return crisisKeywords.any((keyword) => message.contains(keyword));
  }

/// Chat response model from Dialogflow
class ChatResponse {
  final String text;
  final bool isEmpathetic;
  final double confidence;
  final List<ChatAction> suggestedActions;
  final bool shouldEscalate;

  const ChatResponse({
    required this.text,
    required this.isEmpathetic,
    required this.confidence,
    required this.suggestedActions,
    required this.shouldEscalate,
  });

  factory ChatResponse.error(String errorMessage) {
    return ChatResponse(
      text: errorMessage,
      isEmpathetic: true,
      confidence: 0.0,
      suggestedActions: [],
      shouldEscalate: false,
    );
  }
}

/// Suggested actions from chatbot
enum ChatAction {
  logMood('Log Mood', '😊'),
  breathingExercise('Breathing Exercise', '🧘'),
  takeBreak('Take Break', '☕'),
  viewTrends('View Trends', '📈'),
  contactCounselor('Contact Counselor', '👨‍⚕️'),
  callHotline('Call Hotline', '📞'),
  talkToFriend('Talk to Friend', '👥'),
  shareWin('Share Win', '🎉');

  const ChatAction(this.label, this.emoji);
  final String label;
  final String emoji;
}