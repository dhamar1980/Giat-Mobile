import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pembayaran_model.dart';
import '../profile/profile_pasien_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN PEMBAYARAN BERHASIL (Figma Nodes: 977:9343 & 977:9794)
// ─────────────────────────────────────────────────────────────────────────────

class PembayaranBerhasilScreen extends StatelessWidget {
  final String userName;
  final OrderCheckoutData orderData;

  const PembayaranBerhasilScreen({
    super.key,
    this.userName = 'Pasien',
    this.orderData = const OrderCheckoutData(),
  });

  static const _darkGreen = Color(0xFF065A37);
  static const _badgeDark = Color(0xFF0F172A);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);
  static const _infoBoxBg = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topography Curves
          Positioned.fill(
            child: CustomPaint(
              painter: _SuccessTopographyPainter(),
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
                        // ── 1. Top Navigation Bar (Centered Title & Actions) ──
                        _buildTopBar(context),

                        const SizedBox(height: 20),

                        // ── 2. Hero Success Status Box ──
                        _buildHeroSuccessCard(),

                        const SizedBox(height: 18),

                        // ── 3. Detail Pembayaran Card ──
                        _buildDetailPembayaranCard(),

                        const SizedBox(height: 16),

                        // ── 4. Pesanan Obat Card ──
                        _buildPesananObatCard(),

                        const SizedBox(height: 20),

                        // ── 5. Status Pesanan (5 Steps Timeline Stepper) ──
                        _buildStatusPesananSection(),

                        const SizedBox(height: 20),

                        // ── 6. Metode Pengambilan Card ──
                        _buildMetodePengambilanCard(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── 7. Bottom Button: Kembali ke Obat ──
                _buildBottomBar(context),
              ],
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
        // Back Pill
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

        // Center Title Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
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
            'Pembayaran Berhasil',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),

        // Profile Avatar Pill
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePasienScreen(userName: userName),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(5),
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
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF044E2F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HERO SUCCESS CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeroSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF16A34A),
              size: 44,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Pembayaran Berhasil',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pembayaran telah berhasil diterima dan pesananmu sedang di proses.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DETAIL PEMBAYARAN CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDetailPembayaranCard() {
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
                'Detail Pembayaran',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Berhasil',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _darkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDetailRow('Metode Pembayaran', orderData.paymentMethod),
          if (orderData.paymentMethod.contains('Virtual Account')) ...[
            const SizedBox(height: 8),
            _buildDetailRow('No. Virtual Account', orderData.virtualAccountNumber),
          ],
          const SizedBox(height: 8),
          _buildDetailRow('Waktu Transaksi', orderData.transactionTime),
          const SizedBox(height: 8),
          _buildDetailRow('Total Pembayaran', orderData.totalAmountFormatted, isBold: true),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PESANAN OBAT CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPesananObatCard() {
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
                'Pesanan Obat',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  orderData.itemCount,
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
          _buildDetailRow('No Pesanan', orderData.orderNumber),
          const SizedBox(height: 8),
          _buildDetailRow('No. Resep', orderData.prescriptionNumber),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STATUS PESANAN (5 Steps Timeline Stepper)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStatusPesananSection() {
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
                'Status Pesanan',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _darkGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Langkah 2 dari 5',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pesanan telah diteruskan kepada apoteker mitra GIAT untuk diverifikasi dan diproses.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),

          // 5 Steps Stepper
          _buildStepperItem(
            stepNum: 1,
            title: 'Pesanan Dibuat',
            subtitle: '01 Sep 2026, 14:30 WIB',
            isCompleted: true,
            isCurrent: false,
            isLast: false,
          ),
          _buildStepperItem(
            stepNum: 2,
            title: 'Menunggu Verifikasi Apoteker',
            subtitle: 'Sedang diproses oleh Apotek Mitra GIAT',
            isCompleted: false,
            isCurrent: true,
            isLast: false,
          ),
          _buildStepperItem(
            stepNum: 3,
            title: 'Diproses Apoteker',
            subtitle: 'Pemeriksaan dosis & peracikan obat',
            isCompleted: false,
            isCurrent: false,
            isLast: false,
          ),
          _buildStepperItem(
            stepNum: 4,
            title: 'Dikirim / Siap Diambil',
            subtitle: 'Obat siap diantar kurir ke tujuan',
            isCompleted: false,
            isCurrent: false,
            isLast: false,
          ),
          _buildStepperItem(
            stepNum: 5,
            title: 'Selesai',
            subtitle: 'Pesanan diterima oleh pasien',
            isCompleted: false,
            isCurrent: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepperItem({
    required int stepNum,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    Color indicatorBg;
    Widget indicatorChild;

    if (isCompleted) {
      indicatorBg = _darkGreen;
      indicatorChild = const Icon(Icons.check, size: 14, color: Colors.white);
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
      indicatorChild = Text(
        '$stepNum',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Indicator + Connecting Line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: indicatorBg,
                  shape: BoxShape.circle,
                  border: isCurrent ? Border.all(color: _darkGreen, width: 2) : null,
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
          const SizedBox(width: 12),
          // Content
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
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                      color: isCurrent
                          ? _darkGreen
                          : (isCompleted ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
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
  // METODE PENGAMBILAN CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMetodePengambilanCard() {
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
          Text(
            'Metode Pengambilan',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              orderData.pickupMethod,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _darkGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _infoBoxBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${orderData.recipientName} ${orderData.recipientPhone}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orderData.recipientAddress,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 16, color: _darkGreen),
                    const SizedBox(width: 6),
                    Text(
                      'Perkiraan tiba: ${orderData.estimatedArrival}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _darkGreen,
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
  // BOTTOM BUTTON: KEMBALI KE OBAT
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            // Pop until first route or root
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _darkGreen,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Kembali ke Obat',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 14.5 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: BACKGROUND CONTOUR LINES FOR SUCCESS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessTopographyPainter extends CustomPainter {
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
