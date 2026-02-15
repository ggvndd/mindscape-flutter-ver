import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/mood_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../domain/entities/mood.dart';
import '../../widgets/mood_logging_dialog.dart';
import '../../../testing/seed_mood_data.dart';
import 'mindscore_detail_screen.dart';

/// Mood Tracker screen showing mood logging and analytics
class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final MoodService _moodService = MoodService();
  final AuthService _authService = AuthService();
  
  int _mindScore = 60;
  List<Map<String, dynamic>> _weeklyMoodData = [];
  Map<String, Mood?> _dailyMoodData = {};
  bool _isLoading = true;
  DateTime _currentWeekStart = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  String _selectedInterval = 'Mingguan';

  @override
  void initState() {
    super.initState();
    _initializeWeekStart();
    _loadData();
  }

  void _initializeWeekStart() {
    final now = DateTime.now();
    // Set to Monday of current week
    _currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    _currentWeekStart = DateTime(_currentWeekStart.year, _currentWeekStart.month, _currentWeekStart.day);
    _selectedDate = now;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Load mindscore
      final mindscore = await _moodService.calculateMindscore(user.uid);
      
      // Load weekly data
      final weeklyData = await _moodService.getWeeklyMoodData(
        userId: user.uid,
        startDate: _currentWeekStart,
      );
      
      // Load daily data
      final dailyData = await _moodService.getDailyMoods(
        userId: user.uid,
        date: _selectedDate,
      );

      setState(() {
        _mindScore = mindscore;
        _weeklyMoodData = weeklyData;
        _dailyMoodData = dailyData;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _logMood() {
    showMoodLoggingDialog(
      context,
      onMoodLogged: () {
        _loadData(); // Refresh data after logging
      },
    );
  }

  Future<void> _seedDummyData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFA8B475)),
      ),
    );

    try {
      await seedMoodDataForUser(user.uid);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dummy data berhasil ditambahkan! Refresh untuk melihat.'),
            backgroundColor: Color(0xFFA8B475),
            duration: Duration(seconds: 3),
          ),
        );
        _loadData(); // Refresh the screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menambah data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openMindscoreDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MindscoreDetailScreen(),
      ),
    );
  }

  String _getMoodIconPath(String mood) {
    return 'assets/logos/moods/mood_$mood.svg';
  }

  void _showIntervalDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Pilih Interval',
                style: GoogleFonts.urbanist(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3D2914),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDropdownOption('Mingguan', () async {
              Navigator.pop(context);
              _showWeekPicker();
            }),
            _buildDropdownOption('Bulanan', () async {
              Navigator.pop(context);
              _showMonthPicker();
            }),
          ],
        ),
      ),
    );
  }

  void _showWeekPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentWeekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
      helpText: 'Pilih hari pertama minggu',
    );

    if (picked != null) {
      // Use the selected date as the start of the week (not Monday)
      final normalizedWeekStart = DateTime(picked.year, picked.month, picked.day);
      
      setState(() {
        _selectedInterval = 'Mingguan';
        _currentWeekStart = normalizedWeekStart;
      });
      _loadData();
    }
  }

  void _showMonthPicker() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthPickerDialog(
        initialDate: DateTime(_currentWeekStart.year, _currentWeekStart.month),
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedInterval = 'Bulanan';
        // Set to first day of selected month
        _currentWeekStart = DateTime(picked.year, picked.month, 1);
      });
      _loadData();
    }
  }

  void _showHarianDropdown() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  Widget _buildDropdownOption(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF3D2914),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeFormat = DateFormat('HH:mm', 'id_ID');
    final dateFormat = DateFormat('d MMMM yyyy', 'id_ID');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFA8B475),
                ),
              )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF3D2914),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title (Long press to seed dummy data)
              GestureDetector(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Seed Dummy Data'),
                      content: const Text('Tambahkan data mood dummy untuk 30 hari terakhir? Ini akan membantu visualisasi chart.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _seedDummyData();
                          },
                          child: const Text('Tambahkan'),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(
                  'Mood Tracker',
                  style: GoogleFonts.urbanist(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D2914),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Lihat mood kamu berdasarkan timeline yang kamu inginkan!',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  color: const Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Log Mood Card
              _buildLogMoodCard(timeFormat.format(now)),
              
              const SizedBox(height: 16),
              
              // Mindscore Card
              _buildMindscoreCard(),
              
              const SizedBox(height: 24),
              
              // Mood Tracker Interval
              _buildMoodTrackerInterval(),
              
              const SizedBox(height: 24),
              
              // Mood Tracker Harian
              _buildMoodTrackerHarian(dateFormat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogMoodCard(String currentTime) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFA8B475),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Log Moodmu Sekarang!',
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sekarang Jam $currentTime',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _logMood,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Catat',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D2914),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMindscoreCard() {
    return GestureDetector(
      onTap: _openMindscoreDetail,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFA8B475),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/logos/mindscore.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mindscore',
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D2914),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check out your overall moodscore here.',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$_mindScore',
              style: GoogleFonts.urbanist(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D2914),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF3D2914),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodTrackerInterval() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mood Tracker Interval',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D2914),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _showIntervalDropdown();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedInterval,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          color: const Color(0xFF3D2914),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset(
                        'assets/logos/dropdown.svg',
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar chart
          SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklyMoodData.map((data) {
                final score = data['score'] as int;
                final height = (score / 100) * 160;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      style: GoogleFonts.urbanist(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D2914),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: height,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA8B475),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['day'],
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '${DateFormat('d', 'id_ID').format(_currentWeekStart)}-${DateFormat('d MMMM yyyy', 'id_ID').format(_currentWeekStart.add(const Duration(days: 6)))}',
              style: GoogleFonts.urbanist(
                fontSize: 12,
                color: const Color(0xFF666666),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('d MMMM', 'id_ID').format(_currentWeekStart),
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: const Color(0xFF666666),
                ),
              ),
              Text(
                DateFormat('d MMMM', 'id_ID').format(_currentWeekStart.add(const Duration(days: 6))),
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTrackerHarian(DateFormat dateFormat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mood Tracker Harian',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D2914),
                ),
              ),
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    _showHarianDropdown();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            DateFormat('E, d MMM', 'id_ID').format(_selectedDate),
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              color: const Color(0xFF3D2914),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          'assets/logos/dropdown.svg',
                          width: 16,
                          height: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Mood icons with times
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _dailyMoodData.entries.map((entry) {
              final time = entry.key;
              final mood = entry.value;
              
              return Column(
                children: [
                  SvgPicture.asset(
                    mood != null ? _getMoodIconPath(mood.mood) : 'assets/logos/moods/mood_fine.svg',
                    width: 32,
                    height: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      color: const Color(0xFF999999),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Custom month picker dialog
class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const _MonthPickerDialog({
    Key? key,
    required this.initialDate,
  }) : super(key: key);

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;
  final int _currentYear = DateTime.now().year;
  final int _currentMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  final List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _selectedYear > 2020
                      ? () {
                          setState(() {
                            _selectedYear--;
                          });
                        }
                      : null,
                  color: const Color(0xFFA8B475),
                ),
                Text(
                  '$_selectedYear',
                  style: GoogleFonts.urbanist(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D2914),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedYear < _currentYear
                      ? () {
                          setState(() {
                            _selectedYear++;
                          });
                        }
                      : null,
                  color: const Color(0xFFA8B475),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Month grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isDisabled = _selectedYear == _currentYear && month > _currentMonth;
                final isSelected = month == _selectedMonth && _selectedYear == widget.initialDate.year;
                
                return InkWell(
                  onTap: isDisabled
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                            DateTime(_selectedYear, month),
                          );
                        },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFA8B475)
                          : isDisabled
                              ? Colors.grey[200]
                              : const Color(0xFFF5F3F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _monthNames[index],
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isDisabled
                                ? Colors.grey[400]
                                : const Color(0xFF3D2914),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
