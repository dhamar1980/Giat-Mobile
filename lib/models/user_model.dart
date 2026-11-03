import 'dart:convert';
import '../utils/time_utils.dart';

/// Model representing a GIAT user (Pasien, Dokter, Apotek, etc.)
class UserModel {
  final dynamic id;
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
  final String? spesialisasi;
  final String? instansi;
  final String? noStr;
  final String? noSip;
  final String? tanggalLahir;
  final String? golonganDarah;

  String get formattedTanggalLahir => TimeUtils.formatBirthDate(tanggalLahir);

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
    this.spesialisasi,
    this.instansi,
    this.noStr,
    this.noSip,
    this.tanggalLahir,
    this.golonganDarah,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String defaultRole = 'pasien'}) {
    final dynamic parsedId = json['id_admin'] ??
        json['id_pasien'] ??
        json['id_dokter'] ??
        json['id_apotek'] ??
        (json['user'] is Map ? (json['user'] as Map)['id'] : null) ??
        json['id'] ??
        0;

    String resolvedRole = (json['role'] as String?)?.toLowerCase().trim() ?? '';
    if (resolvedRole.isEmpty && json['user'] is Map) {
      resolvedRole = ((json['user'] as Map)['role'] as String?)?.toLowerCase().trim() ?? '';
    }
    if (resolvedRole.isEmpty) {
      if (json['id_admin'] != null || (json['jabatan'] != null && json['jabatan'].toString().trim().isNotEmpty)) {
        resolvedRole = 'admin';
      } else if (json['id_apotek'] != null || (json['lokasi_apotek'] != null && json['lokasi_apotek'].toString().trim().isNotEmpty)) {
        resolvedRole = 'apotek';
      } else if (json['id_dokter'] != null || (json['no_str'] != null && json['no_str'].toString().trim().isNotEmpty) || (json['spesialisasi'] != null && json['spesialisasi'].toString().trim().isNotEmpty)) {
        resolvedRole = 'dokter';
      } else if (json['id_pasien'] != null) {
        resolvedRole = 'pasien';
      } else {
        resolvedRole = defaultRole.toLowerCase();
      }
    }

    return UserModel(
      id: parsedId,
      nama: json['nama'] as String? ?? json['nama_apotek'] as String? ?? json['name'] as String? ?? 'Pengguna GIAT',
      email: json['email'] as String? ?? (json['user'] is Map ? (json['user'] as Map)['email'] as String? : null) ?? '',
      noHp: json['no_hp'] as String?,
      alamat: json['alamat'] as String?,
      jenisKelamin: json['jenis_kelamin'] as String?,
      nik: json['NIK'] as String? ?? json['nik'] as String?,
      fotoProfile: json['foto_profile'] as String? ?? json['foto_profil'] as String?,
      firebaseUid: json['firebase_uid'] as String?,
      authProvider: json['auth_provider'] as String?,
      role: resolvedRole,
      spesialisasi: json['spesialisasi'] as String?,
      instansi: json['institusi'] as String? ?? json['instansi'] as String?,
      noStr: json['no_str'] as String?,
      noSip: json['no_sip'] as String? ?? json['no_sipa_sia'] as String?,
      tanggalLahir: json['tanggal_lahir'] as String?,
      golonganDarah: json['golongan_darah'] as String?,
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
      'spesialisasi': spesialisasi,
      'instansi': instansi,
      'no_str': noStr,
      'no_sip': noSip,
      'tanggal_lahir': tanggalLahir,
      'golongan_darah': golonganDarah,
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
