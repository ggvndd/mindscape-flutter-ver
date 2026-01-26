import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Emoji-based mood picker for quick selection
class MoodPicker extends StatelessWidget {
  final Function(String) onMoodSelected;
  final bool isSimpleMode;

  const MoodPicker({
    super.key,
    required this.onMoodSelected,
    this.isSimpleMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isSimpleMode) 
          const Text(
            'Pilih mood kamu:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        
        const SizedBox(height: 12),
        
        // Mood emoji buttons
        Wrap(
          spacing: isSimpleMode ? 20 : 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: MoodType.values.map((mood) {
            return _buildMoodButton(context, mood);
          }).toList(),
        ),
        
        if (!isSimpleMode) 
          const SizedBox(height: 12),
        
        if (!isSimpleMode)
          Text(
            'Tap untuk log mood dalam <15 detik!',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
      ],
    );
  }

  Widget _buildMoodButton(BuildContext context, MoodType mood) {
    final buttonSize = isSimpleMode ? 60.0 : 50.0;
    final emojiSize = isSimpleMode ? 28.0 : 24.0;
    
    return GestureDetector(
      onTap: () => onMoodSelected(mood.label),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(buttonSize / 2),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mood.emoji,
                style: TextStyle(fontSize: emojiSize),
              ),
              if (!isSimpleMode)
                Text(
                  mood.label,
                  style: const TextStyle(fontSize: 8),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}