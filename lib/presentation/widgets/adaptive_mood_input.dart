import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/gemini_chat_service.dart';
import '../../data/models/mood_entry.dart';
import '../../core/constants/app_constants.dart';

/// Adaptive mood input widget that switches between rush hour and normal mode
class AdaptiveMoodInput extends StatefulWidget {
  const AdaptiveMoodInput({super.key});

  @override
  State<AdaptiveMoodInput> createState() => _AdaptiveMoodInputState();
}

class _AdaptiveMoodInputState extends State<AdaptiveMoodInput> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isRushHour = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(_animationController);
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GeminiChatService>(
      builder: (context, geminiService, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isRushHour 
              ? _buildRushHourMode(context, geminiService)
              : _buildNormalMode(context, geminiService),
        );
      },
    );
  }
  
  /// Rush hour mode - simplified one-tap mood registration
  Widget _buildRushHourMode(BuildContext context, GeminiChatService geminiService) {
    return Card(
      key: const Key('rush_hour_mode'),
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Rush Hour Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _isRushHour = false),
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Exit rush hour',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Quick mood check - just tap one! 💨',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickMoodButtons(context, geminiService),
            const SizedBox(height: 16),
            _buildQuickContextTags(context),
          ],
        ),
      ),
    );
  }
  
  /// Normal mode - detailed mood input with conversation
  Widget _buildNormalMode(BuildContext context, GeminiChatService geminiService) {
    return Card(
      key: const Key('normal_mode'),
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.chat, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showRushHourDialog(context, geminiService),
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text('Rush'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailedMoodSelection(context, geminiService),
            const SizedBox(height: 20),
            _buildNoteInput(context),
            const SizedBox(height: 16),
            _buildAdvancedOptions(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickMoodButtons(BuildContext context, GeminiChatService geminiService) {
    final moods = MoodType.values;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: moods.map((mood) => _buildQuickMoodButton(
        context,
        mood,
        onTap: () => _handleQuickMoodSelection(context, geminiService, mood),
      )).toList(),
    );
  }
  
  Widget _buildQuickMoodButton(BuildContext context, MoodType mood, {required VoidCallback onTap}) {
    final color = _getMoodColor(mood);
    
    return Material(
      borderRadius: BorderRadius.circular(25),
      color: color.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mood.emoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 6),
              Text(
                mood.label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickContextTags(BuildContext context) {
    final quickTags = ['Studying', 'Working', 'Social', 'Rest', 'Commuting'];
    
    return Wrap(
      spacing: 6,
      children: quickTags.map((tag) => 
        Chip(
          label: Text(tag, style: const TextStyle(fontSize: 12)),
          onDeleted: null,
          visualDensity: VisualDensity.compact,
          backgroundColor: Colors.grey[100],
        )
      ).toList(),
    );
  }
  
  Widget _buildDetailedMoodSelection(BuildContext context, GeminiChatService geminiService) {
    return Column(
      children: [
        Text(
          'Select your current mood level:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _buildMoodSlider(context),
      ],
    );
  }
  
  Widget _buildMoodSlider(BuildContext context) {
    return Column(
      children: MoodType.values.map((mood) => 
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  borderRadius: BorderRadius.circular(20),
                  color: _getMoodColor(mood).withOpacity(0.1),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _handleDetailedMoodSelection(context, mood),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        mood.label,
                        style: TextStyle(
                          color: _getMoodColor(mood),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).toList(),
    );
  }
  
  Widget _buildNoteInput(BuildContext context) {
    return TextField(
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'What\'s on your mind? (optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.edit_note),
      ),
    );
  }
  
  Widget _buildAdvancedOptions(BuildContext context) {
    return ExpansionTile(
      title: const Text('Advanced Options'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildSliderOption('Stress Level', 1, 10, 5),
        _buildSliderOption('Energy Level', 1, 10, 5),
        _buildActivitySelector(),
      ],
    );
  }
  
  Widget _buildSliderOption(String label, int min, int max, int initial) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Slider(
              value: initial.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              label: initial.toString(),
              onChanged: (value) {
                // Handle slider change
              },
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(initial.toString(), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivitySelector() {
    final activities = ['Studying', 'Working Part-time', 'Socializing', 'Resting', 'Commuting', 'Exercise'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Activity:', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: activities.map((activity) => 
              FilterChip(
                label: Text(activity, style: const TextStyle(fontSize: 12)),
                selected: false,
                onSelected: (selected) {
                  // Handle activity selection
                },
              )
            ).toList(),
          ),
        ],
      ),
    );
  }
  
  void _showRushHourDialog(BuildContext context, GeminiChatService geminiService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.flash_on, color: Colors.amber),
            SizedBox(width: 8),
            Text('Enable Rush Hour'),
          ],
        ),
        content: const Text(
          'Switch to quick mood tracking mode? Perfect for busy times when you just need a fast check-in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isRushHour = true);
              _showSnackBar(context, 'Rush hour enabled ⚡');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleQuickMoodSelection(
    BuildContext context,
    GeminiChatService geminiService,
    MoodType mood,
  ) async {
    try {
      final moodEntry = MoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        moodType: mood,
        timestamp: DateTime.now(),
        isQuickEntry: true,
        contextTags: const [],
      );
      
      final response = await geminiService.generateQuickMoodResponse(moodEntry);
      
      _showMoodRegisteredBottomSheet(context, mood, response);
      
    } catch (e) {
      _showSnackBar(context, 'Failed to register mood: $e');
    }
  }
  
  void _handleDetailedMoodSelection(BuildContext context, MoodType mood) {
    // Show detailed mood registration dialog
    _showDetailedMoodDialog(context, mood);
  }
  
  void _showDetailedMoodDialog(BuildContext context, MoodType mood) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${mood.emoji} ${mood.label}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tell me more about how you\'re feeling...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Text('This will start a conversation with your mood assistant.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Start conversation mode
            },
            child: const Text('Share & Chat'),
          ),
        ],
      ),
    );
  }
  
  void _showMoodRegisteredBottomSheet(BuildContext context, MoodType mood, String response) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${mood.emoji} Mood Registered!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                response,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Thanks'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Start full conversation
                    },
                    child: const Text('Let\'s Chat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.verySad:
        return Colors.red[600]!;
      case MoodType.sad:
        return Colors.orange[600]!;
      case MoodType.neutral:
        return Colors.amber[600]!;
      case MoodType.happy:
        return Colors.lightGreen[600]!;
      case MoodType.veryHappy:
        return Colors.green[600]!;
    }
  }
}