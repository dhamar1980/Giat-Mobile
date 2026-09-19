import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pragi_state_service.dart';
import 'pragi_topography_background.dart';
import 'pragi_result_screen.dart';

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

    // Auto-navigate to Result Screen after 2.5 seconds
    _transitionTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      // Save result to history
      PragiService().addResult(widget.result);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PragiResultScreen(result: widget.result),
        ),
      );
    });
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
