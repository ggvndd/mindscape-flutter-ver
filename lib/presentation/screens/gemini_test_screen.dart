import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/gemini_chat_service.dart';
import '../../data/models/mood_entry.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/gemini_connectivity_test.dart';

/// Debug screen for testing Gemini API functionality
class GeminiTestScreen extends StatefulWidget {
  const GeminiTestScreen({super.key});

  @override
  State<GeminiTestScreen> createState() => _GeminiTestScreenState();
}

class _GeminiTestScreenState extends State<GeminiTestScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _testConversation = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini API Test'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearConversation,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connectivity Test Widget
          const GeminiConnectivityTest(),
          
          // Quick Test Buttons
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Tests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickTestButton(
                        'Indonesian Greeting',
                        'Hai! Gimana kabar kamu hari ini?',
                      ),
                      _buildQuickTestButton(
                        'UGM Context',
                        'Aku mahasiswa UGM lagi stress sama thesis, capek juga kerja part-time',
                      ),
                      _buildQuickTestButton(
                        'Crisis Detection',
                        'Aku nggak kuat lagi, pengen menyerah aja',
                      ),
                      _buildQuickTestButton(
                        'Quick Mood',
                        '',
                        isQuickMood: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Conversation Area
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Test Conversation',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _testConversation.isEmpty
                        ? const Center(
                            child: Text(
                              'Start a conversation using the quick test buttons or type a message below',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _testConversation.length,
                            itemBuilder: (context, index) {
                              final message = _testConversation[index];
                              final isUser = message['sender'] == 'user';
                              
                              return Align(
                                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isUser ? Colors.blue[100] : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isUser ? 'You' : 'Mindscape',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(message['content']!),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: const Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 12),
                          Text('Gemini is thinking...'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message to test...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _sendMessage(_messageController.text),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTestButton(String label, String message, {bool isQuickMood = false}) {
    return OutlinedButton(
      onPressed: _isLoading ? null : () {
        if (isQuickMood) {
          _testQuickMoodResponse();
        } else {
          _sendMessage(message);
        }
      },
      child: Text(label),
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isLoading) return;
    
    setState(() {
      _isLoading = true;
      _testConversation.add({
        'sender': 'user',
        'content': message,
      });
    });
    
    _messageController.clear();
    
    try {
      final geminiService = context.read<GeminiChatService>();
      final response = await geminiService.sendMessage(message);
      
      setState(() {
        _testConversation.add({
          'sender': 'bot',
          'content': response,
        });
      });
      
    } catch (e) {
      setState(() {
        _testConversation.add({
          'sender': 'bot',
          'content': 'Error: $e',
        });
      });
      
      _showSnackBar('Failed to send message: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testQuickMoodResponse() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _testConversation.add({
        'sender': 'user',
        'content': '[Quick Mood: Bad - Tired from work]',
      });
    });
    
    try {
      final geminiService = context.read<GeminiChatService>();
      final moodEntry = MoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        moodType: MoodType.sad,
        description: 'Tired from work',
        timestamp: DateTime.now(),
        isQuickEntry: true,
        contextTags: const ['work', 'tired'],
      );
      
      final response = await geminiService.generateQuickMoodResponse(moodEntry);
      
      setState(() {
        _testConversation.add({
          'sender': 'bot',
          'content': response,
        });
      });
      
    } catch (e) {
      setState(() {
        _testConversation.add({
          'sender': 'bot',
          'content': 'Error testing quick mood: $e',
        });
      });
      
      _showSnackBar('Failed to test quick mood: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearConversation() {
    setState(() {
      _testConversation.clear();
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}