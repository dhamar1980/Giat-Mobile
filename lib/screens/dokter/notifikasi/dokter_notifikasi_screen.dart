import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import '../konsultasi/dokter_room_chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIKASI DOKTER SCREEN (Figma Node: 1624-7166)
// Tampilan Notifikasi Dokter dengan Header Pill & Background Topografi
// ─────────────────────────────────────────────────────────────────────────────

class DokterNotifikasiScreen extends StatelessWidget {
  const DokterNotifikasiScreen({super.key});

  static const _darkGreen = Color(0xFF005954);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _textColor = Color(0xFF0F172A);
  static const _subtextColor = Color(0xFF1E293B);
  static const _avatarBgColor = Color(0xFFCCE4ED);

  @override
  Widget build(BuildContext context) {
    final notifs = DokterMockData.notifications;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Background Topografi Organik GIAT (Kurva Gelombang Hijau) ──
          Positioned.fill(
            child: CustomPaint(
              painter: _NotifikasiTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Navigation Bar (Kembali Pill di kiri, Notifikasi Pill di tengah) ──
                _buildHeaderBar(context),

                const SizedBox(height: 18),

                // ── Daftar Kartu Notifikasi ──
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: notifs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = notifs[index];
                      return _buildNotificationCard(context, item);
                    },
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
  // HEADER BAR (Tombol "<- Kembali" di kiri atas, lalu Pill "Notifikasi" di tengah)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tombol Pill "<- Kembali"
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _textColor, width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 14, color: _textColor),
                  const SizedBox(width: 5),
                  Text(
                    'Kembali',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Centered "Notifikasi" Badge Pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8.5),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _darkGreen.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Notifikasi',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NOTIFICATION CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildNotificationCard(BuildContext context, DokterNotificationItem item) {
    final isSystem = item.type == 'sistem';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleCardTap(context, item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Box (Pastel Light Blue/Cyan 64x64)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _avatarBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: isSystem
                        ? const Icon(
                            Icons.notifications_active_outlined,
                            color: _textColor,
                            size: 26,
                          )
                        : Text(
                            item.initials,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              color: _textColor,
                              fontSize: 19,
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 14),

                // Text Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title Notifikasi
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Nama Pengirim atau Penjelasan
                      Text(
                        item.senderOrCategory,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: _subtextColor,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Row Waktu dengan Ikon Jam Lingkaran
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: _textColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.timeText,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: _subtextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // INTERAKSI KETIKA KARTU NOTIFIKASI DITEKAN
  // ───────────────────────────────────────────────────────────────────────────
  void _handleCardTap(BuildContext context, DokterNotificationItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _avatarBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: item.type == 'sistem'
                          ? const Icon(Icons.notifications_active_outlined, color: _textColor, size: 24)
                          : Text(
                              item.initials,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                color: _textColor,
                                fontSize: 17,
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
                          item.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.senderOrCategory,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: _subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 15, color: _textColor),
                    const SizedBox(width: 8),
                    Text(
                      item.timeText,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (item.type == 'konsultasi' || item.type == 'jadwal') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      // Pasien Hermanto Kurniawan / fallback
                      final patient = DokterPatient(
                        id: 'p-hk',
                        name: item.senderOrCategory,
                        initials: item.initials,
                        age: 45,
                        gender: 'Laki-laki',
                        address: 'Jl. Pemuda No. 12, Jember',
                        weightKg: 68,
                        heightM: 1.72,
                        condition: 'Stabil',
                        complaint: item.title,
                        complaintDetail: 'Pasien telah terdaftar untuk konsultasi online bersama Anda.',
                        currentMedicines: DokterMockData.initialPrescriptions,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DokterRoomChatScreen(patient: patient),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Buka Ruang Konsultasi',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY PAINTER (GIAT Wavy Organic Curves)
// ─────────────────────────────────────────────────────────────────────────────
class _NotifikasiTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // 1. Kurva Gelombang Atas (Top Contours di sekitar Header)
    for (int i = 0; i < 5; i++) {
      final path = Path();
      final yOffset = -25.0 + (i * 24.0);
      path.moveTo(-20, yOffset + 35);
      path.cubicTo(
        w * 0.30,
        yOffset + 60,
        w * 0.65,
        yOffset - 10,
        w + 30,
        yOffset + 25,
      );
      canvas.drawPath(path, wavePaint);
    }

    // 2. Kurva Gelombang Bawah (Bottom Contours mengalir ke sudut bawah)
    for (int i = 0; i < 8; i++) {
      final path = Path();
      final yOffset = h * 0.52 + (i * 32.0);
      path.moveTo(-30, yOffset + 30);
      path.cubicTo(
        w * 0.35,
        yOffset + 65,
        w * 0.70,
        yOffset - 15,
        w + 40,
        yOffset + 40,
      );
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
