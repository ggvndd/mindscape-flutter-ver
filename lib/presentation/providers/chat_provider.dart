import 'package:flutter/material.dart';
import '../../data/services/gemini_chat_service.dart';

/// Manages chatbot conversations and empathetic responses
class ChatProvider extends ChangeNotifier {
  final GeminiChatService _geminiChatService = GeminiChatService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String _currentSessionId = '';
  
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  
  /// Initialize Gemini service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _geminiChatService.testConnectivity();
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _isInitialized = true;
      
      // Add welcome message
      _addBotMessage('Hai! Aku Mindscape AI 🤖 Aku di sini buat dengerin kamu dan bantu manage mood. Gimana kabar kamu hari ini?');
      
      print('✅ ChatProvider initialized successfully');
      notifyListeners();
    } catch (e) {
      print('❌ Failed to initialize ChatProvider: $e');
      _addBotMessage('Maaf, lagi ada masalah teknis nih 😅 Tapi aku tetap bisa chat sama kamu!');
      notifyListeners();
    }
  }
  
  /// Send message to chatbot
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    // Add user message
    _addUserMessage(message);
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        await initialize();
      }
      
      // Send to Gemini
      final response = await _geminiChatService.sendMessage(message);
      
      // Add bot response
      _addBotMessage(response);
      
    } catch (e) {
      print('❌ Chat error: $e');
      _addBotMessage('Waduh, koneksi lagi bermasalah nih 😔 Tapi aku tetap di sini buat dengerin kamu!');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _addUserMessage(String text) {
    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
  
  void _addBotMessage(String text) {
    _messages.add(ChatMessage(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      isEmpathetic: true,
      shouldEscalate: false,
    ));
    notifyListeners();
  }
  
  /// Clear chat history
  void clearChat() {
    _messages.clear();
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _addBotMessage('Hai lagi! Ada yang bisa aku bantu? 😊');
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isEmpathetic;
  final bool shouldEscalate;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isEmpathetic = false,
    this.shouldEscalate = false,
  });
}