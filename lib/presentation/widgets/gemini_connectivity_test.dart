import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/gemini_chat_service.dart';
import '../../core/config/api_config.dart';

/// Widget to test and display Gemini API connectivity status
class GeminiConnectivityTest extends StatefulWidget {
  const GeminiConnectivityTest({super.key});

  @override
  State<GeminiConnectivityTest> createState() => _GeminiConnectivityTestState();
}

class _GeminiConnectivityTestState extends State<GeminiConnectivityTest> {
  Map<String, dynamic>? _testResults;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    // Auto-run connectivity test on widget load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runConnectivityTest();
    });
  }

  Future<void> _runConnectivityTest() async {
    setState(() {
      _isTesting = true;
      _testResults = null;
    });

    try {
      final geminiService = context.read<GeminiChatService>();
      final results = await geminiService.testConnectivity();
      
      setState(() {
        _testResults = results;
        _isTesting = false;
      });

      // Show success/failure snackbar
      final flashSuccess = results['flash_test']['success'] as bool;
      final proSuccess = results['pro_test']['success'] as bool;
      
      if (flashSuccess && proSuccess) {
        _showSnackBar('✅ Gemini API connectivity successful!', Colors.green);
      } else if (flashSuccess || proSuccess) {
        _showSnackBar('⚠️ Partial connectivity - some models unavailable', Colors.orange);
      } else {
        _showSnackBar('❌ Gemini API connectivity failed', Colors.red);
      }

    } catch (e) {
      setState(() {
        _testResults = {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
        _isTesting = false;
      });
      
      _showSnackBar('❌ Connectivity test failed: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_sync, size: 24, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Gemini API Connectivity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isTesting)
                  IconButton(
                    onPressed: _runConnectivityTest,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Retest connectivity',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // API Configuration Info
            _buildConfigInfo(),
            const SizedBox(height: 16),
            
            // Test Results
            if (_isTesting)
              _buildLoadingState()
            else if (_testResults != null)
              _buildTestResults()
            else
              const Text('No test results available'),
              
            const SizedBox(height: 16),
            
            // Test Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _runConnectivityTest,
                    icon: _isTesting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(_isTesting ? 'Testing...' : 'Test Connectivity'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _testResults != null ? _showDetailedResults : null,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildConfigRow('Project', ApiConfig.geminiProjectName),
          _buildConfigRow('Project ID', ApiConfig.geminiProjectNumber),
          _buildConfigRow('Flash Model', ApiConfig.geminiFlashModel),
          _buildConfigRow('Pro Model', ApiConfig.geminiProModel),
          _buildConfigRow('Environment', ApiConfig.isProduction ? 'Production' : 'Development'),
          _buildConfigRow('API Key', '${ApiConfig.geminiApiKey.substring(0, 10)}...'),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Testing Gemini API connectivity...'),
          SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResults() {
    final results = _testResults!;
    
    if (results.containsKey('error')) {
      return _buildErrorResult(results['error']);
    }
    
    final flashTest = results['flash_test'] as Map<String, dynamic>;
    final proTest = results['pro_test'] as Map<String, dynamic>;
    
    return Column(
      children: [
        _buildModelTestResult('Gemma 4B (Fast)', flashTest),
        const SizedBox(height: 8),
        _buildModelTestResult('Gemma 12B (Quality)', proTest),
        const SizedBox(height: 12),
        Text(
          'Last tested: ${_formatTimestamp(results['timestamp'])}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildModelTestResult(String modelName, Map<String, dynamic> testResult) {
    final success = testResult['success'] as bool;
    final responseTime = testResult['response_time'] as int;
    final error = testResult['error'] as String?;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success ? Colors.green[50] : Colors.red[50],
        border: Border.all(
          color: success ? Colors.green[300]! : Colors.red[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modelName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (success) ...[
                  Text('Response time: ${responseTime}ms'),
                  if (testResult['response'] != null)
                    Text(
                      'Sample: ${testResult['response']}...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ] else if (error != null) ...[
                  Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorResult(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connectivity Test Failed',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedResults() {
    if (_testResults == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connectivity Test Details'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Text(
              _formatTestResults(_testResults!),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  String _formatTestResults(Map<String, dynamic> results) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(results);
  }
}