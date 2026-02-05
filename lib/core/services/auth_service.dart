import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      // Create user document in Firestore
      await _createUserDocument(userCredential.user!);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'profile': {
        'firstName': '',
        'lastName': '',
        'dateOfBirth': null,
        'gender': '',
        'occupation': '',
      },
      'settings': {
        'notifications': true,
        'darkMode': false,
        'language': 'en',
        'timezone': 'UTC',
      },
      'preferences': {
        'rushHourStart': null,
        'rushHourEnd': null,
        'selectedActivities': <String>[],
        'notificationTimes': <String>[],
      },
    };

    await userDoc.set(userData);
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    Map<String, dynamic>? profileData,
    Map<String, dynamic>? preferences,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    // Update display name in Firebase Auth
    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }

    // Update user document in Firestore
    final userDoc = _firestore.collection('users').doc(user.uid);
    final updateData = <String, dynamic>{
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };

    if (displayName != null) {
      updateData['displayName'] = displayName;
    }
    if (profileData != null) {
      updateData['profile'] = profileData;
    }
    if (preferences != null) {
      updateData['preferences'] = preferences;
    }

    await userDoc.update(updateData);
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    final user = currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    return userDoc.data();
  }

  // Save mood entry
  Future<void> saveMoodEntry({
    required String mood,
    String? notes,
    List<String>? activities,
    Map<String, dynamic>? additionalData,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    final moodEntry = {
      'userId': user.uid,
      'mood': mood,
      'notes': notes ?? '',
      'activities': activities ?? <String>[],
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    await _firestore.collection('mood_entries').add(moodEntry);
  }

  // Get user's mood entries
  Stream<QuerySnapshot> getMoodEntries({int? limit}) {
    final user = currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    Query query = _firestore
        .collection('mood_entries')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }
}