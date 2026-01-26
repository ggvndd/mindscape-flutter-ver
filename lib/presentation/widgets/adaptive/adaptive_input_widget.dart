import 'package:flutter/material.dart';
import '../../../domain/entities/adaptive_context.dart';
import '../../../core/constants/app_constants.dart';
import '../mood/mood_picker.dart';
import '../mood/voice_input_widget.dart';
import '../mood/text_mood_input.dart';

/// Adaptive input widget that switches based on user context
class AdaptiveInputWidget extends StatefulWidget {
  final AdaptiveContext context;
  final Function(String) onMoodLogged;

  const AdaptiveInputWidget({
    super.key,
    required this.context,
    required this.onMoodLogged,
  });

  @override
  State<AdaptiveInputWidget> createState() => _AdaptiveInputWidgetState();
}

class _AdaptiveInputWidgetState extends State<AdaptiveInputWidget> {
  late InputMethod _currentMethod;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _currentMethod = widget.context.preferredInputMethod;
    _startTSRTimer();
  }

  void _startTSRTimer() {
    _startTime = DateTime.now();
  }

  void _completeTSRTimer(String mood) {
    if (_startTime != null) {
      final duration = DateTime.now().difference(_startTime!);
      final withinTarget = duration <= AppConstants.quickLogTargetDuration;
      
      // Log TSR-CC metrics
      debugPrint('TSR-CC: ${duration.inSeconds}s, Target: ${withinTarget}');
      // TODO: Send to analytics service
    }
    
    widget.onMoodLogged(mood);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Method switcher (hidden when stressed for simplicity)
        if (!widget.context.shouldUseSimpleUI)
          _buildMethodSwitcher(),
        
        const SizedBox(height: 16),
        
        // Adaptive input based on current method
        _buildCurrentInputMethod(),
        
        // Timer indicator for TSR-CC evaluation
        if (_startTime != null) _buildTimerIndicator(),
      ],
    );
  }

  Widget _buildMethodSwitcher() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildMethodButton(InputMethod.emoji, '😊', 'Emoji'),
        const SizedBox(width: 12),
        _buildMethodButton(InputMethod.voice, '🎤', 'Voice'),
        const SizedBox(width: 12),
        _buildMethodButton(InputMethod.text, '✍️', 'Text'),
      ],
    );
  }

  Widget _buildMethodButton(InputMethod method, String emoji, String label) {
    final isSelected = _currentMethod == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentInputMethod() {
    switch (_currentMethod) {
      case InputMethod.emoji:
        return MoodPicker(
          onMoodSelected: _completeTSRTimer,
          isSimpleMode: widget.context.shouldUseSimpleUI,
        );
      case InputMethod.voice:
        return VoiceInputWidget(
          onTranscribed: _completeTSRTimer,
        );
      case InputMethod.text:
        return TextMoodInput(
          onSubmitted: _completeTSRTimer,
          isSimpleMode: widget.context.shouldUseSimpleUI,
        );
    }
  }

  Widget _buildTimerIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Target: <15 detik ⏱️',
        style: TextStyle(
          fontSize: 10,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }
}