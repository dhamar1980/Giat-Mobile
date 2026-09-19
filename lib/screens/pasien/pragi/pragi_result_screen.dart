import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pragi_state_service.dart';
import 'pragi_topography_background.dart';
import '../konsultasi/dokter_list_screen.dart';

class PragiResultScreen extends StatelessWidget {
  final PragiScreeningResult result;

  const PragiResultScreen({
    super.key,
    required this.result,
  });

  static const _darkGreen = Color(0xFF065A37);
  static const _primaryGreen = Color(0xFF065A37);

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
                        onTap: () => Navigator.of(context).pop(),
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
                          'Hasil Skrining',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 80), // Balance back button
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
                        // Header Card
                        _buildHeaderCard(),

                        const SizedBox(height: 24),

                        // Section 1: Gambaran Hasil
                        _buildSectionPill('Gambaran Hasil'),
                        const SizedBox(height: 10),
                        Text(
                          'Ini merupakan hasil skrining awal berdasarkan jawaban yang kamu berikan. Informasi ini ditujukan untuk membantu meningkatkan kesadaran preventif terhadap kesehatan ginjal dan bukan merupakan diagnosis medis.',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: const Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Section 2: Faktor yang Perlu Diperhatikan
                        _buildSectionPill('Faktor yang Perlu Diperhatikan'),
                        const SizedBox(height: 8),
                        Text(
                          'Faktor-faktor berikut merupakan komponen parameter yang telah Anda laporkan:',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 6 Parameter Cards (2 Columns Grid)
                        _buildParameterGrid(),

                        const SizedBox(height: 24),

                        // Recommendation Action Card
                        _buildRecommendationCard(context),

                        const SizedBox(height: 32),
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

  Widget _buildSectionPill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _darkGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Badge on top right
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Tanggal Skrinning: ${_formatDate(result.date)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stethoscope Icon in Box
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  size: 30,
                  color: _darkGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hasil Skrining Risiko CKD',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '(Hasil)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hasil ini memberikan gambaran awal berdasarkan jawaban skrining yang kamu berikan.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParameterGrid() {
    return Column(
      children: [
        // Row 1: Usia/Gender + IMT
        Row(
          children: [
            Expanded(
              child: _buildParamCard(
                icon: Icons.person_rounded,
                title: 'Usia dan Gender',
                val1: result.gender,
                val2: result.ageRange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildParamCard(
                icon: Icons.calculate_rounded,
                title: 'Indeks Massa Tubuh',
                val1: result.bmi.toStringAsFixed(1).replaceAll('.', ','),
                val2: 'kg/m²',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Riwayat Penyakit + Riwayat Diabetes
        Row(
          children: [
            Expanded(
              child: _buildParamCard(
                icon: Icons.favorite_rounded,
                title: 'Riwayat Penyakit',
                val1: 'Jantung: ${result.hasHeartDisease ? 'Ya' : 'Tidak'}',
                val2: 'Stroke: ${result.hasStroke ? 'Ya' : 'Tidak'}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildParamCard(
                icon: Icons.water_drop_rounded,
                title: 'Riwayat Diabetes',
                val1: result.diabetesStatus == 'Tidak' ? 'Tidak Ada' : 'Terpantau',
                val2: result.diabetesStatus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 3: Aktivitas Fisik + Gaya Hidup
        Row(
          children: [
            Expanded(
              child: _buildParamCard(
                icon: Icons.directions_run_rounded,
                title: 'Aktivitas Fisik',
                val1: result.hasPhysicalActivity ? 'Rutin Berolahraga' : 'Aktivitas Sedentari',
                val2: result.hasPhysicalActivity ? '≥20-30 mnt rutin' : 'Kurang bergerak',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildParamCard(
                icon: Icons.eco_rounded,
                title: 'Gaya Hidup',
                val1: 'Merokok: ${result.hasSmokingHistory ? 'Ya' : 'Tidak'}',
                val2: 'Alkohol: ${result.hasExcessiveAlcohol ? 'Berlebih' : 'Wajar / Tidak'}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParamCard({
    required IconData icon,
    required String title,
    required String val1,
    required String val2,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: _darkGreen),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            val1,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          if (val2.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              val2,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: _darkGreen, size: 22),
              const SizedBox(width: 8),
              Text(
                'Langkah Tindak Lanjut',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Konsultasikan hasil ini kepada Dokter atau Apoteker GIAT untuk mendapatkan rekomendasi gaya hidup dan pemeriksaan laboratorium penunjang.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF166534),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DokterListScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medical_services_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Konsultasi Dokter Sekarang',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
