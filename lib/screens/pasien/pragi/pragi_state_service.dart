import 'package:flutter/material.dart';
import '../../../models/pragi_model.dart';

/// Data model for a completed PRAGI CKD screening
class PragiScreeningResult {
  final String id;
  final DateTime date;
  final String gender; // 'Laki-laki' | 'Perempuan' | 'Male' | 'Female'
  final String ageRange; // e.g. '45 – 49 thn'
  final double heightCm; // e.g. 168
  final double weightKg; // e.g. 65
  final double bmi; // e.g. 23.0
  final String? race; // e.g. 'Asia (Asian)'
  final String? generalHealth; // e.g. 'Baik (Good)'
  final int? physicalHealthDays; // 0..30
  final int? mentalHealthDays; // 0..30
  final int? sleepHours; // 1..24
  final bool hasHeartDisease;
  final bool hasStroke;
  final String diabetesStatus;
  final bool? hasAsthma;
  final bool hasPhysicalActivity;
  final bool hasSmokingHistory;
  final bool hasExcessiveAlcohol;
  final bool hasMobilityDifficulty;
  final String riskLevel; // 'Rendah' | 'Sedang' | 'Tinggi'
  final String riskScore; // e.g. 'Skor 12 / 100' or 'Skor 4'
  final String? rekomendasiDokter;
  final List<String> faktorRisiko;
  final String? hasilPrediksi;
  final String? label;
  final int? prediction;
  final double? confidencePercent;
  final double? probabilityCkd;
  final double? probabilityNoCkd;
  final double? probabilitas;
  final String? sumberPrediksi;
  final bool isFallback;

  PragiScreeningResult({
    required this.id,
    required this.date,
    required this.gender,
    required this.ageRange,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    this.race = 'Asia (Asian)',
    this.generalHealth = 'Baik (Good)',
    this.physicalHealthDays = 0,
    this.mentalHealthDays = 0,
    this.sleepHours = 7,
    required this.hasHeartDisease,
    required this.diabetesStatus,
    required this.hasStroke,
    this.hasAsthma = false,
    required this.hasPhysicalActivity,
    required this.hasSmokingHistory,
    required this.hasExcessiveAlcohol,
    required this.hasMobilityDifficulty,
    this.riskLevel = 'Rendah',
    this.riskScore = 'Risiko Rendah',
    this.rekomendasiDokter,
    this.faktorRisiko = const [],
    this.hasilPrediksi,
    this.label,
    this.prediction,
    this.confidencePercent,
    this.probabilityCkd,
    this.probabilityNoCkd,
    this.probabilitas,
    this.sumberPrediksi,
    this.isFallback = false,
  });

  factory PragiScreeningResult.fromHasil({
    required PragiHasilSkrining hasil,
    required Map<String, dynamic> jawaban,
  }) {
    final double bmiVal = double.tryParse(jawaban['BMI']?.toString() ?? '23.0') ?? 23.0;
    final int physDays = int.tryParse(jawaban['PhysicalHealth']?.toString() ?? '0') ?? 0;
    final int mentDays = int.tryParse(jawaban['MentalHealth']?.toString() ?? '0') ?? 0;
    final int sleepH = int.tryParse(jawaban['SleepTime']?.toString() ?? '7') ?? 7;

    return PragiScreeningResult(
      id: hasil.idPragi.isNotEmpty ? hasil.idPragi : 'scr-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.tryParse(hasil.tanggalScreening) ?? DateTime.now(),
      gender: jawaban['Sex']?.toString() ?? 'Male',
      ageRange: jawaban['AgeCategory']?.toString() ?? '45–49 tahun',
      heightCm: 168.0,
      weightKg: 65.0,
      bmi: bmiVal,
      race: jawaban['Race']?.toString() ?? 'Asian',
      generalHealth: jawaban['GenHealth']?.toString() ?? 'Good',
      physicalHealthDays: physDays,
      mentalHealthDays: mentDays,
      sleepHours: sleepH,
      hasHeartDisease: (jawaban['HeartDisease']?.toString().toLowerCase() == 'yes'),
      hasStroke: (jawaban['Stroke']?.toString().toLowerCase() == 'yes'),
      diabetesStatus: jawaban['Diabetic']?.toString() ?? 'No',
      hasAsthma: (jawaban['Asthma']?.toString().toLowerCase() == 'yes'),
      hasPhysicalActivity: (jawaban['PhysicalActivity']?.toString().toLowerCase() == 'yes'),
      hasSmokingHistory: (jawaban['Smoking']?.toString().toLowerCase() == 'yes'),
      hasExcessiveAlcohol: (jawaban['AlcoholDrinking']?.toString().toLowerCase() == 'yes'),
      hasMobilityDifficulty: (jawaban['DiffWalking']?.toString().toLowerCase() == 'yes'),
      riskLevel: hasil.formattedKategori.replaceAll('Risiko ', ''),
      riskScore: 'Skor ${hasil.skor}',
      rekomendasiDokter: hasil.rekomendasi,
      faktorRisiko: hasil.faktorRisiko,
      hasilPrediksi: hasil.hasilPrediksi,
      label: hasil.label,
      prediction: hasil.prediction,
      confidencePercent: hasil.confidencePercent,
      probabilityCkd: hasil.probabilityCkd,
      probabilityNoCkd: hasil.probabilityNoCkd,
      probabilitas: hasil.probabilitas,
      sumberPrediksi: hasil.sumberPrediksi,
      isFallback: hasil.isFallback,
    );
  }
}

