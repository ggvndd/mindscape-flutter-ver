import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/app_lock_service.dart';

/// Screen for verifying PIN when app is opened
class AppLockVerifyScreen extends StatefulWidget {
  const AppLockVerifyScreen({super.key});

  @override
  State<AppLockVerifyScreen> createState() => _AppLockVerifyScreenState();
}

class _AppLockVerifyScreenState extends State<AppLockVerifyScreen> {
  final AppLockService _appLockService = AppLockService();
  final List<String> _pin = ['', '', '', ''];
  int _currentIndex = 0;
  bool _isError = false;

  void _onNumberPressed(String number) {
    if (_currentIndex < 4) {
      setState(() {
        _pin[_currentIndex] = number;
        _currentIndex++;
        _isError = false;
      });

      if (_currentIndex == 4) {
        // All 4 digits entered
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _pin[_currentIndex] = '';
        _isError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final pinString = _pin.join();
    
    final isValid = await _appLockService.verifyPin(pinString);
    
    if (isValid) {
      // PIN correct, proceed to app
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      // PIN incorrect
      setState(() {
        _isError = true;
      });
      
      // Shake animation
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        setState(() {
          _currentIndex = 0;
          _pin.fillRange(0, 4, '');
          _isError = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F3F0),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D2914),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Selamat Datang!',
                  style: GoogleFonts.urbanist(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3D2914),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  'Input App Lock kamu buat bisa akses aplikasi ini\nMindscape!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                
                // PIN Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = _pin[index].isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isError
                              ? Colors.red
                              : isFilled
                                    ? const Color(0xFFA8B475)
                                  : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isFilled
                            ? Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _isError
                                      ? Colors.red
                                      : const Color(0xFFA8B475),
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                ),
                
                if (_isError) ...[
                  const SizedBox(height: 16),
                  Text(
                    'PIN salah, coba lagi',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 48),

                // Number Pad
                // Rows 1-3
                for (int row = 0; row < 3; row++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (col) {
                        final number = (row * 3 + col + 1).toString();
                        return _buildNumberButton(number);
                      }),
                    ),
                  ),
                
                // Row 4 (empty, 0, delete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 72, height: 72),
                    _buildNumberButton('0'),
                    _buildNumberButton('', isDelete: true),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Forgot PIN text
                TextButton(
                  onPressed: () {
                    // Show dialog explaining they need to contact support or re-login
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'Aku lupa password',
                          style: GoogleFonts.urbanist(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D2914),
                          ),
                        ),
                        content: Text(
                          'Untuk mereset PIN App Lock, kamu perlu logout dan login kembali ke akun kamu.',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Kembali',
                              style: GoogleFonts.urbanist(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'Aku lupa password',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: const Color(0xFFA8B475),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number, {bool isDelete = false}) {
    if (number.isEmpty && !isDelete) {
      return const SizedBox(width: 72, height: 72);
    }

    return GestureDetector(
      onTap: () {
        if (isDelete) {
          _onDeletePressed();
        } else {
          _onNumberPressed(number);
        }
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isDelete ? Colors.transparent : const Color(0xFFA8B475),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isDelete
              ? const Icon(
                  Icons.backspace_outlined,
                  color: Color(0xFFA8B475),
                  size: 28,
                )
              : Text(
                  number,
                  style: GoogleFonts.urbanist(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
