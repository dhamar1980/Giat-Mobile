import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../profile/profile_pasien_screen.dart';
import 'resep_dokter_screen.dart';
import 'pembelian_obat_screen.dart';
import 'lacak_obat_screen.dart';
import 'riwayat_obat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN OBAT & RESEP PASIEN (Figma Screen: Tab Obat Pasien)
// ─────────────────────────────────────────────────────────────────────────────

class DaftarObatScreen extends StatefulWidget {
  final bool isEmbedded;
  final String userName;
  final double heightCm;
  final double weightKg;

  const DaftarObatScreen({
    super.key,
    this.isEmbedded = false,
    this.userName = 'Pasien',
    this.heightCm = 170.0,
    this.weightKg = 65.0,
  });

  @override
  State<DaftarObatScreen> createState() => _DaftarObatScreenState();
}

class _DaftarObatScreenState extends State<DaftarObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Header Section: Gradient Arc & Chat Bubbles ──
          _buildHeaderSection(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── Bagian 1: Resep Saya ──
                _buildResepSayaSection(),

                const SizedBox(height: 22),

                // ── Bagian 2: Katalog Apotek ──
                _buildKatalogApotekSection(),

                const SizedBox(height: 22),

                // ── Bagian 3: Panduan Pembelian Obat & Resep ──
                _buildPanduanSection(),

                const SizedBox(height: 22),

                // ── Bagian 4: Status Pengiriman & Kartu Pesanan ──
                _buildStatusPengirimanSection(),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return Container(
        color: _bgColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ObatTopographyPainter(),
              ),
            ),
            Positioned.fill(
              child: content,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Layanan Obat & Resep',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: _darkGreen),
            tooltip: 'Riwayat Pesanan',
            onPressed: () => _openRiwayatScreen(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ObatTopographyPainter(),
            ),
          ),
          SafeArea(
            top: false,
            child: content,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOP HEADER BANNER (Gradient, Organic Curves & 2 Chat Bubbles)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderSection() {
    final topPadding = widget.isEmbedded
        ? (MediaQuery.of(context).padding.top + 72)
        : (MediaQuery.of(context).padding.top + 16);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF22C55E),
            Color(0xFF16A34A),
            Color(0xFF0D7A3E),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
      ),
      child: Stack(
        children: [
          // Background organic curves
          Positioned.fill(
            child: CustomPaint(
              painter: _ObatHeaderCurvePainter(),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Standalone top action pill (bell & profile)
                if (!widget.isEmbedded) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
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
                              tooltip: 'Notifikasi',
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
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Chat Bubble 1 (Left Aligned) ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 310),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            'Halo! Mulai kelola resep dan kebutuhan obat Anda bersama dokter spesialis GIAT 👋',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _darkGreen,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: Color(0xFF38BDF8),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Chat Bubble 2 (Right Aligned) ──
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.fromLTRB(16, 12, 14, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rawat kesehatanmu dengan pengelolaan obat yang aman dan terpadu. Langkah kecil menuju pulih sempurna. ✨✨',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _darkGreen,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: Color(0xFF38BDF8),
                        ),
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
  // 1. RESEP SAYA
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildResepSayaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Resep Saya',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: const Color(0xFF044E2F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '2 resep aktif',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CardCornerContoursPainter(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF8F6),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.assignment_outlined,
                              color: _darkGreen,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Resep Dokter Spesialis',
                                        style: GoogleFonts.inter(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF065A37),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 11,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Hari ini, 14:00 WIB',
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Diverifikasi oleh Dr. Sp.PD KGH untuk protokol nefrologi Anda.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: _darkGreen,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Siap ditebus ke apotek rekanan',
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResepDokterScreen(userName: widget.userName),
                                ),
                              );
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lihat Resep Dokter',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _darkGreen,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_circle_right_outlined,
                                  color: _darkGreen,
                                  size: 17,
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
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. KATALOG APOTEK
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKatalogApotekSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Katalog Apotek',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        _buildCariBeliObatCard(),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2.1 KARTU CARI DAN BELI OBAT
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCariBeliObatCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Ornamen Gelombang
            Positioned.fill(
              child: CustomPaint(
                painter: _CardCornerContoursPainter(),
              ),
            ),

            // Badge Bebas & Terbatas di Kanan Atas
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3.5),
                decoration: BoxDecoration(
                  color: _darkGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Bebas & Terbatas',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto Dokter/Apoteker + Deskripsi
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/dokter_apoteker.jpg',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 64,
                            height: 64,
                            color: const Color(0xFFDCFCE7),
                            child: const Icon(Icons.person_rounded, color: _darkGreen, size: 36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 65),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cari dan Beli Obat',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Penuhi vitamin, suplemen ginjal, dan obat bebas langsung dari farmasi resmi terakreditasi.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Kapsul Kategori Obat (Navy Chips)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildCategoryChip('Vitamin Ginjal'),
                      _buildCategoryChip('Pengikat Fosfat'),
                      _buildCategoryChip('Suplemen Elektrolit'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tombol Full-Width "Beli Obat"
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PembelianObatScreen(userName: widget.userName),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 19),
                      label: Text(
                        'Beli Obat',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _darkGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildCategoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. PANDUAN PEMBELIAN OBAT & RESEP
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPanduanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header dengan Ikon Info Bulat
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _darkGreen, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.info_outline_rounded,
                  color: _darkGreen,
                  size: 17,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Panduan Pembelian Obat & Resep',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Sub-panduan 1: Obat Bebas & Terbatas
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _darkGreen,
            borderRadius: BorderRadius.circular(4),
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
        const SizedBox(height: 6),
        Text(
          'Pasien dapat langsung membeli vitamin ginjal, suplemen elektrolit, atau pereda nyeri ringan secara mandiri tanpa resep dokter.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF1E293B),
          ),
        ),

        const SizedBox(height: 14),

        // Sub-panduan 2: Obat Keras
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _darkGreen,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Obat Keras (Lingkaran Merah / K):',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Seperti antihipertensi khusus, antibiotik, pengikat fosfat dosis tinggi, dan imunosupresan wajib menyertakan resep dokter demi keselamatan fungsi laju filtrasi glomerulus (GFR).',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. STATUS PENGIRIMAN
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStatusPengirimanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris Header: Status Pengiriman & Lihat Riwayat
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Status Pengiriman',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () => _openRiwayatScreen(context),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Riwayat',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _darkGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_circle_right_outlined,
                    color: _darkGreen,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Kartu Pesanan Pengiriman
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Ornamen Gelombang
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CardCornerContoursPainter(),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris Utama: Truk Ikon & Rincian Pesanan
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF8F6),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.local_shipping_outlined,
                              color: _darkGreen,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '#G-9021',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5A100),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Sedang Diproses',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                RichText(
                                  text: TextSpan(
                                    text: 'Tanggal Pesanan: ',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF475569),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '01 September 2026',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                RichText(
                                  text: TextSpan(
                                    text: 'Item: ',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF475569),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Kalsium Karbonat, Asam Folat',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                RichText(
                                  text: TextSpan(
                                    text: 'Apotek: ',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF475569),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Apotek Mitra GIAT Pasteur',
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Baris Step: Telaah Resep Selesai
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: _darkGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Telaah Resep Selesai',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Obat sedang dikemas dalam packing higienis kedap suhu',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Baris Estimasi Tiba & Tombol Lacak Obat
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: '*Estimasi tiba: ',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF475569),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Hari ini, 15:30',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _openLacakObatScreen(context),
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lacak Obat',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _darkGreen,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_circle_right_outlined,
                                  color: _darkGreen,
                                  size: 17,
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
            ),
          ),
        ),
      ],
    );
  }

  void _openLacakObatScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LacakObatScreen(
          userName: widget.userName,
          orderId: '#G-9021',
          estimasiTiba: 'Hari ini, 15:30 WIB',
          status: 'Sedang Diproses',
        ),
      ),
    );
  }

  void _openRiwayatScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiwayatObatScreen(
          userName: widget.userName,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MODAL INTERAKTIF: LACAK OBAT (#G-9021)
  // ───────────────────────────────────────────────────────────────────────────
  void _showLacakObatModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lacak Pesanan #G-9021',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Estimasi tiba: Hari ini, 15:30 WIB',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A100),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Sedang Diproses',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTimelineStep(
              title: 'Resep Diterima & Diverifikasi',
              time: '01 Sep 2026 • 09:15 WIB',
              isCompleted: true,
            ),
            _buildTimelineStep(
              title: 'Telaah Resep oleh Apoteker Selesai',
              time: '01 Sep 2026 • 10:30 WIB',
              isCompleted: true,
            ),
            _buildTimelineStep(
              title: 'Obat Sedang Dikemas Kedap Suhu',
              time: '01 Sep 2026 • 11:10 WIB',
              isCompleted: true,
              isCurrent: true,
            ),
            _buildTimelineStep(
              title: 'Kurir GIAT Menuju Alamat Pasien',
              time: 'Estimasi 14:45 WIB',
              isCompleted: false,
              isLast: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _darkGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _darkGreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String time,
    required bool isCompleted,
    bool isCurrent = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isCompleted ? _darkGreen : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
                border: isCurrent
                    ? Border.all(color: const Color(0xFF22C55E), width: 3)
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: isCompleted ? _darkGreen : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isCurrent || isCompleted ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent ? _darkGreen : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MODAL INTERAKTIF: RIWAYAT PESANAN OBAT
  // ───────────────────────────────────────────────────────────────────────────
  void _showRiwayatPesananModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Riwayat Pesanan Obat',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),
            _buildRiwayatCard(
              id: '#G-9021',
              date: '01 September 2026',
              items: 'Kalsium Karbonat, Asam Folat',
              status: 'Sedang Diproses',
              statusColor: const Color(0xFFE5A100),
            ),
            _buildRiwayatCard(
              id: '#G-8812',
              date: '18 Agustus 2026',
              items: 'Candesartan 8mg, Vitamin Ginjal',
              status: 'Selesai Diterima',
              statusColor: _darkGreen,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _darkGreen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _darkGreen),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatCard({
    required String id,
    required String date,
    required String items,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  items,
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155)),
                ),
                Text(
                  date,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: CARD CORNER DECORATIVE CONTOURS
// ─────────────────────────────────────────────────────────────────────────────

class _CardCornerContoursPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Gelombang sudut kiri atas
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offset = 10.0 + (i * 12);
      path.moveTo(0, offset + 20);
      path.cubicTo(
        offset + 10,
        offset + 25,
        offset + 25,
        offset + 10,
        offset + 35,
        0,
      );
      canvas.drawPath(path, paint);
    }

    // Gelombang sudut kanan bawah
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offset = 10.0 + (i * 12);
      path.moveTo(size.width, size.height - (offset + 20));
      path.cubicTo(
        size.width - (offset + 10),
        size.height - (offset + 25),
        size.width - (offset + 25),
        size.height - (offset + 10),
        size.width - (offset + 35),
        size.height,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: BACKGROUND TOPOGRAPHY
// ─────────────────────────────────────────────────────────────────────────────

class _ObatTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 8; i++) {
      final path = Path();
      final yOffset = size.height * 0.20 + (i * 90);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.3,
        yOffset - 35,
        size.width * 0.7,
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

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: HEADER ORGANIC CURVE
// ─────────────────────────────────────────────────────────────────────────────

class _ObatHeaderCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final yOffset = 40.0 + (i * 40);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.25,
        yOffset + 30,
        size.width * 0.75,
        yOffset - 30,
        size.width,
        yOffset + 20,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
