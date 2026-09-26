import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../profile/profile_pasien_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN PEMBAYARAN BERHASIL (Sesuai Referensi UI GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class PembayaranBerhasilKonsultasiScreen extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final String selectedDate;
  final String selectedTime;
  final String price;
  final String userName;
  final String paymentMethod; // 'qris' or 'va'
  final String transactionId;

  const PembayaranBerhasilKonsultasiScreen({
    super.key,
    required this.doctor,
    required this.selectedDate,
    required this.selectedTime,
    required this.price,
    this.userName = 'Pasien',
    this.paymentMethod = 'qris',
    this.transactionId = 'GIAT-INV-20260920-0982',
  });

  static const _darkGreen = Color(0xFF044E2F);
  static const _primaryGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF7FAF8);
  static const _cardBorderColor = Color(0xFFE2E8F0);

  String get _paymentMethodLabel {
    if (paymentMethod.toLowerCase() == 'qris') {
      return 'QRIS / Instant Settlement';
    }
    return 'Transfer Virtual Account';
  }

  @override
  Widget build(BuildContext context) {
    final doc = doctor;
    final docName = doc['name'] ?? 'Dr. Anisa Putri';
    final docSpecialty = doc['specialty'] ?? 'Dokter Umum';
    final docRating = doc['rating'] != null ? '${doc['rating']}' : '4.9';
    final docAvatar = doc['avatarUrl'] ?? '';

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topography
          Positioned.fill(
            child: CustomPaint(
              painter: _SuccessTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Navigation Bar ──
                _buildTopBar(context),

                const SizedBox(height: 6),

                // ── Scrollable Body ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Cute Celebratory Mascot Illustration
                        const Center(
                          child: SizedBox(
                            width: 170,
                            height: 125,
                            child: CustomPaint(
                              painter: _MascotCelebrationPainter(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 2. Title: Pembayaran Berhasil
                        Text(
                          'Pembayaran Berhasil',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          'Booking konsultasi Anda dengan $docName telah berhasil dikonfirmasi.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 3. Card Detail Transaksi & Dokter
                        _buildTransactionDetailCard(
                          docName: docName,
                          docSpecialty: docSpecialty,
                          docRating: docRating,
                          docAvatar: docAvatar,
                        ),

                        const SizedBox(height: 18),

                        // 4. Alert Box: Jadwal Siap Digunakan
                        _buildScheduleReadyBox(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── Sticky Bottom Button: Lihat Konsultasi Saya ──
                _buildBottomStickyButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. TOP BAR NAVIGATION
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
                            builder: (_) => ProfilePasienScreen(userName: userName),
                          ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: _darkGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Center Pill Badge: "Pembayaran Berhasil"
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(24),
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
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. KARTU DETAIL TRANSAKSI & DOKTER
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTransactionDetailCard({
    required String docName,
    required String docSpecialty,
    required String docRating,
    required String docAvatar,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: docAvatar.startsWith('http')
                        ? Image.network(
                            docAvatar,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.person_rounded, size: 32, color: _primaryGreen),
                            ),
                          )
                        : Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.person_rounded, size: 32, color: _primaryGreen),
                          ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            docName,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                docRating,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      docSpecialty,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '$selectedDate • $selectedTime',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Detail Item 1: Tanggal
          _buildItemRow(
            icon: Icons.calendar_today_outlined,
            label: 'Tanggal',
            value: selectedDate,
          ),
          const SizedBox(height: 8),

          // Detail Item 2: Waktu Sesi
          _buildItemRow(
            icon: Icons.access_time_rounded,
            label: 'Waktu Sesi',
            value: selectedTime,
          ),
          const SizedBox(height: 8),

          // Detail Item 3: No. Transaksi
          _buildItemRow(
            icon: Icons.receipt_long_rounded,
            label: 'No. Transaksi',
            value: transactionId,
          ),
          const SizedBox(height: 8),

          // Detail Item 4: Metode Pembayaran
          _buildItemRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Metode Pembayaran',
            value: _paymentMethodLabel,
          ),
          const SizedBox(height: 12),

          // Detail Item 5: Total Terbayar (Highlighted Card)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD).withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: Color(0xFF0284C7),
                ),
                const SizedBox(width: 10),
                Text(
                  'Total Terbayar',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    price,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0369A1),
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

  Widget _buildItemRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF059669)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. ALERT BOX: JADWAL SIAP DIGUNAKAN
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildScheduleReadyBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF86EFAC).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications_active_outlined,
                    size: 20,
                    color: Color(0xFF065A37),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Jadwal Siap Digunakan',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF334155),
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text: 'Konsultasi Anda sekarang tersedia di menu ',
                ),
                const TextSpan(
                  text: '"Konsultasi Saya"',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const TextSpan(
                  text: '. Ruang chat & video call akan aktif otomatis ',
                ),
                const TextSpan(
                  text: '10 menit sebelum jadwal dimulai',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF047857)),
                ),
                TextSpan(
                  text: ' pada $selectedDate, ${selectedTime.split(' ').first} WIB.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. STICKY BOTTOM BUTTON: LIHAT KONSULTASI SAYA
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildBottomStickyButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _darkGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            // Pops all the way back with success result to redirect to Konsultasi Saya
            Navigator.pop(context, true);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lihat Konsultasi Saya',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 20,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: CELEBRATORY MASCOT ILLUSTRATION
// ─────────────────────────────────────────────────────────────────────────────

class _MascotCelebrationPainter extends CustomPainter {
  const _MascotCelebrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Organic Backdrop Blob (Light Green)
    final blobPaint = Paint()
      ..color = const Color(0xFFDCFCE7)
      ..style = PaintingStyle.fill;

    final blobBorderPaint = Paint()
      ..color = const Color(0xFF86EFAC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final blobPath = Path();
    blobPath.moveTo(center.dx - 60, center.dy - 35);
    blobPath.cubicTo(center.dx - 40, center.dy - 55, center.dx + 40, center.dy - 60, center.dx + 55, center.dy - 40);
    blobPath.cubicTo(center.dx + 75, center.dy - 20, center.dx + 80, center.dy + 25, center.dx + 55, center.dy + 45);
    blobPath.cubicTo(center.dx + 30, center.dy + 60, center.dx - 30, center.dy + 65, center.dx - 55, center.dy + 45);
    blobPath.cubicTo(center.dx - 80, center.dy + 25, center.dx - 80, center.dy - 15, center.dx - 60, center.dy - 35);
    blobPath.close();

    canvas.drawPath(blobPath, blobPaint);
    canvas.drawPath(blobPath, blobBorderPaint);

    // 2. Character 1 (Left: Vibrant lime green smiling character)
    final char1Center = Offset(center.dx - 28, center.dy + 5);
    const char1Radius = 26.0;

    // Body
    final char1Paint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(char1Center, char1Radius, char1Paint);

    // Tiny antenna / hair sprig
    final strokePaint = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    final sprig = Path()
      ..moveTo(char1Center.dx - 2, char1Center.dy - char1Radius)
      ..quadraticBezierTo(char1Center.dx - 8, char1Center.dy - char1Radius - 10, char1Center.dx - 5, char1Center.dy - char1Radius - 12);
    canvas.drawPath(sprig, strokePaint);

    // Eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(char1Center.dx - 7, char1Center.dy - 4), 2.5, eyePaint);
    canvas.drawCircle(Offset(char1Center.dx + 7, char1Center.dy - 4), 2.5, eyePaint);

    // Smile
    final smilePath = Path()
      ..moveTo(char1Center.dx - 8, char1Center.dy + 3)
      ..quadraticBezierTo(char1Center.dx, char1Center.dy + 12, char1Center.dx + 8, char1Center.dy + 3);
    canvas.drawPath(smilePath, strokePaint);

    // Little Legs
    canvas.drawLine(
      Offset(char1Center.dx - 9, char1Center.dy + char1Radius - 2),
      Offset(char1Center.dx - 12, char1Center.dy + char1Radius + 10),
      strokePaint,
    );
    canvas.drawLine(
      Offset(char1Center.dx + 7, char1Center.dy + char1Radius - 2),
      Offset(char1Center.dx + 4, char1Center.dy + char1Radius + 10),
      strokePaint,
    );

    // 3. Character 2 (Right: Soft mint green joyful character)
    final char2Center = Offset(center.dx + 28, center.dy - 2);
    const char2Radius = 22.0;

    final char2Paint = Paint()
      ..color = const Color(0xFF86EFAC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(char2Center, char2Radius, char2Paint);

    // Cute curved closed eyes (smiling ^ ^)
    final char2Stroke = Paint()
      ..color = const Color(0xFF166534)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    final leftEye = Path()
      ..moveTo(char2Center.dx - 9, char2Center.dy - 3)
      ..quadraticBezierTo(char2Center.dx - 6, char2Center.dy - 8, char2Center.dx - 3, char2Center.dy - 3);
    canvas.drawPath(leftEye, char2Stroke);

    final rightEye = Path()
      ..moveTo(char2Center.dx + 3, char2Center.dy - 3)
      ..quadraticBezierTo(char2Center.dx + 6, char2Center.dy - 8, char2Center.dx + 9, char2Center.dy - 3);
    canvas.drawPath(rightEye, char2Stroke);

    // Happy open mouth
    final mouthPath = Path()
      ..moveTo(char2Center.dx - 6, char2Center.dy + 2)
      ..quadraticBezierTo(char2Center.dx, char2Center.dy + 10, char2Center.dx + 6, char2Center.dy + 2)
      ..close();
    final mouthFill = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(mouthPath, mouthFill);

    // Raised celebration arms
    final armPath = Path()
      ..moveTo(char2Center.dx + char2Radius - 2, char2Center.dy)
      ..quadraticBezierTo(char2Center.dx + char2Radius + 8, char2Center.dy - 8, char2Center.dx + char2Radius + 12, char2Center.dy - 12);
    canvas.drawPath(armPath, char2Stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: TOPOGRAPHY BACKGROUND LINES
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (int i = 0; i < 10; i++) {
      final path = Path();
      final yOffset = 20.0 + (i * 90);
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
