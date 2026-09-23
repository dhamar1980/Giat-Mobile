import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import '../konsultasi/dokter_room_chat_screen.dart';
import '../notifikasi/dokter_notifikasi_screen.dart';
import '../pasien/dokter_detail_pasien_screen.dart';
import '../profile/dokter_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// JADWAL PRAKTIK & PASIEN DOKTER (Sesuai Desain Mockup GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class DokterJadwalScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const DokterJadwalScreen({
    super.key,
    this.onProfileTap,
  });

  @override
  State<DokterJadwalScreen> createState() => _DokterJadwalScreenState();
}

class _DokterJadwalScreenState extends State<DokterJadwalScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF7FBF8);
  static const _border = Color(0xFFE2E8F0);
  static const _dateInactiveBg = Color(0xFFDDF2FD);

  int _selectedDayIndex = 0;
  final List<String> _days = [
    'Senin, 01 Agu',
    'Selasa, 02 Agu',
    'Rabu, 03 Agu',
    'Kamis, 04 Agu',
    'Jumat, 05 Agu',
    'Sabtu, 06 Agu',
  ];

  DokterPatient _findPatient(String patientId) {
    return DokterMockData.patients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => DokterMockData.patients.first,
    );
  }

  void _navigateToDetail(DokterPatient patient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DokterDetailPasienScreen(patient: patient),
      ),
    );
  }

  void _navigateToChat(DokterPatient patient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DokterRoomChatScreen(patient: patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedules = DokterMockData.schedules;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Background Topography Wave ──
          Positioned.fill(
            child: CustomPaint(
              painter: _DokterJadwalTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Header Bar: Notification & Profile Capsule ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildNotificationProfileCapsule(),
                    ],
                  ),
                ),

                const SizedBox(height: 2),

                // ── Title Pill: "Jadwal Pasien" ──
                Center(
                  child: _buildTitlePill('Jadwal Pasien'),
                ),

                const SizedBox(height: 16),

                // ── Scrollable Body Content ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Summary Card: Jumlah Konsultasi Hari Ini ──
                        _buildSummaryCard(),

                        const SizedBox(height: 20),

                        // ── Section: Pilih Tanggal ──
                        Row(
                          children: [
                            const Text('📅', style: TextStyle(fontSize: 15)),
                            const SizedBox(width: 6),
                            Text(
                              'Pilih Tanggal',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ── Horizontal Date Selector Pills ──
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_days.length, (idx) {
                              final isSelected = _selectedDayIndex == idx;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedDayIndex = idx),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _darkGreen : _dateInactiveBg,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: _darkGreen.withValues(alpha: 0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    _days[idx],
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ── Timeline Schedule List ──
                        ...List.generate(schedules.length, (index) {
                          final item = schedules[index];
                          final isLast = index == schedules.length - 1;
                          return _buildTimelineScheduleItem(item, isLast);
                        }),

                        const SizedBox(height: 20),
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
  // TOP NOTIFICATION & PROFILE CAPSULE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildNotificationProfileCapsule() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DokterNotifikasiScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (widget.onProfileTap != null) {
                widget.onProfileTap!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DokterProfileScreen(
                      doctorName: 'Dr. Andi Pratama',
                      onLogout: () => Navigator.of(context).pop(),
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF044E2F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TITLE PILL
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTitlePill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
      decoration: BoxDecoration(
        color: _darkGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SUMMARY CARD: JUMLAH KONSULTASI HARI INI
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Wave Watermark in Corners
            Positioned.fill(
              child: CustomPaint(
                painter: _CardWaveWatermarkPainter(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Text(
                    'Jumlah Konsultasi Hari Ini',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '04',
                    style: GoogleFonts.inter(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildMiniCounterCard('Selesai', '02', const Color(0xFF15803D)),
                      const SizedBox(width: 8),
                      _buildMiniCounterCard('Berlangsung', '01', const Color(0xFF0F172A)),
                      const SizedBox(width: 8),
                      _buildMiniCounterCard('Mendatang', '01', const Color(0xFFEAB308)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCounterCard(String label, String count, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              count,
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TIMELINE SCHEDULE ITEM
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTimelineScheduleItem(DokterScheduleItem sch, bool isLast) {
    final isAktif = sch.status == 'Aktif';
    final patient = _findPatient(sch.patientId);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Time Column on Left ──
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                sch.time,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isAktif ? const Color(0xFF0D7A5F) : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),

          // ── Vertical Timeline Connecting Line ──
          SizedBox(
            width: 18,
            child: Center(
              child: Container(
                width: 1.5,
                color: const Color(0xFFE2E8F0),
              ),
            ),
          ),

          // ── Schedule Card on Right ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAktif ? _darkGreen : _border,
                    width: isAktif ? 1.5 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isAktif
                          ? _darkGreen.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Patient Name & Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            sch.patientName,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(sch.status),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Service Type: Chat Konsultasi
                    Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 15,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sch.serviceType,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Actions
                    if (isAktif)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _darkGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _navigateToChat(patient),
                              child: Text(
                                'Mulai Chat',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFF0F172A), width: 1.1),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => _navigateToDetail(patient),
                            child: Text(
                              'Detail',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: () => _navigateToDetail(patient),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Lihat Detail',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _darkGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_circle_right_outlined,
                              size: 17,
                              color: _darkGreen,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status == 'Aktif') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: _darkGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          status,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY WAVE PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _DokterJadwalTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 14; i++) {
      final path = Path();
      final yOffset = 10.0 + (i * 75);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.35,
        yOffset - 30,
        size.width * 0.65,
        yOffset + 40,
        size.width,
        yOffset - 15,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD WAVE WATERMARK PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _CardWaveWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Top-left decorative lines
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offset = i * 16.0;
      path.moveTo(0, 10 + offset);
      path.cubicTo(
        25 + offset,
        15 + offset,
        45 + offset,
        45 + offset,
        60 + offset,
        0,
      );
      canvas.drawPath(path, paint);
    }

    // Bottom-right decorative lines
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offset = i * 16.0;
      path.moveTo(size.width - 65 - offset, size.height);
      path.cubicTo(
        size.width - 45 - offset,
        size.height - 35 - offset,
        size.width - 25 - offset,
        size.height - 20 - offset,
        size.width,
        size.height - 40 - offset,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
