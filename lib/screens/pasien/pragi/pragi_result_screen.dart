import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/pragi_model.dart';
import 'pragi_state_service.dart';
import 'pragi_topography_background.dart';
import '../../../master_layout.dart';

class PragiResultScreen extends StatelessWidget {
  final PragiHasilSkrining? hasil;
  final PragiScreeningResult? result;

  const PragiResultScreen({
    super.key,
    this.hasil,
    this.result,
  });

  static const _darkGreen = Color(0xFF065A37);
  static const _primaryGreen = Color(0xFF065A37);

  String get _kategoriRisiko {
    if (hasil != null) return hasil!.kategoriRisiko.toLowerCase();
    if (result != null) return result!.riskLevel.toLowerCase();
    return 'rendah';
  }

  bool get _isRisikoTinggi => _kategoriRisiko.contains('tinggi');
  bool get _isRisikoSedang => _kategoriRisiko.contains('sedang');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      body: Stack(
        children: [
          // Background Topography
          Positioned.fill(
            child: CustomPaint(
              painter: PragiTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Back Pill Button
                      GestureDetector(
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const MasterLayout(initialIndex: 0)),
                              (r) => false,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back, size: 16, color: Color(0xFF1E293B)),
                              const SizedBox(width: 4),
                              Text(
                                'Kembali',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Center Badge: Hasil Skrining
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: _primaryGreen,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryGreen.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Hasil Skrining AI',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 80),
                    ],
                  ),
                ),

                // Main Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Result Card
                        _buildMainResultCard(),

                        const SizedBox(height: 20),

                        // Section: Faktor Risiko Teridentifikasi
                        _buildFaktorRisikoSection(),

                        const SizedBox(height: 20),

                        // Section: Rekomendasi AI PRAGI
                        _buildRecommendationCard(context),

                        const SizedBox(height: 20),

                        // Section: Parameter Ringkasan Pasien (Jika ada data result)
                        if (result != null) ...[
                          _buildParameterSummarySection(),
                          const SizedBox(height: 20),
                        ],

                        // Action Buttons: Konsultasi Dokter & Beranda
                        _buildActionButtons(context),

                        const SizedBox(height: 36),
                      ],
                    ),
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
  // MAIN RESULT HERO CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMainResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Date Pill & ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(_tanggal),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'PRAGI AI v2.0',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Badge Kategori Risiko
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _kategoriBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kategoriBorderColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isRisikoTinggi
                      ? Icons.warning_rounded
                      : (_isRisikoSedang ? Icons.shield_outlined : Icons.check_circle_rounded),
                  color: _kategoriColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _kategoriLabel.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _kategoriColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Prediksi Title
          Text(
            _hasilPrediksi,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.25,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Berdasarkan pemrosesan 16 biomarker dan parameter klinis yang telah Anda laporkan secara lengkap.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),

          // Score Indicator Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kategoriColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$_skor',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kategoriColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Skor Risiko: $_skor poin',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isRisikoTinggi
                            ? 'Skor mengindikasikan prioritas perhatian klinis'
                            : (_isRisikoSedang
                                ? 'Skor berada dalam batas kewaspadaan moderat'
                                : 'Skor berada dalam batas normal / terpantau aman'),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
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
  // FAKTOR RISIKO SECTION
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFaktorRisikoSection() {
    final factors = _faktorRisiko;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics_rounded, size: 18, color: _darkGreen),
              ),
              const SizedBox(width: 10),
              Text(
                'Faktor Risiko Teridentifikasi',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (factors.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tidak ada faktor risiko tinggi yang teridentifikasi. Terus pertahankan pola makan rendah garam dan aktivitas fisik rutin!',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF065F46),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Berdasarkan kuesioner Anda, faktor-faktor berikut berkontribusi pada kalkulasi risiko ginjal:',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 12),
            ...factors.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.fiber_manual_record, size: 10, color: Color(0xFFD97706)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF92400E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REKOMENDASI MEDIS AI PRAGI
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRecommendationCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/pragi.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.smart_toy_rounded,
                      color: _darkGreen,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekomendasi AI PRAGI',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _darkGreen,
                    ),
                  ),
                  Text(
                    'Panduan preventif berbasis profil Anda',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _rekomendasi,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF166534),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PARAMETER SUMMARY GRID
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildParameterSummarySection() {
    if (result == null) return const SizedBox.shrink();
    final r = result!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Data Biomarker',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
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
    if (_isRisikoSedang || _isRisikoTinggi) {
      return Column(
        children: [
          // Primary: Konsultasi Dokter
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MasterLayout(initialIndex: 1),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.medical_services_rounded, size: 18),
              label: Text(
                'Konsultasi Dokter Sekarang',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary: Kembali ke Beranda
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MasterLayout(initialIndex: 0),
                  ),
                  (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                foregroundColor: const Color(0xFF334155),
              ),
              child: Text(
                'Kembali ke Beranda',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Risiko Rendah
      return Column(
        children: [
          // Primary: Kembali ke Beranda
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MasterLayout(initialIndex: 0),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
              ),
              child: Text(
                'Kembali ke Beranda',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary: Konsultasi Dokter Opsional
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MasterLayout(initialIndex: 1),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.medical_services_outlined, size: 18),
              label: Text(
                'Konsultasi Dokter (Opsional)',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                foregroundColor: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      );
    }
  }
}
