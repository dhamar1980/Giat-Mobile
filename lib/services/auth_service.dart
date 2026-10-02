import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'storage_service.dart';

/// Authentication Service integrating Firebase Auth, Google Sign-In, and GIAT Laravel Backend.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storage = StorageService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// 1. Masuk dengan Google (Google Sign-In -> kirim idToken ke Backend)
  /// Endpoint: POST /auth/firebase/google
  Future<AuthResult> signInWithGoogle({String role = 'pasien'}) async {
    try {
      // 1. Trigger Google Sign-In UI
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        return AuthResult(
          success: false,
          message: 'Proses Google Sign-In dibatalkan oleh pengguna.',
        );
      }

      // 2. Dapatkan token otentikasi dari Google
      final GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
      String? idToken = googleAuth.idToken;

      // 3. Jika Firebase Auth aktif, daftarkan juga credential ke Firebase SDK
      try {
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final firebaseIdToken = await userCredential.user?.getIdToken();
        if (firebaseIdToken != null && firebaseIdToken.isNotEmpty) {
          idToken = firebaseIdToken;
        }
      } catch (fbErr) {
        debugPrint('Firebase Auth link notice (menggunakan token Google): $fbErr');
      }

      if (idToken == null || idToken.isEmpty) {
        return AuthResult(
          success: false,
          message: 'Gagal mendapatkan ID Token dari Google. Pastikan Google Play Services aktif.',
        );
      }

      // 4. Kirim ID Token ke endpoint Backend GIAT
      final response = await _apiClient.dio.post(
        '/auth/firebase/google',
        data: {
          'id_token': idToken,
          'role': role,
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final resultData = data['data'] as Map<String, dynamic>;
        final String token = resultData['access_token'] ?? '';
        final String resolvedRole = resultData['role'] ?? role;
        final userData = resultData['user'] as Map<String, dynamic>? ?? {};

        final user = UserModel.fromJson(userData, defaultRole: resolvedRole);

        // Simpan sesi login ke penyimpanan aman
        await _storage.saveToken(token);
        await _storage.saveUser(user);
        await _storage.saveRole(resolvedRole);

        return AuthResult(
          success: true,
          message: data['message'] ?? 'Login dengan Google berhasil.',
          user: user,
          token: token,
          role: resolvedRole,
        );
      } else {
        return AuthResult(
          success: false,
          message: data?['message'] ?? 'Gagal memverifikasi akun Google pada backend GIAT.',
        );
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return AuthResult(
        success: false,
        message: ApiClient.getErrorMessage(e),
      );
    }
  }

  /// 2. Native Login (Email & Password)
  /// Endpoint: POST /auth/firebase/login dengan fallback POST /auth/login
  Future<AuthResult> loginWithEmailPassword({
    required String email,
    required String password,
    String? role,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'email': email.trim().toLowerCase(),
        'password': password,
      };
      if (role != null && role.isNotEmpty) {
        payload['role'] = role;
      }

      dynamic response;
      try {
        response = await _apiClient.dio.post(
          '/auth/firebase/login',
          data: payload,
        );
      } on DioException catch (fbErr) {
        final statusCode = fbErr.response?.statusCode;
        // Jika backend Firebase merespons penolakan kredensial / validasi (misal status 400, 401, 403, 422),
        // itu adalah respon resmi validasi dari Firebase (seperti "Akun tidak ditemukan di Firebase" atau "Password salah").
        // Lempar kembali error ini agar pesan error asli Firebase langsung ditampilkan ke pengguna.
        if (statusCode != null && statusCode != 404 && statusCode < 500) {
          rethrow;
        }

        // Hanya coba fallback ke /auth/login jika route Firebase 404 (tidak tersedia) atau 500
        debugPrint('Firebase endpoint unavailable ($statusCode), trying standard /auth/login: $fbErr');
        response = await _apiClient.dio.post(
          '/auth/login',
          data: payload,
        );
      }

      final data = response.data;
      if (data != null && data['success'] == true) {
        final resultData = data['data'] as Map<String, dynamic>;
        final String token = resultData['access_token'] ?? '';
        final String backendRole = (resultData['role'] as String?)?.toLowerCase() ?? (role ?? 'pasien');
        final userData = resultData['user'] as Map<String, dynamic>? ?? {};

        final user = UserModel.fromJson(userData, defaultRole: backendRole);
        final String finalRole = user.role;

        // Simpan ke storage aman
        await _storage.saveToken(token);
        await _storage.saveUser(user);
        await _storage.saveRole(finalRole);

        // Opsional: sinkronkan sesi FirebaseAuth lokal
        if (!Platform.environment.containsKey('FLUTTER_TEST')) {
          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email.trim().toLowerCase(),
              password: password,
            );
          } catch (_) {}
        }

        return AuthResult(
          success: true,
          message: data['message'] ?? 'Login berhasil.',
          user: user,
          token: token,
          role: finalRole,
        );
      } else {
        return AuthResult(
          success: false,
          message: data?['message'] ?? 'Email atau kata sandi tidak valid.',
        );
      }
    } catch (e) {
      debugPrint('Email/Password Login Error: $e');
      return AuthResult(
        success: false,
        message: ApiClient.getErrorMessage(e),
      );
    }
  }

  /// 3. Native Firebase Register Pasien
  /// Endpoint: POST /auth/firebase/register
  Future<AuthResult> registerPasien({
    required String nama,
    required String email,
    required String password,
    required String noHp,
    required String jenisKelamin,
    String? nik,
    String? alamat,
    String role = 'pasien',
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'nama': nama.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
        'no_hp': noHp.trim(),
        'jenis_kelamin': jenisKelamin,
      };

      if (nik != null && nik.trim().isNotEmpty) {
        payload['NIK'] = nik.trim();
      }
      if (alamat != null && alamat.trim().isNotEmpty) {
        payload['alamat'] = alamat.trim();
      }

      final response = await _apiClient.dio.post(
        '/auth/firebase/register',
        data: payload,
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final resultData = data['data'] as Map<String, dynamic>? ?? {};
        final String token = resultData['access_token'] ?? '';
        final String resolvedRole = resultData['role'] ?? role;
        final userData = resultData['user'] as Map<String, dynamic>? ?? {};

        final user = UserModel.fromJson(userData, defaultRole: resolvedRole);

        if (token.isNotEmpty) {
          await _storage.saveToken(token);
          await _storage.saveUser(user);
          await _storage.saveRole(resolvedRole);
        }

        return AuthResult(
          success: true,
          message: data['message'] ?? 'Pendaftaran akun berhasil.',
          user: user,
          token: token,
          role: resolvedRole,
        );
      } else {
        return AuthResult(
          success: false,
          message: data?['message'] ?? 'Pendaftaran akun gagal.',
        );
      }
    } catch (e) {
      debugPrint('Register Error: $e');
      return AuthResult(
        success: false,
        message: ApiClient.getErrorMessage(e),
      );
    }
  }

  /// 4. Verifikasi Token Firebase Langsung
  /// Endpoint: POST /auth/firebase/verify-token
  Future<AuthResult> verifyFirebaseToken({
    required String idToken,
    String role = 'pasien',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/firebase/verify-token',
        data: {
          'id_token': idToken,
          'role': role,
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final resultData = data['data'] as Map<String, dynamic>;
        final String token = resultData['access_token'] ?? '';
        final String resolvedRole = resultData['role'] ?? role;
        final userData = resultData['user'] as Map<String, dynamic>? ?? {};

        final user = UserModel.fromJson(userData, defaultRole: resolvedRole);

        await _storage.saveToken(token);
        await _storage.saveUser(user);
        await _storage.saveRole(resolvedRole);

        return AuthResult(
          success: true,
          message: data['message'] ?? 'Verifikasi token berhasil.',
          user: user,
          token: token,
          role: resolvedRole,
        );
      } else {
        return AuthResult(
          success: false,
          message: data?['message'] ?? 'Verifikasi token gagal.',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: ApiClient.getErrorMessage(e),
      );
    }
  }

  /// 5. Cek Sesi Login Akun Saat Ini
  /// Endpoint: GET /me
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/me');
      final data = response.data;
      if (data != null && data['success'] == true) {
        final resultData = data['data'] as Map<String, dynamic>;
        final userData = resultData['user'] as Map<String, dynamic>? ?? {};
        final role = resultData['role'] as String? ?? 'pasien';

        final user = UserModel.fromJson(userData, defaultRole: role);
        await _storage.saveUser(user);
        await _storage.saveRole(user.role);
        return user;
      }
    } catch (e) {
      debugPrint('GetCurrentUser error: $e');
    }
    return null;
  }

  /// 6. Logout dan Hapus Sesi
  Future<void> logout() async {
    // 1. Bersihkan token & sesi lokal terlebih dahulu agar status segera offline/keluar
    await _storage.clearAuth();

    // 2. Beritahu server backend & bersihkan sesi Firebase/Google di latar belakang
    try {
      _apiClient.dio.post('/auth/logout').timeout(const Duration(seconds: 2)).catchError((_) {
        return Response(requestOptions: RequestOptions(path: '/auth/logout'));
      });
    } catch (_) {}

    try {
      FirebaseAuth.instance.signOut().catchError((_) {});
    } catch (_) {}

    try {
      _googleSignIn.signOut().catchError((_) => null);
    } catch (_) {}
  }

  /// 7. Register Dokter
  /// Endpoint: POST /auth/register/dokter
  Future<AuthResult> registerDokter({
    required String nama,
    required String email,
    required String password,
    required String noHp,
    String? noStr,
    String? noSip,
    String? spesialisasi,
    String? instansi,
    String? jenisKelamin,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'nama': nama.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': 'dokter',
        'no_hp': noHp.trim(),
      };
      if (noStr != null) payload['no_str'] = noStr.trim();
      if (noSip != null) payload['no_sip'] = noSip.trim();
      if (spesialisasi != null) payload['spesialisasi'] = spesialisasi.trim();
      if (instansi != null) payload['instansi'] = instansi.trim();
      if (jenisKelamin != null) payload['jenis_kelamin'] = jenisKelamin;

      final response = await _apiClient.dio.post('/auth/register/dokter', data: payload);
      final data = response.data;
      if (data != null && data['success'] == true) {
        final resultData = data['data'] as Map<String, dynamic>? ?? {};
        final String token = resultData['access_token'] ?? '';
        final userData = resultData['user'] as Map<String, dynamic>? ?? {};
        final user = UserModel.fromJson(userData, defaultRole: 'dokter');

        if (token.isNotEmpty) {
          await _storage.saveToken(token);
          await _storage.saveUser(user);
          await _storage.saveRole('dokter');
        }

        return AuthResult(
          success: true,
          message: data['message'] ?? 'Pendaftaran dokter berhasil.',
          user: user,
          token: token,
          role: 'dokter',
        );
      }
      return AuthResult(success: false, message: data?['message'] ?? 'Pendaftaran dokter gagal.');
    } catch (e) {
      return AuthResult(success: false, message: ApiClient.getErrorMessage(e));
    }
  }

  /// 8. Register Apotek
  /// Endpoint: POST /auth/register/apotek
  Future<AuthResult> registerApotek({
    required String nama,
    required String email,
    required String password,
    required String noHp,
    String? namaApotek,
    String? noSia,
    String? noSipa,
    String? alamat,
    String? jamOperasional,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'nama': nama.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': 'apotek',
        'no_hp': noHp.trim(),
      };
      if (namaApotek != null) payload['nama_apotek'] = namaApotek.trim();
      if (noSia != null) payload['no_sia'] = noSia.trim();
      if (noSipa != null) payload['no_sipa'] = noSipa.trim();
      if (alamat != null) payload['alamat'] = alamat.trim();
      if (jamOperasional != null) payload['jam_operasional'] = jamOperasional.trim();

      final response = await _apiClient.dio.post('/auth/register/apotek', data: payload);
      final data = response.data;
      if (data != null && data['success'] == true) {
        final resultData = data['data'] as Map<String, dynamic>? ?? {};
        final String token = resultData['access_token'] ?? '';
        final userData = resultData['user'] as Map<String, dynamic>? ?? {};
        final user = UserModel.fromJson(userData, defaultRole: 'apotek');

        if (token.isNotEmpty) {
          await _storage.saveToken(token);
          await _storage.saveUser(user);
          await _storage.saveRole('apotek');
        }

        return AuthResult(
          success: true,
          message: data['message'] ?? 'Pendaftaran apotek berhasil.',
          user: user,
          token: token,
          role: 'apotek',
        );
      }
      return AuthResult(success: false, message: data?['message'] ?? 'Pendaftaran apotek gagal.');
    } catch (e) {
      return AuthResult(success: false, message: ApiClient.getErrorMessage(e));
    }
  }

  /// 9. Lupa Password (Kirim Kode OTP)
  /// Endpoint: POST /auth/forgot-password (fallback POST /forgot-password)
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final payload = {'email': email.trim().toLowerCase()};
      dynamic response;
      try {
        response = await _apiClient.dio.post('/auth/forgot-password', data: payload);
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404) {
          response = await _apiClient.dio.post('/forgot-password', data: payload);
        } else {
          rethrow;
        }
      }
      final data = response.data;
      return {
        'success': data?['success'] ?? true,
        'message': data?['message'] ?? 'Kode verifikasi telah dikirim ke email Anda.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': ApiClient.getErrorMessage(e),
      };
    }
  }

  /// 10. Verifikasi OTP Lupa Password
  /// Endpoint: POST /auth/verify-otp
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final payload = {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
      };
      final response = await _apiClient.dio.post('/auth/verify-otp', data: payload);
      final data = response.data;
      return {
        'success': data?['success'] ?? true,
        'message': data?['message'] ?? 'Kode OTP berhasil diverifikasi.',
        'token': data?['data']?['reset_token'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': ApiClient.getErrorMessage(e),
      };
    }
  }

  /// 11. Kirim Ulang OTP
  /// Endpoint: POST /auth/resend-otp
  Future<Map<String, dynamic>> resendOtp(String email) async {
    try {
      final payload = {'email': email.trim().toLowerCase()};
      final response = await _apiClient.dio.post('/auth/resend-otp', data: payload);
      final data = response.data;
      return {
        'success': data?['success'] ?? true,
        'message': data?['message'] ?? 'Kode OTP baru berhasil dikirim.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': ApiClient.getErrorMessage(e),
      };
    }
  }

  /// 12. Reset Password Baru
  /// Endpoint: POST /auth/reset-password (fallback POST /reset-password)
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
    String? otp,
    String? resetToken,
  }) async {
    try {
      final payload = {
        'email': email.trim().toLowerCase(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      };
      if (otp != null && otp.isNotEmpty) payload['otp'] = otp.trim();
      if (resetToken != null && resetToken.isNotEmpty) payload['token'] = resetToken.trim();

      dynamic response;
      try {
        response = await _apiClient.dio.post('/auth/reset-password', data: payload);
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404) {
          response = await _apiClient.dio.post('/reset-password', data: payload);
        } else {
          rethrow;
        }
      }
      final data = response.data;
      return {
        'success': data?['success'] ?? true,
        'message': data?['message'] ?? 'Kata sandi Anda berhasil diperbarui.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': ApiClient.getErrorMessage(e),
      };
    }
  }

  /// 13. Tandai Notifikasi Dibaca
  /// Endpoint: PATCH /notifikasi/{id}/read
  Future<bool> markNotificationRead(dynamic id) async {
    try {
      final response = await _apiClient.dio.patch('/notifikasi/$id/read');
      return response.data?['success'] == true;
    } catch (e) {
      debugPrint('markNotificationRead error: $e');
      return false;
    }
  }

  /// 14. Periksa apakah pengguna saat ini sudah login
  Future<bool> isLoggedIn() async {
    return await _storage.hasToken();
  }
}

