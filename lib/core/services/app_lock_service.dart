import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing app lock PIN for each user account
class AppLockService {
  static const String _pinKey = 'app_lock_pin_';
  static const String _enabledKey = 'app_lock_enabled_';
  
  /// Get the current user's ID
  String? get _currentUserId {
    return FirebaseAuth.instance.currentUser?.uid;
  }
  
  /// Hash the PIN for secure storage
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Check if app lock is enabled for current user
  Future<bool> isAppLockEnabled() async {
    final userId = _currentUserId;
    if (userId == null) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_enabledKey$userId') ?? false;
  }
  
  /// Set app lock PIN for current user
  Future<void> setPin(String pin) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No user logged in');
    
    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw Exception('PIN must be exactly 4 digits');
    }
    
    final prefs = await SharedPreferences.getInstance();
    final hashedPin = _hashPin(pin);
    
    await prefs.setString('$_pinKey$userId', hashedPin);
    await prefs.setBool('$_enabledKey$userId', true);
  }
  
  /// Verify if the provided PIN matches the stored PIN for current user
  Future<bool> verifyPin(String pin) async {
    final userId = _currentUserId;
    if (userId == null) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final storedHashedPin = prefs.getString('$_pinKey$userId');
    
    if (storedHashedPin == null) return false;
    
    final hashedPin = _hashPin(pin);
    return hashedPin == storedHashedPin;
  }
  
  /// Check if PIN is set for current user
  Future<bool> hasPin() async {
    final userId = _currentUserId;
    if (userId == null) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_pinKey$userId');
  }
  
  /// Disable app lock for current user
  Future<void> disableAppLock() async {
    final userId = _currentUserId;
    if (userId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_enabledKey$userId', false);
  }
  
  /// Remove PIN for current user (when they want to reset)
  Future<void> removePin() async {
    final userId = _currentUserId;
    if (userId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_pinKey$userId');
    await prefs.remove('$_enabledKey$userId');
  }
  
  /// Change existing PIN (requires old PIN verification)
  Future<void> changePin(String oldPin, String newPin) async {
    final isOldPinValid = await verifyPin(oldPin);
    if (!isOldPinValid) {
      throw Exception('PIN lama tidak sesuai');
    }
    
    await setPin(newPin);
  }
}
