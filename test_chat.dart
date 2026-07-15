import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyD3wbMUcySh6NOXFt8-niqEWOCcgk5tuBY';
  final model = GenerativeModel(model: 'gemma-3-4b-it', apiKey: apiKey);
  final chat = model.startChat();
  
  try {
    print('Sending message...');
    final response = await chat.sendMessage(Content.text('Hello'));
    print('Response: \${response.text}');
  } catch (e) {
    print('Error: \$e');
  }
  exit(0);
}
