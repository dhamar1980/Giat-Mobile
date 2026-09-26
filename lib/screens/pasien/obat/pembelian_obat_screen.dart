import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_obat_screen.dart';
import 'checkout_resep_screen.dart';
import 'keranjang_screen.dart';
import '../profile/profile_pasien_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN PEMBELIAN OBAT (KATALOG OBAT - Sesuai Gambar 1 & 2)
// ─────────────────────────────────────────────────────────────────────────────

class PembelianObatScreen extends StatefulWidget {
  final String userName;

  const PembelianObatScreen({
    super.key,
    this.userName = 'Pasien',
  });

  @override
  State<PembelianObatScreen> createState() => _PembelianObatScreenState();
}

class _PembelianObatScreenState extends State<PembelianObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);
  static const _redAlert = Color(0xFFDC2626);

  final TextEditingController _searchCtrl = TextEditingController();
  int _cartCount = 2;
  String _searchQuery = '';

  late final List<ObatCatalogItem> _allMedicines;

  @override
  void initState() {
    super.initState();
    _allMedicines = [
      // 1. Antasida Doen
      const ObatCatalogItem(
        id: 'antasida',
        name: 'Antasida Doen',
        category: 'Antasida & Antiflatulen',
        badgeText: 'Terbatas',
        badgeColor: Color(0xFF2DD4BF),
        packageInfo: 'Strip 10 Tablet kunyah',
        price: 6500,
        priceFormatted: 'Rp. 6.500,00',
        imagePath: 'assets/images/antasida_strip.jpg',
        perluResep: false,
        bpomBadge: 'Katalog Resmi BPOM',
        ginjalWarning:
            'Pasien gangguan ginjal berat dianjurkan berkonsultasi mengenai asupan aluminium dan magnesium dalam antasida agar tidak membebani filtrasi ginjal.',
        shortDesc:
            'Membantu meredakan gejala kelebihan asam lambung, gastritis, tukak lambung, dan tukak usus dua belas jari seperti mual dan perih.',
        indications: [
          {'icon': Icons.healing_rounded, 'label': 'Asam Lambung Naik'},
          {'icon': Icons.sentiment_dissatisfied_outlined, 'label': 'Perut Kembung'},
          {'icon': Icons.medical_services_outlined, 'label': 'Nyeri Ulu Hati'},
        ],
        dosageRules: [
          {
            'num': '1',
            'title': 'Dewasa',
            'desc': '1 - 2 tablet dikunyah, 3 - 4 kali sehari, 1 jam sebelum atau 2 jam setelah makan.',
          },
          {
            'num': '2',
            'title': 'Anak-anak (6 - 12 tahun)',
            'desc': '1/2 - 1 tablet dikunyah, 3 - 4 kali sehari sesuai anjuran tenaga medis.',
          },
        ],
      ),

      // 2. Paracetamol 500 mg
      const ObatCatalogItem(
        id: 'paracetamol',
        name: 'Paracetamol 500 mg',
        category: 'Analgesik & Anipiretik',
        badgeText: 'Bebas',
        badgeColor: Color(0xFF065A37),
        packageInfo: 'Strip 10 Tablet',
        price: 8000,
        priceFormatted: 'Rp. 8.000,00',
        imagePath: 'assets/images/paracetamol_strip.jpg',
        perluResep: false,
        bpomBadge: 'Katalog Resmi BPOM',
        ginjalWarning:
            'Pasien dengan riwayat gangguan fungsi ginjal (CKD stadium apa pun) atau penurunan laju filtrasi glomerulus (LFG) disarankan berkonsultasi terlebih dahulu dengan dokter nefrologi Anda di GIAT sebelum mengonsumsi obat ini secara berkala.',
        shortDesc:
            'Analgesik dan antipiretik terpercaya untuk meredakan keluhan nyeri dan demam tanpa mengganggu lambung jika digunakan sesuai dosis anjuran tenaga medis.',
        indications: [
          {'icon': Icons.device_thermostat_rounded, 'label': 'Demam Tinggi'},
          {'icon': Icons.sentiment_dissatisfied_outlined, 'label': 'Sakit Kepala'},
          {'icon': Icons.medical_services_outlined, 'label': 'Sakit gigi'},
          {'icon': Icons.healing_rounded, 'label': 'Nyeri otot'},
        ],
        dosageRules: [
          {
            'num': '1',
            'title': 'Dewasa & Remaja (> 12 tahun)',
            'desc': '1 - 2 tablet, 3 - 4 kali sehari sesudah makan bila diperlukan. Maksimal 8 tablet per hari.',
          },
          {
            'num': '2',
            'title': 'Anak-anak (6 - 12 tahun)',
            'desc': '1/2 - 1 tablet sesuai petunjuk dokter atau apoteker mitra. Jangan melebihi dosis anjuran.',
          },
        ],
      ),

      // 3. Ketosteril Tablet
      const ObatCatalogItem(
        id: 'ketosteril',
        name: 'Ketosteril Tablet',
        category: 'Asam Amino Esensial & Ketoanalog',
        badgeText: 'Obat Keras',
        badgeColor: Color(0xFFDC2626),
        packageInfo: 'Strip 10 kaplet Terapi Ginjal',
        price: 65000,
        priceFormatted: 'Rp. 6.500,00',
        imagePath: 'assets/images/antasida_strip.jpg',
        perluResep: true,
        bpomBadge: 'Katalog Resmi BPOM',
        ginjalWarning:
            'Obat keras untuk terapi insufisiensi ginjal kronis (CKD). Penggunaan dan dosis wajib dipantau langsung oleh dokter spesialis ginjal nefrologi.',
        shortDesc:
            'Kombinasi asam amino esensial bebas nitrogen dan ketoanalog untuk terapi nutrisi medis pada pasien penyakit ginjal kronis berdiet rendah protein.',
        indications: [
          {'icon': Icons.medical_services_outlined, 'label': 'Proteksi Glomerulus'},
          {'icon': Icons.healing_rounded, 'label': 'Keseimbangan Nitrogen'},
          {'icon': Icons.favorite_border_rounded, 'label': 'Terapi Nutrisi Ginjal'},
        ],
        dosageRules: [
          {
            'num': '1',
            'title': 'Dewasa dengan Diet Protein Rendah',
            'desc': '3 kali sehari 4-8 kaplet bersamaan makan. Telan utuh jangan dikunyah.',
          },
        ],
      ),
    ];
  }

  List<ObatCatalogItem> get _filteredMedicines {
    if (_searchQuery.isEmpty) return _allMedicines;
    return _allMedicines
        .where((m) =>
            m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            m.category.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
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
              painter: _PembelianObatTopographyPainter(),
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
                        // ── 1. Top Navigation Bar ──
                        _buildTopBar(context),

                        const SizedBox(height: 16),

                        // ── 2. Screen Title Pill: Pembelian Obat ──
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
                              'Pembelian Obat',
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

                        // ── 3. Search Bar ──
                        _buildSearchBar(),

                        const SizedBox(height: 14),

                        // ── 4. Disclaimer Peringatan Obat Keras ──
                        _buildDisclaimerPeringatan(),

                        const SizedBox(height: 18),

                        // ── 5. Section: Katalog Obat ──
                        Text(
                          'Katalog Obat',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── 6. Grid Katalog Obat (2 Kolom) ──
                        _buildKatalogGrid(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── 7. Sticky Bottom Button: Lihat Keranjang ──
                _buildStickyBottomBar(context),
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

        // Action Pill (Cart with Badge & Avatar)
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
              // Cart Button with Yellow Badge
              GestureDetector(
                onTap: () => _openCart(context),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 22,
                        color: Color(0xFF1F2937),
                      ),
                      onPressed: () => _openCart(context),
                    ),
                    if (_cartCount > 0)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFBBF24),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_cartCount',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Profile Avatar
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
  // SEARCH BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Cari nama obat...',
          hintStyle: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DISCLAIMER PERINGATAN OBAT KERAS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDisclaimerPeringatan() {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _redAlert,
          height: 1.4,
        ),
        children: const [
          TextSpan(
            text: '*Pastikan membaca aturan pakai dan dosis. Obat bertanda ',
          ),
          TextSpan(
            text: 'Obat Keras (K)',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text:
                ' memerlukan verifikasi resep dokter dari menu Tebus Resep atau hasil telekonsultasi dokter sebelum dapat dibeli.',
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GRID KATALOG OBAT (2 Kolom)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKatalogGrid() {
    final list = _filteredMedicines;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
              const SizedBox(height: 10),
              Text(
                'Obat tidak ditemukan',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 14) / 2;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: list.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _buildMedicationCatalogCard(item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMedicationCatalogCard(ObatCatalogItem item) {
    return GestureDetector(
      onTap: () => _navigateToDetail(item),
      child: Container(
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
            // Image with Category Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: const Color(0xFFE2E8F0),
                    child: Image.asset(
                      item.imagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 130,
                        color: const Color(0xFFDCFCE7),
                        child: const Icon(Icons.medication_rounded, color: _darkGreen, size: 40),
                      ),
                    ),
                  ),
                ),
                // Badge top right
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.badgeColor,
                      borderRadius: BorderRadius.circular(10),
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
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.packageInfo,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (item.perluResep) ...[
                    const SizedBox(height: 3),
                    Text(
                      '*Perlu resep dokter',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _redAlert,
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Harga: ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        TextSpan(
                          text: item.priceFormatted,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Button Tambah
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () => _handleTambahObat(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _darkGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Tambah',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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

  // ───────────────────────────────────────────────────────────────────────────
  // STICKY BOTTOM BAR: LIHAT KERANJANG
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStickyBottomBar(BuildContext context) {
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
          onPressed: () => _openCart(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: _darkGreen,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lihat Keranjang',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_circle_right_outlined,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(ObatCatalogItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailObatScreen(
          userName: widget.userName,
          obatItem: item,
          initialCartCount: _cartCount,
          onCartCountChanged: (newCount) {
            setState(() => _cartCount = newCount);
          },
        ),
      ),
    );
  }

  void _handleTambahObat(ObatCatalogItem item) {
    if (item.perluResep) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: _redAlert, size: 24),
              const SizedBox(width: 8),
              Text(
                'Obat Keras (K)',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          content: Text(
            '${item.name} memerlukan resep dokter spesialis nefrologi GIAT. Silakan tebus resep Anda melalui menu "Resep Dokter" atau lakukan telekonsultasi.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Tutup', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _openCartCheckout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Tebus Resep', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _cartCount++);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} ditambahkan ke keranjang! 🛒'),
        backgroundColor: _darkGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KeranjangScreen(userName: widget.userName),
      ),
    );
  }

  void _openCartCheckout(BuildContext context) => _openCart(context);
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: BACKGROUND CONTOUR LINES FOR PEMBELIAN OBAT
// ─────────────────────────────────────────────────────────────────────────────

class _PembelianObatTopographyPainter extends CustomPainter {
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
