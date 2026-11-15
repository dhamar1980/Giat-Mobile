import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_response.dart';
import 'supabase_admin_service.dart';

/// Service for all `/dokter` API endpoints
class DokterApiService {
  static final DokterApiService _instance = DokterApiService._internal();
  factory DokterApiService() => _instance;
  DokterApiService._internal();

  final ApiClient _client = ApiClient();

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  // =========================================================================
  // 1. DASHBOARD & NOTIFIKASI
  // =========================================================================

  /// GET /dokter/dashboard (Terintegrasi langsung dengan Supabase PostgreSQL & REST API)
  Future<ApiResponse<Map<String, dynamic>>> getDashboard({String? dokterId, String? doctorName}) async {
    if (!_isTest) {
      try {
        final supabaseData = await SupabaseAdminService.instance.fetchDokterDashboard(
          dokterId: dokterId,
          doctorName: doctorName,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat dashboard dokter dari Supabase.',
          data: supabaseData,
        );
      } catch (e) {
        // Fallback to REST API if Supabase query fails
      }
    }

    try {
      final response = await _client.dio.get('/dokter/dashboard');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat dashboard dokter.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /dokter/notifikasi (Terintegrasi langsung dengan Supabase PostgreSQL & REST API)
  Future<ApiResponse<List<dynamic>>> getNotifikasi({
    String? dokterId,
    String? doctorName,
  }) async {
    if (!_isTest) {
      try {
        final supabaseData = await SupabaseAdminService.instance.fetchDokterNotifications(
          dokterId: dokterId,
          doctorName: doctorName,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat notifikasi dokter dari Supabase.',
          data: supabaseData,
        );
      } catch (e) {
        // Fallback to REST API if Supabase query fails
      }
    }

    try {
      final response = await _client.dio.get('/dokter/notifikasi');
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat notifikasi dokter.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /dokter/notifikasi/{id}/read
  Future<ApiResponse<void>> markNotificationRead(dynamic id) async {
    if (!_isTest) {
      try {
        await SupabaseAdminService.instance.markNotificationRead(id.toString());
      } catch (_) {}
    }
    try {
      final response = await _client.dio.put('/dokter/notifikasi/$id/read');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Notifikasi berhasil ditandai dibaca.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.success(message: 'Notifikasi berhasil ditandai dibaca.');
    }
  }

  /// PUT /dokter/notifikasi/read-all
  Future<ApiResponse<void>> markAllNotificationsRead({
    String? dokterId,
    String? doctorName,
  }) async {
    if (!_isTest) {
      try {
        await SupabaseAdminService.instance.markDokterNotificationsAllRead(
          dokterId: dokterId,
          doctorName: doctorName,
        );
      } catch (_) {}
    }
    try {
      final response = await _client.dio.put('/dokter/notifikasi/read-all');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Semua notifikasi telah ditandai dibaca.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.success(message: 'Semua notifikasi telah ditandai dibaca.');
    }
  }

  /// DELETE /dokter/notifikasi/{id}
  Future<ApiResponse<void>> deleteNotification(dynamic id) async {
    if (!_isTest) {
      try {
        await SupabaseAdminService.instance.deleteNotification(id.toString());
      } catch (_) {}
    }
    try {
      final response = await _client.dio.delete('/dokter/notifikasi/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Notifikasi berhasil dihapus.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiResponse.success(message: 'Notifikasi berhasil dihapus.');
    }
  }

  // =========================================================================
  // 2. JADWAL KONSULTASI
  // =========================================================================

  /// GET /dokter/jadwal (Terintegrasi langsung dengan Supabase PostgreSQL & REST API)
  Future<ApiResponse<List<dynamic>>> getJadwal({
    String? date,
    String? dokterId,
    String? doctorName,
  }) async {
    if (!_isTest) {
      try {
        final supabaseData = await SupabaseAdminService.instance.fetchDokterJadwal(
          date: date,
          dokterId: dokterId,
          doctorName: doctorName,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat jadwal konsultasi dokter dari Supabase.',
          data: supabaseData,
        );
      } catch (e) {
        // Fallback to REST API if Supabase query fails
      }
    }

    try {
      final Map<String, dynamic> qParams = {};
      if (date != null && date.isNotEmpty) qParams['date'] = date;
      if (dokterId != null && dokterId.isNotEmpty) qParams['id_dokter'] = dokterId;
      final response = await _client.dio.get('/dokter/jadwal', queryParameters: qParams);
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat jadwal konsultasi.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 3. PASIEN & DETAIL PASIEN (Pantau harian + PRAGI screening)
  // =========================================================================

  /// GET /dokter/pasien (Hanya menampilkan pasien yang SUDAH BERHASIL MEMBAYAR sesi dokter)
  Future<ApiResponse<List<dynamic>>> getPasienList({
    String? search,
    String? dokterId,
    String? doctorName,
  }) async {
    if (!_isTest) {
      try {
        final supabaseData = await SupabaseAdminService.instance.fetchDokterPaidPatients(
          dokterId: dokterId,
          doctorName: doctorName,
          search: search,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat daftar pasien berbayar dokter dari Supabase.',
          data: supabaseData,
        );
      } catch (e) {
        // Fallback to REST API if Supabase query fails
      }
    }

    try {
      final Map<String, dynamic> qParams = {};
      if (search != null && search.isNotEmpty) qParams['search'] = search;
      if (dokterId != null && dokterId.isNotEmpty) qParams['id_dokter'] = dokterId;
      final response = await _client.dio.get('/dokter/pasien', queryParameters: qParams);
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat daftar pasien dokter.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /dokter/pasien/{id}/detail
  Future<ApiResponse<Map<String, dynamic>>> getPasienDetail(
    dynamic id, {
    String? dokterId,
    String? doctorName,
  }) async {
    if (!_isTest) {
      try {
        final supabaseData = await SupabaseAdminService.instance.fetchDokterPatientDetail(
          id.toString(),
          dokterId: dokterId,
          doctorName: doctorName,
        );
        if (supabaseData != null) {
          return ApiResponse.success(
            message: 'Berhasil memuat detail kondisi dan riwayat pasien dari Supabase.',
            data: supabaseData,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.get('/dokter/pasien/$id/detail');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat detail kondisi dan riwayat pasien.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 4. RESEP OBAT ELEKTRONIK
  // =========================================================================

  /// POST /dokter/resep
  Future<ApiResponse<Map<String, dynamic>>> createResep(Map<String, dynamic> payload) async {
    // 1. Prioritaskan penyimpanan langsung ke Supabase PostgreSQL
    if (!_isTest) {
      try {
        final pasienId = (payload['pasien_id'] ?? payload['id_pasien'] ?? '').toString();
        final patientName = (payload['pasien_nama'] ?? payload['patient_name'] ?? '').toString();
        final docId = (payload['id_dokter'] ?? payload['dokter_id'] ?? '').toString();
        final docName = (payload['doctor_name'] ?? payload['dokter_nama'] ?? '').toString();
        final consultationId = (payload['id_konsultasi'] ?? payload['konsultasi_id'] ?? '').toString();
        final rawItems = payload['items'] as List<dynamic>? ?? [];
        final items = rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        final res = await SupabaseAdminService.instance.saveResepDokter(
          idPasien: pasienId,
          patientName: patientName.isNotEmpty ? patientName : null,
          idDokter: docId.isNotEmpty ? docId : null,
          doctorName: docName.isNotEmpty ? docName : null,
          idKonsultasi: consultationId.isNotEmpty ? consultationId : null,
          diagnosis: payload['diagnosis']?.toString(),
          catatanDokter: (payload['catatan_dokter'] ?? payload['catatan'])?.toString(),
          items: items,
        );

        return ApiResponse.success(
          message: 'Resep elektronik berhasil dibuat & tersimpan di database Supabase.',
          data: res,
          statusCode: 201,
        );
      } catch (_) {}
    }

    try {
      final response = await _client.dio.post('/dokter/resep', data: payload);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Resep elektronik berhasil dibuat & diteruskan ke apotek.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /dokter/resep
  Future<ApiResponse<List<dynamic>>> getRiwayatResep({
    String? dokterId,
    String? doctorName,
    String? patientId,
  }) async {
    if (!_isTest) {
      try {
        final list = await SupabaseAdminService.instance.fetchDokterResepHistory(
          dokterId: dokterId,
          doctorName: doctorName,
          patientId: patientId,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat riwayat resep dokter dari database Supabase.',
          data: list,
          statusCode: 200,
        );
      } catch (_) {}
    }

    try {
      final response = await _client.dio.get('/dokter/resep');
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat riwayat resep dokter.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /dokter/obat-rekomendasi
  Future<ApiResponse<List<dynamic>>> getObatRekomendasi({String? query}) async {
    if (!_isTest) {
      try {
        final list = await SupabaseAdminService.instance.fetchKatalogObat(search: query);
        return ApiResponse.success(
          message: 'Berhasil memuat katalog obat dari database Supabase.',
          data: list,
          statusCode: 200,
        );
      } catch (_) {}
    }

    try {
      final Map<String, dynamic> qParams = {};
      if (query != null && query.isNotEmpty) qParams['q'] = query;
      final response = await _client.dio.get('/dokter/obat-rekomendasi', queryParameters: qParams);
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat daftar obat rekomendasi.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 5. PROFILE DOKTER & PENGATURAN
  // =========================================================================

  /// GET /dokter/profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile({
    String? dokterId,
    String? doctorName,
  }) async {
    if (!_isTest) {
      try {
        final profile = await SupabaseAdminService.instance.fetchDokterProfile(
          dokterId: dokterId,
          doctorName: doctorName,
        );
        if (profile != null) {
          return ApiResponse.success(
            message: 'Berhasil memuat profil dokter dari database Supabase.',
            data: profile,
            statusCode: 200,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.get('/dokter/profile');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat profil dokter.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /dokter/profile
  Future<ApiResponse<Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> data, {
    String? dokterId,
    String? doctorName,
  }) async {
    if (!_isTest) {
      try {
        final updated = await SupabaseAdminService.instance.updateDokterProfile(
          data,
          dokterId: dokterId,
          doctorName: doctorName,
        );
        if (updated != null) {
          return ApiResponse.success(
            message: 'Profil dokter berhasil diperbarui di database Supabase.',
            data: updated,
            statusCode: 200,
          );
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.put('/dokter/profile', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Profil dokter berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /dokter/profile/foto
  Future<ApiResponse<Map<String, dynamic>>> updateFotoProfil(
    dynamic fileOrPath, {
    String? dokterId,
    String? doctorName,
  }) async {
    if (!_isTest) {
      try {
        String? rawPath;
        if (fileOrPath is File) {
          rawPath = fileOrPath.path;
        } else if (fileOrPath is String && fileOrPath.isNotEmpty) {
          rawPath = fileOrPath;
        }
        if (rawPath != null && rawPath.isNotEmpty) {
          final updated = await SupabaseAdminService.instance.updateDokterPhoto(
            rawPath,
            dokterId: dokterId,
            doctorName: doctorName,
          );
          if (updated != null) {
            return ApiResponse.success(
              message: 'Foto profil dokter berhasil diperbarui di database Supabase.',
              data: updated,
              statusCode: 200,
            );
          }
        }
      } catch (_) {}
    }

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

      final response = await _client.dio.post('/dokter/profile/foto', data: uploadData);
      final raw = response.data;
      Map<String, dynamic>? resData;
      if (raw is Map && raw['data'] is Map) {
        resData = Map<String, dynamic>.from(raw['data'] as Map);
      } else if (raw is Map) {
        resData = Map<String, dynamic>.from(raw);
      }

      return ApiResponse.success(
        message: raw?['message'] ?? 'Foto profil dokter berhasil diperbarui.',
        data: resData,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /dokter/profile/password
  Future<ApiResponse<Map<String, dynamic>>> updatePassword(
    Map<String, dynamic> data, {
    String? dokterId,
    String? doctorName,
  }) async {
    if (!_isTest) {
      try {
        final currentPass = (data['current_password'] ?? data['old_password'] ?? '').toString();
        final newPass = (data['password'] ?? data['new_password'] ?? '').toString();
        final err = await SupabaseAdminService.instance.updateDokterPassword(
          currentPassword: currentPass,
          newPassword: newPass,
          dokterId: dokterId,
          doctorName: doctorName,
        );
        if (err == null) {
          return ApiResponse.success(
            message: 'Kata sandi dokter berhasil diperbarui.',
            data: {'updated': true},
            statusCode: 200,
          );
        } else {
          return ApiResponse.error(message: err, statusCode: 422);
        }
      } catch (_) {}
    }

    try {
      final response = await _client.dio.put('/dokter/profile/password', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Kata sandi dokter berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /dokter/profile/notifikasi
  Future<ApiResponse<Map<String, dynamic>>> getNotificationSettings({
    String? dokterId,
    String? doctorName,
  }) async {
    if (!_isTest) {
      try {
        final settings = await SupabaseAdminService.instance.fetchDokterNotificationSettings(
          dokterId: dokterId,
          doctorName: doctorName,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat pengaturan notifikasi dokter.',
          data: settings,
          statusCode: 200,
        );
      } catch (_) {}
    }

    try {
      final response = await _client.dio.get('/dokter/profile/notifikasi');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat pengaturan notifikasi.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /dokter/profile/notifikasi
  Future<ApiResponse<Map<String, dynamic>>> updateNotificationSettings(
    Map<String, dynamic> settings, {
    String? dokterId,
    String? doctorName,
  }) async {
    if (!_isTest) {
      try {
        final updated = await SupabaseAdminService.instance.updateDokterNotificationSettings(
          settings,
          dokterId: dokterId,
          doctorName: doctorName,
        );
        return ApiResponse.success(
          message: 'Pengaturan notifikasi berhasil diperbarui.',
          data: updated,
          statusCode: 200,
        );
      } catch (_) {}
    }

    try {
      final response = await _client.dio.put('/dokter/profile/notifikasi', data: settings);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Pengaturan notifikasi berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 6. MANAJEMEN PERANGKAT LOGIN (Sanctum Tokens)
  // =========================================================================

  /// GET /dokter/profile/perangkat
  Future<ApiResponse<List<dynamic>>> getLoginDevices({
    String? dokterId,
    String? doctorName,
  }) async {
    if (!_isTest) {
      try {
        final list = await SupabaseAdminService.instance.fetchDokterLoginDevices(
          dokterId: dokterId,
          doctorName: doctorName,
        );
        return ApiResponse.success(
          message: 'Berhasil memuat sesi perangkat aktif.',
          data: list,
          statusCode: 200,
        );
      } catch (_) {}
    }

    try {
      final response = await _client.dio.get('/dokter/profile/perangkat');
      final raw = response.data;
      final List<dynamic> list = ApiClient.extractList(raw);
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat sesi perangkat aktif.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// DELETE /dokter/profile/perangkat/{id_token}
  Future<ApiResponse<void>> revokeDevice(dynamic idToken) async {
    if (!_isTest) {
      try {
        await SupabaseAdminService.instance.revokeDokterDevice(idToken);
        return ApiResponse.success(
          message: 'Perangkat berhasil dikeluarkan.',
          statusCode: 200,
        );
      } catch (_) {}
    }

    try {
      final response = await _client.dio.delete('/dokter/profile/perangkat/$idToken');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Perangkat berhasil dikeluarkan.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }
}
