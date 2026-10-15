/// Model for Pantau Kesehatan (Catatan Harian Ginjal & IMT)
class PantauModel {
  final dynamic id;
  final double bb;
  final double tb;
  final double imt;
  final String kondisiTubuh;
  final String keluhan;
  final String? detailKeluhan;
  final String? catatan;
  final String tanggal;

  PantauModel({
    required this.id,
    required this.bb,
    required this.tb,
    required this.imt,
    required this.kondisiTubuh,
    required this.keluhan,
    this.detailKeluhan,
    this.catatan,
    required this.tanggal,
  });

  factory PantauModel.fromJson(Map<String, dynamic> json) {
    return PantauModel(
      id: json['id'],
      bb: double.tryParse(json['bb']?.toString() ?? json['berat_badan']?.toString() ?? '0') ?? 0.0,
      tb: double.tryParse(json['tb']?.toString() ?? json['tinggi_badan']?.toString() ?? '0') ?? 0.0,
      imt: double.tryParse(json['imt']?.toString() ?? json['bmi']?.toString() ?? '0') ?? 0.0,
      kondisiTubuh: json['kondisi_tubuh']?.toString() ?? json['kondisi']?.toString() ?? 'Baik',
      keluhan: json['keluhan']?.toString() ?? 'Tidak ada',
      detailKeluhan: json['detail_keluhan']?.toString(),
      catatan: json['catatan']?.toString(),
      tanggal: json['tanggal']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bb': bb,
      'tb': tb,
      'keluhan': keluhan,
      'detail_keluhan': detailKeluhan,
      'catatan': catatan,
    };
  }
}

/// Summary of Pantau Kesehatan
class PantauSummary {
  final double rataRataBb;
  final double rataRataImt;
  final String trenBeratBadan;
  final PantauModel? catatanTerakhir;

  PantauSummary({
    required this.rataRataBb,
    required this.rataRataImt,
    required this.trenBeratBadan,
    this.catatanTerakhir,
  });

  factory PantauSummary.fromJson(Map<String, dynamic> json) {
    return PantauSummary(
      rataRataBb: double.tryParse(json['rata_rata_bb']?.toString() ?? json['avg_weight']?.toString() ?? '0') ?? 0.0,
      rataRataImt: double.tryParse(json['rata_rata_imt']?.toString() ?? json['avg_bmi']?.toString() ?? '0') ?? 0.0,
      trenBeratBadan: json['tren_berat_badan']?.toString() ?? json['trend']?.toString() ?? 'Stabil',
      catatanTerakhir: json['catatan_terakhir'] is Map<String, dynamic>
          ? PantauModel.fromJson(json['catatan_terakhir'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Chart Data for Pantau Kesehatan
class PantauChartData {
  final List<String> labels;
  final List<double> beratBadan;
  final List<double> bmi;

  PantauChartData({
    required this.labels,
    required this.beratBadan,
    required this.bmi,
  });

  factory PantauChartData.fromJson(Map<String, dynamic> json) {
    final rawLabels = json['labels'] is List ? json['labels'] as List : [];
    final rawBb = json['berat_badan'] is List ? json['berat_badan'] as List : [];
    final rawBmi = json['bmi'] is List ? json['bmi'] as List : [];

    return PantauChartData(
      labels: rawLabels.map((e) => e.toString()).toList(),
      beratBadan: rawBb.map((e) => double.tryParse(e.toString()) ?? 0.0).toList(),
      bmi: rawBmi.map((e) => double.tryParse(e.toString()) ?? 0.0).toList(),
    );
  }
}
