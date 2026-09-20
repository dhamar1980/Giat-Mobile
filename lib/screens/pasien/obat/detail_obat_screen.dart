import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'keranjang_screen.dart';
import '../profile/profile_pasien_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL DATA KATALOG OBAT
// ─────────────────────────────────────────────────────────────────────────────

class ObatCatalogItem {
  final String id;
  final String name;
  final String category;
  final String badgeText; // 'Bebas', 'Terbatas', 'Obat Keras'
  final Color badgeColor;
  final String packageInfo; // 'Strip 10 Tablet'
  final int price;
  final String priceFormatted;
  final String imagePath;
  final bool perluResep;
  final String bpomBadge;
  final String ginjalWarning;
  final String shortDesc;
  final List<Map<String, dynamic>> indications;
  final List<Map<String, String>> dosageRules;

  const ObatCatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.badgeText,
    required this.badgeColor,
    required this.packageInfo,
    required this.price,
    required this.priceFormatted,
    required this.imagePath,
    this.perluResep = false,
    this.bpomBadge = 'Katalog Resmi BPOM',
    this.ginjalWarning =
        'Pasien dengan riwayat gangguan fungsi ginjal (CKD stadium apa pun) atau penurunan laju filtrasi glomerulus (LFG) disarankan berkonsultasi terlebih dahulu dengan dokter nefrologi Anda di GIAT sebelum mengonsumsi obat ini secara berkala.',
    this.shortDesc =
        'Analgesik dan antipiretik terpercaya untuk meredakan keluhan nyeri dan demam tanpa mengganggu lambung jika digunakan sesuai dosis anjuran tenaga medis.',
    this.indications = const [],
    this.dosageRules = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN DETAIL OBAT
// ─────────────────────────────────────────────────────────────────────────────

class DetailObatScreen extends StatefulWidget {
  final String userName;
  final ObatCatalogItem? obatItem;
  final int initialCartCount;
  final ValueChanged<int>? onCartCountChanged;

  const DetailObatScreen({
    super.key,
    this.userName = 'Pasien',
    this.obatItem,
    this.initialCartCount = 2,
    this.onCartCountChanged,
  });

