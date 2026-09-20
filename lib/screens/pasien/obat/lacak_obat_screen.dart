import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../profile/profile_pasien_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN LACAK OBAT (Figma Node: 977:10969)
// ─────────────────────────────────────────────────────────────────────────────

class LacakObatScreen extends StatefulWidget {
  final String userName;
  final String orderId;
  final String estimasiTiba;
  final String status;

  const LacakObatScreen({
    super.key,
    this.userName = 'Pasien',
    this.orderId = '#G-9021',
    this.estimasiTiba = 'Hari ini, 15:30 WIB',
    this.status = 'Sedang Diproses',
  });

  @override
  State<LacakObatScreen> createState() => _LacakObatScreenState();
}

class _LacakObatScreenState extends State<LacakObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDark = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);
  static const _amberStatus = Color(0xFFE5A100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topography
          Positioned.fill(
            child: CustomPaint(
              painter: _LacakObatTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. Top Navigation Bar (<- Kembali & Action Pill) ──
                        _buildTopBar(context),

                        const SizedBox(height: 16),

                        // ── 2. Screen Title Pill: Lacak Obat ──
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
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
                              'Lacak Obat',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── 3. Header Status Pesanan Card ──
                        _buildHeaderStatusCard(),

                        const SizedBox(height: 16),

                        // ── 4. Timeline Pelacakan Pengiriman ──
                        _buildTimelineCard(),

                        const SizedBox(height: 16),

                        // ── 5. Kurir & Apotek Mitra Card ──
                        _buildKurirApotekCard(),

                        const SizedBox(height: 16),

                        // ── 6. Alamat Pengiriman Card ──
                        _buildAlamatPengirimanCard(),

                        const SizedBox(height: 16),

                        // ── 7. Rincian Obat yang Dikirim Card ──
                        _buildRincianObatCard(),
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
  // 1. TOP BAR NAVIGATION
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
  // 2. HEADER STATUS PESANAN CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF8F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: _darkGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No. Pesanan',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        widget.orderId,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _amberStatus,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _amberStatus.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.status,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: _darkGreen),
              const SizedBox(width: 6),
              RichText(
                text: TextSpan(
                  text: 'Estimasi tiba: ',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                  children: [
                    TextSpan(
                      text: widget.estimasiTiba,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. TIMELINE PELACAKAN PENGIRIMAN
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTimelineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Text(
            'Aktivitas Pengiriman',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          // Step 1: Resep Diterima
          _buildTrackingStep(
            title: 'Resep Diterima & Terverifikasi Digital',
            time: '01 Sep 2026 • 09:15 WIB',
            desc: 'Resep dokter diverifikasi oleh sistem GIAT Smart Pharmacy.',
            isCompleted: true,
          ),

          // Step 2: Telaah Resep Apoteker
          _buildTrackingStep(
            title: 'Telaah Resep oleh Apoteker Mitra Selesai',
            time: '01 Sep 2026 • 10:30 WIB',
            desc: 'apt. Budi Santoso, S.Farm telah memvalidasi dosis aman ginjal.',
            isCompleted: true,
          ),

          // Step 3: Pengemasan Kedap Suhu (Current)
          _buildTrackingStep(
            title: 'Obat Sedang Dikemas Kedap Suhu',
            time: '01 Sep 2026 • 11:10 WIB',
            desc: 'Kemasan tersegel rapi dan higienis dari Apotek Kimia Farma Veteran.',
            isCompleted: true,
            isCurrent: true,
          ),

          // Step 4: Penjemputan Kurir
          _buildTrackingStep(
            title: 'Kurir GIAT Mengambil Paket Obat',
            time: 'Estimasi 14:00 WIB',
            desc: 'Driver spesialis logistik medis GIAT ditugaskan menuju apotek.',
            isCompleted: false,
          ),

          // Step 5: Dalam Perjalanan
          _buildTrackingStep(
            title: 'Kurir Menuju Alamat Tujuan',
            time: 'Estimasi 14:45 WIB',
            desc: 'Paket dalam perjalanan ke Jl. Dharmahusada Indah No. 42.',
            isCompleted: false,
          ),

          // Step 6: Selesai
          _buildTrackingStep(
            title: 'Pesanan Selesai Diterima',
            time: 'Estimasi 15:30 WIB',
            desc: 'Tanda tangan konfirmasi dan verifikasi fisik obat oleh pasien.',
            isCompleted: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStep({
    required String title,
    required String time,
    required String desc,
    required bool isCompleted,
    bool isCurrent = false,
    bool isLast = false,
  }) {
    Color indicatorBg;
    Widget indicatorChild;

    if (isCompleted && !isCurrent) {
      indicatorBg = _darkGreen;
      indicatorChild = const Icon(Icons.check, size: 13, color: Colors.white);
    } else if (isCurrent) {
      indicatorBg = const Color(0xFFDCFCE7);
      indicatorChild = Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: _darkGreen,
          shape: BoxShape.circle,
        ),
      );
    } else {
      indicatorBg = const Color(0xFFF1F5F9);
      indicatorChild = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator & Vertical Line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: indicatorBg,
                  shape: BoxShape.circle,
                  border: isCurrent ? Border.all(color: _darkGreen, width: 2.2) : null,
                ),
                child: Center(child: indicatorChild),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? _darkGreen : const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: isCurrent ? FontWeight.w800 : (isCompleted ? FontWeight.w700 : FontWeight.w600),
                      color: isCurrent
                          ? _darkGreen
                          : (isCompleted ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isCurrent ? _darkGreen : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. KURIR & APOTEK MITRA CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKurirApotekCard() {
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
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded, color: _darkGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apotek Pengirim',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                    ),
                    Text(
                      'Kimia Farma - Veteran Surabaya',
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.moped_outlined, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kurir GIAT Express',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                    ),
                    Text(
                      'Rahmat Setiawan (L-4921-ZA)',
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. ALAMAT PENGIRIMAN CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAlamatPengirimanCard() {
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
            children: [
              const Icon(Icons.location_on_outlined, color: _darkGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Alamat Tujuan Pengiriman',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${widget.userName} • 0812-3456-7890',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 3),
          Text(
            'Jl. Dharmahusada Indah No. 42, RT 02 / RW 05, Kel. Mulyorejo, Kec. Mulyorejo, Surabaya, Jawa Timur 60115',
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w400, color: const Color(0xFF475569), height: 1.35),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Catatan: Titipkan ke satpam jika penerima sedang dialisis di RS.',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569)),
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
  // 6. RINCIAN OBAT YANG DIKIRIM CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRincianObatCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Obat dalam Paket',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '2 Obat',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _darkGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildItemRow('Kalsium Karbonat 500mg', '30 tablet • 3x sehari', 'Rp. 45.000,00'),
          const SizedBox(height: 10),
          _buildItemRow('Asam Folat 1mg', '30 tablet • 1x sehari', 'Rp. 80.000,00'),
        ],
      ),
    );
  }

  Widget _buildItemRow(String name, String dosage, String price) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.medication_rounded, color: _darkGreen, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
              Text(
                dosage,
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: BACKGROUND CONTOUR LINES FOR LACAK OBAT
// ─────────────────────────────────────────────────────────────────────────────

class _LacakObatTopographyPainter extends CustomPainter {
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
