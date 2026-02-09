import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';

/// Rush Hour settings screen for managing rush hour time periods
class RushHourSettingsScreen extends StatefulWidget {
  const RushHourSettingsScreen({super.key});

  @override
  State<RushHourSettingsScreen> createState() => _RushHourSettingsScreenState();
}

class _RushHourSettingsScreenState extends State<RushHourSettingsScreen> {
  final AuthService _authService = AuthService();
  List<RushHourPeriod> _rushHourPeriods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRushHourSettings();
  }

  Future<void> _loadRushHourSettings() async {
    try {
      final userData = await _authService.getUserData();
      final rushHourData = userData?['preferences']?['rushHours'];
      
      setState(() {
        if (rushHourData != null && rushHourData is List) {
          _rushHourPeriods = rushHourData.map((period) {
            return RushHourPeriod(
              startTime: TimeOfDay(
                hour: period['start']['hour'] ?? 9,
                minute: period['start']['minute'] ?? 0,
              ),
              endTime: TimeOfDay(
                hour: period['end']['hour'] ?? 17,
                minute: period['end']['minute'] ?? 0,
              ),
            );
          }).toList();
        } else {
          // Default rush hour periods
          _rushHourPeriods = [
            RushHourPeriod(
              startTime: const TimeOfDay(hour: 9, minute: 0),
              endTime: const TimeOfDay(hour: 12, minute: 0),
            ),
            RushHourPeriod(
              startTime: const TimeOfDay(hour: 13, minute: 0),
              endTime: const TimeOfDay(hour: 17, minute: 0),
            ),
            RushHourPeriod(
              startTime: const TimeOfDay(hour: 19, minute: 0),
              endTime: const TimeOfDay(hour: 21, minute: 0),
            ),
          ];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime 
          ? _rushHourPeriods[index].startTime 
          : _rushHourPeriods[index].endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA8B475),
              onPrimary: Colors.white,
              onSurface: Color(0xFF3D2914),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _rushHourPeriods[index].startTime = picked;
        } else {
          _rushHourPeriods[index].endTime = picked;
        }
      });
    }
  }

  void _addRushHour() {
    setState(() {
      _rushHourPeriods.add(
        RushHourPeriod(
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
        ),
      );
    });
  }

  void _removeRushHour(int index) {
    setState(() {
      _rushHourPeriods.removeAt(index);
    });
  }

  Future<void> _saveSettings() async {
    // TODO: Implement save to Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rush hour settings berhasil disimpan',
          style: GoogleFonts.urbanist(),
        ),
        backgroundColor: Colors.green,
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
                      'Rush Hour Setup',
                      style: GoogleFonts.urbanist(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D2914),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Atur waktu rush hour kamu untuk tracking mood yang lebih akurat.',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Rush Hour Periods
                    ...List.generate(_rushHourPeriods.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildRushHourCard(index),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Add Rush Hour Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addRushHour,
                        icon: const Icon(Icons.add),
                        label: Text(
                          'Tambah Rush Hour Lagi!',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3D2914),
                          side: const BorderSide(
                            color: Color(0xFF3D2914),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D2914),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Simpan Pengaturan',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

  Widget _buildRushHourCard(int index) {
    final period = _rushHourPeriods[index];
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Rush Hour ${index + 1}',
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3D2914),
                ),
              ),
              const Spacer(),
              if (_rushHourPeriods.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red[400],
                  onPressed: () => _removeRushHour(index),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Start Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulai',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectTime(context, index, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF9F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE8E7E5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              period.startTime.format(context),
                              style: GoogleFonts.urbanist(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3D2914),
                              ),
                            ),
                            const Icon(
                              Icons.access_time,
                              color: Color(0xFFA8B475),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // End Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selesai',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectTime(context, index, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF9F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE8E7E5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              period.endTime.format(context),
                              style: GoogleFonts.urbanist(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3D2914),
                              ),
                            ),
                            const Icon(
                              Icons.access_time,
                              color: Color(0xFFA8B475),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RushHourPeriod {
  TimeOfDay startTime;
  TimeOfDay endTime;

  RushHourPeriod({
    required this.startTime,
    required this.endTime,
  });
}
