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

  // =========================================================================
  // REMINDER & NOTIFIKASI LOCAL CACHE (OFFLINE FIRST & PERSISTENCE)
  // =========================================================================
  static const String _remindersCacheKey = 'giat_pasien_reminders_cache';
  static const String _notificationsCacheKey = 'giat_pasien_notifications_cache';
  static const String _notifiedRemindersKey = 'giat_notified_reminder_keys';

  /// Menyimpan daftar pengingat pasien ke cache lokal
  Future<void> saveRemindersCache(List<Map<String, dynamic>> reminders) async {
    final raw = jsonEncode(reminders);
    if (_isTest) {
      _testMemoryStorage[_remindersCacheKey] = raw;
      return;
    }
    await _prefs?.setString(_remindersCacheKey, raw);
  }

  /// Mengambil daftar pengingat pasien dari cache lokal
  List<Map<String, dynamic>> getRemindersCache() {
    String? raw;
    if (_isTest) {
      raw = _testMemoryStorage[_remindersCacheKey];
    } else {
      raw = _prefs?.getString(_remindersCacheKey);
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

  /// Menambahkan atau memperbarui 1 pengingat di cache lokal
  Future<void> upsertReminderInCache(Map<String, dynamic> reminder) async {
    final list = getRemindersCache();
    final remId = (reminder['id'] ?? reminder['id_reminder'])?.toString();
    if (remId != null && remId.isNotEmpty) {
      final idx = list.indexWhere(
        (item) => (item['id'] ?? item['id_reminder'])?.toString() == remId,
      );
      if (idx != -1) {
        list[idx] = {...list[idx], ...reminder};
      } else {
        list.insert(0, reminder);
      }
    } else {
      list.insert(0, reminder);
    }
    await saveRemindersCache(list);
  }

  /// Menghapus pengingat dari cache lokal berdasarkan id
  Future<void> deleteReminderFromCache(dynamic id) async {
    if (id == null) return;
    final list = getRemindersCache();
    final targetId = id.toString().trim();
    list.removeWhere(
      (item) => (item['id'] ?? item['id_reminder'])?.toString().trim() == targetId,
    );
    await saveRemindersCache(list);
  }

  /// Menyimpan daftar notifikasi pasien ke cache lokal
  Future<void> saveNotificationsCache(List<Map<String, dynamic>> notifications) async {
    final raw = jsonEncode(notifications);
    if (_isTest) {
      _testMemoryStorage[_notificationsCacheKey] = raw;
      return;
    }
    await _prefs?.setString(_notificationsCacheKey, raw);
  }

  /// Mengambil daftar notifikasi pasien dari cache lokal
  List<Map<String, dynamic>> getNotificationsCache() {
    String? raw;
    if (_isTest) {
      raw = _testMemoryStorage[_notificationsCacheKey];
    } else {
      raw = _prefs?.getString(_notificationsCacheKey);
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

  /// Menambahkan 1 notifikasi baru ke paling atas cache lokal
  Future<void> addNotificationToCache(Map<String, dynamic> notification) async {
    final list = getNotificationsCache();
    final notifId = notification['id']?.toString();
    if (notifId != null && notifId.isNotEmpty) {
      list.removeWhere((item) => item['id']?.toString() == notifId);
    }
    list.insert(0, notification);
    await saveNotificationsCache(list);
    final unread = list.where((n) => n['is_read'] != true && n['is_read'] != 1 && n['read_at'] == null).length;
    await saveUnreadNotificationCount(unread);
  }

  /// Menandai 1 notifikasi sebagai sudah dibaca di cache lokal
  Future<void> markNotificationReadInCache(dynamic id) async {
    if (id == null) return;
    final list = getNotificationsCache();
    final targetId = id.toString().trim();
    for (int i = 0; i < list.length; i++) {
      if (list[i]['id']?.toString().trim() == targetId) {
        list[i] = {...list[i], 'is_read': true};
      }
    }
    await saveNotificationsCache(list);
    final unread = list.where((n) => n['is_read'] != true && n['is_read'] != 1 && n['read_at'] == null).length;
    await saveUnreadNotificationCount(unread);
  }

  /// Menandai semua notifikasi sebagai sudah dibaca di cache lokal
  Future<void> markAllNotificationsReadInCache() async {
    final list = getNotificationsCache().map((n) => {...n, 'is_read': true}).toList();
    await saveNotificationsCache(list);
    await saveUnreadNotificationCount(0);
  }

  /// Menghapus 1 notifikasi dari cache lokal
  Future<void> deleteNotificationFromCache(dynamic id) async {
    if (id == null) return;
    final list = getNotificationsCache();
    final targetId = id.toString().trim();
    list.removeWhere((item) => item['id']?.toString().trim() == targetId);
    await saveNotificationsCache(list);
    final unread = list.where((n) => n['is_read'] != true && n['is_read'] != 1 && n['read_at'] == null).length;
    await saveUnreadNotificationCount(unread);
  }

  /// Mengambil daftar key pengingat yang sudah dinotifikasi (`reminderId_YYYY-MM-DD_HH:mm`)
  Set<String> getNotifiedReminderKeys() {
    String? raw;
    if (_isTest) {
      raw = _testMemoryStorage[_notifiedRemindersKey];
    } else {
      raw = _prefs?.getString(_notifiedRemindersKey);
    }
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toSet();
        }
      } catch (_) {}
    }
    return <String>{};
  }

  /// Menandai key pengingat sudah dinotifikasi
  Future<void> markReminderNotified(String key) async {
    final keys = getNotifiedReminderKeys();
    keys.add(key);
    // Jaga agar ukuran list tetap ringkas (maks 300 entri terakhir)
    final list = keys.toList();
    if (list.length > 300) {
      list.removeRange(0, list.length - 300);
    }
    final raw = jsonEncode(list);
    if (_isTest) {
      _testMemoryStorage[_notifiedRemindersKey] = raw;
      return;
    }
    await _prefs?.setString(_notifiedRemindersKey, raw);
  }
}