  @override
  State<DetailObatScreen> createState() => _DetailObatScreenState();
}

class _DetailObatScreenState extends State<DetailObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _badgeDark = Color(0xFF0F172A);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);
  static const _redAlert = Color(0xFFDC2626);

  late final ObatCatalogItem _obat;
  int _quantity = 1;
  late int _cartCount;

  @override
  void initState() {
    super.initState();
    _cartCount = widget.initialCartCount;
    _obat = widget.obatItem ??
        const ObatCatalogItem(
          id: 'paracetamol',
          name: 'Paracetamol 500 mg',
          category: 'Analgesik & Anipiretik',
          badgeText: 'Bebas',
          badgeColor: Color(0xFF16A34A),
          packageInfo: 'Strip 10 Tablet',
          price: 8000,
          priceFormatted: 'Rp. 8.000,00',
          imagePath: 'assets/images/paracetamol_strip.jpg',
          perluResep: false,
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
        );
  }

  String _formatNumber(int val) {
    final s = val.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _obat.price * _quantity;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topography Curves
          Positioned.fill(
            child: CustomPaint(
              painter: _DetailObatTopographyPainter(),
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

                        // ── 2. Screen Title Pill: Detail Obat ──
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
                              'Detail Obat',
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

                        // ── 3. Hero Product Image Container ──
                        _buildHeroImageContainer(),

                        const SizedBox(height: 16),

                        // ── 4. Card Header & Spesifikasi Obat ──
                        _buildProductOverviewCard(),

                        const SizedBox(height: 18),

                        // ── 5. Peringatan Pasien Ginjal ──
                        _buildPeringatanGinjalSection(),

                        const SizedBox(height: 16),

                        // ── 6. Deskripsi Singkat ──
                        _buildDeskripsiSingkatSection(),

                        const SizedBox(height: 16),

                        // ── 7. Kegunaan Umum ──
                        _buildKegunaanUmumSection(),

                        const SizedBox(height: 16),

                        // ── 8. Informasi Penggunaan & Aturan Pakai ──
                        _buildAturanPakaiSection(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // ── 9. Bottom Quantity & Add-to-Cart Action Bar ──
                _buildBottomActionBar(context, totalPrice),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KeranjangScreen(userName: widget.userName),
                    ),
                  );
                },
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KeranjangScreen(userName: widget.userName),
                          ),
                        );
                      },
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
  // HERO IMAGE CONTAINER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeroImageContainer() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFB7DFCE),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          _obat.imagePath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(
              Icons.medication_rounded,
              size: 80,
              color: _darkGreen.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PRODUCT OVERVIEW CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildProductOverviewCard() {
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
          // Top row: Katalog Resmi BPOM
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _obat.bpomBadge,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Icon + Category + Name + 3 Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF0284C7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _obat.category,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _obat.name,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Row of 3 status badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildStatusBadge(_obat.packageInfo, _badgeDark),
                        _buildStatusBadge('Original 100%', _badgeDark),
                        _buildStatusBadge('Stok Tersedia', _darkGreen),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Price Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Harga Obat',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _obat.priceFormatted,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    TextSpan(
                      text: ' / Strip',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
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

  Widget _buildStatusBadge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PERINGATAN PASIEN GINJAL
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPeringatanGinjalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _redAlert,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Peringatan Pasien Ginjal',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _obat.ginjalWarning,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DESKRIPSI SINGKAT
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDeskripsiSingkatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _darkGreen,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Deskripsi Singkat',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _obat.shortDesc,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
            height: 1.45,
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // KEGUNAAN UMUM
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKegunaanUmumSection() {
    final indications = _obat.indications.isNotEmpty
        ? _obat.indications
        : [
            {'icon': Icons.device_thermostat_rounded, 'label': 'Demam Tinggi'},
            {'icon': Icons.sentiment_dissatisfied_outlined, 'label': 'Sakit Kepala'},
            {'icon': Icons.medical_services_outlined, 'label': 'Sakit gigi'},
            {'icon': Icons.healing_rounded, 'label': 'Nyeri otot'},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _darkGreen,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Kegunaan Umum',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...indications.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: _darkGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // INFORMASI PENGGUNAAN & ATURAN PAKAI
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAturanPakaiSection() {
    final rules = _obat.dosageRules.isNotEmpty
        ? _obat.dosageRules
        : [
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
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _darkGreen,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Informasi Pengunaan & Aturan Pakai',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...rules.map((rule) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: _darkGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        rule['num']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule['title']!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rule['desc']!,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM QUANTITY & ADD-TO-CART ACTION BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomActionBar(BuildContext context, int totalPrice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
      child: Row(
        children: [
          // Quantity Selector
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minus Button
                InkWell(
                  onTap: () {
                    if (_quantity > 1) {
                      setState(() => _quantity--);
                    }
                  },
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Icon(Icons.remove, size: 18, color: Color(0xFF475569)),
                  ),
                ),
                // Value
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '$_quantity',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                // Plus Button (Light Blue Box)
                InkWell(
                  onTap: () {
                    setState(() => _quantity++);
                  },
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.horizontal(right: Radius.circular(11)),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, size: 18, color: Color(0xFF0284C7)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Add to Cart Button
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _cartCount += _quantity;
                  });
                  widget.onCartCountChanged?.call(_cartCount);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$_quantity ${_obat.name} ditambahkan ke keranjang belanja! 🛒'),
                      backgroundColor: _darkGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: FittedBox(
                  child: Text(
                    'Tambah ke Keranjang • Rp ${_formatNumber(totalPrice)}',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: TOPOGRAPHY BACKGROUND LINES FOR DETAIL OBAT
// ─────────────────────────────────────────────────────────────────────────────

class _DetailObatTopographyPainter extends CustomPainter {
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
