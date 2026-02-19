import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom bottom navigation bar for MindScape app
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PhysicalShape(
      color: Colors.white,
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.15),
      clipper: ShapeBorderClipper(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                iconPath: 'assets/logos/taskbar/home_icon.svg',
                isActive: currentIndex == 0,
              ),
              _buildNavItem(
                context,
                index: 1,
                iconPath: 'assets/logos/taskbar/moodtracker_icon.svg',
                isActive: currentIndex == 1,
              ),
              _buildNavItem(
                context,
                index: 2,
                iconPath: 'assets/logos/taskbar/mindbot_icon.svg',
                isActive: currentIndex == 2,
              ),
              _buildNavItem(
                context,
                index: 3,
                iconPath: 'assets/logos/taskbar/profile_icon.svg',
                isActive: currentIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required String iconPath,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFFA8B475).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SvgPicture.asset(
          iconPath,
          width: 24,
          height: 24,
          color: isActive ? const Color(0xFFA8B475) : const Color(0xFF9E9E9E),
        ),
      ),
    );
  }
}
