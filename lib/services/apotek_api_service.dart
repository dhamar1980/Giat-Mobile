import 'api_client.dart';
import 'api_response.dart';

/// Service for all `/apotek` API endpoints
class ApotekApiService {
  static final ApotekApiService _instance = ApotekApiService._internal();
  factory ApotekApiService() => _instance;
  ApotekApiService._internal();

  final ApiClient _client = ApiClient();

  // =========================================================================
  // 1. DASHBOARD & NOTIFIKASI
  // =========================================================================

  /// GET /apotek/dashboard
  Future<ApiResponse<Map<String, dynamic>>> getDashboard() async {
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

  /// GET /apotek/notifikasi
  Future<ApiResponse<List<dynamic>>> getNotifikasi() async {
    try {
      final response = await _client.dio.get('/apotek/notifikasi');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat notifikasi apotek.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
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
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
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
  // 3. PESANAN OBAT PASIEN
  // =========================================================================

  /// GET /apotek/pesanan
  Future<ApiResponse<List<dynamic>>> getPesananList({String? status}) async {
    try {
      final Map<String, dynamic> qParams = {};
      if (status != null && status.isNotEmpty) qParams['status'] = status;
      final response = await _client.dio.get('/apotek/pesanan', queryParameters: qParams);
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
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
  // 4. RESEP DOKTER
  // =========================================================================

  /// GET /apotek/resep
  Future<ApiResponse<List<dynamic>>> getPesananResep() async {
    try {
      final response = await _client.dio.get('/apotek/resep');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
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
  Future<ApiResponse<Map<String, dynamic>>> validasiDanTerimaResep(dynamic id) async {
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
  // 5. OBAT & STOK OBAT
  // =========================================================================

  /// GET /apotek/obat
  Future<ApiResponse<List<dynamic>>> getDaftarObat({String? query}) async {
    try {
      final Map<String, dynamic> qParams = {};
      if (query != null && query.isNotEmpty) qParams['q'] = query;
      final response = await _client.dio.get('/apotek/obat', queryParameters: qParams);
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
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
  Future<ApiResponse<List<dynamic>>> getStockObat() async {
    try {
      final response = await _client.dio.get('/apotek/obat/stock');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
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
  Future<ApiResponse<Map<String, dynamic>>> tambahObat(Map<String, dynamic> data) async {
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
  Future<ApiResponse<Map<String, dynamic>>> updateStock(Map<String, dynamic> data) async {
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
  // 6. PROFILE, OPERASIONAL & AREA LAYANAN
  // =========================================================================

  /// GET /apotek/profile
  Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
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
  Future<ApiResponse<List<dynamic>>> getJamOperasional() async {
    try {
      final response = await _client.dio.get('/apotek/jam-operasional');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
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
  Future<ApiResponse<List<dynamic>>> getAreaLayanan() async {
    try {
      final response = await _client.dio.get('/apotek/area-layanan');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
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
  Future<ApiResponse<Map<String, dynamic>>> toggleStatusLayanan() async {
    try {
      final response = await _client.dio.patch('/apotek/status-layanan');
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
  Future<ApiResponse<List<dynamic>>> getRiwayatAktivitas() async {
    try {
      final response = await _client.dio.get('/apotek/aktivitas');
      final raw = response.data;
      List<dynamic> list = [];
      if (raw?['data'] is List) {
        list = raw['data'] as List;
      } else if (raw is List) {
        list = raw;
      }
      return ApiResponse.success(
        message: raw?['message'] ?? 'Berhasil memuat riwayat aktivitas.',
        data: list,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error(message: ApiClient.getErrorMessage(e));
    }
  }
}
