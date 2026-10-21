import 'package:flutter/material.dart';
import '../../../models/pragi_model.dart';
import 'pragi_state_service.dart';
import 'pragi_ui_kit.dart';
import '../../../master_layout.dart';

class PragiResultScreen extends StatelessWidget {
  final PragiHasilSkrining? hasil;
  final PragiScreeningResult? result;

  const PragiResultScreen({
    super.key,
    this.hasil,
    this.result,
  });

  String get _kategoriRisiko {
    if (hasil != null) return hasil!.kategoriRisiko.toLowerCase();
    if (result != null) return result!.riskLevel.toLowerCase();
    return 'rendah';
  }

  int? get _prediction => hasil?.prediction ?? result?.prediction;

  double? get _confidencePercent => hasil?.confidencePercent ?? result?.confidencePercent;

  bool get _isRisikoTinggi => _kategoriRisiko.contains('tinggi') || (_prediction == 1 && (_confidencePercent ?? 0) >= 60.0);
  bool get _isRisikoSedang => (_kategoriRisiko.contains('sedang') || _prediction == 1) && !_isRisikoTinggi;

  String get _kategoriLabel {
    if (_isRisikoTinggi) return 'Risiko Tinggi';
    if (_isRisikoSedang) return 'Risiko Sedang';
    return 'Risiko Rendah';
  }

  Color get _kategoriColor {
    if (_isRisikoTinggi) return const Color(0xFFDC2626);
    if (_isRisikoSedang) return const Color(0xFFD97706);
    return const Color(0xFF059669);
  }

  Color get _kategoriBgColor {
    if (_isRisikoTinggi) return const Color(0xFFFEF2F2);
    if (_isRisikoSedang) return const Color(0xFFFFFBEB);
    return const Color(0xFFECFDF5);
  }

  Color get _kategoriBorderColor {
    if (_isRisikoTinggi) return const Color(0xFFFECACA);
    if (_isRisikoSedang) return const Color(0xFFFDE68A);
    return const Color(0xFFA7F3D0);
  }

  int get _skor {
    if (hasil != null) return hasil!.skor;
    if (result != null) {
      final numbers = RegExp(r'\d+').allMatches(result!.riskScore);
      if (numbers.isNotEmpty) {
        return int.tryParse(numbers.first.group(0)!) ?? 0;
      }
    }
    return 0;
  }

  String get _hasilPrediksi {
    if (hasil != null && hasil!.hasilPrediksi.isNotEmpty) {
      return hasil!.hasilPrediksi;
    }
    if (result != null && result!.hasilPrediksi != null && result!.hasilPrediksi!.isNotEmpty) {
      return result!.hasilPrediksi!;
    }
    return 'Hasil Skrining AI PRAGI';
  }

  String get _label {
    if (hasil?.label != null && hasil!.label!.isNotEmpty) {
      return hasil!.label!;
    }
    if (result?.label != null && result!.label!.isNotEmpty) {
      return result!.label!;
    }
    if (_prediction == 1 || _isRisikoTinggi || _isRisikoSedang) {
      return 'Berisiko Penyakit Ginjal Kronis (CKD)';
    }
    return 'Tidak Berisiko Penyakit Ginjal Kronis';
  }

  double get _ckdPercent {
    if (hasil != null) return hasil!.displayCkdPercentage;
    if (_confidencePercent != null && _prediction == 1) {
      return _confidencePercent!.clamp(0.0, 100.0);
    }
    if (result?.probabilityCkd != null) {
      return (result!.probabilityCkd! * 100).clamp(0.0, 100.0);
    }
    if (_isRisikoTinggi) return 72.5;
    if (_isRisikoSedang) return 45.0;
    return 14.2;
  }

  double get _noCkdPercent {
    if (hasil != null) return hasil!.displayNoCkdPercentage;
    if (result?.probabilityNoCkd != null) {
      return (result!.probabilityNoCkd! * 100).clamp(0.0, 100.0);
    }
    return (100.0 - _ckdPercent).clamp(0.0, 100.0);
  }

