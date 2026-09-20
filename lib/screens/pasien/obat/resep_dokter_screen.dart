import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_resep_screen.dart';
import 'checkout_resep_screen.dart';
import '../profile/profile_pasien_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN RESEP DOKTER (Sesuai Desain Figma / Gambar 1 & 2)
// ─────────────────────────────────────────────────────────────────────────────

class ResepDokterScreen extends StatefulWidget {
  final String userName;

  const ResepDokterScreen({
    super.key,
    this.userName = 'Pasien',
  });

  @override
  State<ResepDokterScreen> createState() => _ResepDokterScreenState();
}

class _ResepDokterScreenState extends State<ResepDokterScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _badgeDark = Color(0xFF0F172A);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);
  static const _redStatus = Color(0xFFDC2626);
  static const _greyStatus = Color(0xFF64748B);
  static const _infoBoxBg = Color(0xFFF1F5F9);

  // Daftar data resep dokter
  late final List<ResepDokterData> _resepList;

  @override
  void initState() {
    super.initState();
    _resepList = [
      // 1. Resep Belum Ditebus
      const ResepDokterData(
        rxNumber: 'No. RX-2026-0901-08',
        status: 'Belum Ditebus',
        tanggalTerbit: '01 September 2026',
        masaBerlaku: 's.d. 15 September 2026',
        doctorName: 'Dr. Siti Rahmawati, Sp.PD-KGH',
        doctorSpecialty: 'Spesialis Ginjal Hipertensi',
        doctorSip: 'SIP: 446/SIP.D/35.09/2024',
        doctorImage: 'assets/images/dokter_apoteker.jpg',
        mitraPharmacy: 'farmasi mitra GIAT',
        medications: [
          ResepObatItem(
            name: 'Ketosteril Tablet',
            category: 'Asam Amino Esensial & Ketoanalog',
            badgeText: 'Obat Keras',
            aturanPakai: '3x sehari sesudah makan',
            jumlahObat: '100 tab (1 Box)',
          ),
          ResepObatItem(
            name: 'Candesartan 8mg',
            category: 'Angiotensin ii REceptor Blocker',
            badgeText: 'Obat Keras',
            aturanPakai: '1x sehari pagi (30 tab)',
            jumlahObat: '30 tab (33 Strip)',
          ),
        ],
      ),

      // 2. Resep Sudah Ditebus
      const ResepDokterData(
        rxNumber: 'No. RX-2026-0801-08',
        status: 'Sudah Ditebus',
        tanggalTerbit: '01 September 2026',
        masaBerlaku: 's.d. 15 September 2026',
        doctorName: 'Dr. Siti Rahmawati, Sp.PD-KGH',
        doctorSpecialty: 'Spesialis Ginjal Hipertensi',
        doctorSip: 'SIP: 446/SIP.D/35.09/2024',
        doctorImage: 'assets/images/dokter_apoteker.jpg',
        mitraPharmacy: 'Apotek Kimia Farma Mitra',
        medications: [
          ResepObatItem(
            name: 'Amlodipine 5mg',
            category: 'Calcium Channel Blocker',
            badgeText: 'Obat Keras',
            aturanPakai: '1x sehari malam',
            jumlahObat: '30 tab',
          ),
          ResepObatItem(
            name: 'Asam Folat 1mg',
            category: 'Suplemen & Vitamin Darah',
            badgeText: 'Obat Bebas',
            aturanPakai: '1x sehari',
            jumlahObat: '30 tab',
          ),
        ],
      ),

      // 3. Resep Kadaluwarsa
      const ResepDokterData(
        rxNumber: 'No. RX-2026-0801-08',
        status: 'Kadaluwarsa',
        tanggalTerbit: '10 Agustus 2026',
        masaBerlaku: 's.d. 24 Agustus 2026',
        doctorName: 'Dr. Siti Rahmawati, Sp.PD-KGH',
        doctorSpecialty: 'Spesialis Urologi',
        doctorSip: 'SIP: 446/SIP.D/35.09/2024',
        doctorImage: 'assets/images/dokter_apoteker.jpg',
        mitraPharmacy: 'Apotek Mitra GIAT',
        warningMessage: 'Masa berlaku resep terlewati (maks. 14 hari)',
        medications: [
          ResepObatItem(
            name: 'Amlodipine 5mg',
            category: 'Calcium Channel Blocker',
            badgeText: 'Obat Keras',
            aturanPakai: '1x sehari malam',
            jumlahObat: '30 tab',
          ),
          ResepObatItem(
            name: 'Asam Folat 1mg',
            category: 'Suplemen & Vitamin Darah',
            badgeText: 'Obat Bebas',
            aturanPakai: '1x sehari',
            jumlahObat: '30 tab',
          ),
        ],
      ),
    ];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Belum Ditebus':
        return _redStatus;
      case 'Sudah Ditebus':
        return _darkGreen;
      case 'Kadaluwarsa':
        return _greyStatus;
      default:
        return _redStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topography Curves
          Positioned.fill(
            child: CustomPaint(
              painter: _ResepDokterTopographyPainter(),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Navigation Bar: <- Kembali & Notification/Avatar Pill ──
                  _buildTopBar(context),

                  const SizedBox(height: 16),

                  // ── Center Pill Title: Resep Dokter ──
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                        'Resep Dokter',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Daftar Kartu Resep Dokter ──
                  ..._resepList.map((resep) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildResepCard(context, resep),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOP BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Pill Button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF0F172A), width: 1.2),
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
                const Icon(Icons.arrow_back, size: 16, color: Color(0xFF0F172A)),
                const SizedBox(width: 6),
                Text(
                  'Kembali',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Pill (Bell & Profile Avatar)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
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
                    MaterialPageRoute(
                      builder: (_) => ProfilePasienScreen(userName: widget.userName),
                    ),
                  );
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
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CARD RESEP DOKTER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildResepCard(BuildContext context, ResepDokterData resep) {
    final isBelumDitebus = resep.status == 'Belum Ditebus';
    final isSudahDitebus = resep.status == 'Sudah Ditebus';
    final isKadaluwarsa = resep.status == 'Kadaluwarsa';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Nomor Resep & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _badgeDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  resep.rxNumber,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(resep.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  resep.status,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Row 2: Doctor Profile & Specialty
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  resep.doctorImage,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 54,
                    height: 54,
                    color: const Color(0xFFDCFCE7),
                    child: const Icon(Icons.person_rounded, color: _darkGreen, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resep.doctorName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      resep.doctorSpecialty,
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

          const SizedBox(height: 14),

          // Row 3: Tanggal & Badge Jumlah Jenis Obat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                resep.tanggalTerbit,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${resep.medications.length} Jenis Obat',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Container Preview Obat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _infoBoxBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (isBelumDitebus) ...[
                  _buildMedicationPreviewRow(
                    'Ketosteril Tablet:',
                    '3x sehari (100 tab)',
                  ),
                  const SizedBox(height: 6),
                  _buildMedicationPreviewRow(
                    'Candesartan 8mg',
                    '1x sehari pagi (30 tab)',
                  ),
                ] else ...[
                  _buildMedicationPreviewRow(
                    'Amlodipine 5mg:',
                    '1x sehari malam (30 tab)',
                  ),
                  const SizedBox(height: 6),
                  _buildMedicationPreviewRow(
                    'Asam Folat 1mg',
                    '1x sehari (30 tab)',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Note / Verification Text
          if (isBelumDitebus)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Dapat ditebus di ${resep.mitraPharmacy}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF065A37),
                    ),
                  ),
                ),
              ],
            )
          else if (isSudahDitebus)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ditebus via ${resep.mitraPharmacy}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF065A37),
                    ),
                  ),
                ),
              ],
            )
          else if (isKadaluwarsa)
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: _redStatus,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    resep.warningMessage ?? 'Masa berlaku resep terlewati (maks. 14 hari)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _redStatus,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 14),

          // Action Buttons
          if (isBelumDitebus)
            Row(
              children: [
                // Tombol Lihat Detail (Outlined)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => _navigateToDetail(context, resep),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: _darkGreen, width: 1.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lihat Detail',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _darkGreen,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_circle_right_outlined,
                            color: _darkGreen,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Tombol Tebus Resep (Solid Green)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _handleTebusResep(context, resep),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _darkGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tebus Resep',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.local_pharmacy_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // Single Full-Width Outlined Button: Lihat Detail Resep
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => _navigateToDetail(context, resep),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _darkGreen, width: 1.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lihat Detail Resep',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_circle_right_outlined,
                      color: _darkGreen,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationPreviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, ResepDokterData resep) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailResepScreen(
          userName: widget.userName,
          resepData: resep,
        ),
      ),
    );
  }

  void _handleTebusResep(BuildContext context, ResepDokterData resep) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutResepScreen(
          userName: widget.userName,
          resepData: resep,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: TOPOGRAPHY BACKGROUND FOR RESEP DOKTER SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _ResepDokterTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (int i = 0; i < 9; i++) {
      final path = Path();
      final yOffset = 15.0 + (i * 95);
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
