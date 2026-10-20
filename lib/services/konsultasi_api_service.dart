import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_response.dart';
import 'storage_service.dart';

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

  /// GET /konsultasi/dokter (Bisa kirim query ?spesialisasi=... atau ?search=... atau ?kategori=...)
  Future<ApiResponse<List<dynamic>>> getDokterList({String? kategori, String? spesialisasi, String? search}) async {
    try {
      final Map<String, dynamic> qParams = {};
      final spec = spesialisasi ?? (kategori != 'Semua' ? kategori : null);
      if (spec != null && spec.isNotEmpty) {
        qParams['spesialisasi'] = spec;
        qParams['kategori'] = spec;
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
  /// Body: {"id_dokter": "...", "tanggal_konsultasi": "...", "isi_konsultasi": "..."}
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
  /// Body: {"metode_pembayaran": "qris"}
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
  // 2. CHAT KONSULTASI & VIDEO CALL
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
  /// Body: {"pesan": "...", "attachment": null}
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

  /// POST /konsultasi/{id}/video-call/end
  /// Body: {"durasi_menit": 15}
  Future<ApiResponse<Map<String, dynamic>>> endVideoCall(dynamic id, {int durasiMenit = 15}) async {
    try {
      final response = await _client.dio.post(
        '/konsultasi/$id/video-call/end',
        data: {'durasi_menit': durasiMenit},
      );
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Sesi video call telah diakhiri.',
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

  /// POST /konsultasi/{id}/batal
  /// Body: {"alasan": "..."}
  Future<ApiResponse<Map<String, dynamic>>> batalkanKonsultasi(dynamic id, {required String alasan}) async {
    try {
      final response = await _client.dio.post(
        '/konsultasi/$id/batal',
        data: {'alasan': alasan},
      );
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Sesi konsultasi berhasil dibatalkan.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /konsultasi/{id}/rating
  /// Body: {"rating": 5, "ulasan": "..."}
  Future<ApiResponse<Map<String, dynamic>>> beriRating(dynamic id, {required int rating, String? ulasan}) async {
    try {
      final response = await _client.dio.post(
        '/konsultasi/$id/rating',
        data: {
          'rating': rating,
          'ulasan': ulasan ?? '',
        },
      );
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Ulasan dan rating berhasil dikirim.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /konsultasi/dokter/{id}/rating atau POST /dokter/{id}/rating atau POST /ratings
  /// Menyimpan rating dan ulasan ke database Supabase (tabel: ulasan_dokter / konsultasi)
  Future<ApiResponse<Map<String, dynamic>>> beriRatingDokter({
    required dynamic doctorId,
    dynamic konsultasiId,
    required int rating,
    String? ulasan,
    String? namaPasien,
  }) async {
    try {
      final user = await StorageService().getUser();
      final payload = {
        'id_dokter': doctorId,
        'dokter_id': doctorId,
        'id_pasien': user?.id,
        'nama_pasien': namaPasien ?? user?.nama,
        'rating': rating,
        'ulasan': ulasan ?? '',
      };
      if (konsultasiId != null) {
        payload['id_konsultasi'] = konsultasiId;
        payload['konsultasi_id'] = konsultasiId;
      }

      dynamic response;
      if (konsultasiId != null) {
        response = await _client.dio.post('/konsultasi/$konsultasiId/rating', data: payload);
      } else {
        try {
          response = await _client.dio.post('/konsultasi/dokter/$doctorId/rating', data: payload);
        } on DioException catch (dioErr) {
          if (dioErr.response?.statusCode == 404) {
            try {
              response = await _client.dio.post('/dokter/$doctorId/rating', data: payload);
            } on DioException catch (dioErr2) {
              if (dioErr2.response?.statusCode == 404) {
                response = await _client.dio.post('/ratings', data: payload);
              } else {
                rethrow;
              }
            }
          } else {
            rethrow;
          }
        }
      }

      return ApiResponse.success(
        message: response.data?['message'] ?? 'Penilaian dokter berhasil disimpan ke database.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /konsultasi/{id}/resep
  Future<ApiResponse<Map<String, dynamic>>> getResepKonsultasi(dynamic id) async {
    try {
      final response = await _client.dio.get('/konsultasi/$id/resep');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat resep hasil konsultasi.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 3. RIWAYAT KONSULTASI
  // =========================================================================

  /// GET /pasien/konsultasi/riwayat (fallback GET /konsultasi/riwayat/pasien)
  Future<ApiResponse<List<dynamic>>> getRiwayatPasien() async {
    try {
      dynamic response;
      try {
        response = await _client.dio.get('/pasien/konsultasi/riwayat');
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404) {
          response = await _client.dio.get('/konsultasi/riwayat/pasien');
        } else {
          rethrow;
        }
      }
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
