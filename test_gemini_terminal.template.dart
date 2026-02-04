import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Safe Gemini API Test Template
/// 
/// 🔒 SECURITY INSTRUCTIONS:
/// 1. Copy this file to test_gemini_terminal.dart
/// 2. Replace 'YOUR_GEMINI_API_KEY_HERE' with your actual API key
/// 3. Never commit the actual test file - it's in .gitignore
/// 
/// Or better yet, use environment variables:
/// export GEMINI_API_KEY="your-key-here"
/// export PROJECT_NUMBER="your-project-number"

void main() async {
  print('🚀 Testing Gemini API Connectivity...\n');
  
  // Get API configuration from environment or replace placeholders
  final apiKey = Platform.environment['GEMINI_API_KEY'] ?? 'YOUR_GEMINI_API_KEY_HERE';
  final projectNumber = Platform.environment['PROJECT_NUMBER'] ?? 'YOUR_PROJECT_NUMBER';
  final projectName = 'projects/$projectNumber';
  
  // Validate configuration
  if (apiKey == 'YOUR_GEMINI_API_KEY_HERE' || apiKey.isEmpty) {
    print('❌ ERROR: API key not configured!');
    print('');
    print('Please either:');
    print('1. Set environment variable: export GEMINI_API_KEY="your-key-here"');
    print('2. Or replace YOUR_GEMINI_API_KEY_HERE in this file');
    print('');
    print('⚠️  IMPORTANT: Never commit actual API keys to git!');
    exit(1);
  }
  
  print('📊 Configuration:');
  print('   Project: $projectName');
  print('   Project ID: $projectNumber');
  print('   API Key: ${getSafeDisplayKey(apiKey)}\n');
  
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

/// Returns a safe display version of the API key
String getSafeDisplayKey(String key) {
  if (key.isEmpty || key.length <= 10) return '***';
  return '${key.substring(0, 10)}...';
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