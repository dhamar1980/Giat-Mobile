import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'checkout_resep_screen.dart';
import '../profile/profile_pasien_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL DATA DETAIL RESEP
// ─────────────────────────────────────────────────────────────────────────────

class ResepObatItem {
  final String name;
  final String category;
  final String badgeText;
  final String aturanPakai;
  final String jumlahObat;

  const ResepObatItem({
    required this.name,
    required this.category,
    this.badgeText = 'Obat Keras',
    required this.aturanPakai,
    required this.jumlahObat,
  });
}

class ResepDokterData {
  final String rxNumber;
  final String status; // 'Belum Ditebus', 'Sudah Ditebus', 'Kadaluwarsa'
  final String tanggalTerbit;
  final String masaBerlaku;
  final String doctorName;
  final String doctorSpecialty;
  final String doctorSip;
  final String doctorImage;
  final String mitraPharmacy;
  final String? warningMessage;
  final List<ResepObatItem> medications;

  const ResepDokterData({
    required this.rxNumber,
    required this.status,
    required this.tanggalTerbit,
    required this.masaBerlaku,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.doctorSip,
    required this.doctorImage,
    this.mitraPharmacy = 'Apotek Mitra GIAT',
    this.warningMessage,
    required this.medications,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN DETAIL RESEP DOKTER
// ─────────────────────────────────────────────────────────────────────────────

class DetailResepScreen extends StatefulWidget {
  final String userName;
  final ResepDokterData? resepData;

  const DetailResepScreen({
    super.key,
    this.userName = 'Pasien',
    this.resepData,
  });

  @override
  State<DetailResepScreen> createState() => _DetailResepScreenState();
}

class _DetailResepScreenState extends State<DetailResepScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _badgeDark = Color(0xFF0F172A);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);
  static const _redStatus = Color(0xFFDC2626);
  static const _infoBoxBg = Color(0xFFF1F5F9);

  late final ResepDokterData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.resepData ??
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
              aturanPakai: '1x sehari di pagi hari',
              jumlahObat: '30 tab (33 Strip)',
            ),
          ],
        );
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Belum Ditebus':
        return _redStatus;
      case 'Sudah Ditebus':
        return const Color(0xFF065A37);
      case 'Kadaluwarsa':
        return const Color(0xFF64748B);
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
              painter: _DetailResepTopographyPainter(),
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

                  // ── Center Pill Title: Detail Resep ──
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
                        'Detail Resep',
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

                  // ── Card 1: Nomor Resep & Masa Berlaku ──
                  _buildValidityCard(),

                  const SizedBox(height: 16),

                  // ── Card 2: Informasi Dokter Spesialis Penerbit ──
                  _buildDoctorCard(),

                  const SizedBox(height: 22),

                  // ── Section 3: Obat Dalam Resep ──
                  _buildObatDalamResepHeader(),
                  const SizedBox(height: 14),

                  // List Kartu Obat
                  ..._data.medications.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildMedicationCard(item),
                      )),

                  const SizedBox(height: 16),

                  // ── Section 4: Informasi & Protokol Resep ──
                  _buildProtokolSection(),

                  const SizedBox(height: 24),

                  // ── Bottom Action Buttons ──
                  _buildBottomActionButtons(context),
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
  // CARD 1: VALIDITY & STATUS RESEP
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildValidityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Badges: No RX & Status
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
                  _data.rxNumber,
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
                  color: _getStatusBgColor(_data.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _data.status,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Inner Container: Tanggal Terbit & Masa Berlaku
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _infoBoxBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tanggal Terbit',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      _data.tanggalTerbit,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Masa Berlaku',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      _data.masaBerlaku,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CARD 2: DOKTER SPESIALIS & SIP
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDoctorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _data.doctorImage,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 58,
                    height: 58,
                    color: const Color(0xFFDCFCE7),
                    child: const Icon(Icons.person_rounded, color: _darkGreen, size: 34),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _data.doctorName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _data.doctorSpecialty,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _data.doctorSip,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Label Verifikasi Medis Resmi GIAT
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: _darkGreen,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Resep diterbitkan langsung via sistem medis GIAT terverifikasi.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _darkGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 3: HEADER OBAT DALAM RESEP
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildObatDalamResepHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Obat Dalam Resep',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _badgeDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_data.medications.length} Jenis',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '*Dosis dan jumlah telah ditentukan langsung oleh dokter spesialis.',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MEDICATION ITEM CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMedicationCard(ResepObatItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Icon + Names + Badge Obat Keras
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF0284C7),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.category,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: _redStatus,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Inner box: Aturan Pakai & Jumlah Obat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _infoBoxBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Aturan Pakai',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      item.aturanPakai,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jumlah Obat',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      item.jumlahObat,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 4: INFORMASI & PROTOKOL RESEP
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildProtokolSection() {
    final protocols = [
      'Resep hanya dapat ditebus sesuai obat dan takaran yang tercantum.',
      'Pasien tidak diperbolehkan mengubah jenis, dosis, atau kuantitas obat.',
      'Diracik & diverifikasi langsung oleh apoteker berlisensi SIPA resmi.',
      'Tersedia fitur konsultasi obat interaktif dengan farmasis klinis GIAT.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row with Shield Icon
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: _darkGreen,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Informasi & Protokol Resep',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Sub-badge Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _darkGreen,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Obat Bebas (Hijau) & Bebas Terbatas (Biru):',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 4 Checklist Items
        ...protocols.map((text) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E293B),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM ACTION BUTTONS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomActionButtons(BuildContext context) {
    return Column(
      children: [
        // Button: Tebus Resep Sekarang (Solid Green)
        if (_data.status == 'Belum Ditebus')
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _handleTebusResep(context),
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
              label: Text(
                'Tebus Resep Sekarang',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),

        if (_data.status == 'Belum Ditebus') const SizedBox(height: 10),

        // Button: Bagikan Salinan Resep (PDF) (Outlined)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _handleSharePdf(context),
            icon: const Icon(Icons.share_outlined, color: _darkGreen, size: 20),
            label: Text(
              'Bagikan Salinan Resep (PDF)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _darkGreen,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: _darkGreen, width: 1.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleTebusResep(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutResepScreen(
          userName: widget.userName,
          resepData: _data,
        ),
      ),
    );
  }

  void _handleSharePdf(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Salinan resep elektronik (${_data.rxNumber}.pdf) berhasil disiapkan.'),
        backgroundColor: _darkGreen,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: TOPOGRAPHY BACKGROUND LINES
// ─────────────────────────────────────────────────────────────────────────────

class _DetailResepTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    GiatBackgroundPainter.paintBackground(
      canvas,
      size,
      showGradient: true,
      showLines: true,
    );
    }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
