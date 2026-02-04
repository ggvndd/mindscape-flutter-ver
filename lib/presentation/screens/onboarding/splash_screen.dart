import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

/// Splash screen with MindScape logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
    
    _startAnimation();
  }
  
  void _startAnimation() async {
    await _animationController.forward();
    
    // Wait a bit more to show the logo
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Navigate to onboarding
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0), // Warm background like in design
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/logos/Mindscape.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if image not found
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF8B4513), // Brown
                                    const Color(0xFF654321),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.psychology,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // App name
                    Text(
                      'MindScape',
                      style: GoogleFonts.urbanist(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3D2914), // Brown text
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}