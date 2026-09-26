import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import '../notifikasi/dokter_notifikasi_screen.dart';
import '../profile/dokter_profile_screen.dart';
import 'dokter_detail_pasien_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DAFTAR PASIEN DOKTER (Sesuai Desain Figma: Node 1008-18310)
// ─────────────────────────────────────────────────────────────────────────────

class DokterPasienScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final bool? isTopBarVisible;

  const DokterPasienScreen({
    super.key,
    this.onProfileTap,
    this.isTopBarVisible,
  });

  @override
  State<DokterPasienScreen> createState() => _DokterPasienScreenState();
}

class _DokterPasienScreenState extends State<DokterPasienScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF7FBF8);
  static const _border = Color(0xFFE2E8F0);

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isTopBarVisible = true;

  bool get _effectiveTopBarVisible => widget.isTopBarVisible ?? _isTopBarVisible;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DokterPatient> _getFilteredPatients() {
    final list = DokterMockData.patients;
    if (_searchQuery.trim().isEmpty) return list;
    return list.where((p) {
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.gender.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openPatientDetail(DokterPatient patient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DokterDetailPasienScreen(patient: patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredPatients();

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
            // ── Topography Wave Background ──
            Positioned.fill(
              child: CustomPaint(
                painter: _PasienTopographyPainter(),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 76),

                  // ── Title Badge: "Daftar Pasien" ──
                _buildTitlePill('Daftar Pasien'),

                const SizedBox(height: 16),

                // ── Search Bar (Pill Shaped) ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        width: 1.2,
                      ),
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
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari Pasien...',
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF334155), size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Patient Cards List ──
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada pasien ditemukan.',
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            return _buildPatientListItem(p, index);
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

  Widget _buildTitlePill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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

  Widget _buildPatientListItem(DokterPatient p, int index) {
    final avatarBg = p.avatarBgColor ??
        (index % 2 == 0 ? _darkGreen : const Color(0xFFD0E6ED));
    final avatarTextColor = p.avatarTextColor ??
        (index % 2 == 0 ? Colors.white : const Color(0xFF1E293B));

    return GestureDetector(
      onTap: () => _openPatientDetail(p),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: avatarBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  p.initials,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: avatarTextColor,
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
                    p.name,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${p.age} Tahun  •  ${p.gender}',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY PAINTER UNTUK SCREEN PASIEN
// ─────────────────────────────────────────────────────────────────────────────

class _PasienTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (int i = 0; i < 12; i++) {
      final path = Path();
      final yOffset = 10.0 + (i * 85);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.35,
        yOffset - 35,
        size.width * 0.65,
        yOffset + 45,
        size.width,
        yOffset - 15,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
