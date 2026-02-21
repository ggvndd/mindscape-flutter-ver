import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/mood_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../domain/entities/mood.dart';

/// Full mood history screen - shows all mood entries
class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  final MoodService _moodService = MoodService();
  final AuthService _authService = AuthService();
  List<Mood> _moodHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;
      final moods = await _moodService.getMoodsByDateRange(
        userId: user.uid,
        startDate: DateTime(2020),
        endDate: DateTime.now(),
      );
      moods.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      setState(() {
        _moodHistory = moods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getScoreColor(int score) {
    if (score <= 39) return const Color(0xFFE89A5D);
    if (score <= 79) return const Color(0xFFF7C566);
    return const Color(0xFFA8B475);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d\nMMM');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                'Mood History',
                style: GoogleFonts.urbanist(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3D2914),
                ),
              ),
            ),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFA8B475)))
                  : _moodHistory.isEmpty
                      ? Center(
                          child: Text(
                            'Belum ada mood yang dicatat',
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              color: const Color(0xFF999999),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: _moodHistory.length,
                          itemBuilder: (context, index) {
                            final mood = _moodHistory[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3F0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        dateFormat.format(mood.timestamp),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.urbanist(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF3D2914),
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mood.getMoodDisplayName(),
                                          style: GoogleFonts.urbanist(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3D2914),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          mood.note ?? 'No notes',
                                          style: GoogleFonts.urbanist(
                                            fontSize: 14,
                                            color: const Color(0xFF999999),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          timeFormat.format(mood.timestamp),
                                          style: GoogleFonts.urbanist(
                                            fontSize: 12,
                                            color: const Color(0xFF999999),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Stack(
                                      children: [
                                        SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: CircularProgressIndicator(
                                            value: mood.moodScore / 100,
                                            backgroundColor:
                                                const Color(0xFFF5F3F0),
                                            color:
                                                _getScoreColor(mood.moodScore),
                                            strokeWidth: 4,
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            '${mood.moodScore}',
                                            style: GoogleFonts.urbanist(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF3D2914),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
