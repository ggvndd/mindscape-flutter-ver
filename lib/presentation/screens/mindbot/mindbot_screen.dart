import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'mindbot_chat_screen.dart';
import '../../../core/services/chat_storage_service.dart';

/// MindBot main screen showing chat history and option to start new chat
class MindbotScreen extends StatefulWidget {
  const MindbotScreen({super.key});

  @override
  State<MindbotScreen> createState() => _MindbotScreenState();
}

class _MindbotScreenState extends State<MindbotScreen> {
  final ChatStorageService _chatStorage = ChatStorageService();
  List<Map<String, dynamic>> _chatTopics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);
    try {
      final chats = await _chatStorage.loadChatSessions();
      setState(() {
        _chatTopics = chats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() => _isLoading = false);
    }
  }

  void _startNewChat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MindbotChatScreen(isNewChat: true),
      ),
    );
    // Reload chat history when returning from new chat
    _loadChatHistory();
  }

  void _openChat(String chatId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MindbotChatScreen(
          isNewChat: false,
          chatId: chatId,
        ),
      ),
    );
    // Reload chat history when returning from existing chat
    _loadChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
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
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'Mindbot',
                    style: GoogleFonts.urbanist(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D2914),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    'Mau curhat ke Mindbot, temen kamu untuk ngobrol? Bisa banget!',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      color: const Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // New chat card at top
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFA8B475),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Mau buat chat baru aja? Bisa Kok',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _startNewChat,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Mulai Sekarang',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3D2914),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Chat history list below green card
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(
                      color: Color(0xFFA8B475),
                    ))
                  : _chatTopics.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada riwayat chat',
                            style: GoogleFonts.urbanist(
                              fontSize: 16,
                              color: const Color(0xFF999999),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          itemCount: _chatTopics.length,
                          itemBuilder: (context, index) {
                            final chat = _chatTopics[index];
                            return _buildChatTopicCard(
                              chat['title'],
                              chat['updatedAt'],
                              chat['id'],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTopicCard(String title, DateTime date, String id) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'id_ID');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D2914),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(date),
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _openChat(id),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF3D2914),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Lihat',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
