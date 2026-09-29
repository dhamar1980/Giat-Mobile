import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

/// Storage Service managing authentication tokens, user info, and local settings.
/// Uses FlutterSecureStorage with automatic fallback to SharedPreferences.
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  SharedPreferences? _prefs;

  static const String _tokenKey = 'giat_access_token';
  static const String _userKey = 'giat_user_data';
  static const String _roleKey = 'giat_user_role';
  static const String _baseUrlKey = 'giat_api_base_url';

  /// Initialize local preferences and restore base URL if previously saved
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedUrl = await getBaseUrl();
      if (savedUrl != null && savedUrl.isNotEmpty) {
        ApiConfig.setBaseUrl(savedUrl);
      }
    } catch (e) {
      debugPrint('StorageService init error: $e');
    }
  }

  /// Save Sanctum access token
  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (_) {
      await _prefs?.setString(_tokenKey, token);
    }
  }

  /// Retrieve Sanctum access token
  Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    return _prefs?.getString(_tokenKey);
  }

  /// Delete Sanctum access token
  Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {}
    await _prefs?.remove(_tokenKey);
  }

  /// Save logged-in user profile
  Future<void> saveUser(UserModel user) async {
    final userJson = user.toJsonString();
    try {
      await _secureStorage.write(key: _userKey, value: userJson);
    } catch (_) {
      await _prefs?.setString(_userKey, userJson);
    }
    await saveRole(user.role);
  }

  /// Get logged-in user profile
  Future<UserModel?> getUser() async {
    try {
      final data = await _secureStorage.read(key: _userKey);
      if (data != null && data.isNotEmpty) {
        return UserModel.fromJsonString(data);
      }
    } catch (_) {}

    final prefData = _prefs?.getString(_userKey);
    if (prefData != null && prefData.isNotEmpty) {
      try {
        return UserModel.fromJsonString(prefData);
      } catch (_) {}
    }
    return null;
  }

  /// Save user role
  Future<void> saveRole(String role) async {
    try {
      await _secureStorage.write(key: _roleKey, value: role);
    } catch (_) {}
    await _prefs?.setString(_roleKey, role);
  }

  /// Get user role
  Future<String?> getRole() async {
    try {
      final role = await _secureStorage.read(key: _roleKey);
      if (role != null && role.isNotEmpty) return role;
    } catch (_) {}
    return _prefs?.getString(_roleKey);
  }

  /// Save custom Base URL
  Future<void> saveBaseUrl(String url) async {
    ApiConfig.setBaseUrl(url);
    await _prefs?.setString(_baseUrlKey, url);
  }

  /// Get saved custom Base URL
  Future<String?> getBaseUrl() async {
    return _prefs?.getString(_baseUrlKey);
  }

  /// Clear all authentication session data
  Future<void> clearAuth() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userKey);
      await _secureStorage.delete(key: _roleKey);
    } catch (_) {}
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userKey);
    await _prefs?.remove(_roleKey);
  }

  /// Check if user has an active token
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
