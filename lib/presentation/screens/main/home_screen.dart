import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/adaptive_provider.dart';
import '../../providers/mood_provider.dart';
import '../../widgets/adaptive/adaptive_input_widget.dart';
import '../../../domain/entities/adaptive_context.dart';

/// Main home screen with adaptive dashboard
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindscape'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to settings
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Consumer2<AdaptiveProvider, MoodProvider>(
        builder: (context, adaptiveProvider, moodProvider, child) {
          final adaptiveContext = adaptiveProvider.currentContext;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting based on time
                _buildGreeting(adaptiveContext),
                
                const SizedBox(height: 24),
                
                // Quick mood log - core feature
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Gimana mood kamu hari ini?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AdaptiveInputWidget(
                          context: adaptiveContext,
                          onMoodLogged: (mood) {
                            moodProvider.logMoodQuickly(mood);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mood berhasil dicatat! 💙'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Today's summary (adaptive - simple when stressed)
                if (!adaptiveContext.shouldUseSimpleUI)
                  _buildTodaySummary(context),
                
                const SizedBox(height: 24),
                
                // Quick actions
                _buildQuickActions(context, adaptiveContext),
              ],
            ),
          );
        },
      ),
      
      // Chat FAB for easy access to empathetic support
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to chat screen
        },
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Chat'),
      ),
    );
  }

  Widget _buildGreeting(AdaptiveContext context) {
    String greeting;
    String emoji;
    
    final hour = context.timeOfDay.hour;
    if (hour < 12) {
      greeting = 'Selamat pagi!';
      emoji = '🌅';
    } else if (hour < 17) {
      greeting = 'Selamat siang!';
      emoji = '☀️';
    } else {
      greeting = 'Selamat malam!';
      emoji = '🌙';
    }
    
    // Add stress-aware message
    String stressMessage = '';
    if (context.isHighStress) {
      stressMessage = '\\nTarik napas dulu ya, semua akan baik-baik aja 💙';
    }
    
    return Text(
      '$greeting $emoji$stressMessage',
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTodaySummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hari ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('😊'),
                const SizedBox(width: 8),
                const Text('Mood: Senang'),
                const Spacer(),
                Text(
                  '3 entries',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AdaptiveContext adaptiveContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        
        // Simplified actions when stressed
        if (adaptiveContext.shouldUseSimpleUI)
          _buildSimpleActions(context)
        else
          _buildFullActions(context),
      ],
    );
  }

  Widget _buildSimpleActions(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.chat, color: Colors.blue),
          title: const Text('Chat dengan AI'),
          subtitle: const Text('Ceritain perasaan kamu'),
          onTap: () {
            // TODO: Navigate to chat
          },
        ),
        ListTile(
          leading: const Icon(Icons.trending_up, color: Colors.green),
          title: const Text('Lihat Progress'),
          subtitle: const Text('Mood trend 7 hari'),
          onTap: () {
            // TODO: Navigate to trends
          },
        ),
      ],
    );
  }

  Widget _buildFullActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildActionCard(
          context,
          'Chat',
          '💬',
          'Curhat dengan AI',
          () {
            // TODO: Navigate to chat
          },
        ),
        _buildActionCard(
          context,
          'Trends',
          '📈',
          'Lihat progress mood',
          () {
            // TODO: Navigate to trends
          },
        ),
        _buildActionCard(
          context,
          'Goals',
          '🎯',
          'Set mood goals',
          () {
            // TODO: Navigate to goals
          },
        ),
        _buildActionCard(
          context,
          'Profile',
          '👤',
          'Atur preferensi',
          () {
            // TODO: Navigate to profile
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String emoji,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}