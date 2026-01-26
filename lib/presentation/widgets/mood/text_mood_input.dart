import 'package:flutter/material.dart';

/// Text input widget for detailed mood description
class TextMoodInput extends StatefulWidget {
  final Function(String) onSubmitted;
  final bool isSimpleMode;

  const TextMoodInput({
    super.key,
    required this.onSubmitted,
    this.isSimpleMode = false,
  });

  @override
  State<TextMoodInput> createState() => _TextMoodInputState();
}

class _TextMoodInputState extends State<TextMoodInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitMood() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSubmitted(_controller.text.trim());
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isSimpleMode)
          const Text(
            'Ceritain mood kamu:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        
        const SizedBox(height: 12),
        
        // Text input field
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: widget.isSimpleMode ? 1 : 3,
            maxLength: widget.isSimpleMode ? 50 : 200,
            decoration: InputDecoration(
              hintText: widget.isSimpleMode 
                  ? 'Mood hari ini...'
                  : 'Contoh: Lagi capek banget gara-gara deadline sama shift ojol 😫',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
            ),
            onSubmitted: (_) => _submitMood(),
            textInputAction: TextInputAction.done,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitMood,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Log Mood'),
          ),
        ),
        
        // Quick suggestions for faster input
        if (!widget.isSimpleMode) ...[
          const SizedBox(height: 12),
          const Text(
            'Quick options:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _buildQuickSuggestions(),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildQuickSuggestions() {
    final suggestions = [
      'Capek deadline 😴',
      'Happy banget! 😊',
      'Stres shift 😰',
      'Produktif hari ini ✨',
      'Butuh istirahat 😌',
    ];

    return suggestions.map((suggestion) {
      return GestureDetector(
        onTap: () {
          _controller.text = suggestion;
          _submitMood();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          child: Text(
            suggestion,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      );
    }).toList();
  }
}