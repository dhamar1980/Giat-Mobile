import 'dart:convert';

/// Model representing a GIAT user (Pasien, Dokter, Apotek, etc.)
class UserModel {
  final int id;
  final String nama;
  final String email;
  final String? noHp;
  final String? alamat;
  final String? jenisKelamin;
  final String? nik;
  final String? fotoProfile;
  final String? firebaseUid;
  final String? authProvider;
  final String role;

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    this.noHp,
    this.alamat,
    this.jenisKelamin,
    this.nik,
    this.fotoProfile,
    this.firebaseUid,
    this.authProvider,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String defaultRole = 'pasien'}) {
    final int parsedId = json['id_pasien'] ??
        json['id_dokter'] ??
        json['id_apotek'] ??
        json['id'] ??
        0;

    final String resolvedRole = (json['role'] as String?)?.toLowerCase() ?? defaultRole;

    return UserModel(
      id: parsedId,
      nama: json['nama'] as String? ?? 'Pengguna GIAT',
      email: json['email'] as String? ?? '',
      noHp: json['no_hp'] as String?,
      alamat: json['alamat'] as String?,
      jenisKelamin: json['jenis_kelamin'] as String?,
      nik: json['NIK'] as String? ?? json['nik'] as String?,
      fotoProfile: json['foto_profile'] as String? ?? json['foto_profil'] as String?,
      firebaseUid: json['firebase_uid'] as String?,
      authProvider: json['auth_provider'] as String?,
      role: resolvedRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'no_hp': noHp,
      'alamat': alamat,
      'jenis_kelamin': jenisKelamin,
      'nik': nik,
      'foto_profile': fotoProfile,
      'firebase_uid': firebaseUid,
      'auth_provider': authProvider,
      'role': role,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String source) =>
      UserModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

/// Standard Result wrapper for Authentication operations
class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;
  final String? token;
  final String? role;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.role,
  });

  @override
  String toString() => 'AuthResult(success: $success, message: $message, role: $role)';
}
