import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../constants/api_constants.dart';
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
        // Jika savedUrl adalah tunnel Cloudflare lama yang sudah diganti di ApiConstants,
        // otomatis perbarui SharedPreferences ke URL tunnel yang baru
        final currentHost = Uri.tryParse(ApiConstants.serverUrl)?.host ?? '';
        final savedHost = Uri.tryParse(savedUrl)?.host ?? '';
        if (currentHost.isNotEmpty &&
            savedHost != currentHost &&
            (savedHost.contains('trycloudflare.com') ||
             savedHost == '10.0.2.2' ||
             savedHost == '127.0.0.1' ||
             savedHost == 'localhost' ||
             savedHost.isEmpty)) {
          debugPrint('🔄 Sinkronisasi Base URL ($savedHost) -> URL baru ($currentHost)');
          await saveBaseUrl(ApiConstants.defaultBaseUrl);
        } else {
          ApiConfig.setBaseUrl(savedUrl);
        }
      } else {
        ApiConfig.setBaseUrl(ApiConstants.defaultBaseUrl);
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

  /// Menyimpan rating dan ulasan dokter di local storage
  Future<void> saveDoctorRating({
    required String doctorId,
    required int rating,
    String? ulasan,
  }) async {
    final key = 'giat_doctor_rating_$doctorId';
    final data = jsonEncode({
      'rating': rating,
      'ulasan': ulasan ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (_isTest) {
      _testMemoryStorage[key] = data;
      return;
    }

    try {
      await _secureStorage.write(key: key, value: data);
    } catch (_) {
      await _prefs?.setString(key, data);
    }
  }

  /// Mengambil rating dan ulasan dokter dari local storage
  Future<Map<String, dynamic>?> getDoctorRating(String doctorId) async {
    final key = 'giat_doctor_rating_$doctorId';
    String? raw;

    if (_isTest) {
      raw = _testMemoryStorage[key];
    } else {
      try {
        raw = await _secureStorage.read(key: key);
      } catch (_) {}
      raw ??= _prefs?.getString(key);
    }

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }
    return null;
  }

  // =========================================================================
  // PANTAU LOCAL CACHE (OFFLINE FIRST & PERSISTENCE)
  // =========================================================================
  static const String _pantauHistoryKey = 'giat_pantau_history_cache';
  static const String _pantauSummaryKey = 'giat_pantau_summary_cache';

  /// Menyimpan riwayat pantau ke local storage cache
  Future<void> savePantauHistoryCache(List<Map<String, dynamic>> records) async {
    final raw = jsonEncode(records);
    if (_isTest) {
      _testMemoryStorage[_pantauHistoryKey] = raw;
      return;
    }
    await _prefs?.setString(_pantauHistoryKey, raw);
  }

  /// Mengambil riwayat pantau dari cache lokal
  List<Map<String, dynamic>> getPantauHistoryCache() {
    String? raw;
    if (_isTest) {
      raw = _testMemoryStorage[_pantauHistoryKey];
    } else {
      raw = _prefs?.getString(_pantauHistoryKey);
    }
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  /// Menambahkan 1 catatan kondisi pantau baru ke paling atas cache lokal
  Future<void> addPantauRecordToCache(Map<String, dynamic> record) async {
    final list = getPantauHistoryCache();
    if (record['id'] != null) {
      list.removeWhere((item) => item['id'] != null && item['id'].toString() == record['id'].toString());
    }
    list.insert(0, record);
    await savePantauHistoryCache(list);
  }

  /// Menghapus catatan pantau dari cache lokal berdasarkan id
  Future<void> deletePantauRecordFromCache(dynamic id) async {
    if (id == null) return;
    final list = getPantauHistoryCache();
    list.removeWhere((item) => item['id']?.toString() == id.toString());
    await savePantauHistoryCache(list);
  }

  /// Menyimpan summary pantau ke cache lokal
  Future<void> savePantauSummaryCache(Map<String, dynamic> summary) async {
    final raw = jsonEncode(summary);
    if (_isTest) {
      _testMemoryStorage[_pantauSummaryKey] = raw;
      return;
    }
    await _prefs?.setString(_pantauSummaryKey, raw);
  }

  /// Mengambil summary pantau dari cache lokal
  Map<String, dynamic>? getPantauSummaryCache() {
    String? raw;
    if (_isTest) {
      raw = _testMemoryStorage[_pantauSummaryKey];
    } else {
      raw = _prefs?.getString(_pantauSummaryKey);
    }
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }
    return null;
  }

  static const _unreadNotifKey = 'giat_unread_notif_count';

  /// Menyimpan unread notification count
  Future<void> saveUnreadNotificationCount(int count) async {
    if (_isTest) {
      _testMemoryStorage[_unreadNotifKey] = count.toString();
      return;
    }
    await _prefs?.setInt(_unreadNotifKey, count);
  }

  /// Mengambil unread notification count
  int getUnreadNotificationCount() {
    if (_isTest) {
      return int.tryParse(_testMemoryStorage[_unreadNotifKey] ?? '0') ?? 0;
    }
    return _prefs?.getInt(_unreadNotifKey) ?? 0;
  }
}

