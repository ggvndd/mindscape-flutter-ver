import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/app_lock_service.dart';
import '../profile/app_lock_verify_screen.dart';

/// Splash screen with MindScape logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final AppLockService _appLockService = AppLockService();
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
    
    // Check authentication state
    if (mounted) {
      final user = _authService.currentUser;
      if (user != null) {
        // User is logged in, check if app lock is enabled
        final isAppLockEnabled = await _appLockService.isAppLockEnabled();
        
        if (isAppLockEnabled) {
          // Show app lock verification screen
          final verified = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AppLockVerifyScreen(),
            ),
          );
          
          if (verified == true && mounted) {
            // PIN verified, go to main navigation
            Navigator.pushReplacementNamed(context, '/main');
          }
        } else {
          // No app lock, go directly to main navigation
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else {
        // User is not logged in, go to onboarding
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
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
                      width: 300,
                      height: 300,
                      padding: const EdgeInsets.all(20),
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
                        child: SvgPicture.asset(
                          'assets/logos/Mindscape.svg',
                          fit: BoxFit.contain,
                          placeholderBuilder: (context) => Container(
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
                          ),
                        ),
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