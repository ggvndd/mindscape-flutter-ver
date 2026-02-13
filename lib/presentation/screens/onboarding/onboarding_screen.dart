import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onboarding flow with PageView for smooth navigation
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingData> _pages = [
    OnboardingData(
      stepText: '',
      title: 'Selamat Datang ke',
      subtitle: 'Mindscape!',
      description: 'Personal companion kamu buat\ncek mood kamu selagi sibuk!',
      imagePath: 'assets/images/selamat datang image.svg',
      backgroundColor: const Color(0xFFF5F3F0), // Warm beige
      isWelcome: true,
    ),
    OnboardingData(
      stepText: 'Step Satu',
      title: 'Mood Tracker Buat Kamu',
      subtitle: 'Yang Sibuk Side Gig',
      description: '',
      imagePath: 'assets/images/sibuk image.svg',
      backgroundColor: const Color(0xFFE8F0E8), // Light green
      isWelcome: false,
    ),
    OnboardingData(
      stepText: 'Step Two',
      title: 'Chatbot yang Paham',
      subtitle: 'Struggle Kamu',
      description: '',
      imagePath: 'assets/images/struggle image.svg',
      backgroundColor: const Color(0xFFFDF5E6), // Warm yellow
      isWelcome: false,
    ),
    OnboardingData(
      stepText: 'Step Three',
      title: 'Tips-Tips untuk',
      subtitle: 'Mengelola Burnout-mu!',
      description: '',
      imagePath: 'assets/images/burnout image.svg',
      backgroundColor: const Color(0xFFF0E8FF), // Light purple
      isWelcome: false,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          final page = _pages[index];
          return _buildPage(page, index);
        },
      ),
    );
  }

  Widget _buildPage(OnboardingData page, int index) {
    final isLastPage = index == _pages.length - 1;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Container(
      decoration: BoxDecoration(
        color: page.backgroundColor,
      ),
      child: Column(
        children: [
          // Top section with step indicator
          SafeArea(
            bottom: false,
            child: !page.isWelcome
                ? Padding(
                    padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
                    child: _buildStepIndicator(page.stepText, isTablet),
                  )
                : const SizedBox(height: 20),
          ),
          
          // Main content - takes available space
          Expanded(
            child: page.isWelcome 
              ? _buildWelcomeContent(page, isTablet)
              : _buildStepContent(page, isTablet),
          ),
          
          // Bottom section with white container - consistent for all pages
          _buildBottomContainer(page, index, isLastPage, isTablet),
        ],
      ),
    );
  }

  Widget _buildWelcomeContent(OnboardingData page, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.0 : 24.0),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Welcome text at top
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D2914),
            ),
          ),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: isTablet ? 36 : 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3D2914),
            ),
          ),
          const SizedBox(height: 20),
          
          // Logo in brown container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3D2914),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SvgPicture.asset(
              'assets/logos/logo small.svg',
              width: isTablet ? 48 : 40,
              height: isTablet ? 48 : 40,
            ),
          ),
          
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Image
          _buildImage(page.imagePath, isTablet, scaleFactor: 0.8),
          
          const SizedBox(height: 16),
          
          // Feature icons
          _buildFeatureIcons(isTablet),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepContent(OnboardingData page, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 32.0 : 24.0),
      child: Center(
        child: _buildImage(page.imagePath, isTablet, scaleFactor: 1.8),
      ),
    );
  }

  Widget _buildBottomContainer(OnboardingData page, int index, bool isLastPage, bool isTablet) {
    return SafeArea(
      top: false,
      bottom: false,  // Set to true to respect home indicator area, false to bleed to bottom edge
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: isTablet ? 32 : 24,
          right: isTablet ? 32 : 24,
          top: isTablet ? 32 : 28,
          bottom: isTablet ? 28 : 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page indicators (dots)
            _buildPageIndicators(isTablet),
            SizedBox(height: isTablet ? 24 : 20),
            
            // Title and subtitle (hide for welcome page)
            if (!page.isWelcome)
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.urbanist(
                    fontSize: isTablet ? 32 : 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3D2914),
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(text: page.title),
                    if (page.subtitle.isNotEmpty) ...[
                      const TextSpan(text: '\n'),
                      TextSpan(
                        text: page.subtitle,
                        style: TextStyle(
                          color: _getAccentColor(index),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (!page.isWelcome) SizedBox(height: isTablet ? 32 : 24),
            
            _buildNavigationButton(isLastPage, index, isTablet),
            
            // Login link (only on last page)
            if (isLastPage) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/sign-in'),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.urbanist(
                      fontSize: isTablet ? 16 : 14,
                      color: const Color(0xFF666666),
                    ),
                    children: [
                      const TextSpan(text: 'Sudah memiliki akun? '),
                      TextSpan(
                        text: 'Masuk Sekarang',
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF8C00),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators(bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => Container(
          width: _currentPage == index ? (isTablet ? 32 : 24) : (isTablet ? 10 : 8),
          height: isTablet ? 10 : 8,
          margin: EdgeInsets.symmetric(horizontal: isTablet ? 6 : 4),
          decoration: BoxDecoration(
            color: _currentPage == index 
                ? const Color(0xFF3D2914) 
                : const Color(0xFFD9D9D9),
            borderRadius: BorderRadius.circular(isTablet ? 5 : 4),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(String stepText, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16, 
        vertical: isTablet ? 10 : 8
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        stepText,
        style: GoogleFonts.urbanist(
          fontSize: isTablet ? 16 : 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3D2914),
        ),
      ),
    );
  }

  Widget _buildImage(String imagePath, bool isTablet, {double scaleFactor = 0.8}) {
    final maxSize = (isTablet ? 400.0 : 280.0) * scaleFactor;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: maxSize,
        maxWidth: maxSize,
      ),
      child: SvgPicture.asset(
        imagePath,
        fit: BoxFit.contain,
        placeholderBuilder: (context) {
          // Fallback illustration when image is loading or not found
          return Container(
            width: isTablet ? 250 : 200,
            height: isTablet ? 250 : 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getAccentColor(_currentPage),
                  _getAccentColor(_currentPage).withOpacity(0.7),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.image,
                size: isTablet ? 80 : 60,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureIcons(bool isTablet) {
    final iconSize = isTablet ? 60.0 : 50.0;
    final iconPadding = isTablet ? 30.0 : 25.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFeatureIcon(Icons.trending_up, const Color(0xFFFF8C00), iconSize, iconPadding),
        _buildFeatureIcon(Icons.psychology, const Color(0xFF8FBC8F), iconSize, iconPadding),
        _buildFeatureIcon(Icons.bolt, const Color(0xFFFF8C00), iconSize, iconPadding),
        _buildFeatureIcon(Icons.chat_bubble_outline, const Color(0xFF8FBC8F), iconSize, iconPadding),
      ],
    );
  }

  Widget _buildFeatureIcon(IconData icon, Color color, double size, double padding) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.48,
      ),
    );
  }

  Widget _buildNavigationButton(bool isLastPage, int pageIndex, bool isTablet) {
    String buttonText;
    if (isLastPage) {
      buttonText = 'Mulai';
    } else if (pageIndex == 0) {
      buttonText = 'Selanjutnya';
    } else {
      buttonText = '';
    }
    
    bool showText = isLastPage || pageIndex == 0;
    
    return GestureDetector(
      onTap: () {
        if (isLastPage) {
          Navigator.pushReplacementNamed(context, '/sign-up');
        } else {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Container(
        width: showText ? (isTablet ? 250 : 200) : (isTablet ? 70 : 60),
        height: isTablet ? 70 : 60,
        decoration: BoxDecoration(
          color: const Color(0xFF3D2914),
          borderRadius: BorderRadius.circular(isTablet ? 35 : 30),
        ),
        child: Center(
          child: showText
              ? Text(
                  buttonText,
                  style: GoogleFonts.urbanist(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
        ),
      ),
    );
  }

  Color _getAccentColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFF8C00); // Orange
      case 1:
        return const Color(0xFF8FBC8F); // Green
      case 2:
        return const Color(0xFFFFD700); // Yellow
      case 3:
        return const Color(0xFFDDA0DD); // Purple
      default:
        return const Color(0xFF8B4513); // Brown
    }
  }
}

class OnboardingData {
  final String stepText;
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final Color backgroundColor;
  final bool isWelcome;

  OnboardingData({
    required this.stepText,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
    required this.isWelcome,
  });
}