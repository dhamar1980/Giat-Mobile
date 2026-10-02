import 'dart:io';
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
  final Map<String, String> _testMemoryStorage = {};

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  /// Synchronous user access for test environment interceptors
  UserModel? get testUser {
    if (!_isTest) return null;
    final data = _testMemoryStorage[_userKey];
    if (data != null && data.isNotEmpty) {
      try {
        return UserModel.fromJsonString(data);
      } catch (_) {}
    }
    return null;
  }

  static const String _tokenKey = 'giat_access_token';
  static const String _userKey = 'giat_user_data';
  static const String _roleKey = 'giat_user_role';
  static const String _baseUrlKey = 'giat_api_base_url';

  /// Initialize local preferences and restore base URL if previously saved
  Future<void> init() async {
    if (_isTest) return;
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
    if (_isTest) {
      _testMemoryStorage[_tokenKey] = token;
      return;
    }
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (_) {
      await _prefs?.setString(_tokenKey, token);
    }
  }

  /// Retrieve Sanctum access token
  Future<String?> getToken() async {
    if (_isTest) return _testMemoryStorage[_tokenKey];
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}
    return _prefs?.getString(_tokenKey);
  }

  /// Delete Sanctum access token
  Future<void> deleteToken() async {
    if (_isTest) {
      _testMemoryStorage.remove(_tokenKey);
      return;
    }
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (_) {}
    await _prefs?.remove(_tokenKey);
  }

  /// Save logged-in user profile
  Future<void> saveUser(UserModel user) async {
    final userJson = user.toJsonString();
    if (_isTest) {
      _testMemoryStorage[_userKey] = userJson;
      _testMemoryStorage[_roleKey] = user.role;
      return;
    }
    try {
      await _secureStorage.write(key: _userKey, value: userJson);
    } catch (_) {
      await _prefs?.setString(_userKey, userJson);
    }
    await saveRole(user.role);
  }

  /// Get logged-in user profile
  Future<UserModel?> getUser() async {
    if (_isTest) {
      final data = _testMemoryStorage[_userKey];
      if (data != null && data.isNotEmpty) {
        try {
          return UserModel.fromJsonString(data);
        } catch (_) {}
      }
      return null;
    }
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
    if (_isTest) {
      _testMemoryStorage[_roleKey] = role;
      return;
    }
    try {
      await _secureStorage.write(key: _roleKey, value: role);
    } catch (_) {}
    await _prefs?.setString(_roleKey, role);
  }

  /// Get user role
  Future<String?> getRole() async {
    if (_isTest) return _testMemoryStorage[_roleKey];
    try {
      final role = await _secureStorage.read(key: _roleKey);
      if (role != null && role.isNotEmpty) return role;
    } catch (_) {}
    return _prefs?.getString(_roleKey);
  }

  /// Save custom Base URL
  Future<void> saveBaseUrl(String url) async {
    ApiConfig.setBaseUrl(url);
    if (_isTest) {
      _testMemoryStorage[_baseUrlKey] = url;
      return;
    }
    await _prefs?.setString(_baseUrlKey, url);
  }

  /// Get saved custom Base URL
  Future<String?> getBaseUrl() async {
    if (_isTest) return _testMemoryStorage[_baseUrlKey];
    return _prefs?.getString(_baseUrlKey);
  }

  /// Clear all authentication session data
  Future<void> clearAuth() async {
    if (_isTest) {
      _testMemoryStorage.clear();
      return;
    }
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
