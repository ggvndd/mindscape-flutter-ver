import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/mood_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../domain/entities/mood.dart';
import 'mood_history_screen.dart';

class MindscoreDetailScreen extends StatefulWidget {
  const MindscoreDetailScreen({super.key});

  @override
  State<MindscoreDetailScreen> createState() => _MindscoreDetailScreenState();
}

class _MindscoreDetailScreenState extends State<MindscoreDetailScreen>
    with TickerProviderStateMixin {
  final MoodService _moodService = MoodService();
  final AuthService _authService = AuthService();
  
  int _mindscore = 60;
  List<Mood> _moodHistory = [];
  bool _isLoading = true;
  
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  
  late Animation<Offset> _circle1Animation;
  late Animation<Offset> _circle2Animation;
  late Animation<Offset> _circle3Animation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }
  
  void _initializeAnimations() {
    // Circle 1 - slow movement
    _circle1Controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);
    
    _circle1Animation = Tween<Offset>(
      begin: const Offset(-0.3, -0.2),
      end: const Offset(0.3, 0.2),
    ).animate(CurvedAnimation(
      parent: _circle1Controller,
      curve: Curves.easeInOut,
    ));
    
    // Circle 2 - medium movement
    _circle2Controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);
    
    _circle2Animation = Tween<Offset>(
      begin: const Offset(0.4, 0.1),
      end: const Offset(-0.2, -0.3),
    ).animate(CurvedAnimation(
      parent: _circle2Controller,
      curve: Curves.easeInOut,
    ));
    
    // Circle 3 - faster movement
    _circle3Controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);
    
    _circle3Animation = Tween<Offset>(
      begin: const Offset(0.2, -0.4),
      end: const Offset(-0.4, 0.3),
    ).animate(CurvedAnimation(
      parent: _circle3Controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get mindscore
      final mindscore = await _moodService.calculateMindscore(user.uid);
      
      // Get mood history (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final moods = await _moodService.getMoodsByDateRange(
        userId: user.uid,
        startDate: thirtyDaysAgo,
        endDate: DateTime.now(),
      );

      // Sort by most recent first
      moods.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _mindscore = mindscore;
        _moodHistory = moods;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getMoodInfo(int score) {
    if (score <= 20) {
      return {
        'name': 'Gloomy',
        'color': const Color(0xFF5B3A8E), // Dark purple
        'message': 'Hari ini terasa berat, ya? Gak apa-apa kok merasa gini. Yuk cerita sama Mindbot atau istirahat sejenak. Kamu gak sendirian.',
      };
    } else if (score <= 40) {
      return {
        'name': 'Sad',
        'color': const Color(0xFF7B5FAF), // Light purple
        'message': 'Lagi down ya? It\'s okay to not be okay. Coba ambil waktu buat diri sendiri, atau lakukan hal kecil yang bikin kamu nyaman. Semangat!',
      };
    } else if (score <= 60) {
      return {
        'name': 'Just Okay',
        'color': const Color(0xFFE89A5D), // Light orange
        'message': 'So-so aja hari ini? That\'s totally fine! Kadang kita emang perlu hari yang biasa aja. Semoga besok bisa lebih baik!',
      };
    } else if (score <= 80) {
      return {
        'name': 'Fine',
        'color': const Color(0xFFf5c77e), // Lighter orange
        'message': 'Good vibes! Hari ini cukup lancar ya. Keep up the good energy dan jaga mood-mu tetap stabil!',
      };
    } else if (score <= 99) {
      return {
        'name': 'Happy',
        'color': const Color(0xFFF7C566), // Yellow
        'message': 'You\'re doing great! Senang lihat kamu happy hari ini. Jangan lupa appreciate momen-momen baik kayak gini!',
      };
    } else {
      return {
        'name': 'Cheerful',
        'color': const Color(0xFFA8B475), // Green
        'message': 'Wow, amazing mood! Kamu lagi on fire nih! Share positive energy-mu ke sekitar dan enjoy your day to the fullest!',
      };
    }
  }

  Color _getScoreColor(int score) {
    if (score <= 39) {
      return const Color(0xFFE89A5D); // Orange for low
    } else if (score <= 79) {
      return const Color(0xFFF7C566); // Yellow for medium
    } else {
      return const Color(0xFFA8B475); // Green for high
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodInfo = _getMoodInfo(_mindscore);

    return Scaffold(
      backgroundColor: moodInfo['color'] as Color,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Stack(
                children: [
                  // Animated background circles
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _circle1Controller,
                      _circle2Controller,
                      _circle3Controller,
                    ]),
                    builder: (context, child) {
                      return Stack(
                        children: [
                          // Large Circle 1
                          Positioned(
                            left: MediaQuery.of(context).size.width * 0.1 + 
                                  _circle1Animation.value.dx * 100,
                            top: MediaQuery.of(context).size.height * 0.15 + 
                                 _circle1Animation.value.dy * 100,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          // Large Circle 2
                          Positioned(
                            right: MediaQuery.of(context).size.width * 0.15 + 
                                   _circle2Animation.value.dx * 80,
                            top: MediaQuery.of(context).size.height * 0.25 + 
                                 _circle2Animation.value.dy * 80,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                          ),
                          // Large Circle 3
                          Positioned(
                            left: MediaQuery.of(context).size.width * 0.6 + 
                                  _circle3Animation.value.dx * 60,
                            top: MediaQuery.of(context).size.height * 0.05 + 
                                 _circle3Animation.value.dy * 60,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                          ),
                          // Small circle - top left
                          Positioned(
                            left: -20 + _circle1Animation.value.dx * 30,
                            top: MediaQuery.of(context).size.height * 0.08 + 
                                 _circle2Animation.value.dy * 40,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                          ),
                          // Small circle - top right
                          Positioned(
                            right: -15 + _circle3Animation.value.dx * 25,
                            top: MediaQuery.of(context).size.height * 0.12 + 
                                 _circle1Animation.value.dy * 35,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.07),
                              ),
                            ),
                          ),
                          // Small circle - bottom left
                          Positioned(
                            left: MediaQuery.of(context).size.width * 0.05 + 
                                  _circle2Animation.value.dx * 20,
                            top: MediaQuery.of(context).size.height * 0.35 + 
                                 _circle3Animation.value.dy * 30,
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                          // Tiny circle - middle right edge
                          Positioned(
                            right: -10 + _circle1Animation.value.dx * 15,
                            top: MediaQuery.of(context).size.height * 0.4 + 
                                 _circle2Animation.value.dy * 20,
                            child: Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  // Main content
                  Column(
                children: [
                  // Header with back button
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/logos/back.svg',
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(
                                      Colors.white, BlendMode.srcIn),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Kembali',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Mindscore',
                          style: GoogleFonts.urbanist(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Score circle
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final circleSize = (constraints.maxHeight - 60).clamp(100.0, 180.0);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                child: Center(
                                  child: FittedBox(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        '$_mindscore',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 80,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                moodInfo['name'] as String,
                                style: GoogleFonts.urbanist(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // Motivational message card - in colored area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        moodInfo['message'] as String,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          height: 1.5,
                          color: const Color(0xFF3D2914),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mood history section - separate container
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F3F0),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Mood History',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3D2914),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MoodHistoryScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'See All',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: moodInfo['color'] as Color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Mood list - limited to 4 items
                          Expanded(
                            child: _moodHistory.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Text(
                                        'Belum ada mood yang dicatat',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 14,
                                          color: const Color(0xFF999999),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 24),
                                    itemCount: _moodHistory.length > 4 ? 4 : _moodHistory.length,
                                    itemBuilder: (context, index) {
                                      return _buildMoodHistoryCard(_moodHistory[index]);
                                    },
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
    );
  }

  Widget _buildMoodHistoryCard(Mood mood) {
    final dateFormat = DateFormat('d\nMMM');
    final timeFormat = DateFormat('HH:mm');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Date
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                dateFormat.format(mood.timestamp),
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D2914),
                  height: 1.2,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Mood info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood.getMoodDisplayName(),
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D2914),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mood.note ?? 'No notes',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: const Color(0xFF999999),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormat.format(mood.timestamp),
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Score indicator
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: mood.moodScore / 100,
                    backgroundColor: const Color(0xFFF5F3F0),
                    color: _getScoreColor(mood.moodScore),
                    strokeWidth: 4,
                  ),
                ),
                Center(
                  child: Text(
                    '${mood.moodScore}',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3D2914),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
