import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/mood_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/tot_measurement_service.dart';
import '../../core/services/gemma_mood_response_service.dart';
import 'package:intl/intl.dart';

class MoodLoggingDialog extends StatefulWidget {
  final Function? onMoodLogged;
  final String uiCondition;

  const MoodLoggingDialog({
    Key? key,
    this.onMoodLogged,
    this.uiCondition = 'standard_ui',
  }) : super(key: key);

  @override
  State<MoodLoggingDialog> createState() => _MoodLoggingDialogState();
}

class _MoodLoggingDialogState extends State<MoodLoggingDialog>
    with TickerProviderStateMixin {
  static const bool _showTotDebugBadge = true;

  final MoodService _moodService = MoodService();
  final AuthService _authService = AuthService();
  final TextEditingController _noteController = TextEditingController();
  
  int _selectedIndex = 2; // Default to "Just Okay" (middle)
  bool _isLogging = false;
  bool _isLoadingResponse = false;
  String? _aiResponse;
  int _moodInterval = 3; // loaded from prefs
  int _elapsedTotMs = 0;
  Timer? _totTicker;
  
  late AnimationController _circle1Controller;
  late AnimationController _circle2Controller;
  late AnimationController _circle3Controller;
  
  late Animation<Offset> _circle1Animation;
  late Animation<Offset> _circle2Animation;
  late Animation<Offset> _circle3Animation;

  final List<Map<String, dynamic>> _moods = [
    {
      'name': 'gloomy',
      'display': 'Depresi',
      'label': 'Aku Lagi Depresi',
      'color': Color(0xFF5B3A8E),
    },
    {
      'name': 'sad',
      'display': 'Sedih',
      'label': 'Aku Lagi Sedih',
      'color': Color(0xFFE89A5D),
    },
    {
      'name': 'justokay',
      'display': 'Biasa Aja',
      'label': 'Aku Biasa Aja',
      'color': Color(0xFFF5C77E),
    },
    {
      'name': 'fine',
      'display': 'Senang',
      'label': 'Aku Lagi Senang',
      'color': Color(0xFF8B7355),
    },
    {
      'name': 'happy',
      'display': 'Sangat Senang',
      'label': 'Aku Sangat Senang',
      'color': Color(0xFFA8B475),
    },
    {
      'name': 'cheerful',
      'display': 'Ceria',
      'label': 'Aku Lagi Ceria',
      'color': Color(0xFF7BA85B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInterval();
    _startTotDebugTicker();
  }

  void _startTotDebugTicker() {
    if (!_showTotDebugBadge) return;

    _totTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final elapsed = TotMeasurementService.instance.getCurrentElapsedMs() ?? 0;
      if (elapsed != _elapsedTotMs) {
        setState(() => _elapsedTotMs = elapsed);
      }
    });
  }

  String _formatTotMs(int ms) {
    final seconds = ms / 1000;
    return '${seconds.toStringAsFixed(1)}s';
  }

  Future<void> _loadInterval() async {
    final interval = await NotificationService.getSavedInterval();
    if (mounted) setState(() => _moodInterval = interval);
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
    _totTicker?.cancel();
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

    // ── TOT: record elapsed ms and push to evaluation_logs the moment the
    //        user taps Submit. Fire-and-forget – never awaited on the hot path.
    TotMeasurementService.instance.submitAndLog(
      _moods[_selectedIndex]['name'] as String,
    );

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Check if there's already a mood logged in the current interval window
      final existingMood = await _moodService.getMoodInCurrentWindow(
        user.uid,
        _moodInterval,
      );

      if (existingMood != null && mounted) {
        setState(() => _isLogging = false);
        final timeLabel = DateFormat('HH:mm', 'id_ID')
            .format(existingMood.timestamp);
        final moodName = existingMood.mood;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Sudah Ada Catatan Mood',
              style: GoogleFonts.urbanist(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D2914),
              ),
            ),
            content: Text(
              'Kamu sudah mencatat mood "$moodName" tadi jam $timeLabel. '
              'Kalau lanjut, catatan sebelumnya akan tetap ada dan ini akan jadi entri baru. Lanjutkan?',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: const Color(0xFF3D2914),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.urbanist(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D2914),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Tetap Catat',
                  style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        setState(() => _isLogging = true);
      }

      final now = DateTime.now();
      await _moodService.logMood(
        userId: user.uid,
        mood: _moods[_selectedIndex]['name'],
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      // Schedule next dynamic reminder based on this log time
      final remindersEnabled =
          await NotificationService.getMoodRemindersEnabled();
      if (remindersEnabled) {
        await NotificationService()
            .scheduleNextReminderAfterLog(now, _moodInterval);
      }

      if (mounted) {
        // ── Fetch MindBot response before closing the screen ─────────────
        setState(() => _isLoadingResponse = true);
        final aiReply = await GemmaMoodResponseService.instance.getGemmaResponse(
          userId: user.uid,
          currentMood: _moods[_selectedIndex]['name'] as String,
          currentNote: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          uiCondition: widget.uiCondition,
        );
        if (mounted) {
          setState(() {
            _aiResponse = aiReply;
            _isLoadingResponse = false;
            _isLogging = false;
          });
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
    
    return PopScope(
      // canPop: true keeps default behaviour (back always works).
      // onPopInvokedWithResult fires for EVERY pop — system back gesture,
      // Android back button, and our own Navigator.pop calls.
      // Because submitAndLog() already resets state, calling cancelTimer()
      // after a successful submit is a harmless no-op.
      canPop: true,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) TotMeasurementService.instance.cancelTimer();
      },
      child: Scaffold(
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
            if (_aiResponse != null || _isLoadingResponse)
              ..._buildResponseChildren()
            else ...[
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // ── TOT: user explicitly cancelled – reset the timer ──
                      TotMeasurementService.instance.cancelTimer();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.white.withOpacity(0.8), width: 1.5),
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
                        'Gimana perasaan\nkamu hari ini?',
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
                              'Catatan',
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
                              'Simpan Mood',
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
            ], // close else
          ],
        ),
      ),
          if (_showTotDebugBadge)
            Positioned(
              top: 54,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Text(
                  'TOT ${_formatTotMs(_elapsedTotMs)}',
                  style: GoogleFonts.urbanist(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      ),  // end PopScope
    );
  }

  List<Widget> _buildResponseChildren() {
    final Color bgColor = (_moods[_selectedIndex]['color'] as Color);
    return [
      // MindBot header
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  'assets/logos/chatbot/Vector-1.svg',
                  colorFilter: const ColorFilter.mode(
                      Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'MindBot',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      // Response card
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isLoadingResponse
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: CircularProgressIndicator(
                      color: Colors.white54,
                      strokeWidth: 2.5,
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _aiResponse ?? '',
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      color: const Color(0xFF3D2914),
                      height: 1.65,
                    ),
                  ),
                ),
        ),
      ),
      // Selesai button
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoadingResponse
                ? null
                : () {
                    if (widget.onMoodLogged != null) widget.onMoodLogged!();
                    Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              disabledBackgroundColor: Colors.white38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Selesai',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: bgColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.check_circle_outline, color: bgColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildMoodSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final dotCount = _moods.length;
        
        return Column(
          children: [
            // Interactive hint
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Geser atau tekan titik untuk memilih',
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Curved line with dots
            SizedBox(
              height: 80,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final dx = details.localPosition.dx;
                  final newIndex =
                      (dx / (totalWidth / (dotCount - 1))).round().clamp(0, dotCount - 1);
                  if (newIndex != _selectedIndex) {
                    setState(() => _selectedIndex = newIndex);
                  }
                },
                child: Stack(
                  clipBehavior: Clip.none,
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
            ),
            
            const SizedBox(height: 8),
            
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
void showMoodLoggingDialog(
  BuildContext context, {
  String uiCondition = 'standard_ui',
  Function? onMoodLogged,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => MoodLoggingDialog(
        uiCondition: uiCondition,
        onMoodLogged: onMoodLogged,
      ),
    ),
  );
}
