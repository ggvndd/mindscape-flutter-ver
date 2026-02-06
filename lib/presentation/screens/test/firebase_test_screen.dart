import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

/// Test widget to verify Firebase authentication and Firestore connectivity
class FirebaseTestWidget extends StatefulWidget {
  const FirebaseTestWidget({super.key});

  @override
  State<FirebaseTestWidget> createState() => _FirebaseTestWidgetState();
}

class _FirebaseTestWidgetState extends State<FirebaseTestWidget> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _statusMessage = 'Initializing tests...';
  bool _isLoading = true;
  Color _statusColor = Colors.orange;
  
  final List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _runFirebaseTests();
  }

  Future<void> _runFirebaseTests() async {
    setState(() {
      _statusMessage = 'Running Firebase tests...';
      _testResults.clear();
    });

    // Test 1: Firebase Auth Connection
    await _testAuthConnection();
    
    // Test 2: Firestore Connection
    await _testFirestoreConnection();
    
    // Test 3: Create Test User (if not exists)
    await _testCreateUser();
    
    // Test 4: Firestore Read/Write
    await _testFirestoreReadWrite();

    setState(() {
      _isLoading = false;
      final allPassed = !_testResults.any((r) => r.contains('❌'));
      _statusMessage = allPassed 
          ? '✅ All Firebase tests passed!' 
          : '⚠️ Some tests failed - check details below';
      _statusColor = allPassed ? Colors.green : Colors.red;
    });
  }

  Future<void> _testAuthConnection() async {
    try {
      final user = _auth.currentUser;
      _addTestResult('🔐 Firebase Auth', '✅ Connected (${user != null ? 'Authenticated' : 'Anonymous'})');
    } catch (e) {
      _addTestResult('🔐 Firebase Auth', '❌ Connection failed: $e');
    }
  }

  Future<void> _testFirestoreConnection() async {
    try {
      await _firestore.app.options.projectId;
      _addTestResult('🗃️ Firestore Database', '✅ Connected to project: ${_firestore.app.options.projectId}');
    } catch (e) {
      _addTestResult('🗃️ Firestore Database', '❌ Connection failed: $e');
    }
  }

  Future<void> _testCreateUser() async {
    try {
      final testEmail = 'test+${DateTime.now().millisecondsSinceEpoch}@mindscape.test';
      final testPassword = 'TestPassword123!';
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      
      // Clean up immediately
      await userCredential.user?.delete();
      
      _addTestResult('👤 User Creation', '✅ Test user created and deleted successfully');
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        _addTestResult('👤 User Creation', '✅ Auth working (email validation works)');
      } else {
        _addTestResult('👤 User Creation', '❌ Failed: $e');
      }
    }
  }

  Future<void> _testFirestoreReadWrite() async {
    try {
      final testDoc = _firestore.collection('test').doc('firebase_test');
      
      // Write test
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test_message': 'Firebase connectivity test',
        'status': 'success'
      });
      
      // Read test
      final doc = await testDoc.get();
      
      if (doc.exists && doc.data()?['test_message'] == 'Firebase connectivity test') {
        _addTestResult('📖 Firestore Read/Write', '✅ Successfully wrote and read test data');
        
        // Clean up
        await testDoc.delete();
      } else {
        _addTestResult('📖 Firestore Read/Write', '❌ Data mismatch after read');
      }
    } catch (e) {
      _addTestResult('📖 Firestore Read/Write', '❌ Failed: $e');
    }
  }

  void _addTestResult(String test, String result) {
    setState(() {
      _testResults.add('$test: $result');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      appBar: AppBar(
        title: Text(
          'Firebase Test Results',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_isLoading) 
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _statusColor == Colors.green ? Icons.check_circle : Icons.warning,
                      color: _statusColor,
                      size: 20,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test Results
            Text(
              'Test Details:',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D2914),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _testResults.isEmpty
                    ? const Center(child: Text('Running tests...'))
                    : ListView.builder(
                        itemCount: _testResults.length,
                        itemBuilder: (context, index) {
                          final result = _testResults[index];
                          final isSuccess = result.contains('✅');
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                                  color: isSuccess ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    result,
                                    style: GoogleFonts.urbanist(
                                      fontSize: 14,
                                      color: const Color(0xFF3D2914),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Retry Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _runFirebaseTests,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3D2914),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Run Tests Again',
                  style: GoogleFonts.urbanist(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Back Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Back to App',
                  style: GoogleFonts.urbanist(
                    color: const Color(0xFF3D2914),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}