import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sign up success confirmation screen
class SignUpSuccessScreen extends StatefulWidget {
  const SignUpSuccessScreen({super.key});

  @override
  State<SignUpSuccessScreen> createState() => _SignUpSuccessScreenState();
}

class _SignUpSuccessScreenState extends State<SignUpSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    // Start animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _continueToHome() {
    Navigator.pushReplacementNamed(context, '/main');
  }

  void _goToSignIn() {
    Navigator.pushReplacementNamed(context, '/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Success message (moved to top)
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Akun Berhasil Dibuat!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          fontSize: isTablet ? 32 : 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2914),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Welcome image (replacing checkmark)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: _scaleAnimation,
                      child: SvgPicture.asset(
                        'assets/images/selamat datang image.svg',
                        width: isTablet ? 280 : 220,
                        height: isTablet ? 280 : 220,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Welcome text
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Selamat datang di Mindscape! 🎉\nSekarang kamu bisa mulai tracking mood dan mengelola burnout dengan lebih baik.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          fontSize: isTablet ? 18 : 16,
                          color: const Color(0xFF666666),
                          height: 1.5,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Benefits/Features preview
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 24 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Yang bisa kamu lakukan:',
                              style: GoogleFonts.urbanist(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3D2914),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildFeatureItem(
                              icon: Icons.favorite_rounded,
                              iconColor: const Color(0xFFE53E3E),
                              title: 'Track Mood Harian',
                              description: 'Catat perasaan kamu setiap hari',
                              isTablet: isTablet,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            _buildFeatureItem(
                              icon: Icons.chat_bubble_rounded,
                              iconColor: const Color(0xFF3182CE),
                              title: 'Chat dengan AI',
                              description: 'Curhat dan dapat saran dari AI',
                              isTablet: isTablet,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            _buildFeatureItem(
                              icon: Icons.trending_up_rounded,
                              iconColor: const Color(0xFF38A169),
                              title: 'Analisis Progress',
                              description: 'Lihat perkembangan mood kamu',
                              isTablet: isTablet,
                            ),
                            
                            const SizedBox(height: 12),
                            
                            _buildFeatureItem(
                              icon: Icons.flash_on_rounded,
                              iconColor: const Color(0xFFD69E2E),
                              title: 'Rush Hour Mode',
                              description: 'Tracking super cepat saat sibuk',
                              isTablet: isTablet,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Action buttons
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // Get started button
                          SizedBox(
                            width: double.infinity,
                            height: isTablet ? 60 : 56,
                            child: ElevatedButton(
                              onPressed: _continueToHome,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3D2914),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Mulai Sekarang! 🚀',
                                style: GoogleFonts.urbanist(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Sign in option
                          TextButton(
                            onPressed: _goToSignIn,
                            child: Text(
                              'Atau masuk dengan akun lain',
                              style: GoogleFonts.urbanist(
                                fontSize: isTablet ? 16 : 14,
                                color: const Color(0xFF666666),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isTablet,
  }) {
    return Row(
      children: [
        Container(
          width: isTablet ? 48 : 40,
          height: isTablet ? 48 : 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: isTablet ? 24 : 20,
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.urbanist(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D2914),
                ),
              ),
              Text(
                description,
                style: GoogleFonts.urbanist(
                  fontSize: isTablet ? 14 : 12,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}