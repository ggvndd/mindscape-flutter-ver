import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/conversation_context.dart';
import '../models/mood_entry.dart';
import '../models/user_context.dart';

/// Adaptive chat service that handles conversation memory and context switching
/// Supports multiple backends: OpenAI, Local LLM, or Dialogflow fallback
class AdaptiveChatService extends ChangeNotifier {
  static const String _conversationBoxName = 'conversations';
  static const String _moodHistoryBoxName = 'mood_history';
  static const String _userContextBoxName = 'user_context';
  
  late Box<ConversationContext> _conversationBox;
  late Box<MoodEntry> _moodHistoryBox;
  late Box<UserContext> _userContextBox;
  
  ChatBackend _currentBackend = ChatBackend.openai;
  bool _isRushHour = false;
  
  // Conversation memory - persists across sessions
  List<ChatMessage> _conversationHistory = [];
  String? _currentSessionId;
  
  Future<void> initialize() async {
    _conversationBox = await Hive.openBox<ConversationContext>(_conversationBoxName);
    _moodHistoryBox = await Hive.openBox<MoodEntry>(_moodHistoryBoxName);
    _userContextBox = await Hive.openBox<UserContext>(_userContextBoxName);
    
    // Load last conversation session
    await _loadLastConversation();
  }
  
  /// Quick mood registration for rush hour mode
  Future<String> registerQuickMood(MoodLevel mood, {String? note}) async {
    final moodEntry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mood: mood,
      timestamp: DateTime.now(),
      note: note,
      isQuickEntry: true,
      contextTags: await _getCurrentContextTags(),
    );
    
    // Store mood entry
    await _moodHistoryBox.put(moodEntry.id, moodEntry);
    
    // Generate contextual response based on mood pattern
    final response = await _generateQuickResponse(moodEntry);
    
    // Add to conversation history
    await _addToConversationHistory(
      'Quick mood: ${mood.displayName}${note != null ? ' - $note' : ''}',
      response,
      isQuickEntry: true,
    );
    
