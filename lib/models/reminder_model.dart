/// Model for Pengingat Minum Obat (Reminder)
class ReminderModel {
  final dynamic id;
  final String nama;
  final String tanggal;
  final String waktu;
  final String keterangan;
  final String pengulangan;
  final bool isActive;

  ReminderModel({
    required this.id,
    required this.nama,
    required this.tanggal,
    required this.waktu,
    required this.keterangan,
    required this.pengulangan,
    required this.isActive,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'],
      nama: json['nama']?.toString() ?? json['title']?.toString() ?? 'Pengingat',
      tanggal: json['tanggal']?.toString() ?? json['date']?.toString() ?? '',
      waktu: json['waktu']?.toString() ?? json['time']?.toString() ?? '08:00:00',
      keterangan: json['keterangan']?.toString() ?? json['deskripsi']?.toString() ?? json['subtitle']?.toString() ?? '',
      pengulangan: json['pengulangan']?.toString() ?? 'harian',
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['isActive'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'tanggal': tanggal,
      'waktu': waktu,
      'keterangan': keterangan,
      'pengulangan': pengulangan,
      'is_active': isActive,
    };
  }

  ReminderModel copyWith({
    dynamic id,
    String? nama,
    String? tanggal,
    String? waktu,
    String? keterangan,
    String? pengulangan,
    bool? isActive,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      tanggal: tanggal ?? this.tanggal,
      waktu: waktu ?? this.waktu,
      keterangan: keterangan ?? this.keterangan,
      pengulangan: pengulangan ?? this.pengulangan,
      isActive: isActive ?? this.isActive,
    );
  }
}
