import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/theme_extensions.dart';

/// Demo widget showcasing the new typography and color system
class ThemeShowcaseWidget extends StatelessWidget {
  const ThemeShowcaseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Theme Showcase', style: AppTypography.titleLarge),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypographySection(),
            const SizedBox(height: 32),
            _buildColorPaletteSection(),
            const SizedBox(height: 32),
            _buildMoodColorsSection(),
            const SizedBox(height: 32),
            _buildComponentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypographySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Typography', style: AppTypography.headlineSmall),
        const SizedBox(height: 16),
        Text('Display Large', style: AppTypography.displayLarge),
        Text('Display Medium', style: AppTypography.displayMedium),
        Text('Display Small', style: AppTypography.displaySmall),
        const SizedBox(height: 8),
        Text('Headline Large', style: AppTypography.headlineLarge),
        Text('Headline Medium', style: AppTypography.headlineMedium),
        Text('Headline Small', style: AppTypography.headlineSmall),
        const SizedBox(height: 8),
        Text('Title Large', style: AppTypography.titleLarge),
        Text('Title Medium', style: AppTypography.titleMedium),
        Text('Title Small', style: AppTypography.titleSmall),
        const SizedBox(height: 8),
        Text('Body Large - This is the main body text used throughout the app. It uses the Urbanist font family.', 
             style: AppTypography.bodyLarge),
        Text('Body Medium - Secondary body text for descriptions and details.', 
             style: AppTypography.bodyMedium),
        Text('Body Small - Small body text for captions and metadata.', 
             style: AppTypography.bodySmall),
        const SizedBox(height: 8),
        Text('Label Large', style: AppTypography.labelLarge),
        Text('Label Medium', style: AppTypography.labelMedium),
        Text('Label Small', style: AppTypography.labelSmall),
      ],
    );
  }

  Widget _buildColorPaletteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color Palette', style: AppTypography.headlineSmall),
        const SizedBox(height: 16),
        
        // Brown Family
        _buildColorFamily('Brown', [
          AppColors.brown90, AppColors.brown80, AppColors.brown70, 
          AppColors.brown60, AppColors.brown50, AppColors.brown45, AppColors.brown40
        ]),
        
        // Base Family
        _buildColorFamily('Base (Neutrals)', [
          AppColors.base90, AppColors.base80, AppColors.base70, 
          AppColors.base60, AppColors.base50, AppColors.base45, AppColors.base40
        ]),
        
        // Green Family
        _buildColorFamily('Green', [
          AppColors.green90, AppColors.green80, AppColors.green70, 
          AppColors.green60, AppColors.green50, AppColors.green40
        ]),
        
        // Orange Family
        _buildColorFamily('Orange', [
          AppColors.orange90, AppColors.orange80, AppColors.orange70, 
          AppColors.orange60, AppColors.orange50, AppColors.orange45, AppColors.orange40
        ]),
        
        // Yellow Family
        _buildColorFamily('Yellow', [
          AppColors.yellow90, AppColors.yellow80, AppColors.yellow70, 
          AppColors.yellow60, AppColors.yellow50, AppColors.yellow45, AppColors.yellow40
        ]),
      ],
    );
  }

  Widget _buildColorFamily(String name, List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: colors.map((color) => Expanded(
            child: Container(
              height: 40,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMoodColorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mood Colors', style: AppTypography.headlineSmall),
        const SizedBox(height: 16),
        ...MoodType.values.map((mood) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: mood.gradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mood.borderColor, width: 2),
          ),
          child: Row(
            children: [
              Text(mood.emoji, style: AppTypography.headlineLarge),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mood.label, 
                         style: AppTypography.titleMedium.copyWith(color: mood.textColor)),
                    Text('Score: ${mood.value}', 
                         style: AppTypography.bodySmall.copyWith(color: mood.textColor)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildComponentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UI Components', style: AppTypography.headlineSmall),
        const SizedBox(height: 16),
        
        // Buttons
        Row(
          children: [
            ElevatedButton(
              onPressed: () {},
              child: const Text('Primary Button'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Outlined Button'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {},
              child: const Text('Text Button'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Text Field
        TextField(
          decoration: InputDecoration(
            labelText: 'Sample Text Field',
            hintText: 'Enter your mood here...',
            prefixIcon: const Icon(Icons.mood),
          ),
        ),
        const SizedBox(height: 16),
        
        // Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sample Card', style: AppTypography.titleMedium),
                const SizedBox(height: 8),
                Text('This is a sample card showing how the new theme applies to different components.',
                     style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}