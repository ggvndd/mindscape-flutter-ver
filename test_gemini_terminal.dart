import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple command-line test for Gemini API connectivity
void main() async {
  print('🚀 Testing Gemini API Connectivity...\n');
  
  // Your API configuration
  const apiKey = 'AIzaSyAdzvoaYlr7QgIcj8T19bIzRJ7CzQS1Kt8';
  const projectName = 'projects/965920436747';
  const projectNumber = '965920436747';
  
  print('📊 Configuration:');
  print('   Project: $projectName');
  print('   Project ID: $projectNumber');
  print('   API Key: ${apiKey.substring(0, 10)}...\n');
  
  // Test Gemini Flash Latest
  await testGeminiModel(
    apiKey: apiKey,
    model: 'gemini-flash-latest',
    testMessage: 'Halo! Test connectivity dengan response singkat dalam bahasa Indonesia.',
  );
  
  print('');
  
  // Test Gemini Pro Latest
  await testGeminiModel(
    apiKey: apiKey,
    model: 'gemini-pro-latest',
    testMessage: 'Test connectivity untuk model Pro. Respond dengan empati dalam bahasa Indonesia casual, seperti chatbot untuk mahasiswa UGM.',
  );
  
  print('\n✅ Connectivity test completed!');
  print('📱 You can now run the Flutter app to test full integration.');
}

Future<void> testGeminiModel({
  required String apiKey,
  required String model,
  required String testMessage,
}) async {
  print('🧪 Testing $model...');
  
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
  
  final requestBody = {
    'contents': [
      {
        'parts': [
          {'text': testMessage}
        ]
      }
    ],
    'generationConfig': {
      'temperature': 0.7,
      'topK': 40,
      'topP': 0.8,
      'maxOutputTokens': 200,
    },
    'safetySettings': [
      {
        'category': 'HARM_CATEGORY_HARASSMENT',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
      },
      {
        'category': 'HARM_CATEGORY_HATE_SPEECH',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
      },
      {
        'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
        'threshold': 'BLOCK_ONLY_HIGH'
      },
      {
        'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
        'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
      }
    ]
  };
  
  try {
    final stopwatch = Stopwatch()..start();
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    stopwatch.stop();
    
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final generatedText = responseData['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'No response text';
      
      print('   ✅ SUCCESS (${stopwatch.elapsedMilliseconds}ms)');
      print('   📝 Response: ${generatedText.substring(0, generatedText.length > 100 ? 100 : generatedText.length)}${generatedText.length > 100 ? '...' : ''}');
      
    } else {
      final errorData = jsonDecode(response.body);
      print('   ❌ FAILED (HTTP ${response.statusCode})');
      print('   📝 Error: ${errorData['error']?['message'] ?? response.body}');
    }
    
  } catch (e) {
    print('   ❌ FAILED (Exception)');
    print('   📝 Error: $e');
  }
}