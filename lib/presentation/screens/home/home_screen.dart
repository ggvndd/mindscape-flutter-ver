import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/mood_service.dart';
import '../../../core/services/chat_storage_service.dart';
import '../../../domain/entities/mood.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../mindbot/mindbot_screen.dart';

/// Home screen that shows after successful authentication
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final MoodService _moodService = MoodService();
  final ChatStorageService _chatStorage = ChatStorageService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _mindScore = 0;
  Mood? _latestMood;
  List<Map<String, dynamic>> _weeklyMoodData = [];
  int _conversationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMoodData();
    _loadConversationCount();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoodData() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      final mindScore = await _moodService.calculateMindscore(userId);
      final latestMood = await _moodService.getLatestMood(userId);
      
      // Calculate the start of the week (7 days ago)
      final now = DateTime.now();
      final weekStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      final weeklyData = await _moodService.getWeeklyMoodData(
        userId: userId,
        startDate: weekStart,
      );

      setState(() {
        _mindScore = mindScore;
        _latestMood = latestMood;
        _weeklyMoodData = weeklyData;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadConversationCount() async {
    try {
      final chatSessions = await _chatStorage.loadChatSessions();
      setState(() {
        _conversationCount = chatSessions.length;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.urbanist(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.urbanist(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Keluar',
              style: GoogleFonts.urbanist(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/sign-in');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal sign out: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Profile Section with Brown Background
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3D2914),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date and notification
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                                style: GoogleFonts.urbanist(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Profile row
                          Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(35),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hai, ${user?.displayName ?? 'Pengguna'}!',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.pie_chart,
                                          size: 16,
                                          color: const Color(0xFFA8B475),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$_mindScore%',
                                          style: GoogleFonts.urbanist(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        if (_latestMood != null) ...[
                                          SvgPicture.asset(
                                            'assets/logos/moods/mood_${_latestMood!.mood}.svg',
                                            width: 16,
                                            height: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _latestMood!.getMoodDisplayName(),
                                            style: GoogleFonts.urbanist(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Metriks Kesehatan Mental Kamu
                        Text(
                          'Metriks Kesehatan Mental Kamu',
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D2914),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildMindscoreCard()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildCurrentMoodCard()),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Grafik Mood
                        Text(
                          'Grafik Mood',
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D2914),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMoodGraph(),
                        
                        const SizedBox(height: 24),
                        
                        // MindBot
                        Text(
                          'Mindbot: Teman Kamu Curhat',
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D2914),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMindBotCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Mindful Resources and Tips
                        Text(
                          'Mindful Resources and Tips',
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D2914),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTipsSection(),
                        
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMindscoreCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/mood-tracker');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFA8B475),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mindscore',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Circular progress indicator
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _mindScore / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_mindScore',
                        style: GoogleFonts.urbanist(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _getMoodLevel(_mindScore),
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Learn More',
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFA8B475),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMoodLevel(int score) {
    if (score <= 20) return 'Gloomy';
    if (score <= 40) return 'Sad';
    if (score <= 60) return 'Okay';
    if (score <= 80) return 'Fine';
    if (score <= 99) return 'Happy';
    return 'Cheerful';
  }

  Widget _buildCurrentMoodCard() {
    String moodName = 'N/A';
    String moodIcon = 'assets/logos/moods/mood_justokay.svg';
    
    if (_latestMood != null) {
      moodName = _latestMood!.getMoodDisplayName();
      moodIcon = 'assets/logos/moods/mood_${_latestMood!.mood}.svg';
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/mood-tracker');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE89A5D),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emoji_emotions,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mood Sekarang',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Large mood icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
              ),
              padding: const EdgeInsets.all(20),
              child: SvgPicture.asset(
                moodIcon,
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Learn More',
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE89A5D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodGraph() {
    if (_weeklyMoodData.isEmpty) {
      return Container(
        height: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Belum ada data mood',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 6));
    final dateRangeText = '${startDate.day}-${now.day} ${DateFormat('MMMM yyyy', 'id_ID').format(now)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mood Tracker Interval',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  color: const Color(0xFF666666),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      'Mingguan',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: const Color(0xFF3D2914),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: Color(0xFF3D2914),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyMoodData.map((data) {
                final score = data['score'] as int;
                final height = (score / 100) * 160;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D2914),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: height,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA8B475),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['day'],
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              dateRangeText,
              style: GoogleFonts.urbanist(
                fontSize: 12,
                color: const Color(0xFF666666),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Date range slider representation
          Row(
            children: [
              Text(
                '${startDate.day} ${DateFormat('MMMM', 'id_ID').format(startDate)}',
                style: GoogleFonts.urbanist(
                  fontSize: 11,
                  color: const Color(0xFF999999),
                ),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFCCCCCC), Color(0xFF999999)],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              Text(
                '${now.day} ${DateFormat('MMMM', 'id_ID').format(now)}',
                style: GoogleFonts.urbanist(
                  fontSize: 11,
                  color: const Color(0xFF999999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMindBotCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MindbotScreen(),
          ),
        ).then((_) {
          // Reload conversation count when returning
          _loadConversationCount();
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$_conversationCount',
              style: GoogleFonts.urbanist(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFA8B475),
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Conversations',
              style: GoogleFonts.urbanist(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D2914),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Mau cerita ke Mindbot? Boleh banget!',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                color: const Color(0xFF666666),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF3D2914),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Text(
                'Mulai',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    final tips = [
      {
        'tag': 'Insights Harian',
        'question': 'Why do people self-sabotage themself?',
      },
      {
        'tag': 'Istirahat Mindful',
        'question': 'Why do people self-sabotage themself?',
      },
      {
        'tag': 'Insights Harian',
        'question': 'How to manage stress effectively?',
      },
      {
        'tag': 'Istirahat Mindful',
        'question': 'What are the benefits of meditation?',
      },
    ];

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          return Container(
            width: 240,
            margin: EdgeInsets.only(right: index < tips.length - 1 ? 12 : 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        size: 14,
                        color: Color(0xFF666666),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tip['tag']!,
                        style: GoogleFonts.urbanist(
                          fontSize: 11,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Text(
                    tip['question']!,
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D2914),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D2914),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Baca',
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: const Color(0xFF3D2914),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3D2914).withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF3D2914),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D2914),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Coming Soon',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Fitur $feature akan segera tersedia!',
          style: GoogleFonts.urbanist(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.urbanist(
                color: const Color(0xFF3D2914),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}