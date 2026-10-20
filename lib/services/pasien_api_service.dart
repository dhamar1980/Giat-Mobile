import 'dart:io';
import 'package:dio/dio.dart';
import '../models/pragi_model.dart';
import 'api_client.dart';
import 'api_response.dart';

/// Service for all Pasien, Pantau, PRAGI, Obat, Reminder, Edukasi, and Notifikasi endpoints
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

  /// GET /edukasi (fallback GET /pasien/edukasi)
  Future<ApiResponse<List<dynamic>>> getEdukasiList({String? kategori, String? search}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (kategori != null && kategori.isNotEmpty && kategori != 'Semua') {
        queryParams['kategori'] = kategori;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      dynamic response;
      try {
        response = await _client.dio.get('/edukasi', queryParameters: queryParams);
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404) {
          response = await _client.dio.get('/pasien/edukasi', queryParameters: queryParams);
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
        message: raw?['message'] ?? 'Berhasil memuat artikel edukasi.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /edukasi/kategori
  Future<ApiResponse<List<dynamic>>> getEdukasiKategori() async {
    try {
      final response = await _client.dio.get('/edukasi/kategori');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat kategori edukasi.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /edukasi/{id} (fallback GET /pasien/edukasi/{id})
  Future<ApiResponse<Map<String, dynamic>>> getEdukasiDetail(dynamic id) async {
    try {
      dynamic response;
      try {
        response = await _client.dio.get('/edukasi/$id');
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404) {
          response = await _client.dio.get('/pasien/edukasi/$id');
        } else {
          rethrow;
        }
      }
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

  /// GET /pasien/reminder/hari-ini
  Future<ApiResponse<List<dynamic>>> getRemindersHariIni() async {
    try {
      final response = await _client.dio.get('/pasien/reminder/hari-ini');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat pengingat hari ini.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /pasien/reminder/{id}
  Future<ApiResponse<Map<String, dynamic>>> getReminderDetail(dynamic id) async {
    try {
      final response = await _client.dio.get('/pasien/reminder/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat detail pengingat.',
        data: response.data?['data'] as Map<String, dynamic>?,
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

  /// POST /pasien/profile/foto (Key: 'image' & 'foto')
  Future<ApiResponse<Map<String, dynamic>>> updateFotoProfile(dynamic fileOrPath) async {
    try {
      dynamic uploadData;
      if (fileOrPath is File) {
        final bytes = await MultipartFile.fromFile(
          fileOrPath.path,
          filename: fileOrPath.path.split(Platform.pathSeparator).last,
        );
        uploadData = FormData.fromMap({
          'image': bytes,
          'foto': bytes,
        });
      } else if (fileOrPath is String && fileOrPath.isNotEmpty) {
        if (File(fileOrPath).existsSync()) {
          final bytes = await MultipartFile.fromFile(fileOrPath);
          uploadData = FormData.fromMap({
            'image': bytes,
            'foto': bytes,
          });
        } else {
          uploadData = {'foto_url': fileOrPath, 'image_url': fileOrPath};
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

  /// GET /pasien/pantau/{id}
  Future<ApiResponse<Map<String, dynamic>>> getPantauDetail(dynamic id) async {
    try {
      final response = await _client.dio.get('/pasien/pantau/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat detail pemantauan.',
        data: response.data?['data'] as Map<String, dynamic>?,
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

  /// PUT /pasien/pantau/{id}
  Future<ApiResponse<Map<String, dynamic>>> updatePantau(dynamic id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.put('/pasien/pantau/$id', data: data);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Catatan kondisi berhasil diperbarui.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// DELETE /pasien/pantau/{id}
  Future<ApiResponse<void>> deletePantau(dynamic id) async {
    try {
      final response = await _client.dio.delete('/pasien/pantau/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Catatan pemantauan berhasil dihapus.',
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

  /// GET /pasien/pantau/chart?limit=14
  Future<ApiResponse<Map<String, dynamic>>> getPantauChart({int limit = 14}) async {
    try {
      final response = await _client.dio.get('/pasien/pantau/chart', queryParameters: {'limit': limit});
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat grafik pantau.',
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

  /// GET /api/pasien/pragi/pertanyaan (fallback GET /api/pragi/pertanyaan)
  Future<ApiResponse<List<PragiPertanyaan>>> getPragiQuestions() async {
    try {
      dynamic response;
      try {
        response = await _client.dio.get('/pasien/pragi/pertanyaan');
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404) {
          response = await _client.dio.get('/pragi/pertanyaan');
        } else {
          rethrow;
        }
      }
      final raw = response.data;
      List<dynamic> list = [];
      if (raw is Map && raw['data'] is Map && raw['data']['pertanyaan'] is List) {
        list = raw['data']['pertanyaan'] as List;
      } else if (raw is Map && raw['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is Map && raw['pertanyaan'] is List) {
        list = raw['pertanyaan'] as List;
      } else if (raw is List) {
        list = raw;
      }

      final questions = list
          .map((item) => PragiPertanyaan.fromJson(
              item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map)))
          .toList();

      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat pertanyaan skrining PRAGI.',
        data: questions.isNotEmpty ? questions : PragiPertanyaan.default16Pertanyaan,
        statusCode: response.statusCode,
      );
    } catch (e) {
      // Graceful fallback to default 16 standard questions
      return ApiResponse.success(
        message: 'Menggunakan format pertanyaan standar PRAGI (${ApiClient.getErrorMessage(e)})',
        data: PragiPertanyaan.default16Pertanyaan,
      );
    }
  }

  /// POST /api/pasien/pragi/predict (fallback /api/pasien/pragi/skrining)
  /// Body: 16 biomarker features JSON directly (or wrapped in 'jawaban')
  Future<ApiResponse<PragiHasilSkrining>> submitPragiSkrining(Map<String, dynamic> answers) async {
    try {
      dynamic response;
      DioException? lastDioError;

      // Ensure answers map is flattened to 16 features if inadvertently passed with 'jawaban' key
      final Map<String, dynamic> directPayload = answers.containsKey('jawaban') && answers['jawaban'] is Map
          ? Map<String, dynamic>.from(answers['jawaban'])
          : answers;

      // 1. Try POST /pasien/pragi/predict with direct 16 features
      try {
        response = await _client.dio.post('/pasien/pragi/predict', data: directPayload);
      } on DioException catch (e1) {
        lastDioError = e1;
        // 2. Try POST /pasien/pragi/skrining with direct features
        try {
          response = await _client.dio.post('/pasien/pragi/skrining', data: directPayload);
        } on DioException catch (e2) {
          lastDioError = e2;
          // 3. Try with wrapped {"jawaban": ...} on /pasien/pragi/skrining if 422 or 400
          try {
            response = await _client.dio.post(
              '/pasien/pragi/skrining',
              data: {'jawaban': directPayload},
            );
          } on DioException catch (e3) {
            lastDioError = e3;
            // 4. Try public fallback /pragi/predict
            try {
              response = await _client.dio.post('/pragi/predict', data: directPayload);
            } on DioException catch (e4) {
              lastDioError = e4;
              // 5. Try public fallback /pragi/skrining
              try {
                response = await _client.dio.post('/pragi/skrining', data: directPayload);
              } on DioException catch (e5) {
                lastDioError = e5;
                rethrow;
              }
            }
          }
        }
      }

      final raw = response.data;
      final Map<String, dynamic> dataMap = (raw is Map && raw['data'] is Map)
          ? Map<String, dynamic>.from(raw['data'])
          : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});

      final hasil = PragiHasilSkrining.fromJson(dataMap);

      return ApiResponse.success(
        message: raw?['message'] ?? 'Skrining AI PRAGI berhasil diproses dan diprediksi.',
        data: hasil,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// Legacy submitPragi compatibility
  Future<ApiResponse<Map<String, dynamic>>> submitPragi(Map<String, dynamic> answers) async {
    try {
      final Map<String, dynamic> payload = answers.containsKey('jawaban')
          ? answers
          : {'jawaban': answers};

      dynamic response;
      try {
        response = await _client.dio.post('/pasien/pragi/skrining', data: payload);
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404) {
          response = await _client.dio.post('/pasien/skrining', data: payload);
        } else {
          rethrow;
        }
      }
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

  /// GET /pasien/pragi/riwayat/{id}
  Future<ApiResponse<Map<String, dynamic>>> getPragiDetail(dynamic id) async {
    try {
      final response = await _client.dio.get('/pasien/pragi/riwayat/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Berhasil memuat detail riwayat skrining.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /pasien/pragi/chat/history
  Future<ApiResponse<List<dynamic>>> getPragiChatHistory() async {
    try {
      final response = await _client.dio.get('/pasien/pragi/chat/history');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat riwayat obrolan PRAGI.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /pasien/pragi/chat
  /// Body: {"pesan": "..."}
  Future<ApiResponse<Map<String, dynamic>>> chatPragi(String message) async {
    try {
      final Map<String, dynamic> payload = {
        'pesan': message,
        'message': message,
      };
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

  /// DELETE /pasien/pragi/chat/history
  Future<ApiResponse<void>> deletePragiChatHistory() async {
    try {
      final response = await _client.dio.delete('/pasien/pragi/chat/history');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Riwayat percakapan berhasil direset.',
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
  Future<ApiResponse<List<dynamic>>> getObatList({String? query, String? kategori, String? search}) async {
    try {
      final Map<String, dynamic> qParams = {};
      final q = search ?? query;
      if (q != null && q.isNotEmpty) {
        qParams['search'] = q;
        qParams['q'] = q;
      }
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
  /// Body: {"id_obat": "...", "id_apotek": "...", "jumlah": 2, "alamat_pengiriman": "..."}
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

  /// POST /pasien/obat/checkout
  Future<ApiResponse<Map<String, dynamic>>> checkoutObat(Map<String, dynamic> payload) async {
    try {
      final response = await _client.dio.post('/pasien/obat/checkout', data: payload);
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Checkout obat berhasil diproses.',
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
  /// Body: {"id_resep": "...", "id_apotek": "...", "alamat_pengiriman": "..."}
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

  /// POST /pasien/obat/pesanan/{id}/batal
  Future<ApiResponse<Map<String, dynamic>>> batalkanPesanan(dynamic id, {required String alasan}) async {
    try {
      final response = await _client.dio.post(
        '/pasien/obat/pesanan/$id/batal',
        data: {'alasan': alasan},
      );
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Pesanan berhasil dibatalkan.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /pasien/obat/pesanan/{id}/selesai
  Future<ApiResponse<Map<String, dynamic>>> konfirmasiTerimaPesanan(dynamic id) async {
    try {
      final response = await _client.dio.post('/pasien/obat/pesanan/$id/selesai');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Penerimaan obat berhasil dikonfirmasi.',
        data: response.data?['data'] as Map<String, dynamic>?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 7. NOTIFIKASI
  // =========================================================================

  /// GET /notifikasi (fallback GET /pasien/notifikasi)
  Future<ApiResponse<List<dynamic>>> getNotifikasi() async {
    try {
      dynamic response;
      try {
        response = await _client.dio.get('/notifikasi');
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404) {
          response = await _client.dio.get('/pasien/notifikasi');
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
        message: raw?['message'] ?? 'Berhasil memuat notifikasi.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// GET /notifikasi/unread-count
  Future<ApiResponse<int>> getNotifikasiUnreadCount() async {
    try {
      final response = await _client.dio.get('/notifikasi/unread-count');
      int count = 0;
      final d = response.data?['data'];
      if (d is Map) {
        count = int.tryParse(d['unread_count']?.toString() ?? '0') ?? 0;
      } else if (d is int) {
        count = d;
      } else if (response.data?['unread_count'] != null) {
        count = int.tryParse(response.data['unread_count'].toString()) ?? 0;
      }
      return ApiResponse.success(
        data: count,
        message: response.data?['message'] ?? 'Berhasil memuat counter notifikasi.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// PATCH /notifikasi/{id}/read
  Future<ApiResponse<void>> markNotificationRead(dynamic id) async {
    try {
      final response = await _client.dio.patch('/notifikasi/$id/read');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Notifikasi ditandai dibaca.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// POST /notifikasi/read-all
  Future<ApiResponse<void>> markAllNotificationsRead() async {
    try {
      final response = await _client.dio.post('/notifikasi/read-all');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Semua notifikasi telah ditandai dibaca.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// DELETE /notifikasi/{id}
  Future<ApiResponse<void>> deleteNotification(dynamic id) async {
    try {
      final response = await _client.dio.delete('/notifikasi/$id');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Notifikasi berhasil dihapus.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  /// DELETE /notifikasi (Bersihkan semua notifikasi terbaca)
  Future<ApiResponse<void>> clearReadNotifications() async {
    try {
      final response = await _client.dio.delete('/notifikasi');
      return ApiResponse.success(
        message: response.data?['message'] ?? 'Notifikasi terbaca berhasil dibersihkan.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }

  // =========================================================================
  // 8. RIWAYAT KONSULTASI PASIEN
  // =========================================================================

  /// GET /pasien/konsultasi/riwayat (fallback GET /konsultasi/riwayat/pasien)
  Future<ApiResponse<List<dynamic>>> getRiwayatKonsultasi() async {
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
}
