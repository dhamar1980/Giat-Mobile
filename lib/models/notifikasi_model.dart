/// Models for Notifikasi Pengguna

class NotifikasiModel {
  final dynamic id;
  final String judul;
  final String pesan;
  final String? tipe;
  final bool isRead;
  final String createdAt;
  final Map<String, dynamic>? data;

  NotifikasiModel({
    required this.id,
    required this.judul,
    required this.pesan,
    this.tipe,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      id: json['id'],
      judul: json['judul']?.toString() ?? json['title']?.toString() ?? 'Pemberitahuan',
      pesan: json['pesan']?.toString() ?? json['message']?.toString() ?? json['body']?.toString() ?? '',
      tipe: json['tipe']?.toString() ?? json['type']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['read_at'] != null,
      createdAt: json['created_at']?.toString() ?? json['tanggal']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null,
    );
  }
}
