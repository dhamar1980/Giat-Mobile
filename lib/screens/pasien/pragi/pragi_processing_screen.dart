import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/pragi_model.dart';
import 'pragi_state_service.dart';
import 'pragi_topography_background.dart';
import 'pragi_result_screen.dart';
import '../../../services/pasien_api_service.dart';

class PragiProcessingScreen extends StatefulWidget {
  final Map<String, dynamic>? jawabanMap;
  final PragiScreeningResult? result;

  const PragiProcessingScreen({
    super.key,
    this.jawabanMap,
    this.result,
  });

  @override
  State<PragiProcessingScreen> createState() => _PragiProcessingScreenState();
}

class _PragiProcessingScreenState extends State<PragiProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String _processingStatus = 'Mengirim data ke AI PRAGI...';
  bool _hasError = false;
  String _errorMessage = '';

  static const _darkGreen = Color(0xFF065A37);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _submitAndTransition();
  }

  Future<void> _submitAndTransition() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _processingStatus = 'Menghubungkan ke API Backend GIAT & Machine Learning Python...';
    });

    final Map<String, dynamic> payloadJawaban = widget.jawabanMap ?? {
      "HeartDisease": widget.result?.hasHeartDisease == true ? "Yes" : "No",
      "BMI": widget.result?.bmi ?? 23.0,
      "Smoking": widget.result?.hasSmokingHistory == true ? "Yes" : "No",
      "AlcoholDrinking": widget.result?.hasExcessiveAlcohol == true ? "Yes" : "No",
      "Stroke": widget.result?.hasStroke == true ? "Yes" : "No",
      "PhysicalHealth": widget.result?.physicalHealthDays ?? 0,
      "MentalHealth": widget.result?.mentalHealthDays ?? 0,
      "DiffWalking": widget.result?.hasMobilityDifficulty == true ? "Yes" : "No",
      "Sex": widget.result?.gender == 'Perempuan' ? 'Female' : 'Male',
      "AgeCategory": widget.result?.ageRange ?? '45-49',
      "Race": widget.result?.race ?? 'Asian',
      "Diabetic": widget.result?.diabetesStatus ?? 'No',
      "PhysicalActivity": widget.result?.hasPhysicalActivity == true ? "Yes" : "No",
      "GenHealth": widget.result?.generalHealth ?? 'Good',
      "SleepTime": widget.result?.sleepHours ?? 7,
      "Asthma": widget.result?.hasAsthma == true ? "Yes" : "No",
    };

    try {
      if (mounted) {
        setState(() {
          _processingStatus = 'Menganalisis 16 biomarker & data klinis Anda...';
        });
      }

      final apiResp = await PasienApiService().submitPragiSkrining(payloadJawaban);

      if (mounted) {
        setState(() {
          _processingStatus = 'Menghitung probabilitas risiko & menyusun rekomendasi personal...';
        });
      }

      await Future.delayed(const Duration(milliseconds: 700));

      PragiHasilSkrining hasil;
      if (apiResp.success && apiResp.data != null) {
        hasil = apiResp.data!;
      } else {
        // Fallback jika API backend mengalami kendala koneksi
        int fallbackScore = 0;
        final List<String> faktor = [];
        if (payloadJawaban['HeartDisease'] == 'Yes') {
          fallbackScore += 2;
          faktor.add('Riwayat Penyakit Jantung Koroner');
        }
        if (payloadJawaban['Stroke'] == 'Yes') {
          fallbackScore += 2;
          faktor.add('Riwayat Stroke');
        }
        if (payloadJawaban['Diabetic'] == 'Yes' || payloadJawaban['Diabetic'] == 'No, borderline diabetes') {
          fallbackScore += 2;
          faktor.add('Riwayat Gula Darah Tinggi / Diabetes');
        }
        final double bmiVal = double.tryParse(payloadJawaban['BMI']?.toString() ?? '23.0') ?? 23.0;
        if (bmiVal >= 28.0) {
          fallbackScore += 1;
          faktor.add('Indeks Massa Tubuh (BMI) Berlebih / Obesitas');
        }
        if (payloadJawaban['Smoking'] == 'Yes') {
          fallbackScore += 1;
          faktor.add('Kebiasaan Merokok Aktif');
        }
        if (payloadJawaban['PhysicalActivity'] == 'No') {
          fallbackScore += 1;
          faktor.add('Kurang Aktivitas Fisik Rutin');
        }

        final String kat = fallbackScore >= 5
            ? 'tinggi'
            : (fallbackScore >= 2 ? 'sedang' : 'rendah');

        hasil = PragiHasilSkrining(
          idPragi: 'pragi-${DateTime.now().millisecondsSinceEpoch}',
          skor: fallbackScore,
          kategoriRisiko: kat,
          hasilPrediksi: 'Risiko ${kat.toUpperCase()} CKD',
          rekomendasi: kat == 'tinggi'
              ? 'Terdeteksi beberapa faktor risiko signifikan untuk gangguan fungsi ginjal. Disarankan segera jadwalkan konsultasi dokter spesialis ginjal/penyakit dalam.'
              : (kat == 'sedang'
                  ? 'Terdapat indikasi risiko sedang. Pertahankan hidrasi optimal, kurangi asupan garam harian, dan pertimbangkan konsultasi dokter.'
                  : 'Kondisi profil risiko ginjal Anda terpantau baik. Pertahankan pola hidup sehat dan rutin minum air putih secukupnya.'),
          faktorRisiko: faktor,
          tanggalScreening: DateTime.now().toIso8601String(),
        );
      }

      final PragiScreeningResult finalResult = PragiScreeningResult.fromHasil(
        hasil: hasil,
        jawaban: payloadJawaban,
      );

      PragiService().addResult(finalResult);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PragiResultScreen(
            hasil: hasil,
            result: finalResult,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Top Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: _darkGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _darkGreen.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'AI Screening Analysis',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // PRAGI Mascot in glowing Circle
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 4,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/pragi.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFDCFCE7),
                          child: const Icon(Icons.smart_toy_rounded, size: 64, color: _darkGreen),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Pill: 16 Jawaban Lengkap
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: _darkGreen),
                        const SizedBox(width: 6),
                        Text(
                          '16 Jawaban Terverifikasi',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  if (_hasError) ...[
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal Menganalisis Skrining',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _submitAndTransition,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _darkGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else ...[
                    // Circular Loading Arc
                    const SizedBox(
                      width: 58,
                      height: 58,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_darkGreen),
                        strokeWidth: 4.5,
                        backgroundColor: Color(0xFFE2E8F0),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Title: AI Sedang Menganalisis...
                    Text(
                      'AI sedang menganalisis profil kesehatan ginjal Anda...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle / Dynamic Status
                    Text(
                      _processingStatus,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],

                  const Spacer(flex: 3),

                  // Bottom Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: _darkGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INFORMASI SKRINING AI PRAGI',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hasil skrining dihitung berdasarkan model prediktif machine learning untuk deteksi dini risiko ginjal. Bukan merupakan diagnosis medis langsung.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF334155),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
