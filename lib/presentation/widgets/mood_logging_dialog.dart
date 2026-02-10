import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/services/mood_service.dart';
import '../../core/services/auth_service.dart';

class MoodLoggingDialog extends StatefulWidget {
  final Function? onMoodLogged;

  const MoodLoggingDialog({
    Key? key,
    this.onMoodLogged,
  }) : super(key: key);

  @override
  State<MoodLoggingDialog> createState() => _MoodLoggingDialogState();
}

class _MoodLoggingDialogState extends State<MoodLoggingDialog> {
  final MoodService _moodService = MoodService();
  final AuthService _authService = AuthService();
  final TextEditingController _noteController = TextEditingController();
  
  String? _selectedMood;
  bool _isLogging = false;

  final List<Map<String, String>> _moods = [
    {'name': 'gloomy', 'display': 'Gloomy'},
    {'name': 'sad', 'display': 'Sad'},
    {'name': 'justokay', 'display': 'Just Okay'},
    {'name': 'fine', 'display': 'Fine'},
    {'name': 'happy', 'display': 'Happy'},
    {'name': 'cheerful', 'display': 'Cheerful'},
  ];

  Future<void> _logMood() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih mood kamu dulu yaa!'),
          backgroundColor: Color(0xFF3D2914),
        ),
      );
      return;
    }

    setState(() {
      _isLogging = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _moodService.logMood(
        userId: user.uid,
        mood: _selectedMood!,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mood berhasil dicatat!'),
            backgroundColor: Color(0xFFA8B475),
          ),
        );
        
        // Call the callback if provided
        if (widget.onMoodLogged != null) {
          widget.onMoodLogged!();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLogging = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencatat mood: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F3F0),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Gimana perasaan kamu?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2914),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih mood yang paling sesuai',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 24),
              
              // Mood options grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _moods.length,
                itemBuilder: (context, index) {
                  final mood = _moods[index];
                  final isSelected = _selectedMood == mood['name'];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = mood['name'];
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFA8B475) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFA8B475) : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/logos/moods/${mood['name']}.svg',
                            width: 48,
                            height: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mood['display']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : const Color(0xFF3D2914),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Note field
              const Text(
                'Catatan (opsional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3D2914),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ceritain dong, kenapa kamu merasa seperti ini?',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLogging ? null : _logMood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA8B475),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLogging
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Catat Mood',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
}

// Helper function to show the modal
void showMoodLoggingDialog(BuildContext context, {Function? onMoodLogged}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MoodLoggingDialog(onMoodLogged: onMoodLogged),
  );
}
