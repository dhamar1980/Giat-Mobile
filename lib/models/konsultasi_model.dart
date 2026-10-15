/// Models for Konsultasi Telemedisin, Chat & Video Call

class DokterModel {
  final dynamic id;
  final String nama;
  final String spesialisasi;
  final String instansi;
  final String? noStr;
  final String? noSip;
  final String? alamatPraktik;
  final String? jadwalPraktik;
  final String? avatar;
  final double rating;
  final int tarif;
  final String pengalaman;
  final bool isOnline;

  DokterModel({
    required this.id,
    required this.nama,
    required this.spesialisasi,
    required this.instansi,
    this.noStr,
    this.noSip,
    this.alamatPraktik,
    this.jadwalPraktik,
    this.avatar,
    this.rating = 4.9,
    this.tarif = 150000,
    this.pengalaman = '5+ Tahun',
    this.isOnline = true,
  });

  factory DokterModel.fromJson(Map<String, dynamic> json) {
    return DokterModel(
      id: json['id'] ?? json['id_dokter'] ?? 0,
      nama: json['nama']?.toString() ?? json['name']?.toString() ?? 'Dokter GIAT',
      spesialisasi: json['spesialisasi']?.toString() ?? json['specialty']?.toString() ?? 'Spesialis Ginjal',
      instansi: json['instansi']?.toString() ?? json['hospital']?.toString() ?? 'RS Mitra GIAT',
      noStr: json['no_str']?.toString(),
      noSip: json['no_sip']?.toString(),
      alamatPraktik: json['alamat_praktik']?.toString(),
      jadwalPraktik: json['jadwal_praktik']?.toString() ?? json['schedule']?.toString(),
      avatar: json['foto_profile']?.toString() ?? json['avatarUrl']?.toString(),
      rating: double.tryParse(json['rating']?.toString() ?? '4.9') ?? 4.9,
      tarif: int.tryParse(json['tarif']?.toString() ?? json['biaya']?.toString() ?? '150000') ?? 150000,
      pengalaman: json['pengalaman']?.toString() ?? json['experience']?.toString() ?? '5+ Tahun',
      isOnline: json['is_online'] == true || json['status'] == 'online' || json['status'] == 'Online Sekarang',
    );
  }
}

class KonsultasiSession {
  final dynamic id;
  final dynamic idDokter;
  final String namaDokter;
  final String spesialisasiDokter;
  final String? avatarDokter;
  final String tanggalKonsultasi;
  final String status;
  final String statusPembayaran;
  final String? metodePembayaran;
  final String? videoCallUrl;
  final int totalBiaya;
  final String? isiKonsultasi;
  final dynamic resep;

  KonsultasiSession({
    required this.id,
    required this.idDokter,
    required this.namaDokter,
    required this.spesialisasiDokter,
    this.avatarDokter,
    required this.tanggalKonsultasi,
    required this.status,
    required this.statusPembayaran,
    this.metodePembayaran,
    this.videoCallUrl,
    this.totalBiaya = 150000,
    this.isiKonsultasi,
    this.resep,
  });

  factory KonsultasiSession.fromJson(Map<String, dynamic> json) {
    final dokterData = json['dokter'] is Map<String, dynamic> ? json['dokter'] as Map<String, dynamic> : {};

    return KonsultasiSession(
      id: json['id'],
      idDokter: json['id_dokter'] ?? dokterData['id'],
      namaDokter: dokterData['nama']?.toString() ?? json['nama_dokter']?.toString() ?? 'Dokter GIAT',
      spesialisasiDokter: dokterData['spesialisasi']?.toString() ?? json['spesialisasi']?.toString() ?? 'Spesialis Ginjal',
      avatarDokter: dokterData['foto_profile']?.toString() ?? json['avatar_dokter']?.toString(),
      tanggalKonsultasi: json['tanggal_konsultasi']?.toString() ?? json['tanggal']?.toString() ?? '',
      status: json['status']?.toString() ?? 'menunggu_pembayaran',
      statusPembayaran: json['status_pembayaran']?.toString() ?? json['status_bayar']?.toString() ?? 'belum_dibayar',
      metodePembayaran: json['metode_pembayaran']?.toString(),
      videoCallUrl: json['video_call_url']?.toString(),
      totalBiaya: int.tryParse(json['total_biaya']?.toString() ?? json['tarif']?.toString() ?? '150000') ?? 150000,
      isiKonsultasi: json['isi_konsultasi']?.toString() ?? json['keluhan']?.toString(),
      resep: json['resep'],
    );
  }
}

class KonsultasiChatMessage {
  final dynamic id;
  final dynamic idKonsultasi;
  final dynamic idSender;
  final String pesan;
  final String? attachment;
  final bool isUser;
  final String createdAt;

  KonsultasiChatMessage({
    this.id,
    required this.idKonsultasi,
    this.idSender,
    required this.pesan,
    this.attachment,
    required this.isUser,
    required this.createdAt,
  });

  factory KonsultasiChatMessage.fromJson(Map<String, dynamic> json, {dynamic currentUserId}) {
    final senderId = json['id_pengirim'] ?? json['id_sender'] ?? json['sender_id'];
    final bool isCurrentUser = (currentUserId != null && senderId == currentUserId) ||
        json['is_user'] == true ||
        json['role'] == 'pasien';

    return KonsultasiChatMessage(
      id: json['id'],
      idKonsultasi: json['id_konsultasi'] ?? json['konsultasi_id'],
      idSender: senderId,
      pesan: json['pesan']?.toString() ?? json['message']?.toString() ?? '',
      attachment: json['attachment']?.toString() ?? json['lampiran']?.toString(),
      isUser: isCurrentUser,
      createdAt: json['created_at']?.toString() ?? json['waktu']?.toString() ?? '',
    );
  }
}
