import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyD3wbMUcySh6NOXFt8-niqEWOCcgk5tuBY';
  final model = GenerativeModel(model: 'gemma-3-4b-it', apiKey: apiKey);
  final chat = model.startChat();
  
  try {
    print('Sending stream message...');
    final responseStream = chat.sendMessageStream(Content.text('Hello'));
    await for (final chunk in responseStream) {
      print('Chunk: ${chunk.text}');
    }
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
  exit(0);
}
