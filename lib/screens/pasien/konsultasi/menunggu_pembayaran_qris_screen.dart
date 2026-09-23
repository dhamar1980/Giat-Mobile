import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../profile/profile_pasien_screen.dart';
import 'pembayaran_berhasil_konsultasi_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN MENUNGGU PEMBAYARAN QRIS (Sesuai Referensi UI GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class MenungguPembayaranQrisScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final String selectedDate;
  final String selectedTime;
  final String price;
  final String userName;

  const MenungguPembayaranQrisScreen({
    super.key,
    required this.doctor,
    required this.selectedDate,
    required this.selectedTime,
    required this.price,
    this.userName = 'Pasien',
  });

  @override
  State<MenungguPembayaranQrisScreen> createState() => _MenungguPembayaranQrisScreenState();
}

class _MenungguPembayaranQrisScreenState extends State<MenungguPembayaranQrisScreen> {
  static const _darkGreen = Color(0xFF044E2F);
  static const _primaryGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF7FAF8);
  static const _cardBorderColor = Color(0xFFE2E8F0);

  // 15-minute countdown timer (898 seconds = 14:58 matching screenshot)
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = 898;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;
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
              painter: _QrisTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Navigation Bar ──
                _buildTopBar(context),

                const SizedBox(height: 8),

                // ── Red Countdown Banner ──
                _buildCountdownBanner(),

                const SizedBox(height: 10),

                // ── Scrollable Body ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section: Scan QRIS untuk Membayar
                        Text(
                          'Scan QRIS untuk Membayar',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // QRIS Card
                        _buildQrisCard(context),

                        const SizedBox(height: 20),

                        // Section: Menunggu Pembayaran
                        Text(
                          'Menunggu Pembayaran',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Doctor Card
                        _buildDoctorCard(
                          name: docName,
                          specialty: docSpecialty,
                          rating: docRating,
                          avatarUrl: docAvatar,
                        ),

                        const SizedBox(height: 20),

                        // Section: Tata Cara Pembayaran Via QRIS
                        Text(
                          'Tata Cara Pembayaran Via QRIS',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Instructions Card
                        _buildInstructionsCard(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Sticky Bottom Action Buttons ──
                _buildBottomButtons(context, docName: docName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. TOP NAVIGATION BAR
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        children: [
          Row(
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
                          color: _darkGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 18,
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

          // Center Pill Badge: "Menunggu Pembayaran QRIS"
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
                'Menunggu Pembayaran QRIS',
                style: GoogleFonts.inter(
                  fontSize: 14,
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
  // 2. COUNTDOWN ALERT BANNER
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildCountdownBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_rounded,
            color: Color(0xFFDC2626),
            size: 16,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFDC2626)),
                children: [
                  const TextSpan(text: 'Bayar Dalam '),
                  TextSpan(
                    text: _formatTime(_remainingSeconds),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: ' Menit'),
                  const TextSpan(
                    text: '  Selesaikan sebelum waktu habis',
                    style: TextStyle(color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. QRIS CARD
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildQrisCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: QRIS + GPN & NMID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'QRIS',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA7F3D0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'GPN',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF065A37),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _darkGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'NMID: ID12039437',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // QR Code Graphic Container
          Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0F172A), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Detailed QR Mockup Icon
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 190,
                  color: Color(0xFF0F172A),
                ),
                // Center Giat Logo/Emblem
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _darkGreen,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Standar Pembayaran Nasional',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dicetak otomatis oleh Sistem Resep GIAT',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 18),

          // Button: Unduh QR Code
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR Code berhasil diunduh ke galeri perangkat.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Unduh QR Code',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. KARTU DOKTER
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildDoctorCard({
    required String name,
    required String specialty,
    required String rating,
    required String avatarUrl,
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
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: avatarUrl.startsWith('http')
                    ? Image.network(
                        avatarUrl,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating,
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
                const SizedBox(height: 3),
                Text(
                  specialty,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _darkGreen,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${widget.selectedDate} • ${widget.selectedTime}',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
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
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. TATA CARA PEMBAYARAN VIA QRIS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildInstructionsCard() {
    final steps = [
      'Buka aplikasi m-Banking (BCA, Mandiri, BRI, BNI) atau e-Wallet (GoPay, OVO, Dana) yang mendukung QRIS.',
      'Pilih menu Scan QRIS dan arahkan kamera ke barcode di atas.',
      'Pastikan nama penerima tertera GIAT Telemedicine dengan nominal ${widget.price}.',
      'Masukkan 6 digit PIN transaksi Anda dan simpan resi bukti pembayaran.',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: List.generate(steps.length, (index) {
          final isLast = index == steps.length - 1;
          final stepNum = '${index + 1}';
          final text = steps[index];

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      stepNum,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRichInstruction(index, text),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRichInstruction(int index, String fullText) {
    if (index == 1) {
      return RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
          children: const [
            TextSpan(text: 'Pilih menu '),
            TextSpan(text: 'Scan QRIS', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            TextSpan(text: ' dan arahkan kamera ke barcode di atas.'),
          ],
        ),
      );
    } else if (index == 2) {
      return RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
          children: [
            const TextSpan(text: 'Pastikan nama penerima tertera '),
            const TextSpan(
              text: 'GIAT Telemedicine',
              style: TextStyle(fontWeight: FontWeight.w700, color: _darkGreen),
            ),
            const TextSpan(text: ' dengan nominal '),
            TextSpan(
              text: widget.price,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const TextSpan(text: '.'),
          ],
        ),
      );
    }
    return Text(
      fullText,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: const Color(0xFF334155),
        height: 1.4,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. STICKY BOTTOM BUTTONS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildBottomButtons(BuildContext context, {required String docName}) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Button 1: Saya Sudah Membayar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final success = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PembayaranBerhasilKonsultasiScreen(
                      doctor: widget.doctor,
                      selectedDate: widget.selectedDate,
                      selectedTime: widget.selectedTime,
                      price: widget.price,
                      userName: widget.userName,
                      paymentMethod: 'qris',
                    ),
                  ),
                );
                if (success == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Saya Sudah Membayar',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
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

          const SizedBox(height: 10),

          // Button 2: Ganti Metode Pembayaran
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _darkGreen,
                side: const BorderSide(color: _darkGreen, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Ganti Metode Pembayaran',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _darkGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SUCCESS DIALOG & REDIRECT TO KONSULTASI SAYA
  // ─────────────────────────────────────────────────────────────────────────────
  void _showSuccessDialog(BuildContext context, {required String docName}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Color(0xFF16A34A),
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Pembayaran Berhasil Diverifikasi!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Jadwal konsultasi Anda telah dikonfirmasi dan masuk ke menu "Konsultasi Saya".',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dokter',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                          Text(
                            docName,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Waktu',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                          ),
                          Text(
                            widget.selectedTime,
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _darkGreen),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      Navigator.pop(context, true);
                    },
                    child: Text(
                      'Lihat di Konsultasi Saya',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: TOPOGRAPHY BACKGROUND LINES
// ─────────────────────────────────────────────────────────────────────────────

class _QrisTopographyPainter extends CustomPainter {
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
