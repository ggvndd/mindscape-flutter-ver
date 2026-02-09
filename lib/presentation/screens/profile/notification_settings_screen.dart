import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';

/// Notification settings screen for managing push notifications
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final AuthService _authService = AuthService();
  bool _pushNotificationsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final userData = await _authService.getUserData();
      setState(() {
        _pushNotificationsEnabled = userData?['settings']?['notifications']?['pushEnabled'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePushNotifications(bool value) async {
    setState(() {
      _pushNotificationsEnabled = value;
    });
    
    // TODO: Update Firestore with new notification settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value 
              ? 'Push notifications diaktifkan' 
              : 'Push notifications dinonaktifkan',
          style: GoogleFonts.urbanist(),
        ),
        backgroundColor: const Color(0xFFA8B475),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF3D2914), width: 1.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/logos/back.svg',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kembali',
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Notifications',
                      style: GoogleFonts.urbanist(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D2914),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Atur notifikasi yang ingin kamu terima.',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Push Notifications Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFA8B475).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFF3D2914),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Push Notifications',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3D2914),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Terima notifikasi untuk pengingat dan update',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Toggle Switch
                          Switch(
                            value: _pushNotificationsEnabled,
                            onChanged: _togglePushNotifications,
                            activeColor: const Color(0xFFA8B475),
                            activeTrackColor: const Color(0xFFA8B475).withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Additional Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA8B475).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFA8B475).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFF3D2914),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Kamu akan menerima notifikasi untuk pengingat mood tracking, sesi Rush Hour, dan update penting lainnya dari MindScape.',
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                color: const Color(0xFF3D2914),
                                height: 1.4,
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
          ],
        ),
      ),
    );
  }
}
