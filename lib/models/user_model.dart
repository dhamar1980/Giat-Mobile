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
  final String? spesialisasi;
  final String? instansi;
  final String? noStr;
  final String? noSip;
  final String? tanggalLahir;
  final String? golonganDarah;

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
    final int parsedId = json['id_pasien'] ??
        json['id_dokter'] ??
        json['id_apotek'] ??
        json['id'] ??
        0;

    String resolvedRole = (json['role'] as String?)?.toLowerCase() ?? '';
    if (resolvedRole.isEmpty || resolvedRole == 'pasien') {
      if (json['id_apotek'] != null || json.containsKey('lokasi_apotek') || json.containsKey('jam_operasional')) {
        resolvedRole = 'apotek';
      } else if (json['id_dokter'] != null || json.containsKey('no_str') || json.containsKey('spesialisasi')) {
        resolvedRole = 'dokter';
      } else if (json['id_pasien'] != null) {
        resolvedRole = 'pasien';
      } else if (resolvedRole.isEmpty) {
        resolvedRole = defaultRole.toLowerCase();
      }
    }

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
      spesialisasi: json['spesialisasi'] as String?,
      instansi: json['instansi'] as String?,
      noStr: json['no_str'] as String?,
      noSip: json['no_sip'] as String?,
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
