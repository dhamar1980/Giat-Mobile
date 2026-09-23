import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL PROFIL DOKTER (Sesuai Referensi UI Figma GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class DokterDetailScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DokterDetailScreen({super.key, required this.doctor});

  @override
  State<DokterDetailScreen> createState() => _DokterDetailScreenState();
}

class _DokterDetailScreenState extends State<DokterDetailScreen> {
  static const _primaryGreen = Color(0xFF065A37);
  static const _darkGreen = Color(0xFF044E2F);
  static const _emeraldGreen = Color(0xFF10B981);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorder = Color(0xFFE2E8F0);

  static const _defaultPhoto =
      'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=500';

  String get _doctorName {
    final name = widget.doctor['name']?.toString() ?? '';
    return name.isNotEmpty ? name : 'Dr. Budi Santoso';
  }

  String get _specialty {
    final s = widget.doctor['specialty']?.toString() ?? '';
    return s.isNotEmpty ? s : 'Spesialis Ginjal & Hipertensi';
  }

  String get _avatarUrl {
    final url = widget.doctor['avatarUrl']?.toString() ?? '';
    if (url.isNotEmpty && url.startsWith('http')) {
      return url;
    }
    return _defaultPhoto;
  }

  String get _rating {
    final r = widget.doctor['rating'];
    if (r != null) return r.toString();
    return '4.9';
  }

  String get _experience {
    final exp = widget.doctor['experience']?.toString() ?? '';
    if (exp.contains('15')) return '15+';
    if (exp.isNotEmpty) {
      final numbers = RegExp(r'\d+').firstMatch(exp)?.group(0);
      if (numbers != null) return '$numbers+';
    }
    return '15+';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Background Topography Lines ──
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundTopographyPainter(),
            ),
          ),

          // ── Main Content ──
          SingleChildScrollView(
            child: Column(
              children: [
                // 1. Curved Green Hero Header
                _buildCurvedHeroHeader(context),

                // 2. Body Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Informasi Penilaian
                      _buildPenilaianSection(),

                      const SizedBox(height: 20),

                      // Section: Informasi Tambahan
                      _buildInformasiTambahanSection(),

                      const SizedBox(height: 20),

                      // Section: Jadwal Praktik
                      _buildJadwalPraktikSection(),

                      const SizedBox(height: 20),

                      // Section: Tentang Dokter
                      _buildTentangDokterSection(),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. CURVED GREEN HERO HEADER
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildCurvedHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF22C55E), // Fresh green top
            Color(0xFF059669), // Emerald transition
            Color(0xFF065A37), // Deep GIAT green
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
        child: Stack(
          children: [
            // Topography curves inside header
            Positioned.fill(
              child: CustomPaint(
                painter: _HeaderWavePainter(),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
                child: Column(
                  children: [
                    // Top Bar: [← Kembali] Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back,
                                size: 16,
                                color: Color(0xFF0F172A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Kembali',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Doctor Avatar with ring and online dot
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 106,
                            height: 106,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                _avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFDCFCE7),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 56,
                                    color: _primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Online Status Dot (green circle with white ring)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _emeraldGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Doctor Name
                    Text(
                      _doctorName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Specialty
                    Text(
                      _specialty,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Online Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: _emeraldGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _darkGreen,
                            ),
                          ),
                        ],
                      ),
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

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. INFORMASI PENILAIAN
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildPenilaianSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Penilaian',
          style: GoogleFonts.inter(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 1: 4.9 Ulasan Pasien
            Expanded(
              child: _buildPenilaianCard(
                iconWidget: const Icon(
                  Icons.stars_rounded,
                  size: 28,
                  color: Color(0xFF00796B),
                ),
                value: _rating,
                label: 'Ulasan Pasien',
              ),
            ),
            const SizedBox(width: 14),
            // Card 2: 15+ Tahun Pengalaman
            Expanded(
              child: _buildPenilaianCard(
                iconWidget: const Icon(
                  Icons.medical_services_rounded,
                  size: 26,
                  color: Color(0xFF00796B),
                ),
                value: _experience,
                label: 'Tahun Pengalaman',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPenilaianCard({
    required Widget iconWidget,
    required String value,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Subtle wave background decoration
            Positioned(
              left: 0,
              top: 0,
              child: CustomPaint(
                size: const Size(80, 80),
                painter: _CardTopographyPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(child: iconWidget),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
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

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. INFORMASI TAMBAHAN
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildInformasiTambahanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Tambahan',
          style: GoogleFonts.inter(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Row 1: Spesialisasi
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.health_and_safety_outlined,
                        color: _primaryGreen,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spesialisasi',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Penyakit Dalam, Ginjal, Hipertensi, Hemodialisis',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Row 2: Informasi Praktik
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.medical_information_outlined,
                        color: _primaryGreen,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Praktik',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Layanan Telemedice Video & Chat',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF475569),
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
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. JADWAL PRAKTIK
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildJadwalPraktikSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: Color(0xFF0F172A),
            ),
            const SizedBox(width: 8),
            Text(
              'Jadwal Praktik',
              style: GoogleFonts.inter(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTimelineItem(
                day: 'Senin - Jumat',
                time: '09:00 - 16:00',
                isLast: false,
              ),
              _buildTimelineItem(
                day: 'Sabtu',
                time: '09:00 - 13:00',
                isLast: false,
              ),
              _buildTimelineItem(
                day: 'Senin - Jumat',
                time: 'Tutup',
                isLast: true,
                isClosed: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String day,
    required String time,
    required bool isLast,
    bool isClosed = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator (dot + line)
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _emeraldGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFF86EFAC),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Day label
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Text(
                day,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ),

          // Time slot or status
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isClosed ? FontWeight.w700 : FontWeight.w500,
                color: isClosed ? const Color(0xFFEF4444) : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. TENTANG DOKTER
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTentangDokterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 19,
              color: Color(0xFF0F172A),
            ),
            const SizedBox(width: 8),
            Text(
              'Tentang Dokter',
              style: GoogleFonts.inter(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Dokter yang memberikan layanan konsultasi kesehatan secara daring melalui GIAT. Berkomitmen untuk memberikan penanganan medis yang akurat dan empati bagi pasien dengan gangguan ginjal dan tekanan darah tinggi.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF334155),
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }


}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS: TOPOGRAPHY & WAVES
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 12; i++) {
      final path = Path();
      final yOffset = 40.0 + (i * 90);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.35,
        yOffset - 35,
        size.width * 0.65,
        yOffset + 40,
        size.width,
        yOffset - 10,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final yOffset = 20.0 + (i * 45);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.3,
        yOffset - 25,
        size.width * 0.7,
        yOffset + 30,
        size.width,
        yOffset - 5,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offset = i * 15.0;
      path.moveTo(0, 10 + offset);
      path.cubicTo(
        size.width * 0.4,
        offset - 5,
        size.width * 0.6,
        offset + 25,
        size.width,
        offset + 10,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
