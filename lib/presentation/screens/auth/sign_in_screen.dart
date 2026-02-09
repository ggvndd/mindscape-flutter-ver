import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';

/// Sign in screen with email and password authentication
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  
  // Validation states
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    
    // Add listeners for real-time validation
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
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

  Future<void> _signIn() async {
    // Validate all fields first
    _validateEmail();
    _validatePassword();

    // Check if form is valid
    final hasErrors = _emailError != null || 
                     _passwordError != null ||
                     _emailController.text.isEmpty ||
                     _passwordController.text.isEmpty;

    if (hasErrors) {
      // Show errors for empty fields
      setState(() {
        if (_emailController.text.isEmpty) _emailError = 'Email wajib diisi';
        if (_passwordController.text.isEmpty) _passwordError = 'Password wajib diisi';
      });
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Use Firebase to sign in
      final authService = AuthService();
      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      // Navigate to main navigation screen on success
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login gagal: ${e.toString()}'),
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

  void _forgotPassword() {
    // Show dialog to get email for password reset
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Password',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Masukkan email Anda untuk mendapatkan link reset password.',
              style: GoogleFonts.urbanist(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.urbanist(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Email wajib diisi'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                final authService = AuthService();
                await authService.resetPassword(emailController.text.trim());
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Link reset password telah dikirim ke email Anda.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal mengirim email reset: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Kirim',
              style: GoogleFonts.urbanist(
                color: const Color(0xFF3D2914),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
              
              // Welcome back section
              Center(
                child: Column(
                  children: [
                    // Logo placeholder
                    Container(
                      width: isTablet ? 100 : 80,
                      height: isTablet ? 100 : 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF3D2914),
                            const Color(0xFF2D1F0F),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.psychology,
                        size: isTablet ? 50 : 40,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Selamat Datang Kembali!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: isTablet ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3D2914),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Masuk ke akun kamu untuk melanjutkan tracking mood',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.urbanist(
                        fontSize: isTablet ? 18 : 16,
                        color: const Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: isTablet ? 40 : 32),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
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
                      hint: 'Masukkan password',
                      error: _passwordError,
                      isPassword: true,
                      isPasswordVisible: _isPasswordVisible,
                      onTogglePassword: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      isTablet: isTablet,
                      iconPath: 'assets/logos/sign in and up/password.svg',
                    ),
                    
                    SizedBox(height: isTablet ? 20 : 16),
                    
                    // Remember me and forgot password
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) => setState(() => _rememberMe = value ?? false),
                                activeColor: const Color(0xFF38A169),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ingat saya',
                                style: GoogleFonts.urbanist(
                                  fontSize: isTablet ? 14 : 12,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _forgotPassword,
                          child: Text(
                            'Lupa password?',
                            style: GoogleFonts.urbanist(
                              fontSize: isTablet ? 14 : 12,
                              color: const Color(0xFF3D2914),
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 32 : 24),
                    
                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      height: isTablet ? 60 : 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
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
                                'Masuk',
                                style: GoogleFonts.urbanist(
                                  fontSize: isTablet ? 18 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 32 : 24),
                    
                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'atau',
                            style: GoogleFonts.urbanist(
                              fontSize: isTablet ? 14 : 12,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Sign up link
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.urbanist(
                            fontSize: isTablet ? 16 : 14,
                            color: const Color(0xFF666666),
                          ),
                          children: [
                            const TextSpan(text: 'Belum punya akun? '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/sign-up'),
                                child: Text(
                                  'Daftar di sini',
                                  style: GoogleFonts.urbanist(
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFFB366),
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