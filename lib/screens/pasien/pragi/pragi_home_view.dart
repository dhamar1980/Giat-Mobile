import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pragi_state_service.dart';
import 'pragi_topography_background.dart';
import 'pragi_screening_screen.dart';
import 'pragi_result_screen.dart';
import '../profile/profile_pasien_screen.dart';
import '../widgets/pasien_bottom_navbar.dart';

import '../../../services/pasien_api_service.dart';

class PragiHomeView extends StatefulWidget {
  final bool isEmbedded;

  const PragiHomeView({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<PragiHomeView> createState() => _PragiHomeViewState();
}

class _PragiHomeViewState extends State<PragiHomeView> {
  static const _darkGreen = Color(0xFF065A37);
  static const _accentGreen = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final res = await PasienApiService().getPragiHistory();
      if (res.success && res.data != null && res.data!.isNotEmpty) {
        final List<PragiScreeningResult> items = [];
        for (var d in res.data!) {
          if (d is Map) {
            final dt = d['created_at'] != null
                ? DateTime.tryParse(d['created_at'].toString()) ?? DateTime.now()
                : (d['tanggal'] != null ? DateTime.tryParse(d['tanggal'].toString()) ?? DateTime.now() : DateTime.now());
            items.add(PragiScreeningResult(
              id: d['id']?.toString() ?? 'scr-${dt.millisecondsSinceEpoch}',
              date: dt,
              gender: d['gender']?.toString() ?? 'Laki-laki',
              ageRange: d['age_range']?.toString() ?? '45 – 49 thn',
              heightCm: double.tryParse(d['tb']?.toString() ?? d['height']?.toString() ?? '168') ?? 168.0,
              weightKg: double.tryParse(d['bb']?.toString() ?? d['weight']?.toString() ?? '65') ?? 65.0,
              bmi: double.tryParse(d['bmi']?.toString() ?? '23.0') ?? 23.0,
              race: d['race']?.toString() ?? d['ras']?.toString() ?? 'Asia (Asian)',
              generalHealth: d['general_health']?.toString() ?? d['kesehatan_umum']?.toString() ?? 'Baik (Good)',
              physicalHealthDays: int.tryParse(d['physical_health_days']?.toString() ?? d['fisik_hari']?.toString() ?? '0') ?? 0,
              mentalHealthDays: int.tryParse(d['mental_health_days']?.toString() ?? d['mental_hari']?.toString() ?? '0') ?? 0,
              sleepHours: int.tryParse(d['sleep_hours']?.toString() ?? d['durasi_tidur']?.toString() ?? '7') ?? 7,
              hasHeartDisease: d['has_heart_disease'] == true || d['jantung'] == 1 || d['jantung'] == 'ya',
              diabetesStatus: d['diabetes_status']?.toString() ?? 'Tidak',
              hasStroke: d['has_stroke'] == true || d['stroke'] == 1 || d['stroke'] == 'ya',
              hasAsthma: d['has_asthma'] == true || d['asma'] == 1 || d['asma'] == 'ya',
              hasPhysicalActivity: d['has_physical_activity'] == true || d['aktivitas'] == 1 || d['aktivitas'] == 'ya',
              hasSmokingHistory: d['has_smoking_history'] == true || d['merokok'] == 1 || d['merokok'] == 'ya',
              hasExcessiveAlcohol: d['has_excessive_alcohol'] == true || d['alkohol'] == 1 || d['alkohol'] == 'ya',
              hasMobilityDifficulty: d['has_mobility_difficulty'] == true || d['mobilitas'] == 1 || d['mobilitas'] == 'ya',
              riskLevel: d['kategori_risiko']?.toString() ?? d['risk_level']?.toString() ?? 'Rendah',
              riskScore: d['total_skor'] != null ? 'Skor ${d['total_skor']}' : (d['risk_score']?.toString() ?? 'Risiko Rendah'),
              rekomendasiDokter: d['rekomendasi_dokter']?.toString() ?? d['rekomendasi']?.toString(),
            ));
          }
        }
        if (items.isNotEmpty && mounted) {
          PragiService().historyNotifier.value = items;
        }
      }
    } catch (_) {}
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
    final bodyContent = ValueListenableBuilder<List<PragiScreeningResult>>(
      valueListenable: PragiService().historyNotifier,
      builder: (context, history, _) {
        final recentHistory = history.take(3).toList();

        return Column(
          children: [
            if (!widget.isEmbedded)
              // Top App Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Spacer(),
                    // Standard Bell & Profile Action Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              size: 22,
                              color: Color(0xFF1F2937),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Tidak ada notifikasi baru.')),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProfilePasienScreen()),
                              );
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _darkGreen,
                              ),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(height: MediaQuery.of(context).padding.top + 76),

            // Center Badge: Prajurit Ginjal (Fixed at top, does NOT scroll)
            Center(
              child: Container(
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
                  'Prajurit Ginjal',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scrollable Main Content Below Fixed Header
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PRAGI Chat Welcome Bubbles
                    _buildWelcomeSection(),

                            const SizedBox(height: 18),

                            // Main Action: Mulai Skrining Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const PragiScreeningScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _darkGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.health_and_safety_rounded, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Mulai Skrining',
                                      style: GoogleFonts.inter(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Info text below button
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_rounded,
                                  color: _darkGreen,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Jawab beberapa pertanyaan untuk mendapatkan gambaran awal risiko CKD.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF065A37),
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Section: Riwayat Skrining (Maksimal 3 riwayat terakhir)
                            Text(
                              'Riwayat Skrining',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),

                            const SizedBox(height: 12),

                            if (recentHistory.isNotEmpty)
                              ...recentHistory.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildScreeningCard(
                                      context: context,
                                      result: item,
                                    ),
                                  ))
                            else
                              _buildEmptyPlaceholder('Belum ada riwayat skrining'),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );

    if (widget.isEmbedded) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: PragiTopographyPainter(),
            ),
          ),
          Positioned.fill(
            child: bodyContent,
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: PragiTopographyPainter(),
            ),
          ),
          SafeArea(
            child: bodyContent,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bubble 1
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _darkGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Halo, Aku PRAGI 👋👋\nAku AI yang membantu kamu melakukan skrining awal risiko CKD lohh...',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Bubble 2 with Mascot Avatar
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Mascot avatar circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _accentGreen, width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/pragi.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.smart_toy_rounded, size: 22, color: _darkGreen),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Bubble
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: _darkGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: Text(
                  'Siap mengetahui gambaran risiko kamu?',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScreeningCard({
    required BuildContext context,
    required PragiScreeningResult result,
    bool isLatest = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PragiResultScreen(result: result),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Square
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Icon(
                isLatest ? Icons.health_and_safety_rounded : Icons.assignment_outlined,
                color: _darkGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(result.date),
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hasil Skrining Tersedia',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lihat Hasil',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF065A37),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_circle_right_outlined,
                  size: 16,
                  color: Color(0xFF065A37),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
        ),
      ),
    );
  }
  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR (matches pasien_home_screen design)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNavigationBar(BuildContext context) {
    return const PasienBottomNavbar(
      currentIndex: 2,
    );
  }
}
