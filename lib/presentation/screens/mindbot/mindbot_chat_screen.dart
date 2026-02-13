import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../../../core/services/gemini_chat_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/chat_storage_service.dart';

/// Active chat screen with MindBot
class MindbotChatScreen extends StatefulWidget {
  final bool isNewChat;
  final String? chatId;

  const MindbotChatScreen({
    super.key,
    required this.isNewChat,
    this.chatId,
  });

  @override
  State<MindbotChatScreen> createState() => _MindbotChatScreenState();
}

class _MindbotChatScreenState extends State<MindbotChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiChatService _geminiService = GeminiChatService();
  final AuthService _authService = AuthService();
  final ChatStorageService _chatStorage = ChatStorageService();
  
  late ChatSession _chatSession;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _username;
  String? _currentChatId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadUsername();
  }

  void _initializeChat() async {
    if (widget.isNewChat) {
      _chatSession = _geminiService.startNewChat();
      _currentChatId = null; // Will be created on first message
    } else {
      // Load existing chat from Firestore
      _currentChatId = widget.chatId;
      if (_currentChatId != null) {
        await _loadChatHistory(_currentChatId!);
      }
      _chatSession = _geminiService.startNewChat();
    }
  }

  Future<void> _loadChatHistory(String chatId) async {
    final messages = await _chatStorage.loadMessages(chatId);
    setState(() {
      _messages = messages.map((msg) => ChatMessage(
        text: msg['text'],
        isUser: msg['isUser'],
        timestamp: msg['timestamp'],
        username: msg['username'],
      )).toList();
    });
    _scrollToBottom();
  }

  Future<void> _loadUsername() async {
    final userData = await _authService.getUserData();
    setState(() {
      _username = userData?['displayName'] ?? _authService.currentUser?.displayName ?? 'You';
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading) return;

    // Create chat session on first message
    if (_currentChatId == null) {
      try {
        _currentChatId = await _chatStorage.createChatSession(
          firstMessage: messageText,
        );
      } catch (e) {
        print('Error creating chat session: $e');
      }
    }

    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
        timestamp: DateTime.now(),
        username: _username ?? 'You',
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Save user message to Firestore
    if (_currentChatId != null) {
      try {
        await _chatStorage.saveMessage(
          chatId: _currentChatId!,
          text: messageText,
          isUser: true,
          username: _username,
        );
      } catch (e) {
        print('Error saving user message: $e');
      }
    }

    try {
      final response = await _geminiService.sendMessage(_chatSession, messageText);
      
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
          username: 'Mindbot',
        ));
        _isLoading = false;
      });
      
      _scrollToBottom();

      // Save bot response to Firestore
      if (_currentChatId != null) {
        try {
          await _chatStorage.saveMessage(
            chatId: _currentChatId!,
            text: response,
            isUser: false,
            username: 'Mindbot',
          );
        } catch (e) {
          print('Error saving bot message: $e');
        }
      }
    } catch (e) {
      final errorMessage = 'Waduh, ada error nih. Coba lagi ya!';
      setState(() {
        _messages.add(ChatMessage(
          text: errorMessage,
          isUser: false,
          timestamp: DateTime.now(),
          username: 'Mindbot',
        ));
        _isLoading = false;
      });

      // Save error message to Firestore
      if (_currentChatId != null) {
        try {
          await _chatStorage.saveMessage(
            chatId: _currentChatId!,
            text: errorMessage,
            isUser: false,
            username: 'Mindbot',
          );
        } catch (e) {
          print('Error saving error message: $e');
        }
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM, HH:mm', 'id_ID');
    final timeFormat = DateFormat('HH.mm', 'id_ID');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF3D2914),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    'Mindbot',
                    style: GoogleFonts.urbanist(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D2914),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Start time
                  Text(
                    'Chat dimulai pada ${dateFormat.format(DateTime.now())}',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            
            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message, timeFormat);
                },
              ),
            ),
            
            // Loading indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFA8B475),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Mindbot sedang mengetik...',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Input field
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3F0),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.transparent,
                          width: 0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Write your message',
                                hintStyle: GoogleFonts.urbanist(
                                  color: const Color(0xFF999999),
                                ),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // TODO: Implement voice input
                            },
                            child: const Icon(
                              Icons.mic,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA8B475),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, DateFormat timeFormat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Username and timestamp
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA8B475),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/logos/chatbot/Vector-1.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                message.username,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D2914),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeFormat.format(message.timestamp),
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: const Color(0xFF999999),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA8B475),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Message bubble
          Align(
            alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? const Color(0xFFA8B475)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.text,
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    color: message.isUser
                        ? Colors.white
                        : const Color(0xFF3D2914),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String username;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.username,
  });
}
