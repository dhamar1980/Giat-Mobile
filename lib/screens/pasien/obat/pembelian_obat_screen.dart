import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_obat_screen.dart';
import 'keranjang_screen.dart';
import 'resep_dokter_screen.dart';
import '../profile/profile_pasien_screen.dart';
import '../../../services/pasien_api_service.dart';
import '../../../services/cart_service.dart';

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
  String _searchQuery = '';
  bool _isLoading = true;

  late List<ObatCatalogItem> _allMedicines;

  @override
  void initState() {
    super.initState();
    _allMedicines = [];
    CartService.instance.addListener(_onCartChanged);
    _fetchLiveMedicines();
  }

  @override
  void dispose() {
    CartService.instance.removeListener(_onCartChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  int get _cartCount => CartService.instance.totalCount;

  Future<void> _fetchLiveMedicines() async {
    if (mounted && _allMedicines.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await PasienApiService().getObatList(search: _searchQuery.isNotEmpty ? _searchQuery : null);
      if (res.success && res.data != null && res.data!.isNotEmpty && mounted) {
        final List<ObatCatalogItem> apiItems = [];
        for (var item in res.data!) {
          if (item is Map) {
            final id = (item['id_obat'] ?? item['id'] ?? 'obat-${item['nama_obat'] ?? item['nama'] ?? ''}').toString();
            final name = (item['nama_obat'] ?? item['nama'] ?? item['name'] ?? 'Obat').toString();
            final cat = (item['kategori'] ?? item['category'] ?? 'Obat Bebas').toString();
            final price = double.tryParse((item['harga_jual'] ?? item['harga'] ?? item['price'] ?? '0').toString()) ?? 0.0;
            final formattedPrice = 'Rp ${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
            final desc = (item['aturan_pakai_umum'] ?? item['deskripsi'] ?? item['description'] ?? '').toString();
            final catLower = cat.toLowerCase();
            final nameLower = name.toLowerCase();
            final bool isKeras = item['perlu_resep'] == true ||
                item['is_resep'] == 1 ||
                catLower.contains('keras') ||
                catLower.contains('resep') ||
                catLower.contains('ginjal') ||
                catLower.contains('hipertensi') ||
                catLower.contains('arb') ||
                catLower.contains('diuretik') ||
                nameLower.contains('ketosteril') ||
                nameLower.contains('candesartan') ||
                nameLower.contains('furosemide') ||
                nameLower.contains('amlodipine');

            final isTerbatas = catLower.contains('terbatas');
            final String badgeText = isKeras ? 'Obat Keras' : (isTerbatas ? 'Terbatas' : 'Bebas');
            final Color badgeColor = isKeras
                ? const Color(0xFFDC2626)
                : (isTerbatas ? const Color(0xFF2DD4BF) : const Color(0xFF065A37));

            final kemasan = (item['satuan_kemasan'] ?? item['kemasan'] ?? item['package_info'] ?? '1 Strip').toString();
            final img = (item['foto_obat'] ?? item['gambar'] ?? item['image'] ?? 'assets/images/paracetamol_strip.jpg').toString();

            apiItems.add(ObatCatalogItem(
              id: id,
              name: name,
              category: cat,
              badgeText: badgeText,
              badgeColor: badgeColor,
              packageInfo: kemasan,
              price: price.toInt(),
              priceFormatted: formattedPrice,
              imagePath: img,
              perluResep: isKeras,
              bpomBadge: (item['bpom'] ?? 'Katalog Resmi BPOM').toString(),
              ginjalWarning: (item['peringatan_ginjal'] ??
                  (isKeras
                      ? 'Obat resep dokter spesialis ginjal nefrologi. Gunakan dengan resep dan dosis yang tepat.'
                      : 'Gunakan sesuai petunjuk dokter atau apoteker.')).toString(),
              shortDesc: desc.isNotEmpty ? desc : 'Obat terapi untuk pasien kesehatan ginjal.',
              indications: [
                {'icon': Icons.medical_services_outlined, 'label': cat},
              ],
              dosageRules: [
                {
                  'num': '1',
                  'title': 'Aturan Pakai',
                  'desc': desc.isNotEmpty ? desc : 'Sesuai petunjuk dokter / apoteker.'
                },
              ],
            ));
          }
        }
        if (mounted) {
          setState(() {
            _allMedicines = apiItems;
          });
        }
      } else if (mounted) {
        setState(() {
          _allMedicines = [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching live medicines: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(color: _darkGreen),
        ),
      );
    }

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
                    child: item.imagePath.startsWith('http')
                        ? Image.network(
                            item.imagePath,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 130,
                              color: const Color(0xFFDCFCE7),
                              child: const Icon(Icons.medication_rounded, color: _darkGreen, size: 40),
                            ),
                          )
                        : Image.asset(
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
            setState(() {});
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ResepDokterScreen(userName: widget.userName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Resep Dokter', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    CartService.instance.addItem(
      id: item.id,
      name: item.name,
      category: item.category,
      badgeText: item.badgeText,
      badgeColor: item.badgeColor,
      packageInfo: item.packageInfo,
      dosageInstruction: item.dosageRules.isNotEmpty ? (item.dosageRules.first['desc'] ?? item.packageInfo) : item.packageInfo,
      unitPrice: item.price,
      quantity: 1,
      imagePath: item.imagePath,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} berhasil ditambahkan ke keranjang belanja! 🛒'),
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
      showGradient: false,
      showLines: true,
    );
    }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
