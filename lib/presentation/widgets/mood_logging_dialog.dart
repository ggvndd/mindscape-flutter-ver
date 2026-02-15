import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/mood_service.dart';
import '../../core/services/auth_service.dart';

class MoodLoggingDialog extends StatefulWidget {
  final Function? onMoodLogged;

  const MoodLoggingDialog({
    Key? key,
    this.onMoodLogged,
  }) : super(key: key);

  @override
  State<MoodLoggingDialog> createState() => _MoodLoggingDialogState();
}

class _MoodLoggingDialogState extends State<MoodLoggingDialog>
    with TickerProviderStateMixin {
  final MoodService _moodService = MoodService();
  final AuthService _authService = AuthService();
  final TextEditingController _noteController = TextEditingController();
  
  int _selectedIndex = 2; // Default to "Just Okay" (middle)
  bool _isLogging = false;
  
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  
  late Animation<Offset> _circle1Animation;
  late Animation<Offset> _circle2Animation;
  late Animation<Offset> _circle3Animation;

  final List<Map<String, dynamic>> _moods = [
    {
      'name': 'gloomy',
      'display': 'Depressed',
      'label': "I'm Feeling Depressed",
      'color': Color(0xFF5B3A8E),
    },
    {
      'name': 'sad',
      'display': 'Sad',
      'label': "I'm Feeling Sad",
      'color': Color(0xFFE89A5D),
    },
    {
      'name': 'justokay',
      'display': 'Neutral',
      'label': "I'm Feeling Neutral",
      'color': Color(0xFFF5C77E),
    },
    {
      'name': 'fine',
      'display': 'Happy',
      'label': "I'm Feeling Happy",
      'color': Color(0xFF8B7355),
    },
    {
      'name': 'happy',
      'display': 'Overjoyed',
      'label': "I'm Feeling Overjoyed",
      'color': Color(0xFFA8B475),
    },
    {
      'name': 'cheerful',
      'display': 'Cheerful',
      'label': "I'm Feeling Cheerful",
      'color': Color(0xFF7BA85B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
    _noteController.dispose();
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    super.dispose();
  }

  Future<void> _logMood() async {
    setState(() {
      _isLogging = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _moodService.logMood(
        userId: user.uid,
        mood: _moods[_selectedIndex]['name'],
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mood berhasil dicatat!'),
            backgroundColor: Color(0xFFA8B475),
          ),
        );
        
        // Call the callback if provided
        if (widget.onMoodLogged != null) {
          widget.onMoodLogged!();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLogging = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencatat mood: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMood = _moods[_selectedIndex];
    final Color backgroundColor = currentMood['color'];
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated circles background
          AnimatedBuilder(
            animation: Listenable.merge([
              _circle1Controller,
              _circle2Controller,
              _circle3Controller,
            ]),
            builder: (context, child) {
              return Stack(
                children: [
                  // Circle 1 - Large
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.1 + _circle1Animation.value.dx * 50,
                    top: MediaQuery.of(context).size.height * 0.2 + _circle1Animation.value.dy * 50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(75),
                      ),
                    ),
                  ),
                  // Circle 2 - Medium
                  Positioned(
                    right: MediaQuery.of(context).size.width * 0.15 + _circle2Animation.value.dx * 40,
                    top: MediaQuery.of(context).size.height * 0.4 + _circle2Animation.value.dy * 40,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(60),
                      ),
                    ),
                  ),
                  // Circle 3 - Small
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.6 + _circle3Animation.value.dx * 30,
                    bottom: MediaQuery.of(context).size.height * 0.25 + _circle3Animation.value.dy * 30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  // Small circles at edges
                  Positioned(
                    right: 20,
                    top: MediaQuery.of(context).size.height * 0.15,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    bottom: MediaQuery.of(context).size.height * 0.15,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Main content
          SafeArea(
        child: Column(
          children: [
            // Top bar with close button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        'How are you feeling\nthis day?',
                        style: GoogleFonts.urbanist(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Emoji
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(70),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: SvgPicture.asset(
                          'assets/logos/moods/mood_${currentMood['name']}.svg',
                          width: 100,
                          height: 100,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Mood label
                      Text(
                        currentMood['label'],
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Mood slider line with dots
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: _buildMoodSlider(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Note input field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Note',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _noteController,
                                maxLines: 2,
                                maxLength: 200,
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  color: const Color(0xFF3D2914),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Tambahkan catatan (opsional)...',
                                  hintStyle: GoogleFonts.urbanist(
                                    fontSize: 13,
                                    color: const Color(0xFF999999),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(10),
                                  counterStyle: GoogleFonts.urbanist(
                                    fontSize: 11,
                                    color: const Color(0xFF666666),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.95),
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
            
            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLogging ? null : _logMood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isLogging
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: backgroundColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Set Mood',
                              style: GoogleFonts.urbanist(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: backgroundColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check,
                              color: backgroundColor,
                              size: 20,
                            ),
                          ],
                        ),
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

  Widget _buildMoodSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final dotCount = _moods.length;
        
        return Column(
          children: [
            // Curved line with dots
            SizedBox(
              height: 80,
              child: Stack(
                children: [
                  // Custom painted curved line
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CurvedLinePainter(
                        selectedIndex: _selectedIndex,
                        totalDots: dotCount,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  // Visible dots
                  ...List.generate(dotCount, (index) {
                    final isSelected = index == _selectedIndex;
                    final isFilled = index <= _selectedIndex;
                    final spacing = totalWidth / (dotCount - 1);
                    final xPos = spacing * index;
                    
                    // Calculate Y position along the curve
                    // Use same parabola formula as the line
                    final progress = index / (dotCount - 1);
                    final yOffset = -25 * (1 - (progress * 2 - 1) * (progress * 2 - 1)); // Smooth parabola
                    
                    return Positioned(
                      left: xPos - (isSelected ? 14 : 10),
                      top: 40 + yOffset - (isSelected ? 14 : 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Container(
                          width: isSelected ? 28 : 20,
                          height: isSelected ? 28 : 20,
                          decoration: BoxDecoration(
                            color: isFilled ? Colors.white : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(isSelected ? 14 : 10),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 4)
                                : null,
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ] : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Mini emoji indicators below dots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_moods.length, (index) {
                final isSelected = index == _selectedIndex;
                return SizedBox(
                  width: 28,
                  height: 28,
                  child: Opacity(
                    opacity: isSelected ? 1.0 : 0.5,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      child: SvgPicture.asset(
                        'assets/logos/moods/mood_${_moods[index]['name']}.svg',
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// Custom painter for curved line
class CurvedLinePainter extends CustomPainter {
  final int selectedIndex;
  final int totalDots;
  final Color color;

  CurvedLinePainter({
    required this.selectedIndex,
    required this.totalDots,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final filledPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final spacing = size.width / (totalDots - 1);
    final baseY = size.height / 2;
    
    // Create smooth wave path
    final backgroundPath = Path();
    final filledPath = Path();
    
    // Generate smooth curve using more points for interpolation
    final steps = 50;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = size.width * t;
      
      // Smooth sine wave that dips in the middle
      final angle = t * 3.14159; // 0 to PI for one wave
      final yOffset = -25 * (1 - (t * 2 - 1) * (t * 2 - 1)); // Smooth parabola
      final y = baseY + yOffset;
      
      if (i == 0) {
        backgroundPath.moveTo(x, y);
        if (selectedIndex > 0) {
          filledPath.moveTo(x, y);
        }
      } else {
        backgroundPath.lineTo(x, y);
        
        // Fill path up to selected dot
        if (t <= (selectedIndex / (totalDots - 1))) {
          filledPath.lineTo(x, y);
        }
      }
    }
    
    canvas.drawPath(backgroundPath, paint);
    
    if (selectedIndex > 0) {
      canvas.drawPath(filledPath, filledPaint);
    }
  }

  @override
  bool shouldRepaint(CurvedLinePainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}

// Helper function to show the fullscreen mood dialog
void showMoodLoggingDialog(BuildContext context, {Function? onMoodLogged}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => MoodLoggingDialog(onMoodLogged: onMoodLogged),
    ),
  );
}
