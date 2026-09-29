import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

/// Singleton Dio HTTP client configured with Sanctum Bearer token interceptor
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      ),
    );

    // Setup interceptors
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Keep baseUrl in sync with ApiConfig
          if (!options.path.startsWith('http')) {
            options.baseUrl = ApiConfig.baseUrl;
          }

          // Attach Sanctum Bearer token if present
          final token = await StorageService().getToken();
          if (token != null && token.isNotEmpty) {
            options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
          }

          debugPrint('🌐 [API Request] ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ [API Response] ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          debugPrint('❌ [API Error] ${error.response?.statusCode} ${error.requestOptions.path}: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  /// Helper to extract user-friendly error message from DioException or Backend response
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Koneksi ke server timeout. Pastikan backend GIAT sedang berjalan dan URL sesuai (${ApiConfig.baseUrl}).';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Gagal terhubung ke server backend (${ApiConfig.baseUrl}). Periksa koneksi internet atau IP server.';
      }

      final response = error.response;
      if (response != null && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // 1. Cek validasi errors Laravel (e.g. {"errors": {"email": ["Email sudah digunakan"]}})
          if (data.containsKey('errors') && data['errors'] is Map) {
            final Map errors = data['errors'] as Map;
            final List<String> messages = [];
            errors.forEach((key, val) {
              if (val is List && val.isNotEmpty) {
                messages.add(val.first.toString());
              } else if (val is String) {
                messages.add(val);
              }
            });
            if (messages.isNotEmpty) {
              return messages.join('\n');
            }
          }

          // 2. Cek pesan langsung dari backend (message)
          if (data.containsKey('message') && data['message'] is String) {
            return data['message'] as String;
          }

          // 3. Cek error key
          if (data.containsKey('error') && data['error'] is String) {
            return data['error'] as String;
          }
        }
      }

      final status = response?.statusCode;
      if (status == 401) {
        return 'Sesi tidak valid atau kredensial salah.';
      } else if (status == 403) {
        return 'Akses ditolak untuk peran pengguna ini.';
      } else if (status == 404) {
        return 'Endpoint atau data tidak ditemukan di server.';
      } else if (status == 500) {
        return 'Terjadi kesalahan pada server backend (500 Internal Server Error).';
      }

      return error.message ?? 'Terjadi kesalahan jaringan.';
    }

    return error?.toString() ?? 'Terjadi kesalahan yang tidak diketahui.';
  }
}
