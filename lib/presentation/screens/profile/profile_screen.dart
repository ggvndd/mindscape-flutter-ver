import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Profile screen showing user info and settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final displayName = user?.displayName ?? _userData?['displayName'] ?? 'Username';

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: const Color(0xFFF5F3F0),
              child: Column(
                children: [
                  // Profile Header with brown background
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 32,
                      left: 24,
                      right: 24,
                      bottom: 40,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D2914),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                      child: Column(
                        children: [
                          // Title
                          Text(
                            'Profile',
                            style: GoogleFonts.urbanist(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Username greeting
                          Text(
                            'Hi, $displayName!',
                            style: GoogleFonts.urbanist(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Mood status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/logos/mood.svg',
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '80%',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFA8B475),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '😊 Happy',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Settings Menu Items
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              context,
                              icon: 'assets/logos/profile/account.svg',
                              title: 'Account',
                              onTap: () => Navigator.pushNamed(context, '/account-settings'),
                            ),
                            _buildMenuItem(
                              context,
                              icon: 'assets/logos/profile/Frame 117.svg',
                              title: 'Rush Hour Setup',
                              onTap: () => Navigator.pushNamed(context, '/rush-hour-settings'),
                            ),
                            _buildMenuItem(
                              context,
                              icon: 'assets/logos/profile/Frame 118.svg',
                              title: 'Notifications',
                              onTap: () => Navigator.pushNamed(context, '/notification-settings'),
                            ),
                            _buildMenuItem(
                              context,
                              icon: 'assets/logos/profile/security.svg',
                              title: 'Security',
                              onTap: () => Navigator.pushNamed(context, '/security-settings'),
                            ),

                            const SizedBox(height: 32),

                            // Privacy notice
                            Text(
                              'Your data is safely stored by the developer and will not be used for anything else besides the thesis research.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gavind @2026',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3D2914),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                icon,
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF3D2914),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3D2914),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF3D2914),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
