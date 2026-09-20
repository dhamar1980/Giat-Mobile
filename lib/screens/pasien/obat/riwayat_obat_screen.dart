import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../profile/profile_pasien_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN RIWAYAT PEMBELIAN OBAT (Sesuai Desain Halaman Obat GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class RiwayatObatDetail {
  final String name;
  final String dosage;
  final String packageInfo;
  final int qty;
  final int price;

  const RiwayatObatDetail({
    required this.name,
    required this.dosage,
    required this.packageInfo,
    required this.qty,
    required this.price,
  });
}

class RiwayatPesananData {
  final String orderId;
  final String orderDate;
  final String orderTime;
  final String status;
  final Color statusColor;
  final bool isMelaluiResep;
  final String? resepNumber;
  final String? doctorName;
  final String pharmacyName;
  final List<RiwayatObatDetail> medicines;
  final int totalPrice;
  final String paymentMethod;

  const RiwayatPesananData({
    required this.orderId,
    required this.orderDate,
    required this.orderTime,
    required this.status,
    required this.statusColor,
    required this.isMelaluiResep,
    this.resepNumber,
    this.doctorName,
    required this.pharmacyName,
    required this.medicines,
    required this.totalPrice,
    required this.paymentMethod,
  });
}

class RiwayatObatScreen extends StatefulWidget {
  final String userName;

  const RiwayatObatScreen({
    super.key,
    this.userName = 'Pasien',
  });

  @override
  State<RiwayatObatScreen> createState() => _RiwayatObatScreenState();
}

class _RiwayatObatScreenState extends State<RiwayatObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDark = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);
  static const _amberStatus = Color(0xFFE5A100);

  String _selectedFilter = 'Semua';
  String _searchQuery = '';

  late final List<RiwayatPesananData> _allOrders;

  @override
  void initState() {
    super.initState();
    _allOrders = [
      // 1. Pesanan #G-9021 (Sedang Diproses - Melalui Resep)
      const RiwayatPesananData(
        orderId: '#G-9021',
        orderDate: '01 September 2026',
        orderTime: '14:30 WIB',
        status: 'Sedang Diproses',
        statusColor: _amberStatus,
        isMelaluiResep: true,
        resepNumber: 'No. RX-2026-0901-01',
        doctorName: 'dr. Siti Rahmawati, Sp.PD-KGH',
        pharmacyName: 'Apotek Kimia Farma - Veteran Surabaya',
        totalPrice: 145000,
        paymentMethod: 'QRIS GIAT Pay',
        medicines: [
          RiwayatObatDetail(
            name: 'Kalsium Karbonat 500mg',
            dosage: '3x sehari 1 tablet sesudah makan',
            packageInfo: '30 tablet',
            qty: 1,
            price: 45000,
          ),
          RiwayatObatDetail(
            name: 'Asam Folat 1mg',
            dosage: '1x sehari 1 tablet pagi',
            packageInfo: '30 tablet',
            qty: 1,
            price: 80000,
          ),
        ],
      ),

      // 2. Pesanan #G-8812 (Selesai - Melalui Resep)
      const RiwayatPesananData(
        orderId: '#G-8812',
        orderDate: '18 Agustus 2026',
        orderTime: '10:15 WIB',
        status: 'Selesai Diterima',
        statusColor: _darkGreen,
        isMelaluiResep: true,
        resepNumber: 'No. RX-2026-0818-05',
        doctorName: 'dr. Ahmad Hidayat, Sp.PD',
        pharmacyName: 'Apotek Kimia Farma - Veteran Surabaya',
        totalPrice: 790000,
        paymentMethod: 'BCA Virtual Account',
        medicines: [
          RiwayatObatDetail(
            name: 'Ketosteril Tablet',
            dosage: '3x sehari 4 tablet sesudah makan',
            packageInfo: '100 tablet',
            qty: 1,
            price: 650000,
          ),
          RiwayatObatDetail(
            name: 'Candesartan 8mg',
            dosage: '1x sehari 1 tablet pagi',
            packageInfo: '30 tablet',
            qty: 1,
            price: 120000,
          ),
        ],
      ),

      // 3. Pesanan #G-8450 (Selesai - Tanpa Resep / Obat Bebas)
      const RiwayatPesananData(
        orderId: '#G-8450',
        orderDate: '02 Agustus 2026',
        orderTime: '16:45 WIB',
        status: 'Selesai Diterima',
        statusColor: _darkGreen,
        isMelaluiResep: false,
        pharmacyName: 'Apotek K-24 Dharmahusada Surabaya',
        totalPrice: 27500,
        paymentMethod: 'QRIS',
        medicines: [
          RiwayatObatDetail(
            name: 'Antasida Doen',
            dosage: '1 - 2 tablet dikunyah saat perih',
            packageInfo: 'Strip 10 Tablet kunyah',
            qty: 2,
            price: 13000,
          ),
          RiwayatObatDetail(
            name: 'Paracetamol 500 mg',
            dosage: '1 tablet bila demam / nyeri',
            packageInfo: 'Strip 10 Tablet',
            qty: 1,
            price: 8000,
          ),
        ],
      ),

      // 4. Pesanan #G-7930 (Selesai - Melalui Resep)
      const RiwayatPesananData(
        orderId: '#G-7930',
        orderDate: '15 Juli 2026',
        orderTime: '11:20 WIB',
        status: 'Selesai Diterima',
        statusColor: _darkGreen,
        isMelaluiResep: true,
        resepNumber: 'No. RX-2026-0715-02',
        doctorName: 'dr. Siti Rahmawati, Sp.PD-KGH',
        pharmacyName: 'Apotek Kimia Farma - Veteran Surabaya',
        totalPrice: 85000,
        paymentMethod: 'Mandiri Virtual Account',
        medicines: [
          RiwayatObatDetail(
            name: 'Amlodipine 5mg',
            dosage: '1x sehari 1 tablet malam',
            packageInfo: '30 tablet',
            qty: 1,
            price: 35000,
          ),
          RiwayatObatDetail(
            name: 'Asam Folat 1mg',
            dosage: '1x sehari 1 tablet pagi',
            packageInfo: '30 tablet',
            qty: 1,
            price: 30000,
          ),
        ],
      ),
    ];
  }

  List<RiwayatPesananData> get _filteredOrders {
    return _allOrders.where((order) {
      // Filter tab
      if (_selectedFilter == 'Dengan Resep' && !order.isMelaluiResep) {
        return false;
      }
      if (_selectedFilter == 'Obat Bebas' && order.isMelaluiResep) {
        return false;
      }
      if (_selectedFilter == 'Diproses' && order.status != 'Sedang Diproses') {
        return false;
      }
      if (_selectedFilter == 'Selesai' && order.status != 'Selesai Diterima') {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesId = order.orderId.toLowerCase().contains(query);
        final matchesMedicine = order.medicines.any((m) => m.name.toLowerCase().contains(query));
        final matchesDoctor = order.doctorName?.toLowerCase().contains(query) ?? false;
        return matchesId || matchesMedicine || matchesDoctor;
      }

      return true;
    }).toList();
  }

  String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      count++;
      buffer.write(str[i]);
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return 'Rp. ${buffer.toString().split('').reversed.join('')},00';
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topography
          Positioned.fill(
            child: CustomPaint(
              painter: _RiwayatObatTopographyPainter(),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Top Navigation Bar (<- Kembali & Action Pill) ──
                  _buildTopBar(context),

                  const SizedBox(height: 16),

                  // ── 2. Screen Title Pill: Riwayat Pembelian Obat ──
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
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
                        'Riwayat Pembelian Obat',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── 3. Search Bar ──
                  _buildSearchBar(),

                  const SizedBox(height: 14),

                  // ── 4. Filter Chips Row ──
                  _buildFilterChips(),

                  const SizedBox(height: 18),

                  // ── 5. History Cards List ──
                  if (orders.isEmpty)
                    _buildEmptyState()
                  else
                    ...orders.map((order) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildRiwayatCard(order),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. TOP BAR NAVIGATION
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

        // Action Pill (Bell & Profile Avatar)
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
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 22,
                  color: Color(0xFF1F2937),
                ),
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. SEARCH BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Cari riwayat obat, no. pesanan, atau dokter...',
          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, color: _darkGreen, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. FILTER CHIPS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    final filters = ['Semua', 'Dengan Resep', 'Obat Bebas', 'Diproses', 'Selesai'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = f),
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              backgroundColor: Colors.white,
              selectedColor: _darkGreen,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected ? _darkGreen : _cardBorderColor,
                width: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. KARTU RIWAYAT PEMBELIAN (CARD)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRiwayatCard(RiwayatPesananData order) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Header: ID & Tanggal + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF8F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: _darkGreen, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderId,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${order.orderDate} • ${order.orderTime}',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: order.statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status,
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

            // ── Keterangan Resep Dokter ──
            if (order.isMelaluiResep)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Melalui Resep Dokter',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E40AF),
                                ),
                              ),
                              if (order.resepNumber != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '(${order.resepNumber})',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (order.doctorName != null)
                            Text(
                              'Dokter: ${order.doctorName}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF475569),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 16, color: _darkGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Obat Bebas (Tanpa Resep Dokter)',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Daftar Obat
            ...order.medicines.map((med) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _darkGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: '${med.name} ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            children: [
                              TextSpan(
                                text: '(${med.packageInfo}) x${med.qty}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        _formatRupiah(med.price * med.qty),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 8),

            // Apotek Info
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.pharmacyName,
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),

            // Total Belanja
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Belanja (${order.paymentMethod})',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatRupiah(order.totalPrice),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. EMPTY STATE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF8F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 36, color: _darkGreen),
            ),
            const SizedBox(height: 14),
            Text(
              'Tidak Ada Riwayat Pembelian',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ditemukan pembelian obat dengan kriteria pencarian ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: BACKGROUND CONTOUR LINES FOR RIWAYAT OBAT
// ─────────────────────────────────────────────────────────────────────────────

class _RiwayatObatTopographyPainter extends CustomPainter {
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
