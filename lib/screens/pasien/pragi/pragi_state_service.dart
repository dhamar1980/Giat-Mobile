import 'package:flutter/material.dart';

/// Data model for a completed PRAGI CKD screening
class PragiScreeningResult {
  final String id;
  final DateTime date;
  final String gender; // 'Laki-laki' | 'Perempuan'
  final String ageRange; // e.g. '45 – 49 thn'
  final double heightCm; // e.g. 168
  final double weightKg; // e.g. 65
  final double bmi; // e.g. 23.0
  final bool hasHeartDisease;
  final String diabetesStatus; // 'Ya, pernah' | 'Ya, tetapi hanya selama kehamilan' | 'Tidak, tetapi pernah diberitahu gula darah tinggi' | 'Tidak'
  final bool hasStroke;
  final bool hasPhysicalActivity;
  final bool hasSmokingHistory;
  final bool hasExcessiveAlcohol;
  final bool hasMobilityDifficulty;
  final String riskLevel; // 'Rendah' | 'Sedang' | 'Tinggi'
  final String riskScore; // e.g. 'Skor 12 / 100'

  PragiScreeningResult({
    required this.id,
    required this.date,
    required this.gender,
    required this.ageRange,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.hasHeartDisease,
    required this.diabetesStatus,
    required this.hasStroke,
    required this.hasPhysicalActivity,
    required this.hasSmokingHistory,
    required this.hasExcessiveAlcohol,
    required this.hasMobilityDifficulty,
    this.riskLevel = 'Rendah',
    this.riskScore = 'Risiko Rendah',
  });
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
      ageRange: '45 – 49 thn',
      heightCm: 168,
      weightKg: 65,
      bmi: 23.0,
      hasHeartDisease: false,
      hasStroke: false,
      diabetesStatus: 'Tidak',
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
      ageRange: '45 – 49 thn',
      heightCm: 168,
      weightKg: 66,
      bmi: 23.4,
      hasHeartDisease: false,
      hasStroke: false,
      diabetesStatus: 'Tidak',
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
      ageRange: '45 – 49 thn',
      heightCm: 168,
      weightKg: 65.5,
      bmi: 23.2,
      hasHeartDisease: false,
      hasStroke: false,
      diabetesStatus: 'Tidak',
      hasPhysicalActivity: false,
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
