import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';
import 'apotek_detail_obat_screen.dart';
import 'apotek_tambah_obat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KATALOG & INVENTARIS OBAT APOTEK (Figma Node: 1100-23601)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekObatScreen extends StatefulWidget {
  final String? initialFilter;

  const ApotekObatScreen({
    super.key,
    this.initialFilter,
  });

  @override
  State<ApotekObatScreen> createState() => _ApotekObatScreenState();
}

class _ApotekObatScreenState extends State<ApotekObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  late String _selectedFilter; // 'Semua', 'Stock Aman', 'Stock Menipis', 'Stock Habis'
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'Semua';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ApotekMedicine> _getFilteredMedicines() {
    final all = ApotekMockData.medicines;
    final byFilter = all.where((m) {
      if (_selectedFilter == 'Stock Aman') return m.status == ApotekMedicineStatus.tersedia;
      if (_selectedFilter == 'Stock Menipis') return m.status == ApotekMedicineStatus.stokMenipis;
      if (_selectedFilter == 'Stock Habis') return m.status == ApotekMedicineStatus.habis;
      return true;
    }).toList();

    if (_searchQuery.trim().isEmpty) return byFilter;

    return byFilter.where((m) {
      return m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.id.toLowerCase().contains(_searchQuery.toLowerCase());
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

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredMedicines();

    final amanCount = ApotekMockData.medicines.where((m) => m.status == ApotekMedicineStatus.tersedia).length;
    final menipisCount = ApotekMockData.medicines.where((m) => m.status == ApotekMedicineStatus.stokMenipis).length;
    final habisCount = ApotekMockData.medicines.where((m) => m.status == ApotekMedicineStatus.habis).length;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Daftar Inventaris Obat',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section (Chat Bubble + Stat Cards + Tambah Obat + Search + Filter Chips)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chat Bubble (Figma Node 1100:23601)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.medication_liquid_rounded, size: 18, color: _darkGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Selamat datang kembali! Yuk, kelola penyimpanan dan cek stok obat kamu sekarang di menu Obat. ✨✨',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF14532D),
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3 Stat Cards (Stock Aman, Stock Menipis, Stock Habis)
                  Row(
                    children: [
                      _buildStockStatCard(
                        count: amanCount.toString(),
                        label: 'Stock Aman',
                        color: const Color(0xFF16A34A),
                        bg: const Color(0xFFF0FDF4),
                        border: const Color(0xFFBBF7D0),
                        isSelected: _selectedFilter == 'Stock Aman',
                        onTap: () => setState(() => _selectedFilter = _selectedFilter == 'Stock Aman' ? 'Semua' : 'Stock Aman'),
                      ),
                      const SizedBox(width: 8),
                      _buildStockStatCard(
                        count: menipisCount.toString(),
                        label: 'Stock Menipis',
                        color: const Color(0xFFD97706),
                        bg: const Color(0xFFFFFBEB),
                        border: const Color(0xFFFDE68A),
                        isSelected: _selectedFilter == 'Stock Menipis',
                        onTap: () => setState(() => _selectedFilter = _selectedFilter == 'Stock Menipis' ? 'Semua' : 'Stock Menipis'),
                      ),
                      const SizedBox(width: 8),
                      _buildStockStatCard(
                        count: habisCount.toString(),
                        label: 'Stock Habis',
                        color: const Color(0xFFDC2626),
                        bg: const Color(0xFFFEF2F2),
                        border: const Color(0xFFFECACA),
                        isSelected: _selectedFilter == 'Stock Habis',
                        onTap: () => setState(() => _selectedFilter = _selectedFilter == 'Stock Habis' ? 'Semua' : 'Stock Habis'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Button Tambah Obat Baru (Figma Node 1100:23601)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _buttonDarkGreen,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _buttonDarkGreen.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _openTambahObat,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tambah Obat Baru',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Hanya untuk registrasi SKU/formula baru',
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Cari nama obat, kategori, no batch...',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Stock Aman'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Stock Menipis'),
                        const SizedBox(width: 6),
                        _buildFilterChip('Stock Habis'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Medicine List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.medication_outlined, size: 52, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 10),
                          Text(
                            'Tidak ada obat yang cocok.',
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final med = filtered[index];
                        return _buildMedicineCard(med);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockStatCard({
    required String count,
    required String label,
    required Color color,
    required Color bg,
    required Color border,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : border,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _darkGreen : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(ApotekMedicine med) {
    Color statusBg;
    Color statusColor;
    String statusText;

    switch (med.status) {
      case ApotekMedicineStatus.tersedia:
        statusBg = const Color(0xFFDCFCE7);
        statusColor = const Color(0xFF15803D);
        statusText = 'Tersedia';
        break;
      case ApotekMedicineStatus.stokMenipis:
        statusBg = const Color(0xFFFEF3C7);
        statusColor = const Color(0xFFB45309);
        statusText = 'Stok Menipis';
        break;
      case ApotekMedicineStatus.habis:
        statusBg = const Color(0xFFFEE2E2);
        statusColor = const Color(0xFFB91C1C);
        statusText = 'Habis';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                    const SizedBox(height: 2),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sisa Stok',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${med.stock} ${med.stockUnit}',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Harga Jual',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rp. ${med.sellPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')},00 / ${med.packageUnit.split('/').first.trim()}',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF065A37),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Exp: ${med.expDate}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: _darkGreen,
                ),
                onPressed: () => _openDetail(med),
                child: Row(
                  children: [
                    Text(
                      'Lihat Detail',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
