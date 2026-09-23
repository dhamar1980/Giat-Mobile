import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pragi_state_service.dart';
import 'pragi_topography_background.dart';
import 'pragi_screening_screen.dart';
import 'pragi_result_screen.dart';
import '../profile/profile_pasien_screen.dart';
import '../widgets/pasien_bottom_navbar.dart';

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
        final latest = history.isNotEmpty ? history.first : null;
        final pastHistory = history.length > 1 ? history.sublist(1) : <PragiScreeningResult>[];

        return Column(
          children: [
            if (!widget.isEmbedded)
              // Top App Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                          const Spacer(),
                          // Notification Bell
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B)),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tidak ada notifikasi baru.')),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Profile Circle Button
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProfilePasienScreen()),
                              );
                            },
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _darkGreen,
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Main Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          20,
                          widget.isEmbedded ? (MediaQuery.of(context).padding.top + 72) : 4,
                          20,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Center Badge: Prajurit Ginjal
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

                            // Section: Hasil Skrining Terakhir
                            Text(
                              'Hasil Skrining Terakhir',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),

                            const SizedBox(height: 12),

                            if (latest != null)
                              _buildScreeningCard(
                                context: context,
                                result: latest,
                                isLatest: true,
                              )
                            else
                              _buildEmptyPlaceholder('Belum ada skrining sebelumnya'),

                            const SizedBox(height: 24),

                            // Section: Riwayat Skrining
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Riwayat Skrining',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Menampilkan semua riwayat skrining.')),
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Lihat Semua Riwayat',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_circle_right_outlined, size: 16, color: Color(0xFF0F172A)),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            if (pastHistory.isNotEmpty)
                              ...pastHistory.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildScreeningCard(
                                      context: context,
                                      result: item,
                                      isLatest: false,
                                    ),
                                  ))
                            else
                              _buildEmptyPlaceholder('Tidak ada riwayat tambahan'),

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, Aku PRAGI 👋👋\nAku AI yang membantu kamu melakukan skrining awal risiko CKD lohh...',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '12.00',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF86EFAC),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, size: 14, color: Color(0xFF86EFAC)),
                    ],
                  ),
                ),
              ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Siap mengetahui gambaran risiko kamu?',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '12.00',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF86EFAC),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.done_all, size: 14, color: Color(0xFF86EFAC)),
                        ],
                      ),
                    ),
                  ],
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
    required bool isLatest,
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
