import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/services/gemini_chat_service.dart';
import 'presentation/screens/gemini_test_screen.dart';

void main() {
  runApp(const GeminiTestApp());
}

class GeminiTestApp extends StatelessWidget {
  const GeminiTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GeminiChatService(),
        ),
      ],
      child: MaterialApp(
        title: 'Gemini API Test',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const GeminiTestScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}