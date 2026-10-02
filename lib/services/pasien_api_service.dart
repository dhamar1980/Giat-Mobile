import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_response.dart';

/// Service for all `/pasien` API endpoints
class PasienApiService {
  static final PasienApiService _instance = PasienApiService._internal();
  factory PasienApiService() => _instance;
  PasienApiService._internal();

  final ApiClient _client = ApiClient();

  // =========================================================================
  // 1. HOME & EDUKASI KESEHATAN
  // =========================================================================

  /// GET /pasien/home
  Future<ApiResponse<Map<String, dynamic>>> getHome() async {
    try {
      final response = await _client.dio.get('/pasien/home');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat data home pasien.',
        data: response.data?['data'] is Map<String, dynamic>
            ? response.data['data'] as Map<String, dynamic>
            : null,
        statusCode: response.statusCode,
        rawData: response.data is Map<String, dynamic> ? response.data : null,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /pasien/edukasi
  Future<ApiResponse<List<dynamic>>> getEdukasiList({String? kategori}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (kategori != null && kategori.isNotEmpty && kategori != 'Semua') {
        queryParams['kategori'] = kategori;
      }
      final response = await _client.dio.get('/pasien/edukasi', queryParameters: queryParams);
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat artikel edukasi.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /pasien/edukasi/{id}
  Future<ApiResponse<Map<String, dynamic>>> getEdukasiDetail(dynamic id) async {
    try {
      final response = await _client.dio.get('/pasien/edukasi/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat detail artikel.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 2. REMINDER PENGINGAT MINUM OBAT
  // =========================================================================

  /// GET /pasien/reminder
  Future<ApiResponse<List<dynamic>>> getReminders() async {
    try {
      final response = await _client.dio.get('/pasien/reminder');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat jadwal pengingat.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /pasien/reminder
  Future<ApiResponse<Map<String, dynamic>>> createReminder(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/pasien/reminder', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Pengingat berhasil disimpan.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /pasien/reminder/{id}
  Future<ApiResponse<Map<String, dynamic>>> updateReminder(dynamic id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/pasien/reminder/$id', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Pengingat berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PATCH /pasien/reminder/{id}/toggle
  Future<ApiResponse<Map<String, dynamic>>> toggleReminder(dynamic id) async {
    try {
      final response = await _client.dio.patch('/pasien/reminder/$id/toggle');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Status pengingat berhasil diubah.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// DELETE /pasien/reminder/{id}
  Future<ApiResponse<void>> deleteReminder(dynamic id) async {
    try {
      final response = await _client.dio.delete('/pasien/reminder/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Pengingat berhasil dihapus.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 3. PROFILE, KONTAK, PASSWORD & FOTO PROFIL
  // =========================================================================

  /// GET /pasien/profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    try {
      final response = await _client.dio.get('/pasien/profile');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat profil pasien.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /pasien/profile
  Future<ApiResponse<Map<String, dynamic>>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/pasien/profile', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Profil berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /pasien/profile/nohp
  Future<ApiResponse<Map<String, dynamic>>> updateNoHp(String noHp) async {
    try {
      final response = await _client.dio.put(
        '/pasien/profile/nohp',
        data: {'no_hp': noHp.trim()},
      );
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Nomor HP berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /pasien/profile/email
  Future<ApiResponse<Map<String, dynamic>>> updateEmail(String email) async {
    try {
      final response = await _client.dio.put(
        '/pasien/profile/email',
        data: {'email': email.trim().toLowerCase()},
      );
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Email berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PUT /pasien/profile/password
  Future<ApiResponse<Map<String, dynamic>>> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _client.dio.put(
        '/pasien/profile/password',
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
      );
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Kata sandi berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /pasien/profile/foto
  Future<ApiResponse<Map<String, dynamic>>> updateFotoProfile(dynamic fileOrPath) async {
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

      final response = await _client.dio.post('/pasien/profile/foto', data: uploadData);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Foto profil berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 4. PANTAU (KONDISI HARIAN GINJAL & BERAT BADAN/IMT)
  // =========================================================================

  /// GET /pasien/pantau
  Future<ApiResponse<List<dynamic>>> getPantauHistory() async {
    try {
      final response = await _client.dio.get('/pasien/pantau');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat riwayat pemantauan.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /pasien/pantau
  Future<ApiResponse<Map<String, dynamic>>> storePantau(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/pasien/pantau', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Catatan kondisi berhasil disimpan.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /pasien/pantau/summary
  Future<ApiResponse<Map<String, dynamic>>> getPantauSummary() async {
    try {
      final response = await _client.dio.get('/pasien/pantau/summary');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat ringkasan pantau.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 5. PRAGI (SKRINING RISIKO CKD & CHATBOT AI PRAGI)
  // =========================================================================

  /// GET /pasien/pragi/pertanyaan
  Future<ApiResponse<List<dynamic>>> getPragiQuestions() async {
    try {
      final response = await _client.dio.get('/pasien/pragi/pertanyaan');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat pertanyaan skrining PRAGI.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /pasien/skrining
  Future<ApiResponse<Map<String, dynamic>>> submitPragi(Map<String, dynamic> answers) async {
    try {
      final response = await _client.dio.post('/pasien/skrining', data: answers);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Hasil skrining berhasil diproses.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /pasien/pragi/riwayat
  Future<ApiResponse<List<dynamic>>> getPragiHistory() async {
    try {
      final response = await _client.dio.get('/pasien/pragi/riwayat');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat riwayat skrining PRAGI.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /pasien/pragi/chat
  Future<ApiResponse<Map<String, dynamic>>> chatPragi(
    String message, {
    List<Map<String, String>>? history,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'message': message,
      };
      if (history != null && history.isNotEmpty) {
        payload['history'] = history;
      }
      final response = await _client.dio.post('/pasien/pragi/chat', data: payload);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Respon PRAGI berhasil diterima.',
        data: response.data?['data'] is Map<String, dynamic>
            ? response.data['data'] as Map<String, dynamic>
            : (response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null),
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 6. OBAT (KATALOG, BELI UMUM, RESEP, RIWAYAT & LACAK)
  // =========================================================================

  /// GET /pasien/obat/katalog
  Future<ApiResponse<List<dynamic>>> getObatList({String? query, String? kategori}) async {
    try {
      final Map<String, dynamic> qParams = {};
      if (query != null && query.isNotEmpty) qParams['q'] = query;
      if (kategori != null && kategori.isNotEmpty && kategori != 'Semua') {
        qParams['kategori'] = kategori;
      }
      final response = await _client.dio.get('/pasien/obat/katalog', queryParameters: qParams);
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat katalog obat.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /pasien/obat/katalog/{id}
  Future<ApiResponse<Map<String, dynamic>>> getObatDetail(dynamic id) async {
    try {
      final response = await _client.dio.get('/pasien/obat/katalog/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat rincian obat.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /pasien/obat/beli-umum
  Future<ApiResponse<Map<String, dynamic>>> beliObatUmum(Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.post('/pasien/obat/beli-umum', data: payload);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Pesanan obat berhasil dibuat.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /pasien/obat/resep-saya
  Future<ApiResponse<List<dynamic>>> getResepPasien() async {
    try {
      final response = await _client.dio.get('/pasien/obat/resep-saya');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat resep dokter Anda.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /pasien/obat/beli-resep
  Future<ApiResponse<Map<String, dynamic>>> beliObatResep(Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.post('/pasien/obat/beli-resep', data: payload);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Penebusan resep berhasil diajukan.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /pasien/obat/riwayat-pembelian
  Future<ApiResponse<List<dynamic>>> getRiwayatPembelian() async {
    try {
      final response = await _client.dio.get('/pasien/obat/riwayat-pembelian');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat riwayat pembelian obat.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /pasien/obat/pesanan/{id}
  Future<ApiResponse<Map<String, dynamic>>> getDetailPesanan(dynamic id) async {
    try {
      final response = await _client.dio.get('/pasien/obat/pesanan/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat detail pesanan obat.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /pasien/obat/lacak/{id}
  Future<ApiResponse<Map<String, dynamic>>> lacakPesanan(dynamic id) async {
    try {
      final response = await _client.dio.get('/pasien/obat/lacak/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil melacak status pesanan obat.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 7. NOTIFIKASI & RIWAYAT KONSULTASI PASIEN
  // =========================================================================

  /// GET /pasien/notifikasi
  Future<ApiResponse<List<dynamic>>> getNotifikasi() async {
    try {
      final response = await _client.dio.get('/pasien/notifikasi');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat notifikasi pasien.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /pasien/konsultasi/riwayat
  Future<ApiResponse<List<dynamic>>> getRiwayatKonsultasi() async {
    try {
      final response = await _client.dio.get('/pasien/konsultasi/riwayat');
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
}
