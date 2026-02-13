import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';

/// Sign up screen with form validation and error states
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  
  // Validation states
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  
  // Track if fields have been interacted with
  bool _nameHasBeenFocused = false;
  bool _emailHasBeenFocused = false;
  bool _passwordHasBeenFocused = false;
  bool _confirmPasswordHasBeenFocused = false;

  @override
  void initState() {
    super.initState();
    
    // Add listeners for real-time validation
    _nameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
    
    // Track when fields are focused
    _nameFocusNode.addListener(() {
      if (_nameFocusNode.hasFocus && _nameController.text.isNotEmpty) {
        setState(() => _nameHasBeenFocused = true);
      }
    });
    
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus && _emailController.text.isNotEmpty) {
        setState(() => _emailHasBeenFocused = true);
      }
    });
    
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus && _passwordController.text.isNotEmpty) {
        setState(() => _passwordHasBeenFocused = true);
      }
    });
    
    _confirmPasswordFocusNode.addListener(() {
      if (_confirmPasswordFocusNode.hasFocus && _confirmPasswordController.text.isNotEmpty) {
        setState(() => _confirmPasswordHasBeenFocused = true);
      }
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _validateName() {
    setState(() {
      if (_nameController.text.isEmpty) {
        _nameError = null; // Don't show error while typing
        _nameHasBeenFocused = false;
      } else {
        if (_nameFocusNode.hasFocus) {
          _nameHasBeenFocused = true;
        }
        if (_nameController.text.length < 2) {
          _nameError = 'Nama minimal 2 karakter';
        } else {
          _nameError = null;
        }
      }
    });
  }

  void _validateEmail() {
    setState(() {
      final email = _emailController.text;
      if (email.isEmpty) {
        _emailError = null; // Don't show error while typing
        _emailHasBeenFocused = false;
      } else {
        if (_emailFocusNode.hasFocus) {
          _emailHasBeenFocused = true;
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
          _emailError = 'Format email tidak valid';
        } else {
          _emailError = null;
        }
      }
    });
  }

  void _validatePassword() {
    setState(() {
      final password = _passwordController.text;
      if (password.isEmpty) {
        _passwordError = null; // Don't show error while typing
        _passwordHasBeenFocused = false;
      } else {
        if (_passwordFocusNode.hasFocus) {
          _passwordHasBeenFocused = true;
        }
        if (password.length < 6) {
          _passwordError = 'Password minimal 6 karakter';
        } else {
          _passwordError = null;
        }
      }
    });
  }

  void _validateConfirmPassword() {
    setState(() {
      final confirmPassword = _confirmPasswordController.text;
      if (confirmPassword.isEmpty) {
        _confirmPasswordError = null;
        _confirmPasswordHasBeenFocused = false;
      } else {
        if (_confirmPasswordFocusNode.hasFocus) {
          _confirmPasswordHasBeenFocused = true;
        }
        if (confirmPassword != _passwordController.text) {
          _confirmPasswordError = 'Password tidak sama';
        } else {
          _confirmPasswordError = null;
        }
      }
    });
  }

  Future<void> _signUp() async {
    // Validate all fields first
    _validateName();
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();

    // Check if form is valid
    final hasErrors = _nameError != null || 
                     _emailError != null || 
                     _passwordError != null || 
                     _confirmPasswordError != null ||
                     _nameController.text.isEmpty ||
                     _emailController.text.isEmpty ||
                     _passwordController.text.isEmpty ||
                     _confirmPasswordController.text.isEmpty;

    if (hasErrors) {
      // Show errors for empty fields
      setState(() {
        if (_nameController.text.isEmpty) _nameError = 'Nama wajib diisi';
        if (_emailController.text.isEmpty) _emailError = 'Email wajib diisi';
        if (_passwordController.text.isEmpty) _passwordError = 'Password wajib diisi';
        if (_confirmPasswordController.text.isEmpty) _confirmPasswordError = 'Konfirmasi password wajib diisi';
      });
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Use Firebase to create account
      final authService = AuthService();
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      
      // Navigate to rush hour screen on success
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/rush-hour');
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat akun: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: Column(
        children: [
          // Curved green header
          ClipPath(
            clipper: CurvedHeaderClipper(),
            child: Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFA8B475),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/logos/logo small.svg',
                      width: 60,
                      height: 60,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Daftar ke ',
                          style: GoogleFonts.urbanist(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF3D2914),
                          ),
                        ),
                        Text(
                          'Mindscape',
                          style: GoogleFonts.urbanist(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFA8B475),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Name field
                  Text(
                    'Nama Lengkap',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D2914),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama lengkap anda',
                      hintStyle: GoogleFonts.urbanist(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.person_outline,
                          color: _nameError != null ? Colors.orange : const Color(0xFF3D2914),
                          size: 20,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: _nameError != null ? Colors.orange : const Color(0xFFA8B475),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: _nameError != null ? Colors.orange : const Color(0xFFA8B475),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: _nameError != null ? Colors.orange : const Color(0xFFA8B475),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  if (_nameError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _nameError!,
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Email field
                  Text(
                    'Alamat Email',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D2914),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Masukkan email anda!',
                      hintStyle: GoogleFonts.urbanist(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.email_outlined,
                          color: _emailError != null ? Colors.orange : const Color(0xFF3D2914),
                          size: 20,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: _emailError != null ? Colors.orange : const Color(0xFFA8B475),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: _emailError != null ? Colors.orange : const Color(0xFFA8B475),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: _emailError != null ? Colors.orange : const Color(0xFFA8B475),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  if (_emailError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _emailError!,
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Password field
                  Text(
                    'Password',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D2914),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password anda',
                      hintStyle: GoogleFonts.urbanist(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.lock_outline,
                          color: _passwordError != null ? Colors.orange : const Color(0xFF3D2914),
                          size: 20,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: _passwordError != null ? Colors.orange : const Color(0xFFA8B475),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: _passwordError != null ? Colors.orange : const Color(0xFFA8B475),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: _passwordError != null ? Colors.orange : const Color(0xFFA8B475),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  if (_passwordError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _passwordError!,
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Confirm Password field
                  Text(
                    'Konfirmasi Password',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3D2914),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Ulangi password anda',
                      hintStyle: GoogleFonts.urbanist(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.lock_outline,
                          color: _confirmPasswordError != null ? Colors.orange : const Color(0xFF3D2914),
                          size: 20,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: _confirmPasswordError != null ? Colors.orange : const Color(0xFFA8B475),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: _confirmPasswordError != null ? Colors.orange : const Color(0xFFA8B475),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: _confirmPasswordError != null ? Colors.orange : const Color(0xFFA8B475),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  if (_confirmPasswordError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _confirmPasswordError!,
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _nameHasBeenFocused && 
                                         _emailHasBeenFocused && 
                                         _passwordHasBeenFocused && 
                                         _confirmPasswordHasBeenFocused &&
                                         _nameController.text.isNotEmpty && 
                                         _emailController.text.isNotEmpty && 
                                         _passwordController.text.isNotEmpty && 
                                         _confirmPasswordController.text.isNotEmpty &&
                                         _nameError == null &&
                                         _emailError == null &&
                                         _passwordError == null &&
                                         _confirmPasswordError == null
                            ? const Color(0xFFA8B475)
                            : const Color(0xFF3D2914),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Daftar Sekarang',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sign in link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/sign-in');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Sudah memiliki akun? ',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            color: const Color(0xFF666666),
                          ),
                          children: [
                            TextSpan(
                              text: 'Masuk Sekarang.',
                              style: GoogleFonts.urbanist(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE89A5D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom clipper for curved header
class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    
    final controlPoint1 = Offset(size.width * 0.25, size.height);
    final controlPoint2 = Offset(size.width * 0.75, size.height);
    final endPoint = Offset(size.width, size.height - 40);
    
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
