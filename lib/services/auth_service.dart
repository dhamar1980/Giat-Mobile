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

  /// 2. Native Firebase Login (Email & Password)
  /// Endpoint: POST /auth/firebase/login
  Future<AuthResult> loginWithEmailPassword({
    required String email,
    required String password,
    String role = 'pasien',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/firebase/login',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
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

        // Simpan ke storage aman
        await _storage.saveToken(token);
        await _storage.saveUser(user);
        await _storage.saveRole(resolvedRole);

        // Opsional: sinkronkan sesi FirebaseAuth lokal
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email.trim().toLowerCase(),
            password: password,
          );
        } catch (_) {}

        return AuthResult(
          success: true,
          message: data['message'] ?? 'Login berhasil.',
          user: user,
          token: token,
          role: resolvedRole,
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
        return user;
      }
    } catch (e) {
      debugPrint('GetCurrentUser error: $e');
    }
    return null;
  }

  /// 6. Logout dan Hapus Sesi
  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/auth/logout');
    } catch (_) {}

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _storage.clearAuth();
  }

  /// 7. Periksa apakah pengguna saat ini sudah login
  Future<bool> isLoggedIn() async {
    return await _storage.hasToken();
  }
}
