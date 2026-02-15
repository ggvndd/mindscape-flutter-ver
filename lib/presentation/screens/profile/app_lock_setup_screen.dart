import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/app_lock_service.dart';

/// Screen for setting up app lock PIN
class AppLockSetupScreen extends StatefulWidget {
  const AppLockSetupScreen({super.key});

  @override
  State<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends State<AppLockSetupScreen> {
  final AppLockService _appLockService = AppLockService();
  final List<String> _pin = ['', '', '', ''];
  int _currentIndex = 0;
  bool _isConfirmMode = false;
  List<String> _firstPin = [];

  void _onNumberPressed(String number) {
    if (_currentIndex < 4) {
      setState(() {
        _pin[_currentIndex] = number;
        _currentIndex++;
      });

      if (_currentIndex == 4) {
        // All 4 digits entered
        _handlePinComplete();
      }
    }
  }

  void _onDeletePressed() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _pin[_currentIndex] = '';
      });
    }
  }

  Future<void> _handlePinComplete() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_isConfirmMode) {
      // First PIN entry, ask for confirmation
      setState(() {
        _firstPin = List.from(_pin);
        _isConfirmMode = true;
        _currentIndex = 0;
        _pin.fillRange(0, 4, '');
      });
    } else {
      // Confirm mode - check if PINs match
      final confirmPin = _pin.join();
      final originalPin = _firstPin.join();

      if (confirmPin == originalPin) {
        // PINs match, save it
        try {
          await _appLockService.setPin(confirmPin);
          if (mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'App Lock berhasil diaktifkan!',
                  style: GoogleFonts.urbanist(),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Gagal mengatur PIN: $e',
                  style: GoogleFonts.urbanist(),
                ),
                backgroundColor: Colors.red,
              ),
            );
            // Reset
            setState(() {
              _isConfirmMode = false;
              _firstPin.clear();
              _currentIndex = 0;
              _pin.fillRange(0, 4, '');
            });
          }
        }
      } else {
        // PINs don't match
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PIN tidak cocok, coba lagi',
              style: GoogleFonts.urbanist(),
            ),
            backgroundColor: Colors.red,
          ),
        );
        // Reset
        setState(() {
          _isConfirmMode = false;
          _firstPin.clear();
          _currentIndex = 0;
          _pin.fillRange(0, 4, '');
        });
      }
    }
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA8B475),
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
                      _isConfirmMode ? 'Konfirmasi PIN' : 'App Lock',
                      style: GoogleFonts.urbanist(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D2914),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      _isConfirmMode
                          ? 'Masukkan PIN kamu lagi untuk konfirmasi'
                          : 'Kamu bisa mengunci aplikasi untuk melindungi\nprivasi kamu! Input kombinasi angka untuk\nmengunci aplikasinya.',
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
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFilled
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
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFA8B475),
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                    ),

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
                    
                    // Row 4 (Delete, 0, empty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNumberButton('', isDelete: true),
                        _buildNumberButton('0'),
                        _buildNumberButton('', isDelete: true, showDelete: true),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number, {bool isDelete = false, bool showDelete = false}) {
    if (number.isEmpty && !showDelete) {
      return const SizedBox(width: 72, height: 72);
    }

    return GestureDetector(
      onTap: () {
        if (showDelete) {
          _onDeletePressed();
        } else if (!isDelete) {
          _onNumberPressed(number);
        }
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: showDelete ? Colors.transparent : const Color(0xFFA8B475),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: showDelete
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
