import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import '../notifikasi/dokter_notifikasi_screen.dart';
import '../profile/dokter_profile_screen.dart';
import 'dokter_room_chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DAFTAR KONSULTASI DOKTER (Sesuai Desain Figma / Image 1, 2, 3)
// ─────────────────────────────────────────────────────────────────────────────

class DokterKonsultasiScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final bool? isTopBarVisible;

  const DokterKonsultasiScreen({
    super.key,
    this.onProfileTap,
    this.isTopBarVisible,
  });

  @override
  State<DokterKonsultasiScreen> createState() => _DokterKonsultasiScreenState();
}

class _DokterKonsultasiScreenState extends State<DokterKonsultasiScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _filterInactiveBg = Color(0xFFE0F2FE); // Soft light blue pill
  static const _filterInactiveText = Color(0xFF1E293B);

  int _selectedFilterIndex = 0; // 0: Semua, 1: Terjadwal, 2: Selesai
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isTopBarVisible = true;

  bool get _effectiveTopBarVisible => widget.isTopBarVisible ?? _isTopBarVisible;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DokterConsultation> _getFilteredConsultations() {
    List<DokterConsultation> list;

    if (_selectedFilterIndex == 1) {
      // Terjadwal tab (Matches Image 2: Lestari Putri, Lesti Purnama)
      list = DokterMockData.consultations
          .where((item) => item.status == KonsultasiStatus.terjadwal)
          .toList();
    } else if (_selectedFilterIndex == 2) {
      // Selesai tab (Matches Image 3: Hendra Kurniawan)
      list = DokterMockData.consultations
          .where((item) => item.status == KonsultasiStatus.selesai)
          .toList();
    } else {
      // Semua tab (Matches Image 1: Budi Santoso, Lestari Putri, Hendra Kurniawan)
      list = DokterMockData.consultations.where((item) {
        return item.id != 'c-3'; // c-3 is Lesti Purnama shown in Terjadwal
      }).toList();
    }

    if (_searchQuery.trim().isEmpty) return list;

    return list.where((item) {
      return item.patientName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  DokterPatient _findPatient(String patientId) {
    return DokterMockData.patients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => DokterMockData.patients.first,
    );
  }

  void _openChat(DokterConsultation item) {
    final patient = _findPatient(item.patientId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DokterRoomChatScreen(
          patient: patient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredConsultations();

    return Scaffold(
      backgroundColor: _bgColor,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            final pixels = notification.metrics.pixels;
            if (pixels > 20) {
              if (_isTopBarVisible) setState(() => _isTopBarVisible = false);
            } else if (pixels <= 5) {
              if (!_isTopBarVisible) setState(() => _isTopBarVisible = true);
            }
          }
          return false;
        },
        child: Stack(
          children: [
            // ── Wavy Topography Background ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 240,
              child: CustomPaint(
                painter: _KonsultasiHeaderTopographyPainter(),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 76),

                  // ── Centered Pill Badge: "Daftar Konsultasi" ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  decoration: BoxDecoration(
                    color: _darkGreen,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _darkGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Daftar Konsultasi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Search Bar: "Cari Pasien..." ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Cari Pasien...',
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Segmented Filter Pills: Semua, Terjadwal, Selesai ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildFilterPill(0, 'Semua'),
                      const SizedBox(width: 10),
                      _buildFilterPill(1, 'Terjadwal'),
                      const SizedBox(width: 10),
                      _buildFilterPill(2, 'Selesai'),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Consultation Cards List ──
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 10),
                              Text(
                                'Tidak ada konsultasi ditemukan.',
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (context, _) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _buildConsultationCard(item);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  // Segmented Pill Item
  Widget _buildFilterPill(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? _darkGreen : _filterInactiveBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _darkGreen.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : _filterInactiveText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Consultation Card matching Image 1, 2, 3
  Widget _buildConsultationCard(DokterConsultation item) {
    final isCompleted = item.status == KonsultasiStatus.selesai;
    final isOngoing = item.status == KonsultasiStatus.berlangsung;
    final isScheduled = item.status == KonsultasiStatus.terjadwal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar box with initials and soft light blue background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFE8F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item.initials,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Patient Info & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.patientName,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Status Indicator
                    if (isOngoing)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Sedang Berlangsung',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (isScheduled)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: _darkGreen,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Terjadwal',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _darkGreen,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Sudah Selesai',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _darkGreen,
                        ),
                      ),

                    const SizedBox(height: 4),
                    Text(
                      'Waktu Konsultasi: ${item.scheduledTimeText}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread Badge (e.g. "2 Pesan" on Budi Santoso)
              if (item.messageCount > 0 && isOngoing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB91C1C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.messageCount} Pesan',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Button: Solid Green
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonDarkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _openChat(item),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCompleted ? 'Lihat Riwayat Chat' : 'Mulai Chat',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _KonsultasiHeaderTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 6; i++) {
      final path = Path();
      final yOffset = 20.0 + (i * 45);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.3,
        yOffset - 25,
        size.width * 0.65,
        yOffset + 35,
        size.width,
        yOffset - 10,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
