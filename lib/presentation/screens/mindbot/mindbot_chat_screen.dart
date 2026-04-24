import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/gemini_chat_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/chat_storage_service.dart';
import '../../../core/services/mood_service.dart';

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
  final MoodService _moodService = MoodService();
  
  late ChatSession _chatSession;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _username;
  String? _currentChatId;
  bool _showCrisisSupport = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _loadUsername();
  }

  Future<void> _initializeChat() async {
    if (widget.isNewChat) {
      _chatSession = _geminiService.startNewChat();
      _currentChatId = null; // Will be created on first message
    } else {
      // Load existing chat from Firestore
      _currentChatId = widget.chatId;
      if (_currentChatId != null) {
        await _loadChatHistory(_currentChatId!);
        if (!mounted) return;
      }
      _chatSession = _geminiService.startNewChat();
    }
    // Inject the user's recent mood history so Mindbot can give
    // context-aware responses from the very first message.
    await _injectMoodContext();
  }

  Future<void> _injectMoodContext() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;
      final now = DateTime.now();
      final recentMoods = await _moodService.getMoodsByDateRange(
        userId: user.uid,
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
      );
      // Most-recent first so the context block reads naturally.
      recentMoods.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _geminiService.setMoodContext(recentMoods);
    } catch (_) {
      // Mood context is best-effort — never block the chat.
    }
  }

  Future<void> _loadChatHistory(String chatId) async {
    final messages = await _chatStorage.loadMessages(chatId);
    if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      _username = userData?['displayName'] ?? _authService.currentUser?.displayName ?? 'You';
    });
  }

  Future<void> _openSupportLink(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: uri.scheme == 'tel'
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uri.scheme == 'tel' 
                ? 'Gagal membuka telepon. Pastikan perangkatmu mendukung panggilan seluler.'
                : 'Gagal membuka tautan bantuan.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Tidak dapat membuka ${uri.scheme == "tel" ? "telepon" : "tautan"}.')),
        );
      }
    }
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
      _messages.add(ChatMessage(
        text: '',
        isUser: false,
        timestamp: DateTime.now(),
        username: 'Mindbot',
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

    String responseText = '';
    try {
      await for (final partial in _geminiService.sendMessageStream(_chatSession, messageText)) {
        if (!mounted) return;
        responseText = partial;
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          setState(() {
            final lastIndex = _messages.length - 1;
            _messages[lastIndex] = ChatMessage(
              text: responseText,
              isUser: false,
              timestamp: DateTime.now(),
              username: 'Mindbot',
            );
          });
          _scrollToBottom();
        }
      }

      if (responseText.isEmpty) {
        if (!mounted) return;
        responseText = 'Maaf, aku ga bisa kasih response sekarang. Coba lagi ya!';
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          setState(() {
            final lastIndex = _messages.length - 1;
            _messages[lastIndex] = ChatMessage(
              text: responseText,
              isUser: false,
              timestamp: DateTime.now(),
              username: 'Mindbot',
            );
          });
        }
      }

      setState(() {
        _isLoading = false;
      });

      _scrollToBottom();

      // Save bot response to Firestore
      if (_currentChatId != null) {
        try {
          await _chatStorage.saveMessage(
            chatId: _currentChatId!,
            text: responseText,
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
        if (_messages.isNotEmpty && !_messages.last.isUser) {
          _messages.removeLast();
        }
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
      if (!mounted) return;
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
        left: false,
        right: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF3D2914), width: 1.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/logos/back.svg',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kembali',
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3D2914),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title and Start time with SOS button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mindbot',
                            style: GoogleFonts.urbanist(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3D2914),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chat dimulai pada ${dateFormat.format(DateTime.now())}',
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              color: const Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showCrisisSupport = !_showCrisisSupport;
                            if (_showCrisisSupport) {
                              FocusScope.of(context).unfocus();
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5DA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: Color(0xFF7A3E2D), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Bantuan',
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7A3E2D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                  return _buildMessageBubble(message, timeFormat, index);
                },
              ),
            ),
            
            // Removed the extra loading indicator; Handled directly in message stream
            if (_showCrisisSupport)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF7F2), Color(0xFFFFFCFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF0D7CC)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3D2914).withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE5DA),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: Color(0xFF7A3E2D),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bantuan krisis',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7A3E2D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pilih salah satu jalur bantuan di bawah ini kalau kamu merasa tidak aman.',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF8B5E50),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sumber bantuan profesional yang tersedia:',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: const Color(0xFF8B5E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width > 500 ? 2 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: MediaQuery.of(context).size.width > 500 ? 2.6 : 4.2,
                      children: [
                        _buildSupportButton(
                          icon: Icons.public,
                          title: 'Into The Light',
                          subtitle: 'Bantuan profesional nasional',
                          onPressed: () => _openSupportLink(
                            Uri.parse('https://intothelightid.org'),
                          ),
                        ),
                        _buildSupportButton(
                          icon: Icons.local_hospital_outlined,
                          title: 'UGM Counseling',
                          subtitle: 'Tel. +62 274 513163',
                          onPressed: () => _openSupportLink(
                            Uri.parse('tel:+62274513163'),
                          ),
                        ),
                        _buildSupportButton(
                          icon: Icons.phone_in_talk_outlined,
                          title: 'Hotline 119',
                          subtitle: 'Layanan darurat nasional',
                          onPressed: () => _openSupportLink(
                            Uri.parse('tel:119'),
                          ),
                        ),
                        _buildSupportButton(
                          icon: Icons.chat_bubble_outline,
                          title: 'Kembali ke chat',
                          subtitle: 'Kalau kamu cuma perlu ditemani',
                          onPressed: () {
                            setState(() {
                              _showCrisisSupport = false;
                            });
                            _scrollToBottom();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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
                              onTap: () {
                                if (_showCrisisSupport) {
                                  setState(() {
                                    _showCrisisSupport = false;
                                  });
                                }
                              },
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
    ),
  ),
    );
  }

  Widget _buildBotBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: MarkdownBody(
            data: text,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: GoogleFonts.urbanist(
                fontSize: 16,
                color: const Color(0xFF3D2914),
                height: 1.4,
              ),
              strong: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D2914),
              ),
              em: GoogleFonts.urbanist(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF3D2914),
              ),
              code: GoogleFonts.robotoMono(
                fontSize: 14,
                color: const Color(0xFF3D2914),
                backgroundColor: const Color(0xFFF5F3F0),
              ),
              codeblockDecoration: BoxDecoration(
                color: const Color(0xFFF5F3F0),
                borderRadius: BorderRadius.circular(8),
              ),
              blockquote: GoogleFonts.urbanist(
                fontSize: 16,
                color: const Color(0xFF666666),
                fontStyle: FontStyle.italic,
              ),
              h1: GoogleFonts.urbanist(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF3D2914)),
              h2: GoogleFonts.urbanist(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF3D2914)),
              h3: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF3D2914)),
              listBullet: GoogleFonts.urbanist(fontSize: 16, color: const Color(0xFF3D2914)),
              a: GoogleFonts.urbanist(
                fontSize: 16,
                color: const Color(0xFFA8B475),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFFA8B475),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Mindbot sedang mengetik...',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: const Color(0xFF999999),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3D2914),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF3D2914).withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFA8B475).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF3D2914)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D2914),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.urbanist(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7A6A60),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_outward_rounded, size: 16),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, DateFormat timeFormat, int index) {
    // Split bot messages into separate paragraph bubbles
    final paragraphs = message.isUser
        ? <String>[message.text]
        : message.text
            .split('\n\n')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Username and timestamp header
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
          // Bubbles — one per paragraph for bot, single for user
          if (message.isUser)
            Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA8B475),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            )
          else if (message.text.trim().isEmpty && _isLoading && index == _messages.length - 1)
            _buildTypingBubble()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < paragraphs.length; i++) ...[
                  _buildBotBubble(paragraphs[i]),
                  if (i < paragraphs.length - 1) const SizedBox(height: 6),
                ],
              ],
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
