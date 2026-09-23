import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import 'dokter_informasi_profile_screen.dart';
import 'dokter_pengaturan_notifikasi_screen.dart';
import 'dokter_keamanan_akun_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROFIL DOKTER UTAMA (Figma Node: 1008-19649)
// ─────────────────────────────────────────────────────────────────────────────

class DokterProfileScreen extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final VoidCallback? onLogout;

  const DokterProfileScreen({
    super.key,
    this.doctorName = 'Dr. Andi Pratama',
    this.specialty = 'Spesialis Penyakti Dalam / Ginjal',
    this.onLogout,
  });

  static const _darkGreen = Color(0xFF065A37);
  static const _border = Color(0xFFE2E8F0);

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar dari Akun Dokter',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Dokter?',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (onLogout != null) {
                onLogout!();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text('Keluar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = DokterProfileState.instance;

    return ListenableBuilder(
      listenable: profileState,
      builder: (context, _) {
        final currentName = profileState.doctorName.isNotEmpty ? profileState.doctorName : doctorName;
        final currentSpecialty = profileState.specialty.isNotEmpty ? profileState.specialty : specialty;

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAF8),
          body: Stack(
            children: [
              // Subtle background topography wave lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _ProfileTopographyPainter(),
                ),
              ),

              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Organic Curved Green Header (Screenshot 1 & 2)
                    _buildHeader(context, currentName, currentSpecialty, profileState),

                    const SizedBox(height: 20),

                    // Section 1: Profil Dokter
                    _buildSectionTitle('Profil Dokter'),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.025),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DokterInformasiProfileScreen(
                                    doctorName: currentName,
                                    specialty: currentSpecialty,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    color: _darkGreen,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      'Profile Dokter',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 2: Profil Dokter (Notifikasi & Keamanan)
                    _buildSectionTitle('Profil Dokter'),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.025),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              // Notifikasi
                              InkWell(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const DokterPengaturanNotifikasiScreen(),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.notifications_none_rounded,
                                        color: _darkGreen,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          'Notifikasi',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFF94A3B8),
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),

                              // Keamanan
                              InkWell(
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const DokterKeamananAkunScreen(),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.shield_outlined,
                                        color: _darkGreen,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          'Keamanan',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFF94A3B8),
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Section 3: Akun (Keluar)
                    _buildSectionTitle('Akun'),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.025),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _showLogoutDialog(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.logout_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    'Keluar',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String name, String specialty, DokterProfileState profileState) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipPath(
      clipper: _ProfileHeaderOrganicClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF22C55E),
              Color(0xFF10B981),
              Color(0xFF0F7644),
              Color(0xFF065A37),
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _HeaderWaveOverlayPainter(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular Avatar with White Border (Screenshot 1 & 2)
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: profileState.buildAvatarWidget(size: 104, iconSize: 52),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Doctor Name
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 4),

                    // Doctor Specialty
                    Text(
                      specialty,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM CLIPPERS & PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeaderOrganicClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 38);

    // Organic wavy curve matching the design mockup
    path.cubicTo(
      size.width * 0.28,
      size.height + 16,
      size.width * 0.72,
      size.height + 12,
      size.width,
      size.height - 30,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeaderWaveOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.45);
    path.cubicTo(
      size.width * 0.35,
      size.height * 0.55,
      size.width * 0.20,
      size.height * 0.85,
      0,
      size.height - 30,
    );
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = const Color(0xFF34D399).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.cubicTo(
      size.width * 0.40,
      size.height * 0.75,
      size.width * 0.15,
      size.height * 0.95,
      0,
      size.height,
    );
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;

    const baseColor = Color(0xFF10B981);
    final opacities = [0.06, 0.08, 0.10, 0.12, 0.09, 0.07];

    for (int i = 0; i < opacities.length; i++) {
      wavePaint.color = baseColor.withValues(alpha: opacities[i]);
      final y0 = (h * 0.42) + (i * 38.0);

      final path = Path()
        ..moveTo(-30, y0)
        ..cubicTo(
          w * 0.30,
          y0 - 24,
          w * 0.65,
          y0 + 35,
          w + 30,
          y0 - 15,
        );

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