  String get _sumberPrediksi => hasil?.sumberPrediksi ?? result?.sumberPrediksi ?? 'python_ml_api';

  String get _rekomendasi {
    if (hasil != null && hasil!.rekomendasi.isNotEmpty) {
      return hasil!.rekomendasi;
    }
    if (result != null && result!.rekomendasiDokter != null && result!.rekomendasiDokter!.isNotEmpty) {
      return result!.rekomendasiDokter!;
    }
    return 'Pertahankan gaya hidup sehat, minum air putih secara teratur, dan lakukan pemeriksaan kesehatan berkala.';
  }

  List<String> get _faktorRisiko {
    if (hasil != null && hasil!.faktorRisiko.isNotEmpty) {
      return hasil!.faktorRisiko;
    }
    if (result != null && result!.faktorRisiko.isNotEmpty) {
      return result!.faktorRisiko;
    }
    final List<String> list = [];
    if (result != null) {
      if (result!.hasHeartDisease) list.add('Riwayat Penyakit Jantung Koroner');
      if (result!.hasStroke) list.add('Riwayat Penyakit Stroke');
      if (result!.diabetesStatus.toLowerCase().contains('ya') || result!.diabetesStatus.toLowerCase().contains('borderline')) {
        list.add('Riwayat Diabetes / Gula Darah Tinggi');
      }
      if (result!.bmi >= 28.0) list.add('Indeks Massa Tubuh (BMI) Berlebih / Obesitas');
      if (result!.hasSmokingHistory) list.add('Kebiasaan Merokok');
      if (!result!.hasPhysicalActivity) list.add('Kurang Aktivitas Fisik / Olahraga');
      if (result!.hasMobilityDifficulty) list.add('Keterbatasan Mobilitas Fisik');
    }
    return list;
  }

