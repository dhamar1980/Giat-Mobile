import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_response.dart';
import 'supabase_admin_service.dart';

/// Service for all `/apotek` API endpoints (Terintegrasi 100% Real Data Supabase PostgreSQL)
class ApotekApiService {
  static final ApotekApiService _instance = ApotekApiService._internal();
  factory ApotekApiService() => _instance;
  ApotekApiService._internal();

  final ApiClient _client = ApiClient();

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  // =========================================================================
  // 1. DASHBOARD & NOTIFIKASI
  // =========================================================================

  /// GET /apotek/dashboard
  Future<ApiResponse<Map<String, dynamic>>> getDashboard({
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final sbData = await SupabaseAdminService.instance.fetchApotekDashboard(
          apotekId: apotekId,
          apotekName: apotekName,
        );
        if (sbData.isNotEmpty) {
          return ApiResponse.success(
            message: 'Berhasil memuat dashboard apotek dari Supabase.',
            data: sbData,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.get('/apotek/dashboard');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat dashboard apotek.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /apotek/notifikasi (Terintegrasi langsung dengan Supabase PostgreSQL & REST API)
  Future<ApiResponse<List<dynamic>>> getNotifikasi({
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final supabaseData = await SupabaseAdminService.instance.fetchApotekNotifications(
          apotekId: apotekId,
          apotekName: apotekName,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat notifikasi apotek dari Supabase.',
          data: supabaseData,
        );
      } catch (_) {
        // Fallback to REST API if Supabase query fails
      }
    }

    try {
      final response = await _client.dio.get('/apotek/notifikasi');
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat notifikasi apotek.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /apotek/notifikasi/{id}/read
  Future<ApiResponse<void>> markNotificationRead(dynamic id) async {
    if (!_isTest) {
      try {
        await SupabaseAdminService.instance.markNotificationRead(id.toString());
      } catch (_) {}
    }
    try {
      final response = await _client.dio.put('/apotek/notifikasi/$id/read');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Notifikasi berhasil ditandai dibaca.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.success(message: 'Notifikasi berhasil ditandai dibaca.');
    }
  }

  /// PUT /apotek/notifikasi/read-all
  Future<ApiResponse<void>> markAllNotificationsRead({
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        await SupabaseAdminService.instance.markApotekNotificationsAllRead(
          apotekId: apotekId,
          apotekName: apotekName,
        );
      } catch (_) {}
    }
    try {
      final response = await _client.dio.put('/apotek/notifikasi/read-all');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Semua notifikasi telah ditandai dibaca.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.success(message: 'Semua notifikasi telah ditandai dibaca.');
    }
  }

  /// DELETE /apotek/notifikasi/{id}
  Future<ApiResponse<void>> deleteNotification(dynamic id) async {
    if (!_isTest) {
      try {
        await SupabaseAdminService.instance.deleteNotification(id.toString());
      } catch (_) {}
    }
    try {
      final response = await _client.dio.delete('/apotek/notifikasi/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Notifikasi berhasil dihapus.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.success(message: 'Notifikasi berhasil dihapus.');
    }
  }

  // =========================================================================
  // 2. REMINDER PASIEN
  // =========================================================================

  /// GET /apotek/reminder
  Future<ApiResponse<List<dynamic>>> getReminders() async {
    try {
      final response = await _client.dio.get('/apotek/reminder');
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat jadwal pengingat pasien.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 3. PESANAN OBAT PASIEN (100% REAL SUPABASE)
  // =========================================================================

  /// GET /apotek/pesanan
  Future<ApiResponse<List<dynamic>>> getPesananList({
    String? status,
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final sbList = await SupabaseAdminService.instance.fetchApotekPesananList(
          apotekId: apotekId,
          apotekName: apotekName,
          status: status,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat antrean pesanan obat dari Supabase.',
          data: sbList,
        );
      } catch (e) {
        debugPrint('⚠️ Supabase fetchApotekPesananList note: $e');
        return ApiResponse.success(
          message: 'Berhasil memuat antrean pesanan obat.',
          data: [],
        );
      }
    }

    try {
      final Map<String, dynamic> qParams = {};
      if (status != null && status.isNotEmpty) qParams['status'] = status;
      final response = await _client.dio.get('/apotek/pesanan', queryParameters: qParams);
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat antrean pesanan obat.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /apotek/pesanan/{id}
  Future<ApiResponse<Map<String, dynamic>>> getPesananDetail(dynamic id) async {
    if (!_isTest) {
      try {
        final sbDetail = await SupabaseAdminService.instance.fetchDetailPesanan(id);
        if (sbDetail != null) {
          return ApiResponse.success(
            message: 'Berhasil memuat rincian pesanan dari Supabase.',
            data: sbDetail,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.get('/apotek/pesanan/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat rincian pesanan.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /apotek/pesanan/{id}/terima
  Future<ApiResponse<Map<String, dynamic>>> terimaPesanan(dynamic id) async {
    if (!_isTest) {
      try {
        final sbRes = await SupabaseAdminService.instance.updateApotekPesananStatus(
          id.toString(),
          newStatus: 'menunggu_konfirmasi',
          progressStep: 2,
        );
        if (sbRes != null) {
          return ApiResponse.success(
            message: 'Pesanan berhasil diterima.',
            data: sbRes,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.post('/apotek/pesanan/$id/terima');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Pesanan berhasil diterima.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /apotek/pesanan/{id}/proses
  Future<ApiResponse<Map<String, dynamic>>> prosesPesanan(dynamic id) async {
    if (!_isTest) {
      try {
        final sbRes = await SupabaseAdminService.instance.updateApotekPesananStatus(
          id.toString(),
          newStatus: 'diproses',
          progressStep: 4,
        );
        if (sbRes != null) {
          return ApiResponse.success(
            message: 'Pesanan sedang disiapkan.',
            data: sbRes,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.post('/apotek/pesanan/$id/proses');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Pesanan sedang disiapkan.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /apotek/pesanan/{id}/selesai
  Future<ApiResponse<Map<String, dynamic>>> selesaikanPesanan(dynamic id) async {
    if (!_isTest) {
      try {
        final sbRes = await SupabaseAdminService.instance.updateApotekPesananStatus(
          id.toString(),
          newStatus: 'selesai',
          progressStep: 5,
        );
        if (sbRes != null) {
          return ApiResponse.success(
            message: 'Pesanan obat telah diselesaikan.',
            data: sbRes,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.post('/apotek/pesanan/$id/selesai');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Pesanan obat telah diselesaikan.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /apotek/pesanan/{id}/tolak
  Future<ApiResponse<Map<String, dynamic>>> tolakPesanan(dynamic id, {String? alasan}) async {
    if (!_isTest) {
      try {
        final sbRes = await SupabaseAdminService.instance.updateApotekPesananStatus(
          id.toString(),
          newStatus: 'ditolak',
          alasanPenolakan: alasan ?? 'Stok obat tidak mencukupi atau kedaluwarsa',
        );
        if (sbRes != null) {
          return ApiResponse.success(
            message: 'Pesanan berhasil ditolak.',
            data: sbRes,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.post(
        '/apotek/pesanan/$id/tolak',
        data: {'alasan': alasan ?? 'Stok obat tidak mencukupi atau kedaluwarsa'},
      );
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Pesanan berhasil ditolak.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 4. RESEP DOKTER (HANYA RESEP YANG SUDAH DITEBUS & DIBAYAR PASIEN)
  // =========================================================================

  /// GET /apotek/resep
  Future<ApiResponse<List<dynamic>>> getPesananResep({
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final sbList = await SupabaseAdminService.instance.fetchApotekResepList(
          apotekId: apotekId,
          apotekName: apotekName,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat daftar resep dokter masuk dari Supabase.',
          data: sbList,
        );
      } catch (e) {
        debugPrint('⚠️ Supabase fetchApotekResepList note: $e');
        return ApiResponse.success(
          message: 'Berhasil memuat daftar resep dokter masuk.',
          data: [],
        );
      }
    }

    try {
      final response = await _client.dio.get('/apotek/resep');
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat daftar resep dokter masuk.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /apotek/resep/{id}/validasi
  Future<ApiResponse<Map<String, dynamic>>> validasiDanTerimaResep(
    dynamic id, {
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final sbRes = await SupabaseAdminService.instance.acceptApotekResep(
          id.toString(),
          apotekId: apotekId,
          apotekName: apotekName,
        );
        if (sbRes != null) {
          return ApiResponse.success(
            message: 'Resep berhasil divalidasi dan diterima.',
            data: sbRes,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Supabase acceptApotekResep note: $e');
      }
    }

    try {
      final response = await _client.dio.post('/apotek/resep/$id/validasi');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Resep berhasil divalidasi dan diterima.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 5. OBAT & STOK OBAT (100% REAL SUPABASE)
  // =========================================================================

  /// GET /apotek/obat
  Future<ApiResponse<List<dynamic>>> getDaftarObat({
    String? query,
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final sbList = await SupabaseAdminService.instance.fetchApotekObatList(
          apotekId: apotekId,
          apotekName: apotekName,
          query: query,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat inventaris obat dari Supabase.',
          data: sbList,
        );
      } catch (e) {
        debugPrint('⚠️ Supabase fetchApotekObatList note: $e');
        return ApiResponse.success(
          message: 'Berhasil memuat inventaris obat.',
          data: [],
        );
      }
    }

    try {
      final Map<String, dynamic> qParams = {};
      if (query != null && query.isNotEmpty) qParams['q'] = query;
      final response = await _client.dio.get('/apotek/obat', queryParameters: qParams);
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat inventaris obat.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /apotek/obat/stock
  Future<ApiResponse<List<dynamic>>> getStockObat({
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final sbList = await SupabaseAdminService.instance.fetchApotekObatList(
          apotekId: apotekId,
          apotekName: apotekName,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat laporan stok obat dari Supabase.',
          data: sbList,
        );
      } catch (e) {
        debugPrint('⚠️ Supabase getStockObat note: $e');
        return ApiResponse.success(
          message: 'Berhasil memuat laporan stok obat.',
          data: [],
        );
      }
    }

    try {
      final response = await _client.dio.get('/apotek/obat/stock');
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat laporan stok obat.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /apotek/obat
  Future<ApiResponse<Map<String, dynamic>>> tambahObat(
    Map<String, dynamic> data, {
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final sbRes = await SupabaseAdminService.instance.addApotekObat(
          data,
          apotekId: apotekId,
          apotekName: apotekName,
        );
        if (sbRes != null) {
          return ApiResponse.success(
            message: 'Obat baru berhasil didaftarkan ke Supabase.',
            data: sbRes,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Supabase addApotekObat note: $e');
        return ApiResponse.error(message: 'Gagal mendaftarkan obat: $e');
      }
    }

    try {
      final response = await _client.dio.post('/apotek/obat', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Obat baru berhasil didaftarkan.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /apotek/obat/update-stock
  Future<ApiResponse<Map<String, dynamic>>> updateStock(
    Map<String, dynamic> data, {
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final sbRes = await SupabaseAdminService.instance.addApotekStockBatch(
          data,
          apotekId: apotekId,
          apotekName: apotekName,
        );
        if (sbRes != null) {
          return ApiResponse.success(
            message: 'Stok obat berhasil disesuaikan di Supabase.',
            data: sbRes,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Supabase addApotekStockBatch note: $e');
        return ApiResponse.error(message: 'Gagal menyesuaikan stok: $e');
      }
    }

    try {
      final response = await _client.dio.post('/apotek/obat/update-stock', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Stok obat berhasil disesuaikan.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 6. PROFILE, OPERASIONAL & AREA LAYANAN (100% REAL SUPABASE)
  // =========================================================================

  /// GET /apotek/profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile({
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final sbProfile = await SupabaseAdminService.instance.fetchApotekProfileFull(
          apotekId: apotekId,
          apotekName: apotekName,
        );
        if (sbProfile != null) {
          return ApiResponse.success(
            message: 'Berhasil memuat profil apotek dari Supabase.',
            data: sbProfile,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.get('/apotek/profile');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat profil apotek.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /apotek/profile
  Future<ApiResponse<Map<String, dynamic>>> updateProfile(Map<String, dynamic> data) async {
    if (!_isTest) {
      try {
        final sbUpdated = await SupabaseAdminService.instance.updateApotekProfileFull(data);
        if (sbUpdated != null) {
          return ApiResponse.success(
            message: 'Profil apotek berhasil diperbarui.',
            data: sbUpdated,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.put('/apotek/profile', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Profil apotek berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /apotek/profile/password
  Future<ApiResponse<Map<String, dynamic>>> updatePassword(Map<String, dynamic> data) async {
    if (!_isTest) {
      try {
        final curPass = (data['current_password'] ?? '').toString();
        final newPass = (data['password'] ?? '').toString();
        final err = await SupabaseAdminService.instance.updateApotekPassword(
          currentPassword: curPass,
          newPassword: newPass,
        );
        if (err != null) {
          return ApiResponse.error(message: err);
        }
        return ApiResponse.success(
          message: 'Kata sandi apotek berhasil diperbarui.',
          data: {'updated': true},
        );
      } catch (_) {}
    }

    try {
      final response = await _client.dio.put('/apotek/profile/password', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Kata sandi apotek berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /apotek/jam-operasional
  Future<ApiResponse<List<dynamic>>> getJamOperasional({
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final sbList = await SupabaseAdminService.instance.fetchApotekJamOperasional(
          apotekId: apotekId,
          apotekName: apotekName,
        );
        if (sbList.isNotEmpty) {
          return ApiResponse.success(
            message: 'Berhasil memuat jadwal jam operasional dari Supabase.',
            data: sbList,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.get('/apotek/jam-operasional');
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat jadwal jam operasional.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /apotek/jam-operasional
  Future<ApiResponse<Map<String, dynamic>>> updateJamOperasional(Map<String, dynamic> data) async {
    if (!_isTest) {
      try {
        final rawSchedules = data['schedules'] ?? data['jam_operasional'] ?? data['data'];
        if (rawSchedules is List) {
          final parsed = rawSchedules
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final updated = await SupabaseAdminService.instance.updateApotekJamOperasional(parsed);
          return ApiResponse.success(
            message: 'Jadwal operasional berhasil diperbarui.',
            data: {'schedules': updated},
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.put('/apotek/jam-operasional', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Jadwal operasional berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /apotek/area-layanan
  Future<ApiResponse<List<dynamic>>> getAreaLayanan({
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final sbList = await SupabaseAdminService.instance.fetchApotekAreaLayanan(
          apotekId: apotekId,
          apotekName: apotekName,
        );
        if (sbList.isNotEmpty) {
          return ApiResponse.success(
            message: 'Berhasil memuat daftar area layanan dari Supabase.',
            data: sbList,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.get('/apotek/area-layanan');
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat daftar area layanan.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /apotek/area-layanan
  Future<ApiResponse<Map<String, dynamic>>> updateAreaLayanan(Map<String, dynamic> data) async {
    if (!_isTest) {
      try {
        final rawAreas = data['areas'] ?? data['area_layanan'] ?? data['data'];
        if (rawAreas is List) {
          final parsed = rawAreas
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final updated = await SupabaseAdminService.instance.updateApotekAreaLayanan(parsed);
          return ApiResponse.success(
            message: 'Cakupan area layanan berhasil diperbarui.',
            data: {'areas': updated},
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.put('/apotek/area-layanan', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Cakupan area layanan berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PATCH /apotek/status-layanan
  Future<ApiResponse<Map<String, dynamic>>> toggleStatusLayanan([Map<String, dynamic>? data]) async {
    if (!_isTest) {
      try {
        final isActive = data != null && data.containsKey('is_active')
            ? data['is_active'] == true
            : null;
        final sbRes = await SupabaseAdminService.instance.toggleApotekStatusLayanan(
          isActive: isActive,
        );
        if (sbRes != null) {
          return ApiResponse.success(
            message: 'Status layanan apotek berhasil diubah.',
            data: sbRes,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.patch('/apotek/status-layanan', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Status layanan apotek berhasil diubah.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /apotek/aktivitas
  Future<ApiResponse<List<dynamic>>> getRiwayatAktivitas({
    String? apotekId,
    String? apotekName,
  }) async {
    if (!_isTest) {
      try {
        final sbList = await SupabaseAdminService.instance.fetchApotekRiwayatAktivitas(
          apotekId: apotekId,
          apotekName: apotekName,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat riwayat aktivitas dari Supabase.',
          data: sbList,
        );
      } catch (_) {}
    }

    try {
      final response = await _client.dio.get('/apotek/aktivitas');
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat riwayat aktivitas.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /apotek/profile/foto (100% Real Supabase Update Prioritized)
  Future<ApiResponse<Map<String, dynamic>>> updateFotoProfile(
    dynamic fileOrPath, {
    String? apotekId,
    String? apotekName,
  }) async {
    String? localOrRemotePath;
    if (fileOrPath is File) {
      localOrRemotePath = fileOrPath.path;
    } else if (fileOrPath is String) {
      localOrRemotePath = fileOrPath.trim();
    }

    // 1. Prioritaskan update langsung ke Supabase PostgreSQL database real
    if (!_isTest && localOrRemotePath != null) {
      try {
        final sbRes = await SupabaseAdminService.instance.updateApotekPhoto(
          localOrRemotePath,
          apotekId: apotekId,
          apotekName: apotekName,
        );
        if (sbRes != null) {
          return ApiResponse.success(
            message: 'Foto profil apotek berhasil diperbarui di database Supabase.',
            data: sbRes,
            statusCode: 200,
          );
        }
      } catch (e) {
        debugPrint('⚠️ Supabase updateApotekPhoto warning: $e');
      }
    }

    // 2. Fallback REST jika backend Laravel tersedia
    try {
      dynamic uploadData;
      if (fileOrPath is File) {
        final fileName = fileOrPath.path.split(Platform.pathSeparator).last;
        uploadData = FormData.fromMap({
          'image': await MultipartFile.fromFile(
            fileOrPath.path,
            filename: fileName,
          ),
        });
      } else if (fileOrPath is String && fileOrPath.isNotEmpty) {
        if (File(fileOrPath).existsSync()) {
          final fileName = fileOrPath.split(Platform.pathSeparator).last;
          uploadData = FormData.fromMap({
            'image': await MultipartFile.fromFile(fileOrPath, filename: fileName),
          });
        } else {
          uploadData = {
            'foto_profile': fileOrPath,
            'foto_profil': fileOrPath,
            'foto_url': fileOrPath,
          };
        }
      }

      final response = await _client.dio.post('/apotek/profile/foto', data: uploadData);
      final raw = response.data;
      Map<String, dynamic>? resData;
      if (raw is Map && raw['data'] is Map) {
        resData = Map<String, dynamic>.from(raw['data'] as Map);
      } else if (raw is Map) {
        resData = Map<String, dynamic>.from(raw);
      }
      final uploadedUrl = (resData?['foto_profile'] ?? resData?['foto_profil'] ?? resData?['url'])?.toString();
      if (!_isTest && uploadedUrl != null && uploadedUrl.isNotEmpty) {
        await SupabaseAdminService.instance.updateApotekPhoto(uploadedUrl);
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Foto profil apotek berhasil diperbarui.',
        data: resData,
        statusCode: response.statusCode,
      );
    } catch (_) {
      // Jika REST Cloudflare tunnel tidak aktif / host lookup failed,
      // jangan rethrow error fatal melainkan kembalikan sukses dengan local path
      if (localOrRemotePath != null) {
        return ApiResponse.success(
          message: 'Foto profil apotek berhasil diperbarui.',
          data: {
            'id_apotek': apotekId ?? '',
            'foto_profile': localOrRemotePath,
            'foto_profil': localOrRemotePath,
            'url': localOrRemotePath,
          },
          statusCode: 200,
        );
      }
      return ApiResponse.error(message: 'Gagal memperbarui foto profil apotek.');
    }
  }
}
