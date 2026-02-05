import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Rush hour preferences screen
class RushHourScreen extends StatefulWidget {
  const RushHourScreen({super.key});

  @override
  State<RushHourScreen> createState() => _RushHourScreenState();
}

class _RushHourScreenState extends State<RushHourScreen> {
  // Rush hour preferences
  bool _enableRushHour = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);
  
  // Activity selections
  final Set<String> _selectedActivities = {'work', 'study'};
  
  final Map<String, String> _activities = {
    'work': 'Kerja Part-time',
    'study': 'Kuliah',
    'commute': 'Perjalanan',
    'exercise': 'Olahraga',
    'social': 'Sosial',
  };

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3D2914),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _continue() {
    // Save rush hour preferences (mock)
    Navigator.pushReplacementNamed(context, '/sign-up-success');
  }

  void _skip() {
    // Skip rush hour setup
    Navigator.pushReplacementNamed(context, '/sign-up-success');
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skip button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Lewati',
                    style: GoogleFonts.urbanist(
                      fontSize: isTablet ? 16 : 14,
                      color: const Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: isTablet ? 20 : 16),
              
              // Illustration placeholder
              Center(
                child: Container(
                  width: isTablet ? 300 : 250,
                  height: isTablet ? 300 : 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.3),
                        const Color(0xFFFF8C00).withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: isTablet ? 80 : 60,
                          color: const Color(0xFFFF8C00),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '⚡ Rush Hour',
                          style: GoogleFonts.urbanist(
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3D2914),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: isTablet ? 40 : 32),
              
              // Title and description
              Text(
                'Atur Rush Hour Mode',
                style: GoogleFonts.urbanist(
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3D2914),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Saat kamu lagi sibuk banget, aktifkan mode cepat untuk tracking mood dalam hitungan detik!',
                style: GoogleFonts.urbanist(
                  fontSize: isTablet ? 18 : 16,
                  color: const Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              
              SizedBox(height: isTablet ? 32 : 24),
              
              // Enable rush hour toggle
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flash_on,
                      color: _enableRushHour ? const Color(0xFFFFD700) : const Color(0xFFCBD5E0),
                      size: isTablet ? 28 : 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aktifkan Rush Hour',
                            style: GoogleFonts.urbanist(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3D2914),
                            ),
                          ),
                          Text(
                            'Mode tracking super cepat',
                            style: GoogleFonts.urbanist(
                              fontSize: isTablet ? 14 : 12,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _enableRushHour,
                      onChanged: (value) => setState(() => _enableRushHour = value),
                      activeColor: const Color(0xFF38A169),
                      inactiveThumbColor: const Color(0xFFCBD5E0),
                    ),
                  ],
                ),
              ),
              
              if (_enableRushHour) ...[
                SizedBox(height: isTablet ? 24 : 20),
                
                // Time settings
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waktu Rush Hour',
                        style: GoogleFonts.urbanist(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3D2914),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeSelector(
                              context,
                              'Mulai',
                              _startTime,
                              () => _selectTime(context, true),
                              isTablet,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimeSelector(
                              context,
                              'Selesai',
                              _endTime,
                              () => _selectTime(context, false),
                              isTablet,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isTablet ? 24 : 20),
                
                // Activity preferences
                Container(
                  padding: EdgeInsets.all(isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktivitas Saat Rush Hour',
                        style: GoogleFonts.urbanist(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3D2914),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Pilih aktivitas yang biasanya kamu lakukan',
                        style: GoogleFonts.urbanist(
                          fontSize: isTablet ? 14 : 12,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _activities.entries.map((entry) {
                          final isSelected = _selectedActivities.contains(entry.key);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedActivities.remove(entry.key);
                                } else {
                                  _selectedActivities.add(entry.key);
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12,
                                vertical: isTablet ? 10 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF3D2914) : const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF3D2914) : const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                entry.value,
                                style: GoogleFonts.urbanist(
                                  fontSize: isTablet ? 14 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF4A5568),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: isTablet ? 40 : 32),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                height: isTablet ? 60 : 56,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D2914),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Lanjutkan',
                    style: GoogleFonts.urbanist(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector(
    BuildContext context,
    String label,
    TimeOfDay time,
    VoidCallback onTap,
    bool isTablet,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 16 : 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: isTablet ? 12 : 10,
                color: const Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: GoogleFonts.urbanist(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D2914),
              ),
            ),
          ],
        ),
      ),
    );
  }
}