  DateTime get _tanggal {
    if (hasil != null && hasil!.tanggalScreening.isNotEmpty) {
      return DateTime.tryParse(hasil!.tanggalScreening) ?? DateTime.now();
    }
    if (result != null) return result!.date;
    return DateTime.now();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ▼▼▼  DI BAWAH INI HANYA TAMPILAN (UI)  ▼▼▼
  // ═══════════════════════════════════════════════════════════════════════════

  void _goToMaster(BuildContext context, int index) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MasterLayout(initialIndex: index)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PragiScaffold(
      child: Column(
        children: [
          PragiHeader(
            chipLabel: 'Hasil Skrining AI',
            onBack: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                _goToMaster(context, 0);
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kartu ringkasan: cincin persentase + kategori risiko
                  _buildSummaryRingCard(),
                  const SizedBox(height: 16),

                  // Bubble PRAGI: label hasil AI
                  PragiBubble(
                    title: _label,
                    hint:
                        '(Berdasarkan hasil analisis prediktif 16 biomarker dan parameter klinis tubuh yang Anda laporkan.)',
                  ),
                  const SizedBox(height: 16),

                  const PragiSectionLabel('Hasil Analisis Anda'),
                  const SizedBox(height: 14),

                  // Probabilitas CKD vs Non-CKD
                  _buildProbabilityCard(),
                  const SizedBox(height: 12),

                  // Total skor
                  _buildScoreCard(),
                  const SizedBox(height: 12),

                  // Faktor risiko
                  _buildFaktorRisikoSection(),
                  const SizedBox(height: 12),

                  // Rekomendasi AI
                  PragiInfoCard(
                    title: 'Rekomendasi AI PRAGI',
                    body: _rekomendasi,
                    icon: Icons.tips_and_updates_outlined,
                  ),
                  const SizedBox(height: 12),

                  // Ringkasan biomarker (jika ada data result)
                  if (result != null) ...[
                    _buildParameterSummarySection(),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 4),
                  _buildActionButtons(context),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // KARTU RINGKASAN (CINCIN PERSEN + KATEGORI)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSummaryRingCard() {
    final double ckdVal = _ckdPercent;

    return PragiRingCard(
      progress: ckdVal / 100.0,
      centerLabel: 'Risiko',
      centerValue: '${ckdVal.toStringAsFixed(0)}%',
      ringColor: _kategoriColor,
      titleColor: _kategoriColor,
      title: _kategoriLabel,
      subtitle: 'Hasil skrining AI PRAGI • ${_formatDate(_tanggal)}',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PROBABILITAS CKD VS NON-CKD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildProbabilityCard() {
    final double ckdVal = _ckdPercent;
    final double noCkdVal = _noCkdPercent;
    final double? confVal = _confidencePercent;

    return PragiCard(
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: PragiUi.cardDecoration(radius: 10),
                child: const Icon(Icons.analytics_outlined,
                    size: 20, color: PragiUi.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Probabilitas AI Prediksi',
                      style: PragiUi.text(size: 13, weight: FontWeight.w600),
                    ),
                    Text(
                      'CKD vs Non-CKD',
                      style: PragiUi.text(size: 11.5, color: PragiUi.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bar probabilitas dua segmen
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(
                    flex: (ckdVal * 10).round().clamp(1, 999),
                    child: Container(color: const Color(0xFFDC2626)),
                  ),
                  Expanded(
                    flex: (noCkdVal * 10).round().clamp(1, 999),
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendDot(
                color: const Color(0xFFDC2626),
                text: 'Berisiko CKD: ${ckdVal.toStringAsFixed(1)}%',
                textColor: const Color(0xFFDC2626),
              ),
              _legendDot(
                color: const Color(0xFF10B981),
                text: 'Bebas CKD: ${noCkdVal.toStringAsFixed(1)}%',
                textColor: const Color(0xFF047857),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Badge: keyakinan AI & mesin
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                icon: Icons.auto_awesome_rounded,
                text: confVal != null
                    ? 'Keyakinan AI: ${confVal.toStringAsFixed(1)}%'
                    : 'Keyakinan AI: ${ckdVal.toStringAsFixed(1)}%',
                color: const Color(0xFF1D4ED8),
                bg: const Color(0xFFEFF6FF),
                border: const Color(0xFFBFDBFE),
              ),
              _pill(
                icon: Icons.psychology_rounded,
                text: 'AI ML Python Gateway',
                color: const Color(0xFF047857),
                bg: const Color(0xFFECFDF5),
                border: const Color(0xFFA7F3D0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot({
    required Color color,
    required String text,
    required Color textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: PragiUi.text(
            size: 11.5,
            weight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _pill({
    required IconData icon,
    required String text,
    required Color color,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: PragiUi.text(size: 11, weight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOTAL SKOR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildScoreCard() {
    return PragiCard(
      radius: 12,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kategoriBgColor,
              shape: BoxShape.circle,
              border: Border.all(color: _kategoriBorderColor, width: 1.5),
            ),
            child: Text(
              '$_skor',
              style: PragiUi.text(
                size: 16,
                weight: FontWeight.w700,
                color: _kategoriColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Skor Risiko: $_skor poin',
                  style: PragiUi.text(size: 12.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _isRisikoTinggi
                      ? 'Skor mengindikasikan prioritas perhatian klinis nefrologi'
                      : (_isRisikoSedang
                          ? 'Skor berada dalam batas kewaspadaan moderat'
                          : 'Skor berada dalam batas normal / terpantau aman'),
                  style: PragiUi.text(
                    size: 11.5,
                    color: PragiUi.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FAKTOR RISIKO
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFaktorRisikoSection() {
    final factors = _faktorRisiko;

    return PragiCard(
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: PragiUi.cardDecoration(radius: 10),
                child: const Icon(Icons.fact_check_outlined,
                    size: 20, color: PragiUi.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Faktor Risiko Teridentifikasi',
                  style: PragiUi.text(size: 13.5, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (factors.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF059669), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tidak ada faktor risiko tinggi yang teridentifikasi. Terus pertahankan pola makan rendah garam dan aktivitas fisik rutin!',
                      style: PragiUi.text(
                        size: 12,
                        color: const Color(0xFF065F46),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'Berdasarkan kuesioner Anda, faktor-faktor berikut berkontribusi pada kalkulasi risiko ginjal:',
              style: PragiUi.text(size: 12, color: PragiUi.muted, height: 1.45),
            ),
            const SizedBox(height: 12),
            ...List.generate(factors.length, (i) {
              return Padding(
                padding:
                    EdgeInsets.only(bottom: i == factors.length - 1 ? 0 : 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFDE68A),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: PragiUi.text(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          factors[i],
                          style: PragiUi.text(
                            size: 12.5,
                            weight: FontWeight.w500,
                            color: const Color(0xFF92400E),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RINGKASAN BIOMARKER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildParameterSummarySection() {
    if (result == null) return const SizedBox.shrink();
    final r = result!;

    return PragiCard(
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Data Biomarker',
            style: PragiUi.text(size: 13.5, weight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildParameterChip(
                  title: 'IMT / BMI',
                  value: '${r.bmi.toStringAsFixed(1)} kg/m²',
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildParameterChip(
                  title: 'Durasi Tidur',
                  value: '${r.sleepHours ?? 7} Jam / hari',
                  icon: Icons.bedtime_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildParameterChip(
                  title: 'Riwayat Diabetes',
                  value: r.diabetesStatus,
                  icon: Icons.bloodtype_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildParameterChip(
                  title: 'Aktivitas Fisik',
                  value: r.hasPhysicalActivity ? 'Rutin Aktif' : 'Kurang Aktif',
                  icon: Icons.directions_run_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParameterChip({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PragiUi.selectedBg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: PragiUi.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: PragiUi.text(
                    size: 11,
                    weight: FontWeight.w500,
                    color: PragiUi.muted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: PragiUi.text(size: 12.5, weight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ACTION BUTTONS (KONSULTASI DOKTER / KEMBALI KE BERANDA)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildActionButtons(BuildContext context) {
    final bool hasRisk = _isRisikoSedang || _isRisikoTinggi || _prediction == 1;

    if (hasRisk) {
      return Column(
        children: [
          // Primary: Konsultasi Dokter Ginjal Sekarang
          PragiPrimaryButton(
            label: 'Konsultasi Dokter Ginjal Sekarang',
            icon: Icons.medical_services_rounded,
            color: _isRisikoTinggi ? const Color(0xFFDC2626) : PragiUi.green,
            onPressed: () => _goToMaster(context, 1),
          ),
          const SizedBox(height: 12),

          // Secondary: Riwayat Skrining & Ke Beranda
          Row(
            children: [
              Expanded(
                child: PragiOutlineButton(
                  label: 'Riwayat Skrining',
                  icon: Icons.history_rounded,
                  onPressed: () => _goToMaster(context, 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PragiOutlineButton(
                  label: 'Ke Beranda',
                  icon: Icons.home_outlined,
                  onPressed: () => _goToMaster(context, 0),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Risiko Rendah
      return Column(
        children: [
          // Primary: Kembali ke Beranda
          PragiPrimaryButton(
            label: 'Kembali ke Beranda',
            icon: Icons.home_rounded,
            onPressed: () => _goToMaster(context, 0),
          ),
          const SizedBox(height: 12),

          // Secondary: Riwayat Skrining & Konsultasi Dokter Opsional
          Row(
            children: [
              Expanded(
                child: PragiOutlineButton(
                  label: 'Riwayat Skrining',
                  icon: Icons.history_rounded,
                  onPressed: () => _goToMaster(context, 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PragiOutlineButton(
                  label: 'Konsultasi Dokter',
                  icon: Icons.medical_services_outlined,
                  onPressed: () => _goToMaster(context, 1),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }
}