    notifyListeners();
    return response;
  }
  
  /// Full conversation mode
  Future<String> sendMessage(String message, {Map<String, dynamic>? metadata}) async {
    try {
      // Add user message to history
      await _addToConversationHistory(message, null, isQuickEntry: false);
      
      String response;
      
      // Route to appropriate backend based on context
      switch (_currentBackend) {
        case ChatBackend.openai:
          response = await _sendToOpenAI(message);
          break;
        case ChatBackend.localLLM:
          response = await _sendToLocalLLM(message);
          break;
        case ChatBackend.dialogflow:
          response = await _sendToDialogflow(message);
          break;
      }
      
      // Add bot response to history
      await _addToConversationHistory(null, response, isQuickEntry: false);
      
      notifyListeners();
      return response;
      
    } catch (e) {
      // Fallback to simple responses if all backends fail
      return _getFallbackResponse(message);
    }
  }
  
  /// Switch to rush hour mode - simplified UI and interactions
  void enableRushHour({Duration? duration}) {
    _isRushHour = true;
    notifyListeners();
    
    if (duration != null) {
      Future.delayed(duration, () {
        _isRushHour = false;
        notifyListeners();
      });
    }
  }
  
  void disableRushHour() {
    _isRushHour = false;
    notifyListeners();
  }
  
  /// Get conversation history with mood context
  Future<List<ChatMessage>> getConversationHistory({int? limit}) async {
    final messages = _conversationHistory;
    if (limit != null && messages.length > limit) {
      return messages.reversed.take(limit).toList().reversed.toList();
    }
    return messages;
  }
  
  /// Get mood patterns for the chatbot to understand user better
  Future<List<MoodEntry>> getMoodHistory({Duration? timespan}) async {
    final allMoods = _moodHistoryBox.values.toList();
    
    if (timespan != null) {
      final cutoffTime = DateTime.now().subtract(timespan);
      return allMoods.where((mood) => mood.timestamp.isAfter(cutoffTime)).toList();
    }
    
    return allMoods;
  }
  
  /// Advanced: Get user behavioral patterns for fine-tuning
  Future<UserBehaviorPattern> getUserBehaviorPattern() async {
    final moodHistory = await getMoodHistory(timespan: const Duration(days: 30));
    final conversations = await getConversationHistory(limit: 100);
    
    return UserBehaviorPattern(
      averageMoodScore: _calculateAverageMood(moodHistory),
      mostActiveTimeRanges: _analyzeActiveHours(moodHistory),
      preferredInteractionStyle: _analyzeInteractionStyle(conversations),
      commonMoodTriggers: _identifyMoodTriggers(moodHistory),
      conversationLengthPreference: _analyzeConversationLength(conversations),
    );
  }
  
  // Private methods
  
  Future<void> _loadLastConversation() async {
    final lastContext = _conversationBox.get('last_session');
    if (lastContext != null) {
      _conversationHistory = lastContext.messages;
      _currentSessionId = lastContext.sessionId;
    } else {
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }
  
  Future<void> _addToConversationHistory(
    String? userMessage,
    String? botResponse,
    {required bool isQuickEntry}
  ) async {
    final timestamp = DateTime.now();
    
    if (userMessage != null) {
      _conversationHistory.add(ChatMessage(
        content: userMessage,
        isBot: false,
        timestamp: timestamp,
        isQuickEntry: isQuickEntry,
      ));
    }
    
    if (botResponse != null) {
      _conversationHistory.add(ChatMessage(
        content: botResponse,
        isBot: true,
        timestamp: timestamp,
        isQuickEntry: isQuickEntry,
      ));
    }
    
    // Persist conversation context
    final context = ConversationContext(
      sessionId: _currentSessionId!,
      messages: _conversationHistory,
      lastUpdated: timestamp,
    );
    
    await _conversationBox.put('last_session', context);
    
    // Keep only last 200 messages to prevent memory bloat
    if (_conversationHistory.length > 200) {
      _conversationHistory = _conversationHistory.skip(50).toList();
    }
  }
  
  Future<String> _generateQuickResponse(MoodEntry moodEntry) async {
    final recentMoods = await getMoodHistory(timespan: const Duration(days: 7));
    final moodTrend = _analyzeMoodTrend(recentMoods);
    
    // Contextual responses based on mood patterns
    switch (moodEntry.mood) {
      case MoodLevel.terrible:
        if (moodTrend.isDescending && moodTrend.severity > 0.7) {
          return "Aku notice kamu lagi tough period banget nih. Udah berapa hari kamu ngerasa begini? 💙";
        }
        return "Thanks udah share mood kamu. Want to talk about what's bothering you? Aku di sini 🤗";
        
      case MoodLevel.bad:
        return "Oke, noted. Bad day happens. Ada yang spesifik bikin mood kamu drop? 💭";
        
      case MoodLevel.okay:
        return "Alright, so-so day ya. Semoga bisa jadi better! Ada yang pengen kamu share? 😊";
        
      case MoodLevel.good:
        if (moodTrend.isAscending) {
          return "Nice! Seneng deh liat mood kamu improving! Keep it up! ✨";
        }
        return "Good to hear! Apa yang bikin mood kamu good hari ini? 😄";
        
      case MoodLevel.great:
        return "Wohoo! Amazing mood! Share dong apa yang bikin kamu happy hari ini! 🎉";
    }
  }
  
  Future<String> _sendToOpenAI(String message) async {
    // Implementation for OpenAI API
    final context = await _buildConversationContext();
    
    // This would be your actual OpenAI API call
    // For now, return a contextual response
    return "This would be an OpenAI response with full conversation context";
  }
  
  Future<String> _sendToLocalLLM(String message) async {
    // Implementation for local LLM (Ollama, etc.)
    return "This would be a local LLM response";
  }
  
  Future<String> _sendToDialogflow(String message) async {
    // Your existing Dialogflow implementation
    return "This would be your Dialogflow response";
  }
  
  String _getFallbackResponse(String message) {
    // Simple rule-based responses as fallback
    final responses = [
      "Aku ngerti kamu lagi sharing something important. Tell me more? 😊",
      "Thanks udah cerita ke aku. How are you feeling about this? 💭",
      "I hear you. Apa yang paling bikin kamu concerned tentang ini? 🤔",
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }
  
  Future<List<String>> _getCurrentContextTags() async {
    final context = await _userContextBox.get('current_context');
    return context?.tags ?? [];
  }
  
  Future<String> _buildConversationContext() async {
    final moodHistory = await getMoodHistory(timespan: const Duration(days: 7));
    final recentConversation = _conversationHistory.reversed.take(20).toList();
    
    final contextBuilder = StringBuffer();
    contextBuilder.writeln("User's recent mood pattern:");
    
    for (final mood in moodHistory.take(5)) {
      contextBuilder.writeln("${mood.timestamp.day}/${mood.timestamp.month}: ${mood.mood.displayName}${mood.note != null ? ' (${mood.note})' : ''}");
    }
    
    contextBuilder.writeln("\nRecent conversation:");
    for (final msg in recentConversation) {
      contextBuilder.writeln("${msg.isBot ? 'Bot' : 'User'}: ${msg.content}");
    }
    
    return contextBuilder.toString();
  }
  
  // Analytics methods
  
  double _calculateAverageMood(List<MoodEntry> moods) {
    if (moods.isEmpty) return 2.5; // neutral
    return moods.map((m) => m.mood.numericValue).reduce((a, b) => a + b) / moods.length;
  }
  
  List<TimeRange> _analyzeActiveHours(List<MoodEntry> moods) {
    // Group by hour and find most active periods
    final hourCounts = <int, int>{};
    for (final mood in moods) {
      final hour = mood.timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    
    // Return top active hours as time ranges
    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedHours.take(3).map((entry) => 
      TimeRange(start: entry.key, end: entry.key + 1)
    ).toList();
  }
  
  InteractionStyle _analyzeInteractionStyle(List<ChatMessage> conversations) {
    final quickEntries = conversations.where((m) => m.isQuickEntry).length;
    final totalEntries = conversations.length;
    
    if (totalEntries == 0) return InteractionStyle.balanced;
    
    final quickRatio = quickEntries / totalEntries;
    if (quickRatio > 0.7) return InteractionStyle.quick;
    if (quickRatio < 0.3) return InteractionStyle.detailed;
    return InteractionStyle.balanced;
  }
  
  List<String> _identifyMoodTriggers(List<MoodEntry> moods) {
    // Simple keyword analysis from notes
    final triggers = <String>[];
    final keywords = <String, int>{};
    
    for (final mood in moods) {
      if (mood.note != null && mood.mood.numericValue <= 2) {
        final words = mood.note!.toLowerCase().split(' ');
        for (final word in words) {
          if (word.length > 3) {
            keywords[word] = (keywords[word] ?? 0) + 1;
          }
        }
      }
    }
    
    final sortedKeywords = keywords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedKeywords.take(5).map((e) => e.key).toList();
  }
  
  ConversationLength _analyzeConversationLength(List<ChatMessage> conversations) {
    // This is a simplified analysis - you'd want more sophisticated logic
    final avgLength = conversations.isEmpty ? 0 : 
        conversations.map((c) => c.content.length).reduce((a, b) => a + b) / conversations.length;
    
    if (avgLength < 50) return ConversationLength.short;
    if (avgLength > 150) return ConversationLength.long;
    return ConversationLength.medium;
  }
  
  MoodTrend _analyzeMoodTrend(List<MoodEntry> moods) {
    if (moods.length < 3) return MoodTrend(isAscending: false, isDescending: false, severity: 0);
    
    final recent = moods.reversed.take(5).map((m) => m.mood.numericValue).toList();
    double trendSlope = 0;
    
    for (int i = 1; i < recent.length; i++) {
      trendSlope += recent[i] - recent[i-1];
    }
    
    trendSlope /= recent.length - 1;
    
    return MoodTrend(
      isAscending: trendSlope > 0.3,
      isDescending: trendSlope < -0.3,
      severity: trendSlope.abs(),
    );
  }
  
  // Getters
  bool get isRushHour => _isRushHour;
  ChatBackend get currentBackend => _currentBackend;
  List<ChatMessage> get conversationHistory => List.unmodifiable(_conversationHistory);
  
  // Backend switching
  void switchBackend(ChatBackend backend) {
    _currentBackend = backend;
    notifyListeners();
  }
}

enum ChatBackend { openai, localLLM, dialogflow }
enum MoodLevel { 
  terrible, bad, okay, good, great;
  
  String get displayName {
    switch (this) {
      case terrible: return 'Terrible';
      case bad: return 'Bad';
      case okay: return 'Okay';
      case good: return 'Good';
      case great: return 'Great';
    }
  }
  
  double get numericValue {
    switch (this) {
      case terrible: return 1.0;
      case bad: return 2.0;
      case okay: return 3.0;
      case good: return 4.0;
      case great: return 5.0;
    }
  }
}

enum InteractionStyle { quick, balanced, detailed }
enum ConversationLength { short, medium, long }

// Data models would be defined in separate files
class ChatMessage {
  final String content;
  final bool isBot;
  final DateTime timestamp;
  final bool isQuickEntry;
  
  ChatMessage({
    required this.content,
    required this.isBot,
    required this.timestamp,
    required this.isQuickEntry,
  });
}

class UserBehaviorPattern {
  final double averageMoodScore;
  final List<TimeRange> mostActiveTimeRanges;
  final InteractionStyle preferredInteractionStyle;
  final List<String> commonMoodTriggers;
  final ConversationLength conversationLengthPreference;
  
  UserBehaviorPattern({
    required this.averageMoodScore,
    required this.mostActiveTimeRanges,
    required this.preferredInteractionStyle,
    required this.commonMoodTriggers,
    required this.conversationLengthPreference,
  });
}

class TimeRange {
  final int start;
  final int end;
  
  TimeRange({required this.start, required this.end});
}

class MoodTrend {
  final bool isAscending;
  final bool isDescending;
  final double severity;
  
  MoodTrend({
    required this.isAscending,
    required this.isDescending,
    required this.severity,
  });
}