import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../profile/profile_pasien_screen.dart';
import '../widgets/midtrans_payment_webview_page.dart';
import 'lacak_obat_screen.dart';
import 'pembayaran_model.dart';
import '../../../constants/api_constants.dart';
import '../../../services/pasien_api_service.dart';
import '../../../utils/time_utils.dart';

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
  final String? rawId;
  final String orderId;
  final String orderDate;
  final String orderTime;
  final String status;
  final String statusPembayaran;
  final String? snapToken;
  final String? redirectUrl;
  final Color statusColor;
  final bool isMelaluiResep;
  final String? resepNumber;
  final String? doctorName;
  final String pharmacyName;
  final List<RiwayatObatDetail> medicines;
  final int totalPrice;
  final String paymentMethod;

  const RiwayatPesananData({
    this.rawId,
    required this.orderId,
    required this.orderDate,
    required this.orderTime,
    required this.status,
    this.statusPembayaran = 'lunas',
    this.snapToken,
    this.redirectUrl,
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
  final bool autoFetch;

  const RiwayatObatScreen({
    super.key,
    this.userName = 'Pasien',
    this.autoFetch = true,
  });

  @override
  State<RiwayatObatScreen> createState() => _RiwayatObatScreenState();
}

class _RiwayatObatScreenState extends State<RiwayatObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);
  static const _amberStatus = Color(0xFFE5A100);

  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  bool _isLoading = true;

  List<RiwayatPesananData> _allOrders = [];

  @override
  void initState() {
    super.initState();
    _allOrders = [];
    if (widget.autoFetch) {
      _isLoading = true;
      _fetchRiwayatFromApi();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchRiwayatFromApi() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await PasienApiService().getRiwayatPembelian();
      if (res.success && res.data != null && mounted) {
        final List<RiwayatPesananData> list = [];
        for (var item in res.data!) {
          if (item is Map) {
            final rawId = (item['id'] ?? item['id_pembelian'])?.toString();
            final noPesanan = item['no_pesanan']?.toString() ??
                item['order_id']?.toString() ??
                (rawId != null ? 'ORD-$rawId' : '#G-000');
            final statusBayar =
                (item['status_pembayaran'] ?? 'lunas').toString().toLowerCase();
            final rawStatusPesanan =
                (item['status_pesanan'] ?? item['status'] ?? 'Sedang Diproses')
                    .toString();
            final isWaitingPayment = statusBayar == 'menunggu_pembayaran';
            final displayStatus = isWaitingPayment
                ? 'Menunggu Pembayaran'
                : _mapOrderStatusLabel(rawStatusPesanan);
            final total = double.tryParse(
                      (item['total_bayar'] ??
                              item['total_harga'] ??
                              item['total'] ??
                              '0')
                          .toString(),
                    )?.round() ??
                0;
            final dateStr = item['created_at'] != null
                ? TimeUtils.formatDate(item['created_at'])
                : (item['tanggal']?.toString() ?? 'Hari ini');
            final timeStr = item['created_at'] != null
                ? TimeUtils.formatTimeWithZone(item['created_at'])
                : TimeUtils.replaceTimezoneSuffix(
                    item['waktu']?.toString() ?? '14:00 WIB');

            // Parse daftar item obat jika tersedia dari backend
            final List<RiwayatObatDetail> parsedMeds = [];
            if (item['items'] is List && (item['items'] as List).isNotEmpty) {
              for (final med in (item['items'] as List)) {
                if (med is Map) {
                  final obatMap =
                      med['obat'] is Map ? med['obat'] as Map : null;
                  final mName = (med['nama_obat'] ??
                          med['nama'] ??
                          obatMap?['nama_obat'] ??
                          obatMap?['nama'] ??
                          'Obat Terapi Ginjal')
                      .toString();
                  final mQty = int.tryParse(
                          (med['jumlah'] ?? med['qty'] ?? 1).toString()) ??
                      1;
                  final mPrice = double.tryParse(
                            (med['harga_satuan'] ??
                                    med['harga'] ??
                                    obatMap?['harga'] ??
                                    50000)
                                .toString(),
                          )?.round() ??
                      50000;
                  parsedMeds.add(
                    RiwayatObatDetail(
                      name: mName,
                      dosage: (med['aturan_pakai'] ?? 'Sesuai petunjuk')
                          .toString(),
                      packageInfo:
                          (med['satuan'] ?? '$mQty unit').toString(),
                      qty: mQty,
                      price: mPrice,
                    ),
                  );
                }
              }
            }
            if (parsedMeds.isEmpty) {
              parsedMeds.add(
                RiwayatObatDetail(
                  name: 'Obat Terapi Ginjal',
                  dosage: 'Sesuai anjuran dokter/apoteker',
                  packageInfo: '1 Paket Terapi',
                  qty: 1,
                  price: total > 0 ? total : 50000,
                ),
              );
            }

            final apotekMap =
                item['apotek'] is Map ? item['apotek'] as Map : null;
            final pharmacyName = (item['nama_apotek'] ??
                    apotekMap?['nama_apotek'] ??
                    apotekMap?['nama'] ??
                    item['apotek_name'] ??
                    'Apotek Mitra GIAT')
                .toString();

            final docName = item['nama_dokter']?.toString() ??
                (item['dokter'] is Map
                    ? item['dokter']['nama']?.toString()
                    : null);

            list.add(RiwayatPesananData(
              rawId: rawId,
              orderId: noPesanan,
              orderDate: dateStr,
              orderTime: timeStr,
              status: displayStatus,
              statusPembayaran: statusBayar,
              snapToken: item['snap_token']?.toString(),
              redirectUrl: item['redirect_url']?.toString(),
              statusColor: isWaitingPayment
                  ? const Color(0xFFD97706)
                  : (displayStatus.toLowerCase().contains('selesai')
                      ? const Color(0xFF16A34A)
                      : _amberStatus),
              isMelaluiResep: item['is_resep'] == true ||
                  item['resep_id'] != null ||
                  item['id_resep'] != null,
              resepNumber: (item['resep_id'] ?? item['id_resep'])?.toString(),
              doctorName: docName,
              pharmacyName: pharmacyName,
              totalPrice: total,
              paymentMethod: (item['metode_pembayaran'] ?? 'Midtrans Snap')
                  .toString()
                  .replaceAll('_', ' ')
                  .toUpperCase(),
              medicines: parsedMeds,
            ));
          }
        }
        setState(() {
          _allOrders = list;
        });
      } else if (mounted) {
        setState(() {
          _allOrders = [];
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _allOrders = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapOrderStatusLabel(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower == 'menunggu_konfirmasi') return 'Sedang Diproses';
    if (lower == 'diproses') return 'Sedang Diproses';
    if (lower == 'dikirim') return 'Sedang Dikirim';
    if (lower == 'selesai') return 'Selesai Diterima';
    if (lower == 'dibatalkan') return 'Dibatalkan';
    return raw;
  }

  Future<void> _handlePayOrderMidtrans(RiwayatPesananData order) async {
    final idPesanan = order.rawId;
    String? redirectUrl = order.redirectUrl;
    String? snapToken = order.snapToken;

    if (ApiConstants.resolveMidtransRedirectUrl(
          redirectUrl: redirectUrl,
          snapToken: snapToken,
        ) ==
        null &&
        idPesanan != null &&
        idPesanan.isNotEmpty) {
      final snapRes = await PasienApiService()
          .getSnapTokenObat(idPesanan, forceNew: false);
      if (snapRes.success && snapRes.data != null) {
        redirectUrl =
            snapRes.data!['redirect_url']?.toString() ?? redirectUrl;
        snapToken = snapRes.data!['snap_token']?.toString() ?? snapToken;
      }
    }

    final resolvedUrl = ApiConstants.resolveMidtransRedirectUrl(
      redirectUrl: redirectUrl,
      snapToken: snapToken,
    );

    if (!mounted) return;
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat URL pembayaran Midtrans untuk pesanan ${order.orderId}.',
            style: GoogleFonts.inter(fontSize: 12.5),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    final webViewRes = await Navigator.push<MidtransPaymentResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MidtransPaymentWebViewPage(
          redirectUrl: resolvedUrl,
          snapToken: snapToken,
          title: 'Pembayaran Obat Apotek',
          subtitle: 'Pesanan Obat Apotek Mitra GIAT',
          amountFormatted: _formatRupiah(order.totalPrice),
          onCheckStatus: idPesanan != null && idPesanan.isNotEmpty
              ? () async {
                  final r = await PasienApiService()
                      .cekStatusPembayaranObat(idPesanan);
                  return r.data;
                }
              : null,
          onRefreshSnapUrl: idPesanan != null && idPesanan.isNotEmpty
              ? () async {
                  final r = await PasienApiService()
                      .getSnapTokenObat(idPesanan, forceNew: true);
                  if (r.success && r.data != null) {
                    return ApiConstants.resolveMidtransRedirectUrl(
                      redirectUrl: r.data!['redirect_url']?.toString(),
                      snapToken: r.data!['snap_token']?.toString(),
                    );
                  }
                  return null;
                }
              : null,
        ),
      ),
    );

    if (!mounted) return;

    bool isLunas = webViewRes?.isPaid == true;
    if (!isLunas && idPesanan != null && idPesanan.isNotEmpty) {
      final checkRes =
          await PasienApiService().cekStatusPembayaranObat(idPesanan);
      if (checkRes.success && checkRes.data != null) {
        isLunas = MidtransPaymentWebViewPage.isStatusLunas(checkRes.data);
      }
    }

    await _fetchRiwayatFromApi();
    if (!mounted) return;

    if (isLunas) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pembayaran Pesanan ${order.orderId} Berhasil (LUNAS)! Mengarahkan ke Detail & Lacak Pesanan...',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: _darkGreen,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LacakObatScreen(
            userName: widget.userName,
            orderId: order.orderId,
            pesananId: order.rawId,
            orderData: OrderCheckoutData(
              idPesanan: order.rawId,
              orderNumber: order.orderId,
              totalAmount: order.totalPrice,
              totalAmountFormatted: _formatRupiah(order.totalPrice),
              statusPembayaran: 'lunas',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _handleCheckOrderPaymentStatus(RiwayatPesananData order) async {
    final idPesanan = order.rawId;
    if (idPesanan == null || idPesanan.isEmpty) return;

    final checkRes =
        await PasienApiService().cekStatusPembayaranObat(idPesanan);
    if (!mounted) return;
    final isLunas = MidtransPaymentWebViewPage.isStatusLunas(checkRes.data);
    await _fetchRiwayatFromApi();
    if (!mounted) return;

    if (isLunas) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pembayaran Pesanan ${order.orderId} telah LUNAS! Membuka Lacak Pesanan...',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: _darkGreen,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LacakObatScreen(
            userName: widget.userName,
            orderId: order.orderId,
            pesananId: order.rawId,
            orderData: OrderCheckoutData(
              idPesanan: order.rawId,
              orderNumber: order.orderId,
              totalAmount: order.totalPrice,
              totalAmountFormatted: _formatRupiah(order.totalPrice),
              statusPembayaran: 'lunas',
            ),
          ),
        ),
      );
    } else {
      final statusStr =
          (checkRes.data?['status_pembayaran'] ?? 'menunggu_pembayaran')
              .toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status pembayaran pesanan ${order.orderId} masih ${statusStr.replaceAll('_', ' ')}. Klik "Bayar Sekarang" untuk membayar.',
            style: GoogleFonts.inter(fontSize: 12.5),
          ),
          backgroundColor: const Color(0xFFD97706),
        ),
      );
    }
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
      if (_selectedFilter == 'Diproses' &&
          (order.status == 'Selesai Diterima' ||
              order.status == 'Dibatalkan')) {
        return false;
      }
      if (_selectedFilter == 'Selesai' && order.status != 'Selesai Diterima') {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesId = order.orderId.toLowerCase().contains(query);
        final matchesMedicine =
            order.medicines.any((m) => m.name.toLowerCase().contains(query));
        final matchesDoctor =
            order.doctorName?.toLowerCase().contains(query) ?? false;
        final matchesPharmacy =
            order.pharmacyName.toLowerCase().contains(query);
        return matchesId || matchesMedicine || matchesDoctor || matchesPharmacy;
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
            child: RefreshIndicator(
              color: _darkGreen,
              onRefresh: _fetchRiwayatFromApi,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 8),
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
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: CircularProgressIndicator(color: _darkGreen),
                        ),
                      )
                    else if (orders.isEmpty)
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
                              order.isMelaluiResep
                                  ? 'Pesanan Resep Dokter'
                                  : 'Pembelian Obat',
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
                child: Text(
                  'Obat Bebas (Tanpa Resep Dokter)',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF166534),
                  ),
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

            // Total Belanja & Tombol Aksi Pembayaran / Lacak
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
                if (order.statusPembayaran.toLowerCase() !=
                    'menunggu_pembayaran')
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LacakObatScreen(
                            userName: widget.userName,
                            orderId: order.orderId,
                            status: order.status,
                            pesananId: order.rawId,
                            orderData: OrderCheckoutData(
                              idPesanan: order.rawId,
                              orderNumber: order.orderId,
                              totalAmount: order.totalPrice,
                              totalAmountFormatted:
                                  _formatRupiah(order.totalPrice),
                              statusPembayaran: order.statusPembayaran,
                              snapToken: order.snapToken,
                              redirectUrl: order.redirectUrl,
                            ),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _darkGreen,
                      side: const BorderSide(color: _darkGreen, width: 1.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.local_shipping_outlined, size: 16),
                    label: Text(
                      'Lacak Pesanan',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            if (order.statusPembayaran.toLowerCase() ==
                'menunggu_pembayaran') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleCheckOrderPaymentStatus(order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _darkGreen,
                          side: const BorderSide(color: _darkGreen, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.verified_outlined, size: 16),
                        label: Text(
                          'Cek Status',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () => _handlePayOrderMidtrans(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.payment_rounded, size: 16),
                        label: Text(
                          'Bayar Sekarang',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
