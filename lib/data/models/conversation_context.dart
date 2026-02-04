import 'package:hive/hive.dart';

part 'conversation_context.g.dart';

@HiveType(typeId: 0)
class ConversationContext extends HiveObject {
  @HiveField(0)
  String sessionId;
  
  @HiveField(1)
  List<ChatMessage> messages;
  
  @HiveField(2)
  DateTime lastUpdated;
  
  @HiveField(3)
  Map<String, dynamic>? metadata;
  
  ConversationContext({
    required this.sessionId,
    required this.messages,
    required this.lastUpdated,
    this.metadata,
  });
}

@HiveType(typeId: 1)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String content;
  
  @HiveField(1)
  bool isBot;
  
  @HiveField(2)
  DateTime timestamp;
  
  @HiveField(3)
  bool isQuickEntry;
  
  @HiveField(4)
  Map<String, dynamic>? metadata;
  
  ChatMessage({
    required this.content,
    required this.isBot,
    required this.timestamp,
    required this.isQuickEntry,
    this.metadata,
  });
}