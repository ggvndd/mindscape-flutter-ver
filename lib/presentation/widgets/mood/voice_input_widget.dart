import 'package:flutter/material.dart';

/// Voice input widget for hands-free mood logging
class VoiceInputWidget extends StatefulWidget {
  final Function(String) onTranscribed;

  const VoiceInputWidget({
    super.key,
    required this.onTranscribed,
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with TickerProviderStateMixin {
  bool _isListening = false;
  String _transcribedText = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _transcribedText = '';
    });
    
    _animationController.repeat();
    
    // TODO: Implement speech-to-text using speech_to_text package
    // For now, simulate with a delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Simulate transcription
    final mockTranscriptions = [
      'Lagi capek banget',
      'Senang hari ini',
      'Stres deadline',
      'Alhamdulillah lancar',
      'Agak down mood'
    ];
    
    final transcription = (mockTranscriptions..shuffle()).first;
    
    setState(() {
      _isListening = false;
      _transcribedText = transcription;
    });
    
    _animationController.stop();
    
    // Auto-submit after transcription
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onTranscribed(transcription);
    });
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
    });
    _animationController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Ceritain mood kamu:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        
        const SizedBox(height: 16),
        
        // Voice input button
        GestureDetector(
          onTap: _isListening ? _stopListening : _startListening,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isListening 
                      ? Colors.red.withOpacity(0.2) 
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: _isListening 
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                    width: _isListening 
                        ? 2 + (_animationController.value * 2)
                        : 2,
                  ),
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  size: 32,
                  color: _isListening 
                      ? Colors.red
                      : Theme.of(context).primaryColor,
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Status text
        Text(
          _isListening 
              ? 'Mendengarkan... (tap untuk stop)'
              : _transcribedText.isNotEmpty
                  ? 'Transcribed: $_transcribedText'
                  : 'Tap untuk mulai bicara',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontStyle: _transcribedText.isNotEmpty ? FontStyle.italic : null,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Microphone hint
        if (!_isListening && _transcribedText.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '🎤 Ideal saat lagi mobile atau malam hari',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
      ],
    );
  }
}