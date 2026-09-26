import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';
import '../notifikasi/apotek_notifikasi_screen.dart';
import 'apotek_detail_pesanan_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN PESANAN APOTEK (Revisi Sesuai 5 Screenshot Desain GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekPesananScreen extends StatefulWidget {
  final int initialTabIndex;
  final ValueChanged<int>? onNavigateToTab;
  final bool? isTopBarVisible;

  const ApotekPesananScreen({
    super.key,
    this.initialTabIndex = 0,
    this.onNavigateToTab,
    this.isTopBarVisible,
  });

  @override
  State<ApotekPesananScreen> createState() => _ApotekPesananScreenState();
}

class _ApotekPesananScreenState extends State<ApotekPesananScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _cardBorder = Color(0xFFE2E8F0);
  static const _innerBorder = Color(0xFFCBD5E1);

  late int _selectedTabIndex;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _internalIsTopBarVisible = true;

  bool get _effectiveTopBarVisible => widget.isTopBarVisible ?? _internalIsTopBarVisible;

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

    final q = _searchQuery.toLowerCase().trim();
    return byStatus.where((o) {
      final matchId = o.id.toLowerCase().contains(q);
      final matchPatient = o.patientName.toLowerCase().contains(q);
      final matchItems = o.items.any((it) => it.medicineName.toLowerCase().contains(q));
      return matchId || matchPatient || matchItems;
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
    ).then((_) => setState(() {}));
  }

  void _handleProcessOrder(ApotekOrder order) {
    setState(() {
      order.status = ApotekOrderStatus.diproses;
      _selectedTabIndex = 1; // Pindah ke tab Diproses
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pesanan ${order.id} berhasil dipindahkan ke status Diproses.'),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleCompleteOrder(ApotekOrder order) {
    setState(() {
      order.status = ApotekOrderStatus.selesai;
      _selectedTabIndex = 2; // Pindah ke tab Selesai
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pesanan ${order.id} telah diselesaikan.'),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final filteredOrders = _getFilteredOrders();

    String sectionTitle;
    if (_selectedTabIndex == 0) {
      sectionTitle = 'Pesanan Menunggu Diproses';
    } else if (_selectedTabIndex == 1) {
      sectionTitle = 'Pesanan Sedang Diproses';
    } else {
      sectionTitle = 'Pesanan Selesai';
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Top Curved Green Header with Chat Bubbles (Fixed at top, does not scroll) ──
          _buildHeaderSection(topPadding),

          // ── 2. Search & Tab Filter & Content (Scrollable) ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 16, bottom: 28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar with Dark Green Outline
                    _buildSearchBar(),

                    const SizedBox(height: 14),

                    // Three Filter Tabs: Menunggu, Diproses, Selesai
                    _buildFilterTabs(),

                    const SizedBox(height: 20),

                    // Section Title
                    Text(
                      sectionTitle,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Order Cards List
                    if (filteredOrders.isEmpty)
                      _buildEmptyState()
                    else
                      ...filteredOrders.map((order) => Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _buildOrderCard(order),
                          )),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER SECTION (Green Gradient + Topography + Action Pill + Chat Bubbles)
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
                painter: _PesananHeaderCurvePainter(),
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
                          'Kelola Pesanan Masuk ✨✨',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF065A37),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Yuk, cek dan proses pesanan masuk obat kamu sekarang di menu Pesanan.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF065A37).withValues(alpha: 0.9),
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
                color: Colors.black.withOpacity(0.08),
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
  // SEARCH BAR (Pill shape with green outline)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _darkGreen, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Cari nomor pesanan atau nama pasien...',
          hintStyle: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF334155), size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Color(0xFF64748B)),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SEGMENTED TABS (Menunggu, Diproses, Selesai)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFilterTabs() {
    return Row(
      children: [
        _buildPillTab(index: 0, title: 'Menunggu'),
        const SizedBox(width: 10),
        _buildPillTab(index: 1, title: 'Diproses'),
        const SizedBox(width: 10),
        _buildPillTab(index: 2, title: 'Selesai'),
      ],
    );
  }

  Widget _buildPillTab({required int index, required String title}) {
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _darkGreen : const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ORDER CARD (Matching user screenshots 1, 2, 3, 4, 5)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOrderCard(ApotekOrder ord) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + ORD ID & Name + "Lihat Detail Pesanan ->"
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Light blue-cyan container with pharmacy/medicine icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6EFF6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_pharmacy_rounded,
                    color: _darkGreen,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ID and Patient Name
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
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),

              // "Lihat Detail Pesanan ->"
              GestureDetector(
                onTap: () => _openDetail(ord),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Detail Pesanan',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _darkGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_circle_right_outlined,
                        size: 18,
                        color: _darkGreen,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Inner Bordered Box for Items & Total
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _innerBorder),
            ),
            child: Column(
              children: [
                // Item List
                ...ord.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.medicineName,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.formAndPack,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Green Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: _darkGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.qtyText,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (idx < ord.items.length - 1)
                        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                    ],
                  );
                }),

                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                // Total Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        '${ord.items.length} item obat',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
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

          // Bottom Action Button based on status
          if (ord.status == ApotekOrderStatus.menunggu) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonDarkGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _handleProcessOrder(ord),
                child: Text(
                  'Proses Pesanan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ] else if (ord.status == ApotekOrderStatus.diproses) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonDarkGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _handleCompleteOrder(ord),
                child: Text(
                  'Pesanan Selesai',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Text(
            'Tidak ada pesanan',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Belum ada pesanan pada status ini.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM CLIPPERS & PAINTERS FOR HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _PesananHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 35);
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

class _PesananHeaderCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
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
