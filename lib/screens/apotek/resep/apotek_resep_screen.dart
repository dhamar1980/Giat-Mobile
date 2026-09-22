import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';
import 'apotek_detail_resep_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DAFTAR RESEP MASUK APOTEK (Figma Node: 1100-21623)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekResepScreen extends StatefulWidget {
  final int initialTabIndex;
  final Function(int targetTab)? onNavigateToOrderTab;

  const ApotekResepScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onNavigateToOrderTab,
  });

  @override
  State<ApotekResepScreen> createState() => _ApotekResepScreenState();
}

class _ApotekResepScreenState extends State<ApotekResepScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  late int _selectedTabIndex;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ApotekRecipe> _getFilteredRecipes() {
    final all = ApotekMockData.recipes;
    final byStatus = all.where((r) {
      if (_selectedTabIndex == 0) return true; // Semua
      if (_selectedTabIndex == 1) return r.status == ApotekRecipeStatus.belumDiverifikasi;
      if (_selectedTabIndex == 2) return r.status == ApotekRecipeStatus.diverifikasi;
      return r.status == ApotekRecipeStatus.selesai;
    }).toList();

    if (_searchQuery.trim().isEmpty) return byStatus;

    return byStatus.where((r) {
      return r.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.doctorName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openDetail(ApotekRecipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApotekDetailResepScreen(
          recipe: recipe,
          onStatusChanged: () => setState(() {}),
          onNavigateToOrderTab: widget.onNavigateToOrderTab,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  /// Figma Node 1100:23057: Pop Up Validasi Mulai Proses Resep
  void _showAcceptRecipeDialog(ApotekRecipe recipe) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Mulai Proses Resep?',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Pesanan ${recipe.id} akan dipindahkan ke daftar resep yang sedang diproses. Pastikan resep dan ketersediaan obat telah diperiksa.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _buttonDarkGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final newOrder = ApotekMockData.acceptRecipeAndCreateOrder(recipe);
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Resep ${recipe.id} diverifikasi! Masuk ke Pesanan MENUNGGU (${newOrder.id}).',
                  ),
                  backgroundColor: _darkGreen,
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Buka Pesanan',
                    textColor: const Color(0xFF86EFAC),
                    onPressed: () {
                      widget.onNavigateToOrderTab?.call(0);
                    },
                  ),
                ),
              );
            },
            child: Text(
              'Mulai Proses',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredRecipes();

    final allCount = ApotekMockData.recipes.length;
    final belumCount = ApotekMockData.recipes.where((r) => r.status == ApotekRecipeStatus.belumDiverifikasi).length;
    final verifCount = ApotekMockData.recipes.where((r) => r.status == ApotekRecipeStatus.diverifikasi).length;
    final selesaiCount = ApotekMockData.recipes.where((r) => r.status == ApotekRecipeStatus.selesai).length;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Daftar Resep Masuk',
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
            // Top chat bubble header (Figma Node 1100:21623)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.medical_services_rounded, size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Selamat datang kembali! Yuk, cek dan proses resep masuk kamu sekarang di menu Resep. ✨✨',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF1E40AF),
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
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
                        hintText: 'Cari nomor resep, pasien, atau dokter...',
                        hintStyle: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Segmented Tabs with Count Badges (Semua, Belum Diverifikasi, Diverifikasi, Selesai)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusTab(0, 'Semua', '$allCount'),
                        const SizedBox(width: 8),
                        _buildStatusTab(1, 'Belum Diverifikasi', '$belumCount'),
                        const SizedBox(width: 8),
                        _buildStatusTab(2, 'Diverifikasi', '$verifCount'),
                        const SizedBox(width: 8),
                        _buildStatusTab(3, 'Selesai', '$selesaiCount'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Recipe List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.note_alt_outlined, size: 48, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 10),
                          Text(
                            'Tidak ada resep pada kategori ini.',
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final recipe = filtered[index];
                        return _buildRecipeCard(recipe);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTab(int index, String title, String count) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? _darkGreen : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(ApotekRecipe r) {
    String badgeText;
    Color badgeBg;
    Color badgeColor;

    switch (r.status) {
      case ApotekRecipeStatus.belumDiverifikasi:
        badgeText = 'Belum Diverifikasi';
        badgeBg = const Color(0xFFFEF3C7);
        badgeColor = const Color(0xFFB45309);
        break;
      case ApotekRecipeStatus.diverifikasi:
        badgeText = 'Diverifikasi';
        badgeBg = const Color(0xFFDCFCE7);
        badgeColor = const Color(0xFF15803D);
        break;
      case ApotekRecipeStatus.selesai:
        badgeText = 'Selesai';
        badgeBg = const Color(0xFFF1F5F9);
        badgeColor = const Color(0xFF64748B);
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Recipe ID & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_rounded, color: Color(0xFF0369A1), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.id,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${r.patientName} • ${r.doctorName}',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Items summary
          ...r.items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        it.medicineName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      it.qtyText,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Total: ${r.items.length} item obat  •  ${r.timeText}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (r.status == ApotekRecipeStatus.belumDiverifikasi)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonDarkGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => _showAcceptRecipeDialog(r),
                  child: Text(
                    'Terima Resep',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                )
              else
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _darkGreen,
                    side: const BorderSide(color: _darkGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _openDetail(r),
                  child: Text(
                    'Lihat Detail',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
