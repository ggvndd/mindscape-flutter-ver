import 'package:flutter_test/flutter_test.dart';
import 'package:mindscape_flutter/data/services/dialogflow_service.dart';
import 'package:mindscape_flutter/core/config/api_keys.dart';

void main() {
  group('Dialogflow Integration Tests', () {
    late DialogflowService dialogflowService;
    
    setUp(() {
      dialogflowService = DialogflowService();
    });
    
    tearDown(() {
      dialogflowService.dispose();
    });

    test('should initialize Dialogflow service', () async {
      // Test credentials configuration
      expect(ApiKeys.isConfigured, isTrue);
      expect(ApiKeys.dialogflowProjectId, equals('mood-tracker-for-thesis-igb9'));
      
      // Test service initialization
      await dialogflowService.initialize();
      expect(dialogflowService.isInitialized, isTrue);
    });

    test('should send message and get response', () async {
      await dialogflowService.initialize();
      
      final response = await dialogflowService.sendMessage(
        'Halo, aku lagi stres nih', 
        'test-session-123'
      );
      
      expect(response.text, isNotEmpty);
      expect(response.isEmpathetic, isTrue);
      
      print('📱 Bot response: ${response.text}');
      print('🎯 Confidence: ${response.confidence}');
      print('💙 Empathetic: ${response.isEmpathetic}');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('should detect crisis messages', () async {
      await dialogflowService.initialize();
      
      final response = await dialogflowService.sendMessage(
        'Aku gak kuat lagi, mau bunuh diri', 
        'crisis-test-session'
      );
      
      expect(response.shouldEscalate, isTrue);
      expect(response.text, contains('konselor'));
      
      print('🚨 Crisis detected: ${response.shouldEscalate}');
      print('🏥 Response: ${response.text}');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('should handle Indonesian casual language', () async {
      await dialogflowService.initialize();
      
      final testMessages = [
        'Lagi capek banget nih gara-gara deadline',
        'Seneng banget hari ini!',
        'Gimana cara manage stress ya?',
        'Thanks ya bot, kamu baik banget',
      ];

      for (final message in testMessages) {
        final response = await dialogflowService.sendMessage(
          message, 
          'indo-test-${DateTime.now().millisecondsSinceEpoch}'
        );
        
        expect(response.text, isNotEmpty);
        print('User: $message');
        print('Bot: ${response.text}');
        print('---');
        
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}