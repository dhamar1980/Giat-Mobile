import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../profile/profile_pasien_screen.dart';
import 'pembayaran_berhasil_konsultasi_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN MENUNGGU PEMBAYARAN VIRTUAL ACCOUNT (Sesuai Referensi UI GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class MenungguPembayaranVaScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final String selectedDate;
  final String selectedTime;
  final String price;
  final String userName;
  final String vaNumber;
  final String bankName;
  final String accountName;
  final String paymentDeadline;

  const MenungguPembayaranVaScreen({
    super.key,
    required this.doctor,
    required this.selectedDate,
    required this.selectedTime,
    required this.price,
    this.userName = 'Pasien',
    this.vaNumber = '8808 1234 5678 9012',
    this.bankName = 'BCA Virtual Account',
    this.accountName = 'A.N. GIAT Farma / Encep Suryana',
    this.paymentDeadline = '01 September 2026, 23:59 WIB',
  });

  @override
  State<MenungguPembayaranVaScreen> createState() => _MenungguPembayaranVaScreenState();
}

class _MenungguPembayaranVaScreenState extends State<MenungguPembayaranVaScreen> {
  static const _darkGreen = Color(0xFF044E2F);
  static const _primaryGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF7FAF8);
  static const _cardBorderColor = Color(0xFFE2E8F0);

  // Tab index for Petunjuk Transfer: 0 = m-Banking, 1 = ATM BCA, 2 = KlikBCA
  int _selectedTabIndex = 0;

  String _formatPrice(String price) {
    if (price.endsWith(',00')) return price;
    return '$price,00';
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
              painter: _VaTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Navigation Bar ──
                _buildTopBar(context),

                const SizedBox(height: 12),

                // ── Scrollable Body ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Total Pembayaran Card
                        _buildTotalPaymentCard(),

                        const SizedBox(height: 18),

                        // 2. Bank Information Header
                        Text(
                          widget.bankName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.accountName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 3. Virtual Account Details Card
                        _buildVaNumberCard(context),

                        const SizedBox(height: 20),

                        // 4. Section: Menunggu Pembayaran
                        Text(
                          'Menunggu Pembayaran',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 5. Doctor Card
                        _buildDoctorCard(
                          name: docName,
                          specialty: docSpecialty,
                          rating: docRating,
                          avatarUrl: docAvatar,
                        ),

                        const SizedBox(height: 20),

                        // 6. Section: Petunjuk Transfer
                        Text(
                          'Petunjuk Transfer',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 7. Transfer Instructions with Tabs Card
                        _buildTransferGuideCard(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Sticky Bottom Buttons ──
                _buildBottomButtons(context, docName: docName),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Kembali Pill Button
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

          const SizedBox(height: 12),

          // Center Pill Badge: "Menunggu Pembayaran Virtual Account"
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                'Menunggu Pembayaran Virtual Account',
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
  // 2. TOTAL PEMBAYARAN CARD
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTotalPaymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        children: [
          Text(
            'TOTAL PEMBAYARAN',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatPrice(widget.price),
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. VIRTUAL ACCOUNT DETAILS CARD
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildVaNumberCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nomor Virtual Account',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),

          // VA Number & Salin Button Row
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.vaNumber,
                  style: GoogleFonts.inter(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.vaNumber.replaceAll(' ', '')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nomor Virtual Account berhasil disalin!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _darkGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Salin No. VA',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bayar Sebelum Red Notice
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 15,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFDC2626),
                    ),
                    children: [
                      const TextSpan(
                        text: 'Bayar sebelum: ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      TextSpan(
                        text: widget.paymentDeadline,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. KARTU DOKTER DENGAN BADGE MENUNGGU PEMBAYARAN
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status Badge "⏳ Menunggu Pembayaran"
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 13,
                      color: Color(0xFF065A37),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Menunggu Pembayaran',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF065A37),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Doctor Avatar & Info Row
          Row(
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            name,
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
                                rating,
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
                      specialty,
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
                            '${widget.selectedDate} • ${widget.selectedTime}',
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
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. PETUNJUK TRANSFER CARD DENGAN TABS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTransferGuideCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Tabs: m-Banking, ATM BCA, KlikBCA
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildSegmentTab(index: 0, label: 'm-Banking'),
                _buildSegmentTab(index: 1, label: 'ATM BCA'),
                _buildSegmentTab(index: 2, label: 'KlikBCA'),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Steps list based on active tab
          _buildActiveTabSteps(),
        ],
      ),
    );
  }

  Widget _buildSegmentTab({required int index, required String label}) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
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
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF044E2F) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabSteps() {
    List<Widget> stepWidgets = [];

    if (_selectedTabIndex == 0) {
      // m-Banking (Exact 5 steps from Screenshot 4)
      stepWidgets = [
        _buildStepItem(
          stepNumber: 1,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: const [
                TextSpan(text: 'Buka aplikasi BCA mobile, pilih menu '),
                TextSpan(text: 'm-Transfer', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          stepNumber: 2,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: const [
                TextSpan(text: 'Pilih '),
                TextSpan(text: 'BCA Virtual Account', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          stepNumber: 3,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: [
                const TextSpan(text: 'Masukkan nomor Virtual Account '),
                TextSpan(
                  text: widget.vaNumber,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const TextSpan(text: ' lalu klik '),
                const TextSpan(text: 'Send', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          stepNumber: 4,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: [
                const TextSpan(text: 'Periksa nominal '),
                TextSpan(
                  text: widget.price,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const TextSpan(text: ' dan nama penerima '),
                const TextSpan(
                  text: 'GIAT Telemedicine',
                  style: TextStyle(fontWeight: FontWeight.w700, color: _darkGreen),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          stepNumber: 5,
          isLast: true,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: const [
                TextSpan(text: 'Masukkan '),
                TextSpan(text: 'PIN m-BCA', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                TextSpan(text: ' Anda untuk menyelesaikan pembayaran.'),
              ],
            ),
          ),
        ),
      ];
    } else if (_selectedTabIndex == 1) {
      // ATM BCA
      stepWidgets = [
        _buildStepItem(
          stepNumber: 1,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: const [
                TextSpan(text: 'Masukkan kartu ATM BCA dan 6 digit '),
                TextSpan(text: 'PIN Anda', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          stepNumber: 2,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: const [
                TextSpan(text: 'Pilih menu '),
                TextSpan(text: 'Transaksi Lainnya > Transfer > ke Rekening BCA Virtual Account', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          stepNumber: 3,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: [
                const TextSpan(text: 'Masukkan nomor Virtual Account '),
                TextSpan(
                  text: widget.vaNumber,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const TextSpan(text: ' lalu tekan '),
                const TextSpan(text: 'Benar', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          stepNumber: 4,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: [
                const TextSpan(text: 'Periksa rincian pembayaran nominal '),
                TextSpan(
                  text: widget.price,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const TextSpan(text: ' dan nama penerima '),
                const TextSpan(text: 'GIAT Telemedicine', style: TextStyle(fontWeight: FontWeight.w700, color: _darkGreen)),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          stepNumber: 5,
          isLast: true,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: const [
                TextSpan(text: 'Tekan '),
                TextSpan(text: 'Ya', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                TextSpan(text: ' untuk memproses pembayaran dan simpan bukti transaksi.'),
              ],
            ),
          ),
        ),
      ];
    } else {
      // KlikBCA
      stepWidgets = [
        _buildStepItem(
          stepNumber: 1,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: const [
                TextSpan(text: 'Akses situs KlikBCA Individual dan login ke akun Anda.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          stepNumber: 2,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: const [
                TextSpan(text: 'Pilih menu '),
                TextSpan(text: 'Transfer Dana > Transfer ke BCA Virtual Account', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          stepNumber: 3,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: [
                const TextSpan(text: 'Masukkan nomor Virtual Account '),
                TextSpan(
                  text: widget.vaNumber,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const TextSpan(text: ' lalu klik '),
                const TextSpan(text: 'Lanjutkan', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          stepNumber: 4,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: const [
                TextSpan(text: 'Pastikan data tagihan sesuai, lalu masukkan respon '),
                TextSpan(text: 'KeyBCA Appli 1', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        _buildStepItem(
          stepNumber: 5,
          isLast: true,
          content: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155), height: 1.4),
              children: const [
                TextSpan(text: 'Klik '),
                TextSpan(text: 'Kirim', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                TextSpan(text: ' untuk menyelesaikan pembayaran dan simpan bukti transfer.'),
              ],
            ),
          ),
        ),
      ];
    }

    return Column(children: stepWidgets);
  }

  Widget _buildStepItem({
    required int stepNumber,
    required Widget content,
    bool isLast = false,
  }) {
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
                '$stepNumber',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0284C7),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: content),
        ],
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
                      paymentMethod: 'va',
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
                side: const BorderSide(color: _darkGreen, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, false);
              },
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
  // 7. SUKSES DIALOG
  // ─────────────────────────────────────────────────────────────────────────────
  void _showSuccessDialog(BuildContext context, {required String docName}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Badge Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF16A34A),
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Pembayaran Berhasil Diverifikasi!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Sesi konsultasi Anda dengan $docName telah berhasil dijadwalkan.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),

                // Booking details box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tanggal', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
                          Flexible(
                            child: Text(
                              widget.selectedDate,
                              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Waktu', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
                          Flexible(
                            child: Text(
                              widget.selectedTime,
                              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Metode', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
                          Flexible(
                            child: Text(
                              widget.bankName,
                              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: _primaryGreen),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Status', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Sudah Dijadwalkan',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Button: Lihat di Konsultasi Saya
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

class _VaTopographyPainter extends CustomPainter {
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
