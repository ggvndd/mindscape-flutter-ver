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

  @override
  void initState() {
    super.initState();
    
    // Add listeners for real-time validation
    _nameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
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
      } else if (_nameController.text.length < 2) {
        _nameError = 'Nama minimal 2 karakter';
      } else {
        _nameError = null;
      }
    });
  }

  void _validateEmail() {
    setState(() {
      final email = _emailController.text;
      if (email.isEmpty) {
        _emailError = null; // Don't show error while typing
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'Format email tidak valid';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    setState(() {
      final password = _passwordController.text;
      if (password.isEmpty) {
        _passwordError = null; // Don't show error while typing
      } else if (password.length < 6) {
        _passwordError = 'Password minimal 6 karakter';
      } else {
        _passwordError = null;
      }
    });
  }

  void _validateConfirmPassword() {
    setState(() {
      final confirmPassword = _confirmPasswordController.text;
      if (confirmPassword.isEmpty) {
        _confirmPasswordError = null;
      } else if (confirmPassword != _passwordController.text) {
        _confirmPasswordError = 'Password tidak sama';
      } else {
        _confirmPasswordError = null;
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
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/onboarding');
                  }
                },
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
              
              SizedBox(height: isTablet ? 40 : 24),
              
              // Title
              Text(
                'Buat Akun Baru',
                style: GoogleFonts.urbanist(
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3D2914),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Bergabung dengan Mindscape untuk mulai tracking mood kamu!',
                style: GoogleFonts.urbanist(
                  fontSize: isTablet ? 18 : 16,
                  color: const Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              
              SizedBox(height: isTablet ? 40 : 32),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Name field
                    _buildTextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      label: 'Nama Lengkap',
                      hint: 'Masukkan nama lengkap',
                      error: _nameError,
                      keyboardType: TextInputType.name,
                      isTablet: isTablet,
                      iconPath: 'assets/logos/sign in and up/email.svg',
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Email field
                    _buildTextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      label: 'Email',
                      hint: 'nama@email.com',
                      error: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      isTablet: isTablet,
                      iconPath: 'assets/logos/sign in and up/email.svg',
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Password field
                    _buildTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      label: 'Password',
                      hint: 'Minimal 6 karakter',
                      error: _passwordError,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onTogglePassword: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      isTablet: isTablet,
                      iconPath: 'assets/logos/sign in and up/password.svg',
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Confirm Password field
                    _buildTextField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      label: 'Konfirmasi Password',
                      hint: 'Ulangi password',
                      error: _confirmPasswordError,
                      isPassword: true,
                      isPasswordVisible: _isConfirmPasswordVisible,
                      onTogglePassword: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      isTablet: isTablet,
                      iconPath: 'assets/logos/sign in and up/password.svg',
                    ),
                    
                    SizedBox(height: isTablet ? 40 : 32),
                    
                    // Sign up button
                    SizedBox(
                      width: double.infinity,
                      height: isTablet ? 60 : 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D2914),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                            : Text(
                                'Daftar Sekarang',
                                style: GoogleFonts.urbanist(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Sign in link
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.urbanist(
                            fontSize: isTablet ? 16 : 14,
                            color: const Color(0xFF666666),
                          ),
                          children: [
                            const TextSpan(text: 'Sudah punya akun? '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/sign-in'),
                                child: Text(
                                  'Masuk di sini',
                                  style: GoogleFonts.urbanist(
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3D2914),
                                    decoration: TextDecoration.underline,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool isTablet,
    String? error,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
    String? iconPath,
  }) {
    final hasError = error != null;
    final isFocused = focusNode.hasFocus;
    final hasContent = controller.text.isNotEmpty;
    
    // Determine border color: red for error, green for active/content, gray for default
    Color borderColor;
    if (hasError) {
      borderColor = const Color(0xFFE53E3E); // Red
    } else if (isFocused || hasContent) {
      borderColor = const Color(0xFF38A169); // Green
    } else {
      borderColor = const Color(0xFFE2E8F0); // Gray
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3D2914),
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (focused) => setState(() {}), // Rebuild to update border color
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            obscureText: isPassword && !isPasswordVisible,
            style: GoogleFonts.urbanist(
              fontSize: isTablet ? 16 : 14,
              color: const Color(0xFF1A202C),
            ),
            decoration: InputDecoration(
              prefixIcon: iconPath != null
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        iconPath,
                        width: 20,
                        height: 20,
                        color: hasError 
                            ? const Color(0xFFE53E3E)
                            : (isFocused || hasContent)
                                ? const Color(0xFF38A169)
                                : const Color(0xFFA0AEC0),
                      ),
                    )
                  : null,
              hintText: hint,
              hintStyle: GoogleFonts.urbanist(
                fontSize: isTablet ? 16 : 14,
                color: const Color(0xFFA0AEC0),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 16,
                vertical: isTablet ? 20 : 16,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFFA0AEC0),
                      ),
                      onPressed: onTogglePassword,
                    )
                  : null,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              SvgPicture.asset(
                'assets/logos/sign in and up/warning.svg',
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error!,
                  style: GoogleFonts.urbanist(
                    fontSize: isTablet ? 14 : 12,
                    color: const Color(0xFFE53E3E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}