import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';
import '../notifikasi/apotek_notifikasi_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL PESANAN APOTEK (Revisi Sesuai 4 Screenshot Desain GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekDetailPesananScreen extends StatefulWidget {
  final ApotekOrder order;
  final VoidCallback? onStatusChanged;

  const ApotekDetailPesananScreen({
    super.key,
    required this.order,
    this.onStatusChanged,
  });

  @override
  State<ApotekDetailPesananScreen> createState() => _ApotekDetailPesananScreenState();
}

class _ApotekDetailPesananScreenState extends State<ApotekDetailPesananScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF7FAF8);
  static const _cardBorder = Color(0xFFE2E8F0);
  static const _iconBgBlue = Color(0xFFD6EFF6);

  void _startProcessOrder() {
    setState(() {
      widget.order.status = ApotekOrderStatus.diproses;
    });
    widget.onStatusChanged?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pesanan ${widget.order.id} mulai diproses.'),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _completeOrder() {
    setState(() {
      widget.order.status = ApotekOrderStatus.selesai;
      widget.order.progressStep = 5;
    });
    widget.onStatusChanged?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pesanan ${widget.order.id} telah diselesaikan.'),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ord = widget.order;
    final isMenunggu = ord.status == ApotekOrderStatus.menunggu;
    final isDiproses = ord.status == ApotekOrderStatus.diproses;
    final isSelesai = ord.status == ApotekOrderStatus.selesai;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topographic Waves
          Positioned.fill(
            child: CustomPaint(
              painter: _DetailPesananTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Custom Top Bar & Center Badge ──
                _buildTopHeader(),

                // ── Scrollable Body Content ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMenunggu) ...[
                          // ── STATE 1: MENUNGGU (Screenshot 1 & 2) ──
                          _buildMenungguHeaderCard(ord),
                          const SizedBox(height: 18),
                          _buildPatientInfoSection(ord),
                          const SizedBox(height: 18),
                          _buildRecipeInfoSection(ord),
                          const SizedBox(height: 18),
                          _buildMenungguMedicinesSection(ord),
                        ] else ...[
                          // ── STATE 2 & 3: DIPROSES / SELESAI (Screenshot 3 & 4) ──
                          _buildDiprosesHeaderCard(ord, isSelesai),
                          const SizedBox(height: 18),
                          _buildOrderInfoSection(ord),
                          const SizedBox(height: 18),
                          _buildDiprosesRecipeSection(ord),
                          const SizedBox(height: 18),
                          _buildDiprosesMedicinesSection(ord),
                          const SizedBox(height: 18),
                          _buildOrderProgressSection(ord, isSelesai),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Bottom Action Button Bar (Hanya untuk Menunggu & Diproses) ──
                if (!isSelesai)
                  _buildBottomActionBar(isMenunggu, isDiproses),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOP BAR & HEADER BADGE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Pill Button: [← Kembali]
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF0F172A), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
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
                        size: 15,
                        color: Color(0xFF0F172A),
                      ),
                      const SizedBox(width: 4),
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

              // Right Pill: [Bell & User Profile]
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
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
                          MaterialPageRoute(
                            builder: (_) => const ApotekNotifikasiScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: _darkGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Center Green Badge: [Detail Pesanan]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
            decoration: BoxDecoration(
              color: _darkGreen,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _darkGreen.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              'Detail Pesanan',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STATE 1: MENUNGGU WIDGETS (Screenshot 1 & 2)
  // ───────────────────────────────────────────────────────────────────────────

  // Top Card: Pill icon in light blue, ORD ID, Patient name, subtitle
  Widget _buildMenungguHeaderCard(ApotekOrder ord) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Soft blue box with rotated pill icon
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _iconBgBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Transform.rotate(
                angle: -0.75,
                child: const Icon(
                  Icons.medication_outlined,
                  size: 26,
                  color: Color(0xFF0F172A),
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
                  ord.id,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ord.patientName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${ord.items.length} item obat • ${ord.timeText}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section: informasi Pasien
  Widget _buildPatientInfoSection(ApotekOrder ord) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'informasi Pasien',
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Initials avatar in light blue
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _iconBgBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    ord.patientInitials.isNotEmpty ? ord.patientInitials : 'BS',
                    style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
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
                      ord.patientName,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Usia: ${ord.patientAge} Tahun',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kelamin: ${ord.patientGender}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Alamat :${ord.patientAddress}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section: Resep
  Widget _buildRecipeInfoSection(ApotekOrder ord) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resep',
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Light blue box with document icon
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _iconBgBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.description_outlined,
                    size: 28,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ord.recipeRef.isNotEmpty ? ord.recipeRef : 'RX-00110',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Dokter: ${ord.doctorName.isNotEmpty ? ord.doctorName : 'Dr. Andi Wijaya'}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tanggal: ${ord.recipeDate.isNotEmpty ? ord.recipeDate : '1 Juni 2025'}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section: Daftar Obat (with "Obat Tersedia" dark green capsule badges)
  Widget _buildMenungguMedicinesSection(ApotekOrder ord) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Obat',
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: List.generate(ord.items.length, (idx) {
              final item = ord.items[idx];
              final isLast = idx == ord.items.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.medicineName,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.formAndPack,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Dark green capsule badge: [Obat Tersedia]
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: _buttonDarkGreen,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Obat Tersedia',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STATE 2: DIPROSES & SELESAI WIDGETS (Screenshot 3 & 4)
  // ───────────────────────────────────────────────────────────────────────────

  // Top Card: Dark green icon box, ORD ID, yellow Diproses badge, Pasien, Jumlah, Tanggal
  Widget _buildDiprosesHeaderCard(ApotekOrder ord, bool isSelesai) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Solid dark green box with white medical kit icon
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _darkGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                Icons.medical_services_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ord.id,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (isSelesai)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Selesai',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF08A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Diproses',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF854D0E),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Pasien: ${ord.patientName}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jumlah Obat: ${ord.items.length} item obat',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tanggal & Waktu: ${ord.orderDateTime}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section: Informasi Pesanan (Table rows)
  Widget _buildOrderInfoSection(ApotekOrder ord) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Pesanan',
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTableRow('Nomor Pesanan', ord.id),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildTableRow('Tanggal & Waktu', ord.orderDateTime),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildTableRow('Mulai Diproses', ord.processStartTime),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildTableRow('Jumlah Obat', '${ord.items.length} item'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // Section: Informasi Resep (in Screenshot 3)
  Widget _buildDiprosesRecipeSection(ApotekOrder ord) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Pesanan', // Header matching screenshot 3
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Light blue box with pill icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _iconBgBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: -0.75,
                    child: const Icon(
                      Icons.medication_outlined,
                      size: 26,
                      color: Color(0xFF0F172A),
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
                      ord.recipeRef.isNotEmpty ? ord.recipeRef : 'RX-00110',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Resep ${ord.doctorName.isNotEmpty ? ord.doctorName : 'Dr. Andi'}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section: Daftar Obat (with quantity capsules and bottom Total row)
  Widget _buildDiprosesMedicinesSection(ApotekOrder ord) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Obat',
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              ...List.generate(ord.items.length, (idx) {
                final item = ord.items[idx];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.medicineName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.formAndPack,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Dark green capsule badge with quantity e.g. [2 Tablet]
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: _buttonDarkGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.qtyText,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ],
                );
              }),

              // Total Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${ord.items.length} item obat',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section: Progres Pesanan (5 Step Vertical Timeline - Screenshot 4)
  Widget _buildOrderProgressSection(ApotekOrder ord, bool isSelesai) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progres Pesanan',
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Step 1: Pesanan diterima (Completed)
              _buildProgressStepItem(
                title: 'Pesanan diterima',
                subtitle: '10:05',
                status: _StepStatus.completed,
                isLast: false,
              ),

              // Step 2: Resep diperiksa (Completed)
              _buildProgressStepItem(
                title: 'Resep diperiksa',
                subtitle: '10:18',
                status: _StepStatus.completed,
                isLast: false,
              ),

              // Step 3: Obat diperiksa (Completed)
              _buildProgressStepItem(
                title: 'Obat diperiksa',
                subtitle: '10:20',
                status: _StepStatus.completed,
                isLast: false,
              ),

              // Step 4: Obat sedang disiapkan (Active / Completed)
              _buildProgressStepItem(
                title: 'Obat sedang disiapkan',
                subtitle: isSelesai ? '10:24' : 'Sedang berlangsung',
                status: isSelesai ? _StepStatus.completed : _StepStatus.active,
                isLast: false,
              ),

              // Step 5: Pemeriksaan akhir (Pending / Completed)
              _buildProgressStepItem(
                title: 'Pemeriksaan akhir',
                subtitle: isSelesai ? '10:25' : 'Belum dilakukan',
                status: isSelesai ? _StepStatus.completed : _StepStatus.pending,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStepItem({
    required String title,
    required String subtitle,
    required _StepStatus status,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicator column with vertical connecting line
        Column(
          children: [
            if (status == _StepStatus.completed)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              )
            else if (status == _StepStatus.active)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF065A37), width: 2.2),
                ),
                child: Center(
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF065A37),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
                ),
              ),

            // Connecting vertical line downwards
            if (!isLast)
              Container(
                width: 1.8,
                height: 32,
                color: const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: status == _StepStatus.pending ? FontWeight.w500 : FontWeight.w700,
                    color: status == _StepStatus.pending ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: status == _StepStatus.active ? FontWeight.w600 : FontWeight.w400,
                    color: status == _StepStatus.active
                        ? _darkGreen
                        : (status == _StepStatus.pending ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM ACTION BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomActionBar(bool isMenunggu, bool isDiproses) {
    String buttonText;
    VoidCallback? onPressed;
    Color buttonColor;

    if (isMenunggu) {
      buttonText = 'Mulai Proses';
      buttonColor = _buttonDarkGreen;
      onPressed = _startProcessOrder;
    } else if (isDiproses) {
      buttonText = 'Selesaikan Pesanan Sekarang';
      buttonColor = _buttonDarkGreen;
      onPressed = _completeOrder;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          onPressed: onPressed,
          child: Text(
            buttonText,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

enum _StepStatus {
  completed,
  active,
  pending,
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHIC WAVES BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPesananTopographyPainter extends CustomPainter {
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
