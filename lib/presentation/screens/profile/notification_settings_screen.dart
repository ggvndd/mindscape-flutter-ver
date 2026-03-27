import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/app_colors.dart';

/// Notification settings screen — mood log interval + notification toggles
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notifService = NotificationService();

  bool _isLoading = true;
  bool _isSaving = false;

  // Settings state
  int _moodInterval = 3; // hours
  bool _moodRemindersEnabled = false;
  bool _rushHourNotifEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final interval = await NotificationService.getSavedInterval();
    final moodEnabled = await NotificationService.getMoodRemindersEnabled();
    final rushEnabled = await NotificationService.getRushHourNotifEnabled();
    setState(() {
      _moodInterval = interval;
      _moodRemindersEnabled = moodEnabled;
      _rushHourNotifEnabled = rushEnabled;
      _isLoading = false;
    });
  }

  Future<void> _saveAndApply() async {
    setState(() => _isSaving = true);

    // Persist to SharedPreferences
    await NotificationService.saveInterval(_moodInterval);
    await NotificationService.saveMoodRemindersEnabled(_moodRemindersEnabled);
    await NotificationService.saveRushHourNotifEnabled(_rushHourNotifEnabled);

    // Also persist to Firestore for cross-device sync
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _authService.saveNotificationSettings(
          userId: user.uid,
          moodInterval: _moodInterval,
          moodRemindersEnabled: _moodRemindersEnabled,
          rushHourNotifEnabled: _rushHourNotifEnabled,
        );
      }
    } catch (_) {
      // Firestore failure is non-fatal; settings are saved in SharedPreferences
    }

    // Schedule or cancel mood reminders
    if (_moodRemindersEnabled) {
      final granted = await _notifService.requestPermissions();
      if (granted) {
        await _notifService.scheduleMoodReminders(_moodInterval);
      } else {
        // Permission denied – turn off toggle
        await NotificationService.saveMoodRemindersEnabled(false);
        setState(() => _moodRemindersEnabled = false);
      }
    } else {
      await _notifService.cancelMoodReminders();
    }

    // If rush hour notif is disabled, cancel any existing one
    if (!_rushHourNotifEnabled) {
      await _notifService.cancelRushHourNotification();
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengaturan notifikasi atau mood logging disimpan!',
            style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFA8B475),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF3D2914), width: 1.5),
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

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFA8B475)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifikasi dan Mood Logging',
                            style: GoogleFonts.urbanist(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF3D2914),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Atur seberapa sering kamu moodlogging dan MindScape mengingatkan kamu.',
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Mood Log Interval ──────────────────────────
                          _buildSectionLabel(
                            'Interval Log Mood',
                            'Seberapa sering kamu ingin diingatkan untuk mencatat mood.',
                          ),
                          const SizedBox(height: 16),
                          _buildIntervalSelector(),
                          const SizedBox(height: 8),
                          _buildTimeSlotPreview(),
                          const SizedBox(height: 28),

                          // ── Mood Reminders Toggle ──────────────────────
                          _buildToggleCard(
                            icon: Icons.alarm_outlined,
                            title: 'Pengingat Log Mood',
                            subtitle:
                                'Terima notifikasi harian sesuai interval di atas',
                            value: _moodRemindersEnabled,
                            onChanged: (v) =>
                                setState(() => _moodRemindersEnabled = v),
                          ),
                          const SizedBox(height: 16),

                          // ── Rush Hour Notification Toggle ──────────────
                          _buildToggleCard(
                            icon: Icons.bolt_outlined,
                            title: 'Notifikasi Rush Hour',
                            subtitle:
                                'Beri tahu saat jam sibuk kamu dimulai setiap hari',
                            value: _rushHourNotifEnabled,
                            onChanged: (v) =>
                                setState(() => _rushHourNotifEnabled = v),
                          ),
                          const SizedBox(height: 32),

                          // ── Save Button ────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveAndApply,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3D2914),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Simpan Pengaturan',
                                      style: GoogleFonts.urbanist(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Test buttons ───────────────────────────────
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await _notifService.requestPermissions();
                                    await _notifService
                                        .showImmediateMoodNotification();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                          'Notifikasi mood dikirim!',
                                          style: GoogleFonts.urbanist(),
                                        ),
                                        backgroundColor:
                                            const Color(0xFFA8B475),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF3D2914),
                                    side: const BorderSide(
                                        color: Color(0xFF3D2914), width: 1.5),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.alarm, size: 18),
                                  label: Text('Tes Mood',
                                      style: GoogleFonts.urbanist(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await _notifService.requestPermissions();
                                    await NotificationService()
                                        .showRushHourNotification();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                          'Notifikasi Rush Hour dikirim!',
                                          style: GoogleFonts.urbanist(),
                                        ),
                                        backgroundColor: AppColors.primary,
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.primary, width: 1.5),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.bolt, size: 18),
                                  label: Text('Tes Rush Hour',
                                      style: GoogleFonts.urbanist(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── Info box ───────────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA8B475).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      const Color(0xFFA8B475).withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Color(0xFF3D2914), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Pastikan notifikasi diizinkan di pengaturan perangkat kamu agar pengingat bisa berjalan.',
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

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D2914),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.urbanist(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildIntervalSelector() {
    final options = [3, 4, 5, 6];
    return Row(
      children: options.map((h) {
        final selected = _moodInterval == h;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: h != options.last ? 10 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _moodInterval = h),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF3D2914)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF3D2914)
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF3D2914).withOpacity(0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  children: [
                    Text(
                      '${h}j',
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF3D2914),
                      ),
                    ),
                    Text(
                      'sekali',
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        color: selected
                            ? Colors.white70
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeSlotPreview() {
    final hours = NotificationService.getMoodReminderHours(_moodInterval);
    final labels = hours
        .map((h) => '${h.toString().padLeft(2, '0')}:00')
        .join('  •  ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFA8B475).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        labels,
        style: GoogleFonts.urbanist(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3D2914),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFA8B475).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF3D2914), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D2914),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.urbanist(
                      fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFA8B475),
            activeTrackColor: const Color(0xFFA8B475).withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}
