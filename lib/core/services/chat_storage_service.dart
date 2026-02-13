import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for storing and retrieving chat sessions from Firestore
class ChatStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Save a new chat session
  Future<String> createChatSession({
    required String firstMessage,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    final chatRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('chatSessions')
        .doc();

    final chatData = {
      'id': chatRef.id,
      'title': _generateTitle(firstMessage),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'userId': _userId,
      'messageCount': 0,
    };

    await chatRef.set(chatData);
    return chatRef.id;
  }

  /// Save a message to a chat session
  Future<void> saveMessage({
    required String chatId,
    required String text,
    required bool isUser,
    String? username,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    // Add message to subcollection
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('chatSessions')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'isUser': isUser,
      'username': username ?? (isUser ? 'User' : 'Mindbot'),
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update chat session metadata
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('chatSessions')
        .doc(chatId)
        .update({
      'updatedAt': FieldValue.serverTimestamp(),
      'messageCount': FieldValue.increment(1),
      'lastMessage': text.length > 100 ? '${text.substring(0, 100)}...' : text,
    });
  }

  /// Load all chat sessions for current user
  Future<List<Map<String, dynamic>>> loadChatSessions() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('chatSessions')
          .orderBy('updatedAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Chat',
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'messageCount': data['messageCount'] ?? 0,
          'lastMessage': data['lastMessage'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error loading chat sessions: $e');
      return [];
    }
  }

  /// Load messages for a specific chat session
  Future<List<Map<String, dynamic>>> loadMessages(String chatId) async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('chatSessions')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'text': data['text'] ?? '',
          'isUser': data['isUser'] ?? false,
          'username': data['username'] ?? 'Unknown',
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print('Error loading messages: $e');
      return [];
    }
  }

  /// Delete a chat session
  Future<void> deleteChatSession(String chatId) async {
    if (_userId == null) return;

    try {
      // Delete all messages first
      final messagesSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('chatSessions')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete the chat session
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('chatSessions')
          .doc(chatId)
          .delete();
    } catch (e) {
      print('Error deleting chat session: $e');
    }
  }

  /// Generate a title from the first message
  String _generateTitle(String message) {
    if (message.isEmpty) return 'New Chat';
    
    // Take first 50 characters or until first newline
    final firstLine = message.split('\n').first;
    if (firstLine.length <= 50) return firstLine;
    
    return '${firstLine.substring(0, 50)}...';
  }
}
