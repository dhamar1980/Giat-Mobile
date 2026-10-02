import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_response.dart';

/// Service for all `/konsultasi` API endpoints
class KonsultasiApiService {
  static final KonsultasiApiService _instance = KonsultasiApiService._internal();
  factory KonsultasiApiService() => _instance;
  KonsultasiApiService._internal();

  final ApiClient _client = ApiClient();

  // =========================================================================
  // 1. INFORMASI DOKTER & BOOKING
  // =========================================================================

  /// GET /konsultasi/kategori-dokter
  Future<ApiResponse<List<dynamic>>> getKategoriDokter() async {
    try {
      final response = await _client.dio.get('/konsultasi/kategori-dokter');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat kategori dokter.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /konsultasi/dokter
  Future<ApiResponse<List<dynamic>>> getDokterList({String? kategori, String? search}) async {
    try {
      final Map<String, dynamic> qParams = {};
      if (kategori != null && kategori.isNotEmpty && kategori != 'Semua') {
        qParams['kategori'] = kategori;
      }
      if (search != null && search.isNotEmpty) {
        qParams['search'] = search;
      }
      final response = await _client.dio.get('/konsultasi/dokter', queryParameters: qParams);
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat daftar dokter.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /konsultasi/dokter/{id}
  Future<ApiResponse<Map<String, dynamic>>> getDokterDetail(dynamic id) async {
    try {
      final response = await _client.dio.get('/konsultasi/dokter/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat profil dokter.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /konsultasi/booking
  Future<ApiResponse<Map<String, dynamic>>> bookingDokter(Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.post('/konsultasi/booking', data: payload);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Booking jadwal konsultasi berhasil dibuat.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /konsultasi/{id}
  Future<ApiResponse<Map<String, dynamic>>> getDetailKonsultasi(dynamic id) async {
    try {
      final response = await _client.dio.get('/konsultasi/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat rincian konsultasi.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /konsultasi/{id}/bayar
  Future<ApiResponse<Map<String, dynamic>>> bayarKonsultasi(dynamic id, Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.post('/konsultasi/$id/bayar', data: payload);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Instruksi pembayaran berhasil diproses.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /konsultasi/{id}/status-bayar
  Future<ApiResponse<Map<String, dynamic>>> cekStatusPembayaran(dynamic id) async {
    try {
      final response = await _client.dio.get('/konsultasi/$id/status-bayar');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memeriksa status pembayaran.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 2. CHAT KONSULTASI REALTIME & VIDEO CALL
  // =========================================================================

  /// GET /konsultasi/{id}/pesan
  Future<ApiResponse<List<dynamic>>> getMessages(dynamic id) async {
    try {
      final response = await _client.dio.get('/konsultasi/$id/pesan');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat pesan chat.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /konsultasi/{id}/pesan
  Future<ApiResponse<Map<String, dynamic>>> sendMessage(
    dynamic id, {
    required String pesan,
    dynamic attachment,
  }) async {
    try {
      dynamic payload;
      if (attachment != null && attachment is File) {
        payload = FormData.fromMap({
          'pesan': pesan,
          'attachment': await MultipartFile.fromFile(
            attachment.path,
            filename: attachment.path.split(Platform.pathSeparator).last,
          ),
        });
      } else {
        final Map<String, dynamic> data = {'pesan': pesan};
        if (attachment != null) {
          data['attachment'] = attachment;
        }
        payload = data;
      }

      final response = await _client.dio.post('/konsultasi/$id/pesan', data: payload);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Pesan berhasil terkirim.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /konsultasi/{id}/video-call
  Future<ApiResponse<Map<String, dynamic>>> getVideoCall(dynamic id) async {
    try {
      final response = await _client.dio.get('/konsultasi/$id/video-call');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat sesi video call.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /konsultasi/{id}/selesai
  Future<ApiResponse<Map<String, dynamic>>> selesaikanKonsultasi(dynamic id) async {
    try {
      final response = await _client.dio.post('/konsultasi/$id/selesai');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Sesi konsultasi telah diselesaikan.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 3. RIWAYAT KONSULTASI PER PENGGUNA
  // =========================================================================

  /// GET /konsultasi/riwayat/pasien
  Future<ApiResponse<List<dynamic>>> getRiwayatPasien() async {
    try {
      final response = await _client.dio.get('/konsultasi/riwayat/pasien');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat riwayat konsultasi pasien.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /konsultasi/riwayat/dokter
  Future<ApiResponse<List<dynamic>>> getRiwayatDokter() async {
    try {
      final response = await _client.dio.get('/konsultasi/riwayat/dokter');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat riwayat konsultasi dokter.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }
}
