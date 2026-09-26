import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';
import '../notifikasi/apotek_notifikasi_screen.dart';
import '../profile/apotek_profile_screen.dart';
import 'apotek_detail_obat_screen.dart';
import 'apotek_tambah_obat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KATALOG & INVENTARIS OBAT APOTEK (Revisi Sesuai Screenshot Desain GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekObatScreen extends StatefulWidget {
  final String? initialFilter;
  final VoidCallback? onOpenProfile;

  const ApotekObatScreen({
    super.key,
    this.initialFilter,
    this.onOpenProfile,
  });

  @override
  State<ApotekObatScreen> createState() => _ApotekObatScreenState();
}

class _ApotekObatScreenState extends State<ApotekObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _border = Color(0xFFE2E8F0);

  late String _selectedFilter; // 'Semua', 'Tersedia', 'Stok Menipis', 'Habis'
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _normalizeInitialFilter();
  }

  void _normalizeInitialFilter() {
    final init = widget.initialFilter;
    if (init == 'Stock Aman' || init == 'Tersedia') {
      _selectedFilter = 'Tersedia';
    } else if (init == 'Stock Menipis' || init == 'Stok Menipis') {
      _selectedFilter = 'Stok Menipis';
    } else if (init == 'Stock Habis' || init == 'Habis') {
      _selectedFilter = 'Habis';
    } else {
      _selectedFilter = 'Semua';
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ApotekMedicine> _getFilteredMedicines() {
    final all = ApotekMockData.medicines;
    final byFilter = all.where((m) {
      if (_selectedFilter == 'Tersedia' || _selectedFilter == 'Stock Aman') {
        return m.status == ApotekMedicineStatus.tersedia;
      }
      if (_selectedFilter == 'Stok Menipis' || _selectedFilter == 'Stock Menipis') {
        return m.status == ApotekMedicineStatus.stokMenipis;
      }
      if (_selectedFilter == 'Habis' || _selectedFilter == 'Stock Habis') {
        return m.status == ApotekMedicineStatus.habis;
      }
      return true;
    }).toList();

    if (_searchQuery.trim().isEmpty) return byFilter;

    final q = _searchQuery.toLowerCase().trim();
    return byFilter.where((m) {
      final inBatches = m.batches.any((b) => b.batchNo.toLowerCase().contains(q));
      return m.name.toLowerCase().contains(q) ||
          m.category.toLowerCase().contains(q) ||
          m.id.toLowerCase().contains(q) ||
          m.form.toLowerCase().contains(q) ||
          inBatches;
    }).toList();
  }

  void _openDetail(ApotekMedicine med) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApotekDetailObatScreen(
          medicine: med,
          onStockUpdated: () => setState(() {}),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openTambahObat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApotekTambahObatScreen(
          onMedicineAdded: () => setState(() {}),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _handleOpenProfile() {
    if (widget.onOpenProfile != null) {
      widget.onOpenProfile!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ApotekProfileScreen(showBackButton: true)),
      );
    }
  }

  String _formatCurrency(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return formatted;
  }

  String _getDisplayUnit(ApotekMedicine med) {
    if (med.status == ApotekMedicineStatus.habis && med.stockUnit == 'Box') {
      return 'Box';
    }
    final unitParts = med.packageUnit.split('/');
    if (unitParts.isNotEmpty && unitParts.first.trim().isNotEmpty) {
      return unitParts.first.trim();
    }
    return med.stockUnit;
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final filtered = _getFilteredMedicines();

    // Dinamis namun selaras dengan total inventaris apotek (148, 12, 3) di desain screenshot
    final actualAman = ApotekMockData.medicines.where((m) => m.status == ApotekMedicineStatus.tersedia).length;
    final actualMenipis = ApotekMockData.medicines.where((m) => m.status == ApotekMedicineStatus.stokMenipis).length;
    final actualHabis = ApotekMockData.medicines.where((m) => m.status == ApotekMedicineStatus.habis).length;

    final amanCount = 147 + actualAman;
    final menipisCount = 11 + actualMenipis;
    final habisCount = 2 + actualHabis;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topography Curves (seperti di screenshot & tab Apotek lain)
          Positioned.fill(
            child: CustomPaint(
              painter: _ObatTopographyPainter(),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Top Curved Green Header with Chat Bubbles (Fixed at top, does not scroll) ──
              _buildHeaderSection(topPadding),

              // ── 2. Content Section (Scrollable) ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 16, bottom: 28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Judul Seksi: "Daftar Inventaris Obat" (Screenshot 1)
                      Text(
                        'Daftar Inventaris Obat',
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 3 Stat Cards (Stock Aman: 148, Stock Menipis: 12, Stock Habis: 3)
                      Row(
                        children: [
                          _buildStockStatCard(
                            count: '$amanCount',
                            label: 'Stock Aman',
                            bg: const Color(0xFF065A37),
                            textColor: Colors.white,
                            countColor: Colors.white,
                            borderColor: null,
                            watermarkColor: Colors.white.withValues(alpha: 0.08),
                            isSelected: _selectedFilter == 'Tersedia',
                            onTap: () {
                              setState(() {
                                _selectedFilter = _selectedFilter == 'Tersedia' ? 'Semua' : 'Tersedia';
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildStockStatCard(
                            count: '$menipisCount',
                            label: 'Stock Menipis',
                            bg: const Color(0xFFEEF5FD),
                            textColor: const Color(0xFF1E293B),
                            countColor: const Color(0xFF0F172A),
                            borderColor: const Color(0xFFC7D9EE),
                            watermarkColor: const Color(0xFF065A37).withValues(alpha: 0.05),
                            isSelected: _selectedFilter == 'Stok Menipis',
                            onTap: () {
                              setState(() {
                                _selectedFilter = _selectedFilter == 'Stok Menipis' ? 'Semua' : 'Stok Menipis';
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildStockStatCard(
                            count: '$habisCount',
                            label: 'Stock Habis',
                            bg: const Color(0xFFFEF7D6),
                            textColor: const Color(0xFF1E293B),
                            countColor: const Color(0xFF0F172A),
                            borderColor: const Color(0xFFF7E591),
                            watermarkColor: const Color(0xFFD97706).withValues(alpha: 0.06),
                            isSelected: _selectedFilter == 'Habis',
                            onTap: () {
                              setState(() {
                                _selectedFilter = _selectedFilter == 'Habis' ? 'Semua' : 'Habis';
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Baris Peringatan Registrasi Baru (Screenshot 1)
                      Row(
                        children: [
                          const Icon(
                            Icons.info_rounded,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Hanya untuk registrasi SKU/formula baru',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Tombol "Tambah Obat Baru" Penuh (Screenshot 1)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonDarkGreen,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: _buttonDarkGreen.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: _openTambahObat,
                          child: Text(
                            'Tambah Obat Baru',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Search Bar Membulat Kapsul (Screenshot 1)
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: _border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (val) => setState(() => _searchQuery = val),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Cari nama obat, kategori, no batch...',
                                  hintStyle: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Filter Chips Row (Screenshot 1: Semua, Tersedia, Stok Menipis, Habis)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildFilterChip('Semua'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Tersedia'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Stok Menipis'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Habis'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Judul Daftar Obat: "Daftar Obat" (Screenshot 1, 2)
                      Text(
                        'Daftar Obat',
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // List Obat Cards (Screenshot 1, 2, 3)
                      if (filtered.isEmpty)
                        _buildEmptyState()
                      else
                        ...filtered.map((med) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildMedicineCard(med),
                            )),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER SECTION (Mockup Screenshot 1: Green Gradient + 2 Chat Bubbles + Pill)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderSection(double topPadding) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF22C55E),
            Color(0xFF16A34A),
            Color(0xFF065A37),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              child: CustomPaint(
                painter: _ObatHeaderCurvePainter(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 78, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Single Chat Bubble
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildChatBubble(
                    isLeft: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Kelola & Stok Obat ✨✨',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF14532D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Yuk, kelola penyimpanan dan cek stok obat apotek kamu sekarang di menu Obat.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF14532D).withValues(alpha: 0.9),
                            height: 1.35,
                          ),
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

  Widget _buildChatBubble({
    required bool isLeft,
    required Widget child,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isLeft ? const Radius.circular(4) : const Radius.circular(16),
              bottomRight: isLeft ? const Radius.circular(16) : const Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
        // WhatsApp style speech bubble tail
        Positioned(
          bottom: 0,
          left: isLeft ? -7 : null,
          right: isLeft ? null : -7,
          child: CustomPaint(
            size: const Size(8, 12),
            painter: _ChatTailPainter(isLeft: isLeft),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3 STAT CARDS: STOCK AMAN, STOCK MENIPIS, STOCK HABIS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStockStatCard({
    required String count,
    required String label,
    required Color bg,
    required Color textColor,
    required Color countColor,
    required Color? borderColor,
    required Color watermarkColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: _darkGreen, width: 2.0)
                : borderColor != null
                    ? Border.all(color: borderColor, width: 1.2)
                    : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CardWavePainter(color: watermarkColor),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          count,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: countColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FILTER CHIP (Semua, Tersedia, Stok Menipis, Habis)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected ? _darkGreen : const Color(0xFFE8F1FC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MEDICINE CARD (Screenshot 1, 2, 3: Thumbnail, Badge, Info Box, Exp & Detail)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMedicineCard(ApotekMedicine med) {
    Color statusBg;
    Color statusTextColor;
    String statusText;

    switch (med.status) {
      case ApotekMedicineStatus.tersedia:
        statusBg = const Color(0xFF065A37);
        statusTextColor = Colors.white;
        statusText = 'Tersedia';
        break;
      case ApotekMedicineStatus.stokMenipis:
        statusBg = const Color(0xFFEAB308);
        statusTextColor = const Color(0xFF1E293B);
        statusText = 'Stok Menipis';
        break;
      case ApotekMedicineStatus.habis:
        statusBg = const Color(0xFFDC2626);
        statusTextColor = Colors.white;
        statusText = 'Habis';
        break;
    }

    final isHabis = med.status == ApotekMedicineStatus.habis;
    final displayUnit = _getDisplayUnit(med);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Row: Image Thumbnail + Title & Subtitle + Status Pill ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Obat dengan Border Membulat
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (med.imagePath != null)
                        Image.asset(
                          med.imagePath!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.medication_rounded, size: 30, color: _darkGreen),
                          ),
                        )
                      else
                        const Center(
                          child: Icon(Icons.medication_rounded, size: 30, color: _darkGreen),
                        ),
                      // Tanda Silang Overlay Merah jika Stok Habis (Screenshot 3: Omeprazole)
                      if (isHabis)
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.block_rounded,
                              color: Color(0xFFDC2626),
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${med.category} • ${med.form}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Status Badge Pill (Tersedia, Stok Menipis, Habis)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Middle Container: Kotak Biru Muda Sisa Stok & Harga Jual ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sisa Stok',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      '${med.stock} ${med.stockUnit}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Harga Jual',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Rp. ${_formatCurrency(med.sellPrice)},00 / $displayUnit',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Bottom Row: Exp Date (Merah) & Lihat Detail (Hijau dengan Ikon Panah) ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Exp: ${med.expDate}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _openDetail(med),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Detail',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _darkGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_circle_right_outlined,
                        size: 16,
                        color: _darkGreen,
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'Tidak ada obat yang cocok',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coba ubah kata kunci pencarian atau ganti filter status stok.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM CLIPPERS & PAINTERS (Sesuai Desain GIAT Apotek)
// ─────────────────────────────────────────────────────────────────────────────

class _ObatHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 35);
    // Smooth asymmetric organic curve
    path.cubicTo(
      size.width * 0.25,
      size.height + 18,
      size.width * 0.65,
      size.height - 45,
      size.width,
      size.height - 25,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ChatTailPainter extends CustomPainter {
  final bool isLeft;
  const _ChatTailPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardWavePainter extends CustomPainter {
  final Color color;
  const _CardWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final yOffset = size.height * 0.2 + (i * 20);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.3,
        yOffset - 15,
        size.width * 0.7,
        yOffset + 15,
        size.width,
        yOffset - 5,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ObatTopographyPainter extends CustomPainter {
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

class _ObatHeaderCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final yOffset = 30.0 + (i * 45);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.25,
        yOffset + 35,
        size.width * 0.75,
        yOffset - 35,
        size.width,
        yOffset + 25,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
