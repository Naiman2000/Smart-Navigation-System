import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CredentialsService {
  // Singleton pattern
  static final CredentialsService _instance = CredentialsService._internal();
  factory CredentialsService() => _instance;
  CredentialsService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Storage keys
  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';
  static const String _keyRememberMe = 'remember_me';

  /// Save user credentials securely
  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await _secureStorage.write(key: _keyEmail, value: email);
      await _secureStorage.write(key: _keyPassword, value: password);
    } catch (e) {
      throw Exception('Failed to save credentials: $e');
    }
  }

  /// Load saved credentials
  Future<Map<String, String>?> loadCredentials() async {
    try {
      final email = await _secureStorage.read(key: _keyEmail);
      final password = await _secureStorage.read(key: _keyPassword);

      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load credentials: $e');
    }
  }

  /// Clear saved credentials
  Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: _keyEmail);
      await _secureStorage.delete(key: _keyPassword);
      await setSaveCredentialsPref(false);
    } catch (e) {
      throw Exception('Failed to clear credentials: $e');
    }
  }

  /// Get "Remember Me" preference
  Future<bool> getSaveCredentialsPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRememberMe) ?? false;
    } catch (e) {
      throw Exception('Failed to get preference: $e');
    }
  }

  /// Set "Remember Me" preference
  Future<void> setSaveCredentialsPref(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, value);
    } catch (e) {
      throw Exception('Failed to set preference: $e');
    }
  }

  /// Check if credentials exist
  Future<bool> hasCredentials() async {
    try {
      final credentials = await loadCredentials();
      return credentials != null;
    } catch (e) {
      return false;
    }
  }
}
