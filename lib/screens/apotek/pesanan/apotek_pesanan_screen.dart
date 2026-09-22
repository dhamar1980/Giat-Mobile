import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';
import 'apotek_detail_pesanan_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PESANAN MASUK APOTEK (Figma Node: 1100-19155, 1598-6527, 1598-6776, 1100-19050)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekPesananScreen extends StatefulWidget {
  final int initialTabIndex;

  const ApotekPesananScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<ApotekPesananScreen> createState() => _ApotekPesananScreenState();
}

class _ApotekPesananScreenState extends State<ApotekPesananScreen> {
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

  List<ApotekOrder> _getFilteredOrders() {
    final all = ApotekMockData.orders;
    final byStatus = all.where((o) {
      if (_selectedTabIndex == 0) return o.status == ApotekOrderStatus.menunggu;
      if (_selectedTabIndex == 1) return o.status == ApotekOrderStatus.diproses;
      return o.status == ApotekOrderStatus.selesai;
    }).toList();

    if (_searchQuery.trim().isEmpty) return byStatus;

    return byStatus.where((o) {
      return o.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.recipeRef.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.doctorName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openDetail(ApotekOrder order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ApotekDetailPesananScreen(
          order: order,
          onStatusChanged: () => setState(() {}),
        ),
      ),
    );
  }

  /// Figma Node 1100:19050: Pop up Mulai Proses Pesanan
  void _showProcessConfirmationDialog(ApotekOrder order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Mulai proses pesanan?',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Pesanan ${order.id} akan dipindahkan ke daftar pesanan yang sedang diproses. Pastikan resep dan ketersediaan obat telah diperiksa.',
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
              setState(() {
                order.status = ApotekOrderStatus.diproses;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pesanan ${order.id} berhasil dipindahkan ke status Diproses.'),
                  backgroundColor: _darkGreen,
                  behavior: SnackBarBehavior.floating,
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

  void _advanceOrder(ApotekOrder order) {
    if (order.status == ApotekOrderStatus.menunggu) {
      _showProcessConfirmationDialog(order);
    } else if (order.status == ApotekOrderStatus.diproses) {
      setState(() {
        order.status = ApotekOrderStatus.selesai;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pesanan ${order.id} telah diselesaikan.'),
          backgroundColor: _darkGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredOrders();

    final menungguCount = ApotekMockData.orders.where((o) => o.status == ApotekOrderStatus.menunggu).length;
    final diprosesCount = ApotekMockData.orders.where((o) => o.status == ApotekOrderStatus.diproses).length;
    final selesaiCount = ApotekMockData.orders.where((o) => o.status == ApotekOrderStatus.selesai).length;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Pesanan Hari Ini',
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
            // Top chat bubble header (Figma Nodes 1100:19155, 1598:6527, 1598:6776)
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
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 18, color: _darkGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Selamat datang kembali! Yuk, cek dan proses pesanan masuk kamu sekarang di menu Pesanan. ✨✨',
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
                        hintText: 'Cari nomor pesanan atau nama pasien...',
                        hintStyle: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Segmented Tabs with Count Badges
                  Row(
                    children: [
                      _buildStatusTab(0, 'Menunggu', '$menungguCount'),
                      const SizedBox(width: 8),
                      _buildStatusTab(1, 'Diproses', '$diprosesCount'),
                      const SizedBox(width: 8),
                      _buildStatusTab(2, 'Selesai', '$selesaiCount'),
                    ],
                  ),
                ],
              ),
            ),

            // Order List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 10),
                          Text(
                            'Tidak ada pesanan pada status ini.',
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
                        final ord = filtered[index];
                        return _buildOrderCard(ord);
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
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? _darkGreen : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
        ),
      ),
    );
  }

  Widget _buildOrderCard(ApotekOrder ord) {
    final isFromRecipe = ord.recipeRef.isNotEmpty;

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
          // If from doctor recipe, show special banner badge
          if (isFromRecipe)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.note_alt_rounded, size: 13, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Resep Dokter (${ord.recipeRef}) • ${ord.doctorName}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1D4ED8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Order ID & Patient Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ord.id,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ord.patientName,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () => _openDetail(ord),
                child: Row(
                  children: [
                    Text('Lihat Detail', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _darkGreen)),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _darkGreen),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 18),

          // Items summary
          ...ord.items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        it.medicineName,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      it.qtyText,
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
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
                  'Total: ${ord.items.length} item obat',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              if (ord.status == ApotekOrderStatus.menunggu)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonDarkGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => _advanceOrder(ord),
                  child: Text('Proses Pesanan', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                )
              else if (ord.status == ApotekOrderStatus.diproses)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => _advanceOrder(ord),
                  child: Text('Pesanan Selesai', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Selesai',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
