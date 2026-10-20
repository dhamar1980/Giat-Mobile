/// Models for PRAGI (Skrining AI Ginjal & Chatbot AI)

/// Pilihan opsi jawaban untuk pertanyaan bertipe binary atau select
class PragiPertanyaanOption {
  final String label;
  final dynamic nilai;
  final num? nilaiNumeric;

  PragiPertanyaanOption({
    required this.label,
    required this.nilai,
    this.nilaiNumeric,
  });

  factory PragiPertanyaanOption.fromJson(Map<String, dynamic> json) {
    return PragiPertanyaanOption(
      label: json['label']?.toString() ?? '',
      nilai: json['nilai'] ?? json['value'] ?? json['label'],
      nilaiNumeric: json['nilai_numeric'] != null
          ? num.tryParse(json['nilai_numeric'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'nilai': nilai,
    if (nilaiNumeric != null) 'nilai_numeric': nilaiNumeric,
  };
}

/// Model Pertanyaan Skrining AI PRAGI
class PragiPertanyaan {
  final int id;
  final String kodeField;
  final String pertanyaan;
  final String tipeInput; // "binary", "number", atau "select"
  final String? satuan;
  final num? min;
  final num? max;
  final List<PragiPertanyaanOption> opsiJawaban;

  PragiPertanyaan({
    required this.id,
    required this.kodeField,
    required this.pertanyaan,
    required this.tipeInput,
    this.satuan,
    this.min,
    this.max,
    this.opsiJawaban = const [],
  });

  factory PragiPertanyaan.fromJson(Map<String, dynamic> json) {
    List<PragiPertanyaanOption> opsi = [];
    if (json['opsi_jawaban'] is List) {
      opsi = (json['opsi_jawaban'] as List).map((item) {
        if (item is Map<String, dynamic>) {
          return PragiPertanyaanOption.fromJson(item);
        } else if (item is Map) {
          return PragiPertanyaanOption.fromJson(Map<String, dynamic>.from(item));
        } else if (item is String) {
          return PragiPertanyaanOption(label: item, nilai: item);
        }
        return PragiPertanyaanOption(label: item.toString(), nilai: item.toString());
      }).toList();
    }

    return PragiPertanyaan(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      kodeField: json['kode_field']?.toString() ?? json['kode']?.toString() ?? '',
      pertanyaan: json['pertanyaan']?.toString() ?? '',
      tipeInput: json['tipe_input']?.toString() ?? 'binary',
      satuan: json['satuan']?.toString(),
      min: json['min'] != null ? num.tryParse(json['min'].toString()) : null,
      max: json['max'] != null ? num.tryParse(json['max'].toString()) : null,
      opsiJawaban: opsi,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kode_field': kodeField,
    'pertanyaan': pertanyaan,
    'tipe_input': tipeInput,
    if (satuan != null) 'satuan': satuan,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    'opsi_jawaban': opsiJawaban.map((e) => e.toJson()).toList(),
  };

  /// Fallback daftar 16 pertanyaan standar Skrining AI PRAGI
  static List<PragiPertanyaan> get default16Pertanyaan => [
    PragiPertanyaan(
      id: 1,
      kodeField: 'HeartDisease',
      pertanyaan: 'Apakah Anda pernah didiagnosis menderita penyakit jantung koroner atau serangan jantung?',
      tipeInput: 'binary',
      opsiJawaban: [
        PragiPertanyaanOption(label: 'Ya', nilai: 'Yes'),
        PragiPertanyaanOption(label: 'Tidak', nilai: 'No'),
      ],
    ),
    PragiPertanyaan(
      id: 2,
      kodeField: 'BMI',
      pertanyaan: 'Berapa Indeks Massa Tubuh (BMI / IMT) Anda saat ini?',
      tipeInput: 'number',
      satuan: 'kg/m²',
      min: 10.0,
      max: 60.0,
    ),
    PragiPertanyaan(
      id: 3,
      kodeField: 'Smoking',
      pertanyaan: 'Apakah Anda pernah merokok setidaknya 100 batang rokok sepanjang hidup Anda?',
      tipeInput: 'binary',
      opsiJawaban: [
        PragiPertanyaanOption(label: 'Ya', nilai: 'Yes'),
        PragiPertanyaanOption(label: 'Tidak', nilai: 'No'),
      ],
    ),
    PragiPertanyaan(
      id: 4,
      kodeField: 'AlcoholDrinking',
      pertanyaan: 'Apakah Anda mengonsumsi alkohol secara berlebih (>14 gelas/minggu untuk pria, >7 gelas/minggu untuk wanita)?',
      tipeInput: 'binary',
      opsiJawaban: [
        PragiPertanyaanOption(label: 'Ya', nilai: 'Yes'),
        PragiPertanyaanOption(label: 'Tidak', nilai: 'No'),
      ],
    ),
    PragiPertanyaan(
      id: 5,
      kodeField: 'Stroke',
      pertanyaan: 'Apakah Anda pernah didiagnosis mengalami stroke?',
      tipeInput: 'binary',
      opsiJawaban: [
        PragiPertanyaanOption(label: 'Ya', nilai: 'Yes'),
        PragiPertanyaanOption(label: 'Tidak', nilai: 'No'),
      ],
    ),
    PragiPertanyaan(
      id: 6,
      kodeField: 'PhysicalHealth',
      pertanyaan: 'Dalam 30 hari terakhir, berapa hari kesehatan fisik Anda terasa tidak baik / sakit?',
      tipeInput: 'number',
      satuan: 'hari',
      min: 0,
      max: 30,
    ),
    PragiPertanyaan(
      id: 7,
      kodeField: 'MentalHealth',
      pertanyaan: 'Dalam 30 hari terakhir, berapa hari kesehatan mental Anda terasa tidak baik (stres, cemas, atau depresi)?',
      tipeInput: 'number',
      satuan: 'hari',
      min: 0,
      max: 30,
    ),
    PragiPertanyaan(
      id: 8,
      kodeField: 'DiffWalking',
      pertanyaan: 'Apakah Anda mengalami kesulitan yang signifikan saat berjalan atau menaiki tangga?',
      tipeInput: 'binary',
      opsiJawaban: [
        PragiPertanyaanOption(label: 'Ya', nilai: 'Yes'),
        PragiPertanyaanOption(label: 'Tidak', nilai: 'No'),
      ],
    ),
    PragiPertanyaan(
      id: 9,
      kodeField: 'Sex',
      pertanyaan: 'Apa jenis kelamin biologis Anda?',
      tipeInput: 'select',
      opsiJawaban: [
        PragiPertanyaanOption(label: 'Laki-laki (Male)', nilai: 'Male'),
        PragiPertanyaanOption(label: 'Perempuan (Female)', nilai: 'Female'),
      ],
    ),
    PragiPertanyaan(
      id: 10,
      kodeField: 'AgeCategory',
      pertanyaan: 'Berapa rentang usia Anda saat ini?',
      tipeInput: 'select',
      opsiJawaban: [
        PragiPertanyaanOption(label: '18–24 tahun', nilai: '18-24'),
        PragiPertanyaanOption(label: '25–29 tahun', nilai: '25-29'),
        PragiPertanyaanOption(label: '30–34 tahun', nilai: '30-34'),
        PragiPertanyaanOption(label: '35–39 tahun', nilai: '35-39'),
        PragiPertanyaanOption(label: '40–44 tahun', nilai: '40-44'),
        PragiPertanyaanOption(label: '45–49 tahun', nilai: '45-49'),
        PragiPertanyaanOption(label: '50–54 tahun', nilai: '50-54'),
        PragiPertanyaanOption(label: '55–59 tahun', nilai: '55-59'),
        PragiPertanyaanOption(label: '60–64 tahun', nilai: '60-64'),
        PragiPertanyaanOption(label: '65–69 tahun', nilai: '65-69'),
        PragiPertanyaanOption(label: '70–74 tahun', nilai: '70-74'),
        PragiPertanyaanOption(label: '75–79 tahun', nilai: '75-79'),
        PragiPertanyaanOption(label: '80 tahun ke atas', nilai: '80 or older'),
      ],
    ),
    PragiPertanyaan(
      id: 11,
      kodeField: 'Race',
      pertanyaan: 'Apa kelompok ras atau etnis Anda?',
      tipeInput: 'select',
      opsiJawaban: [
        PragiPertanyaanOption(label: 'Asia (Asian)', nilai: 'Asian'),
        PragiPertanyaanOption(label: 'Kaukasia / Kulit Putih (White)', nilai: 'White'),
        PragiPertanyaanOption(label: 'Kulit Hitam (Black)', nilai: 'Black'),
        PragiPertanyaanOption(label: 'Hispanik (Hispanic)', nilai: 'Hispanic'),
        PragiPertanyaanOption(label: 'Penduduk Asli Amerika (American Indian/Alaskan Native)', nilai: 'American Indian/Alaskan Native'),
        PragiPertanyaanOption(label: 'Lainnya (Other)', nilai: 'Other'),
      ],
    ),
    PragiPertanyaan(
      id: 12,
      kodeField: 'Diabetic',
      pertanyaan: 'Apakah Anda pernah didiagnosis menderita penyakit kencing manis / diabetes?',
      tipeInput: 'select',
      opsiJawaban: [
        PragiPertanyaanOption(label: 'Tidak (No)', nilai: 'No'),
        PragiPertanyaanOption(label: 'Ya, menderita Diabetes (Yes)', nilai: 'Yes'),
        PragiPertanyaanOption(label: 'Prediabetes / Batas Gula Tinggi', nilai: 'No, borderline diabetes'),
        PragiPertanyaanOption(label: 'Ya, hanya saat masa kehamilan (Gestasional)', nilai: 'Yes (during pregnancy)'),
      ],
    ),
    PragiPertanyaan(
      id: 13,
      kodeField: 'PhysicalActivity',
      pertanyaan: 'Apakah Anda rutin berolahraga atau melakukan aktivitas fisik di luar pekerjaan dalam 30 hari terakhir?',
      tipeInput: 'binary',
      opsiJawaban: [
        PragiPertanyaanOption(label: 'Ya', nilai: 'Yes'),
        PragiPertanyaanOption(label: 'Tidak', nilai: 'No'),
      ],
    ),
    PragiPertanyaan(
      id: 14,
      kodeField: 'GenHealth',
      pertanyaan: 'Secara keseluruhan, bagaimana Anda menilai status kesehatan Anda saat ini?',
      tipeInput: 'select',
      opsiJawaban: [
        PragiPertanyaanOption(label: 'Sangat Baik Sekali (Excellent)', nilai: 'Excellent'),
        PragiPertanyaanOption(label: 'Sangat Baik (Very good)', nilai: 'Very good'),
        PragiPertanyaanOption(label: 'Baik (Good)', nilai: 'Good'),
        PragiPertanyaanOption(label: 'Cukup / Biasa Saja (Fair)', nilai: 'Fair'),
        PragiPertanyaanOption(label: 'Buruk (Poor)', nilai: 'Poor'),
      ],
    ),
    PragiPertanyaan(
      id: 15,
      kodeField: 'SleepTime',
      pertanyaan: 'Berapa rata-rata jam tidur yang Anda dapatkan dalam kurun waktu 24 jam?',
      tipeInput: 'number',
      satuan: 'jam',
      min: 1,
      max: 24,
    ),
    PragiPertanyaan(
      id: 16,
      kodeField: 'Asthma',
      pertanyaan: 'Apakah Anda pernah didiagnosis menderita asma?',
      tipeInput: 'binary',
      opsiJawaban: [
        PragiPertanyaanOption(label: 'Ya', nilai: 'Yes'),
        PragiPertanyaanOption(label: 'Tidak', nilai: 'No'),
      ],
    ),
  ];
}

/// Hasil evaluasi skrining AI PRAGI dari response POST /api/pasien/pragi/predict atau /skrining
class PragiHasilSkrining {
  final String idPragi;
  final String? label;
  final int? prediction; // 0: Non-CKD, 1: CKD
  final double? confidencePercent; // contoh: 62.62
  final double? probabilityCkd; // contoh: 0.6262
  final double? probabilityNoCkd; // contoh: 0.3738
  final String kategoriRisiko; // "rendah", "sedang", "tinggi"
  final String hasilPrediksi;
  final int skor;
  final double? probabilitas;
  final String rekomendasi;
  final List<String> faktorRisiko;
  final String? sumberPrediksi;
  final bool isFallback;
  final String tanggalScreening;

  PragiHasilSkrining({
    required this.idPragi,
    this.label,
    this.prediction,
    this.confidencePercent,
    this.probabilityCkd,
    this.probabilityNoCkd,
    required this.kategoriRisiko,
    required this.hasilPrediksi,
    required this.skor,
    this.probabilitas,
    required this.rekomendasi,
    this.faktorRisiko = const [],
    this.sumberPrediksi,
    this.isFallback = false,
    required this.tanggalScreening,
  });

  factory PragiHasilSkrining.fromJson(Map<String, dynamic> json) {
    List<String> faktor = [];
    if (json['faktor_risiko'] is List) {
      faktor = (json['faktor_risiko'] as List).map((e) => e.toString()).toList();
    } else if (json['faktor'] is List) {
      faktor = (json['faktor'] as List).map((e) => e.toString()).toList();
    }

    // Parse nested probability object { ckd: 0.6262, no_ckd: 0.3738 }
    double? ckdProb;
    double? noCkdProb;
    if (json['probability'] is Map) {
      final pMap = json['probability'] as Map;
      ckdProb = double.tryParse(pMap['ckd']?.toString() ?? '');
      noCkdProb = double.tryParse(pMap['no_ckd']?.toString() ?? '');
    }

    final double? probabilitasVal = json['probabilitas'] != null
        ? double.tryParse(json['probabilitas'].toString())
        : (ckdProb ?? (json['probability'] is num ? (json['probability'] as num).toDouble() : null));

    final double? confPercent = json['confidence_percent'] != null
        ? double.tryParse(json['confidence_percent'].toString())
        : (probabilitasVal != null ? probabilitasVal * 100 : null);

    final int? predVal = json['prediction'] != null
        ? int.tryParse(json['prediction'].toString())
        : (json['prediksi_numeric'] != null
            ? int.tryParse(json['prediksi_numeric'].toString())
            : null);

    final String labelVal = json['label']?.toString() ??
        json['hasil_prediksi']?.toString() ??
        json['prediksi']?.toString() ??
        'Hasil Skrining AI PRAGI';

    return PragiHasilSkrining(
      idPragi: json['id_pragi']?.toString() ?? json['id']?.toString() ?? '',
      label: labelVal,
      prediction: predVal,
      confidencePercent: confPercent,
      probabilityCkd: ckdProb,
      probabilityNoCkd: noCkdProb,
      kategoriRisiko: (json['kategori_risiko']?.toString() ?? 'rendah').toLowerCase(),
      hasilPrediksi: labelVal,
      skor: int.tryParse(json['skor']?.toString() ?? json['total_skor']?.toString() ?? '0') ?? 0,
      probabilitas: probabilitasVal,
      rekomendasi: json['rekomendasi']?.toString() ?? 'Jaga pola makan seimbang dan konsumsi air putih secukupnya.',
      faktorRisiko: faktor,
      sumberPrediksi: json['sumber_prediksi']?.toString(),
      isFallback: json['is_fallback'] == true,
      tanggalScreening: json['tanggal_screening']?.toString() ??
          json['tanggal']?.toString() ??
          json['created_at']?.toString() ??
          DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_pragi': idPragi,
    if (label != null) 'label': label,
    if (prediction != null) 'prediction': prediction,
    if (confidencePercent != null) 'confidence_percent': confidencePercent,
    if (probabilityCkd != null || probabilityNoCkd != null)
      'probability': {
        if (probabilityCkd != null) 'ckd': probabilityCkd,
        if (probabilityNoCkd != null) 'no_ckd': probabilityNoCkd,
      },
    'kategori_risiko': kategoriRisiko,
    'hasil_prediksi': hasilPrediksi,
    'skor': skor,
    if (probabilitas != null) 'probabilitas': probabilitas,
    'rekomendasi': rekomendasi,
    'faktor_risiko': faktorRisiko,
    if (sumberPrediksi != null) 'sumber_prediksi': sumberPrediksi,
    'is_fallback': isFallback,
    'tanggal_screening': tanggalScreening,
  };

  bool get isRisikoTinggi => kategoriRisiko.contains('tinggi') || prediction == 1 && (confidencePercent ?? 0) >= 60.0;
  bool get isRisikoSedang => kategoriRisiko.contains('sedang') || (prediction == 1 && !isRisikoTinggi);
  bool get isRisikoRendah => !isRisikoTinggi && !isRisikoSedang;

  bool get isCkdDetected => (prediction == 1) || isRisikoTinggi || isRisikoSedang;

  String get formattedKategori {
    if (isRisikoTinggi) return 'Risiko Tinggi';
    if (isRisikoSedang) return 'Risiko Sedang';
    return 'Risiko Rendah';
  }

  /// Persentase probabilitas CKD untuk indikator visual (0..100)
  double get displayCkdPercentage {
    if (confidencePercent != null && prediction == 1) {
      return confidencePercent!.clamp(0.0, 100.0);
    }
    if (probabilityCkd != null) {
      return (probabilityCkd! * 100).clamp(0.0, 100.0);
    }
    if (probabilitas != null && prediction == 1) {
      return (probabilitas! * 100).clamp(0.0, 100.0);
    }
    if (isRisikoTinggi) return 72.5;
    if (isRisikoSedang) return 45.0;
    return 14.2;
  }

  /// Persentase probabilitas Non-CKD untuk perbandingan visual (0..100)
  double get displayNoCkdPercentage {
    if (probabilityNoCkd != null) {
      return (probabilityNoCkd! * 100).clamp(0.0, 100.0);
    }
    return (100.0 - displayCkdPercentage).clamp(0.0, 100.0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEGACY COMPATIBILITY MODELS (Untuk kompatibilitas riwayat / chat yang sudah ada)
// ─────────────────────────────────────────────────────────────────────────────

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