/// Global State Management for PRAGI Screening & History
class PragiService {
  static final PragiService _instance = PragiService._internal();
  factory PragiService() => _instance;
  PragiService._internal();

  final ValueNotifier<List<PragiScreeningResult>> historyNotifier =
      ValueNotifier<List<PragiScreeningResult>>([
    PragiScreeningResult(
      id: 'scr-001',
      date: DateTime(2026, 9, 1),
      gender: 'Laki-laki',
      ageRange: '45–49 tahun',
      heightCm: 168,
      weightKg: 65,
      bmi: 23.0,
      race: 'Asia (Asian)',
      generalHealth: 'Baik (Good)',
      physicalHealthDays: 0,
      mentalHealthDays: 2,
      sleepHours: 7,
      hasHeartDisease: false,
      hasStroke: false,
      diabetesStatus: 'Tidak',
      hasAsthma: false,
      hasPhysicalActivity: true,
      hasSmokingHistory: false,
      hasExcessiveAlcohol: false,
      hasMobilityDifficulty: false,
      riskLevel: 'Rendah',
      riskScore: 'Risiko Terpantau Rendah',
    ),
    PragiScreeningResult(
      id: 'scr-002',
      date: DateTime(2026, 8, 20),
      gender: 'Laki-laki',
      ageRange: '45–49 tahun',
      heightCm: 168,
      weightKg: 66,
      bmi: 23.4,
      race: 'Asia (Asian)',
      generalHealth: 'Baik (Good)',
      physicalHealthDays: 1,
      mentalHealthDays: 1,
      sleepHours: 6,
      hasHeartDisease: false,
      hasStroke: false,
      diabetesStatus: 'Tidak',
      hasAsthma: false,
      hasPhysicalActivity: true,
      hasSmokingHistory: false,
      hasExcessiveAlcohol: false,
      hasMobilityDifficulty: false,
      riskLevel: 'Rendah',
      riskScore: 'Risiko Terpantau Rendah',
    ),
    PragiScreeningResult(
      id: 'scr-003',
      date: DateTime(2026, 8, 5),
      gender: 'Laki-laki',
      ageRange: '45–49 tahun',
      heightCm: 168,
      weightKg: 65.5,
      bmi: 23.2,
      race: 'Asia (Asian)',
      generalHealth: 'Cukup / Biasa Saja (Fair)',
      physicalHealthDays: 3,
      mentalHealthDays: 5,
      sleepHours: 6,
      hasHeartDisease: false,
      hasStroke: false,
      diabetesStatus: 'Tidak',
      hasAsthma: false,
      hasPhysicalActivity: false,
      hasSmokingHistory: false,
      hasExcessiveAlcohol: false,
      hasMobilityDifficulty: false,
      riskLevel: 'Rendah',
      riskScore: 'Risiko Terpantau Rendah',
    ),
    PragiScreeningResult(
      id: 'scr-004',
      date: DateTime(2026, 7, 18),
      gender: 'Laki-laki',
      ageRange: '45–49 tahun',
      heightCm: 168,
      weightKg: 65.0,
      bmi: 23.0,
      race: 'Asia (Asian)',
      generalHealth: 'Sangat Baik (Very Good)',
      physicalHealthDays: 0,
      mentalHealthDays: 0,
      sleepHours: 8,
      hasHeartDisease: false,
      hasStroke: false,
      diabetesStatus: 'Tidak',
      hasAsthma: false,
      hasPhysicalActivity: true,
      hasSmokingHistory: false,
      hasExcessiveAlcohol: false,
      hasMobilityDifficulty: false,
      riskLevel: 'Rendah',
      riskScore: 'Risiko Terpantau Rendah',
    ),
  ]);

  void addResult(PragiScreeningResult result) {
    historyNotifier.value = [result, ...historyNotifier.value];
  }

  PragiScreeningResult? get latestResult {
    if (historyNotifier.value.isEmpty) return null;
    return historyNotifier.value.first;
  }
}
