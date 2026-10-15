/// Models for PRAGI (Skrining Ginjal & Chatbot AI)

class PragiQuestion {
  final dynamic id;
  final String pertanyaan;
  final String? keterangan;
  final List<String> opsi;

  PragiQuestion({
    required this.id,
    required this.pertanyaan,
    this.keterangan,
    this.opsi = const ['Ya', 'Tidak'],
  });

  factory PragiQuestion.fromJson(Map<String, dynamic> json) {
    List<String> parsedOpsi = ['Ya', 'Tidak'];
    if (json['opsi'] is List) {
      parsedOpsi = (json['opsi'] as List).map((e) => e.toString()).toList();
    }
    return PragiQuestion(
      id: json['id'] ?? json['nomor'] ?? 0,
      pertanyaan: json['pertanyaan']?.toString() ?? json['question']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? json['description']?.toString(),
      opsi: parsedOpsi,
    );
  }
}

class PragiScreeningResponse {
  final dynamic id;
  final int totalSkor;
  final String kategoriRisiko;
  final String rekomendasiDokter;
  final List<String> saranTindakan;
  final String tanggal;

  PragiScreeningResponse({
    this.id,
    required this.totalSkor,
    required this.kategoriRisiko,
    required this.rekomendasiDokter,
    this.saranTindakan = const [],
    required this.tanggal,
  });

  factory PragiScreeningResponse.fromJson(Map<String, dynamic> json) {
    List<String> saran = [];
    if (json['saran_tindakan'] is List) {
      saran = (json['saran_tindakan'] as List).map((e) => e.toString()).toList();
    } else if (json['saran'] is List) {
      saran = (json['saran'] as List).map((e) => e.toString()).toList();
    }

    return PragiScreeningResponse(
      id: json['id'],
      totalSkor: int.tryParse(json['total_skor']?.toString() ?? json['skor']?.toString() ?? '0') ?? 0,
      kategoriRisiko: json['kategori_risiko']?.toString() ?? json['risk_level']?.toString() ?? 'Risiko Rendah CKD',
      rekomendasiDokter: json['rekomendasi_dokter']?.toString() ?? json['rekomendasi']?.toString() ?? 'Lakukan pola hidup sehat.',
      saranTindakan: saran,
      tanggal: json['tanggal']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }
}

class PragiChatMessage {
  final dynamic id;
  final String text;
  final bool isUser;
  final String time;
  final List<String>? saranTindakan;

  PragiChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.saranTindakan,
  });

  factory PragiChatMessage.fromJson(Map<String, dynamic> json) {
    List<String>? saran;
    if (json['saran_tindakan'] is List) {
      saran = (json['saran_tindakan'] as List).map((e) => e.toString()).toList();
    }

    final isUserBool = json['sender']?.toString().toLowerCase() == 'user' ||
        json['role']?.toString().toLowerCase() == 'user' ||
        json['is_user'] == true;

    return PragiChatMessage(
      id: json['id'],
      text: json['pesan']?.toString() ?? json['message']?.toString() ?? json['reply']?.toString() ?? '',
      isUser: isUserBool,
      time: json['waktu']?.toString() ?? json['created_at']?.toString() ?? '',
      saranTindakan: saran,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pesan': text,
      'is_user': isUser,
    };
  }
}
