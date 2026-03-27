import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/data_export_service.dart';
import '../../providers/adaptive_provider.dart';

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
  bool _isExporting = false;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: theme.colorScheme.surface,
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
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.primaryContainer
                          : const Color(0xFF3D2914),
                      borderRadius: const BorderRadius.only(
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
                              color: isDark
                                  ? theme.colorScheme.onPrimaryContainer
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: isDark
                                  ? theme.colorScheme.onSurface
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Username greeting
                          Text(
                            'Hi, $displayName!',
                            style: GoogleFonts.urbanist(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? theme.colorScheme.onPrimaryContainer
                                  : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // MindScore and Mood status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/logos/chatbot/Vector-1.svg',
                                width: 20,
                                height: 20,
                                colorFilter: ColorFilter.mode(
                                  isDark
                                      ? theme.colorScheme.primary
                                      : const Color(0xFFA8B475),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '80%',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? theme.colorScheme.onPrimaryContainer
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              SvgPicture.asset(
                                'assets/logos/profile/Frame 117.svg',
                                width: 20,
                                height: 20,
                                colorFilter: ColorFilter.mode(
                                  isDark
                                      ? theme.colorScheme.primary
                                      : const Color(0xFFA8B475),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Happy',
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? theme.colorScheme.onPrimaryContainer
                                      : Colors.white,
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
                              title: 'Akun',
                              onTap: () => Navigator.pushNamed(context, '/account-settings'),
                            ),
                            _buildMenuItem(
                              context,
                              icon: 'assets/logos/profile/Frame 117.svg',
                              title: 'Pengaturan Rush Hour',
                              onTap: () => Navigator.pushNamed(context, '/rush-hour-settings'),
                            ),
                            _buildMenuItem(
                              context,
                              icon: 'assets/logos/profile/Frame 118.svg',
                              title: 'Notifikasi dan Mood Logging',
                              onTap: () => Navigator.pushNamed(context, '/notification-settings'),
                            ),
                            _buildMenuItem(
                              context,
                              icon: 'assets/logos/profile/security.svg',
                              title: 'Keamanan',
                              onTap: () => Navigator.pushNamed(context, '/security-settings'),
                            ),
                            _buildDarkModeToggle(context),

                            // Logout button
                            _buildLogoutButton(context),

                            const SizedBox(height: 32),

                            // Privacy notice
                            Text(
                              'Data kamu disimpan dengan aman oleh pengembang dan tidak akan digunakan untuk hal lain selain penelitian skripsi.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? theme.colorScheme.onSurface.withOpacity(0.6)
                                    : Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Hidden admin export trigger — long-press to export
                            GestureDetector(
                              onLongPress: () async {
                                if (_isExporting) return;
                                setState(() => _isExporting = true);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Fetching evaluation logs...'),
                                    duration: Duration(seconds: 30),
                                  ),
                                );

                                try {
                                  final result =
                                      await DataExportService.instance.exportToCsv();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(result),
                                        backgroundColor:
                                            const Color(0xFFA8B475),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Export failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isExporting = false);
                                  }
                                }
                              },
                              child: Text(
                                'Gavind @2026',
                                style: GoogleFonts.urbanist(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? theme.colorScheme.onSurface
                                      : const Color(0xFF3D2914),
                                ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
                colorFilter: ColorFilter.mode(
                  isDark
                      ? theme.colorScheme.onSurface
                      : const Color(0xFF3D2914),
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
                    color: isDark
                        ? theme.colorScheme.onSurface
                        : const Color(0xFF3D2914),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? theme.colorScheme.onSurface
                    : const Color(0xFF3D2914),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(BuildContext context) {
    final theme = Theme.of(context);
    final isThemeDark = theme.brightness == Brightness.dark;

    return Consumer<AdaptiveProvider>(
      builder: (context, adaptiveProvider, child) {
        final isDarkMode = adaptiveProvider.isDarkMode;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isThemeDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isThemeDark ? 0.2 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  size: 24,
                  color: isThemeDark
                      ? theme.colorScheme.onSurface
                      : const Color(0xFF3D2914),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Mode Gelap',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isThemeDark
                          ? theme.colorScheme.onSurface
                          : const Color(0xFF3D2914),
                    ),
                  ),
                ),
                Switch(
                  value: isDarkMode,
                  onChanged: (_) => adaptiveProvider.toggleDarkMode(),
                  activeTrackColor: const Color(0xFFA8B475),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      child: InkWell(
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Keluar dari Akun',
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

          if (confirm == true && mounted) {
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
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFEF5350),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout,
                size: 24,
                color: Color(0xFFEF5350),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Keluar',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF5350),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFEF5350),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
