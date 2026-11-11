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

  /// GET /dokter/notifikasi
  Future<ApiResponse<List<dynamic>>> getNotifikasi() async {
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

  // =========================================================================
  // 2. JADWAL KONSULTASI
  // =========================================================================

  /// GET /dokter/jadwal
  Future<ApiResponse<List<dynamic>>> getJadwal({String? date}) async {
    try {
      final Map<String, dynamic> qParams = {};
      if (date != null && date.isNotEmpty) qParams['date'] = date;
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
  Future<ApiResponse<List<dynamic>>> getRiwayatResep() async {
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
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
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
  Future<ApiResponse<Map<String, dynamic>>> updateProfile(Map<String, dynamic> data) async {
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
  Future<ApiResponse<Map<String, dynamic>>> updateFotoProfil(dynamic fileOrPath) async {
    try {
      dynamic uploadData;
      if (fileOrPath is File) {
        uploadData = FormData.fromMap({
          'foto': await MultipartFile.fromFile(
            fileOrPath.path,
            filename: fileOrPath.path.split(Platform.pathSeparator).last,
          ),
        });
      } else if (fileOrPath is String && fileOrPath.isNotEmpty) {
        if (File(fileOrPath).existsSync()) {
          uploadData = FormData.fromMap({
            'foto': await MultipartFile.fromFile(fileOrPath),
          });
        } else {
          uploadData = {'foto_url': fileOrPath};
        }
      }

      final response = await _client.dio.post('/dokter/profile/foto', data: uploadData);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Foto profil dokter berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /dokter/profile/password
  Future<ApiResponse<Map<String, dynamic>>> updatePassword(Map<String, dynamic> data) async {
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

  /// PUT /dokter/profile/notifikasi
  Future<ApiResponse<Map<String, dynamic>>> updateNotificationSettings(Map<String, dynamic> settings) async {
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
  Future<ApiResponse<List<dynamic>>> getLoginDevices() async {
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
