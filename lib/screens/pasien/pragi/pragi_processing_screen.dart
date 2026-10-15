import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pragi_state_service.dart';
import 'pragi_topography_background.dart';
import 'pragi_result_screen.dart';
import '../../../services/pasien_api_service.dart';

class PragiProcessingScreen extends StatefulWidget {
  final PragiScreeningResult result;

  const PragiProcessingScreen({
    super.key,
    required this.result,
  });

  @override
  State<PragiProcessingScreen> createState() => _PragiProcessingScreenState();
}

class _PragiProcessingScreenState extends State<PragiProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _transitionTimer;

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
    final Map<String, dynamic> jawaban = {
      "1": widget.result.gender == 'Laki-laki' ? 'L' : 'P',
      "2": widget.result.ageRange,
      "3": '${widget.result.heightCm}/${widget.result.weightKg}',
      "4": widget.result.hasHeartDisease ? 'ya' : 'tidak',
      "5": widget.result.hasStroke ? 'ya' : 'tidak',
      "6": widget.result.diabetesStatus,
      "7": widget.result.hasPhysicalActivity ? 'ya' : 'tidak',
      "8": widget.result.hasSmokingHistory ? 'ya' : 'tidak',
      "9": widget.result.hasExcessiveAlcohol ? 'ya' : 'tidak',
      "10": widget.result.hasMobilityDifficulty ? 'ya' : 'tidak',
    };

    PragiScreeningResult finalResult = widget.result;

    try {
      final apiResp = await PasienApiService().submitPragi({
        'jawaban': jawaban,
        'risk_level': widget.result.riskLevel,
        'risk_score': widget.result.riskScore,
        'gender': widget.result.gender,
        'age_range': widget.result.ageRange,
        'bmi': widget.result.bmi,
      });

      if (apiResp.success && apiResp.data != null) {
        final data = apiResp.data!;
        final serverRisk = data['kategori_risiko'] ?? data['risk_level'] ?? widget.result.riskLevel;
        final serverScore = data['total_skor']?.toString() ?? data['risk_score'] ?? widget.result.riskScore;
        final serverRekomendasi = data['rekomendasi_dokter'] ?? data['rekomendasi'] ?? '';

        finalResult = PragiScreeningResult(
          id: data['id']?.toString() ?? widget.result.id,
          date: widget.result.date,
          gender: widget.result.gender,
          ageRange: widget.result.ageRange,
          heightCm: widget.result.heightCm,
          weightKg: widget.result.weightKg,
          bmi: widget.result.bmi,
          hasHeartDisease: widget.result.hasHeartDisease,
          diabetesStatus: widget.result.diabetesStatus,
          hasStroke: widget.result.hasStroke,
          hasPhysicalActivity: widget.result.hasPhysicalActivity,
          hasSmokingHistory: widget.result.hasSmokingHistory,
          hasExcessiveAlcohol: widget.result.hasExcessiveAlcohol,
          hasMobilityDifficulty: widget.result.hasMobilityDifficulty,
          riskLevel: serverRisk.toString(),
          riskScore: serverScore.toString(),
          rekomendasiDokter: serverRekomendasi.toString(),
        );
      }
    } catch (_) {}

    PragiService().addResult(finalResult);

    // Keep smooth visual loading experience
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PragiResultScreen(result: finalResult),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _transitionTimer?.cancel();
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
                  // Top Pill: Biomarker Lab Input
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
                      'Biomarker Lab Input',
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

                  // Pill: 10 Jawaban Lengkap
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
                          '10 Jawaban Lengkap',
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

                  // Circular Loading Arc
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(_darkGreen),
                      strokeWidth: 5,
                      backgroundColor: const Color(0xFFE2E8F0),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Title: Sedang memproses...
                  Text(
                    'Sedang memproses hasil skrining...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'PRAGI sedang memproses jawaban kamu untuk memberikan gambaran risiko awal.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),

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
                                'INFORMASI SKRINING',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hasil skrining bukan diagnosis medis. Mohon tunggu sebentar, hasil akan segera ditampilkan secara otomatis.',
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
