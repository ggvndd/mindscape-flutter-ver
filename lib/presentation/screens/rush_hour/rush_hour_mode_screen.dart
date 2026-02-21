import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/mood_logging_dialog.dart';
import '../mindbot/mindbot_screen.dart';
import '../mood_tracker/mindscore_detail_screen.dart';

/// Full-screen Rush Hour Mode overlay with animated background circles
/// and quick-access action buttons.
class RushHourModeScreen extends StatefulWidget {
  const RushHourModeScreen({super.key});

  @override
  State<RushHourModeScreen> createState() => _RushHourModeScreenState();
}

class _RushHourModeScreenState extends State<RushHourModeScreen>
    with TickerProviderStateMixin {
  // ── Floating circle animations (same style as mood & mindscore screens) ──
  late final AnimationController _circle1Controller;
  late final AnimationController _circle2Controller;
  late final AnimationController _circle3Controller;
  late final AnimationController _circle4Controller;

  late final Animation<Offset> _circle1Animation;
  late final Animation<Offset> _circle2Animation;
  late final Animation<Offset> _circle3Animation;
  late final Animation<Offset> _circle4Animation;

  // Icon pulse animation
  late final AnimationController _iconPulseController;
  late final Animation<double> _iconPulse;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Circle 1 – large, slow float
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

    // Circle 2 – medium
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

    // Circle 3 – smaller, faster
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

    // Circle 4 – tiny accent
    _circle4Controller = AnimationController(
      duration: const Duration(seconds: 18),
      vsync: this,
    )..repeat(reverse: true);

    _circle4Animation = Tween<Offset>(
      begin: const Offset(0.1, 0.3),
      end: const Offset(-0.3, -0.1),
    ).animate(CurvedAnimation(
      parent: _circle4Controller,
      curve: Curves.easeInOut,
    ));

    // Icon pulse
    _iconPulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _iconPulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _iconPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _circle1Controller.dispose();
    _circle2Controller.dispose();
    _circle3Controller.dispose();
    _circle4Controller.dispose();
    _iconPulseController.dispose();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _openMoodLogging() {
    showMoodLoggingDialog(context, onMoodLogged: () {});
  }

  void _openMindscore() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MindscoreDetailScreen()),
    );
  }

  void _openMindbot() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MindbotScreen()),
    );
  }

  void _exitRushHour() {
    Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const bgColor = Color(0xFF7A9B58);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Animated background circles ──────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([
              _circle1Controller,
              _circle2Controller,
              _circle3Controller,
              _circle4Controller,
            ]),
            builder: (_, __) => Stack(
              children: [
                // Circle 1 – large top-left
                Positioned(
                  left: size.width * 0.05 + _circle1Animation.value.dx * 50,
                  top: size.height * 0.05 + _circle1Animation.value.dy * 50,
                  child: _circle(180, 0.12),
                ),
                // Circle 2 – medium right
                Positioned(
                  right: size.width * 0.1 + _circle2Animation.value.dx * 40,
                  top: size.height * 0.35 + _circle2Animation.value.dy * 40,
                  child: _circle(140, 0.10),
                ),
                // Circle 3 – small bottom-left
                Positioned(
                  left: size.width * 0.55 + _circle3Animation.value.dx * 30,
                  bottom: size.height * 0.22 + _circle3Animation.value.dy * 30,
                  child: _circle(110, 0.08),
                ),
                // Circle 4 – tiny top-right accent
                Positioned(
                  right: 24,
                  top: size.height * 0.10 + _circle4Animation.value.dy * 20,
                  child: _circle(70, 0.06),
                ),
              ],
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // Icon with pulse
                  ScaleTransition(
                    scale: _iconPulse,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_run_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Mode Rush Hour',
                    style: GoogleFonts.urbanist(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.urbanist(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.90),
                        height: 1.6,
                      ),
                      children: [
                        const TextSpan(text: 'Kamu telah memasuki '),
                        TextSpan(
                          text: 'mode rush hour',
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const TextSpan(
                          text:
                              '! Mode ini dibuat biar kamu bisa pake fitur Mindscape secepat mungkin!',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Action buttons ──────────────────────────────────────
                  _actionButton(
                    label: 'Logging Mood',
                    onTap: _openMoodLogging,
                  ),
                  const SizedBox(height: 14),
                  _actionButton(
                    label: 'Cek Mindscore',
                    onTap: _openMindscore,
                  ),
                  const SizedBox(height: 14),
                  _actionButton(
                    label: 'Chat Mindbot',
                    onTap: _openMindbot,
                  ),

                  const SizedBox(height: 24),

                  // Exit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _exitRushHour,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D2914),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Keluar Mode Rush Hour',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Footnote
                  Text(
                    '*Tenang aja, kamu bisa balik lagi lewat menu di home!',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.75),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _actionButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
