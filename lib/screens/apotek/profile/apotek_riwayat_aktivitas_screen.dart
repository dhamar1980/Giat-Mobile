import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/apotek_api_service.dart';
import '../../../widgets/giat_background.dart';
import '../models/apotek_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RIWAYAT AKTIVITAS & AUDIT APOTEK (Tanpa Header Hijau & Tanpa Bubble Chat)
// Seragam dengan UI Pasien / Dokter
// ─────────────────────────────────────────────────────────────────────────────

class ApotekRiwayatAktivitasScreen extends StatefulWidget {
  const ApotekRiwayatAktivitasScreen({super.key});

  @override
  State<ApotekRiwayatAktivitasScreen> createState() =>
      _ApotekRiwayatAktivitasScreenState();
}

class _ApotekRiwayatAktivitasScreenState
    extends State<ApotekRiwayatAktivitasScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF7FAF8);
  static const _border = Color(0xFFE2E8F0);

  bool _isLoading = false;
  List<ApotekActivity> _realActivities = [];

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    if (_isTest) return;
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await ApotekApiService().getRiwayatAktivitas();
      if (res.success && res.data != null && mounted) {
        final parsed = res.data!
            .whereType<Map>()
            .map((e) => ApotekActivity.fromSupabaseMap(Map<String, dynamic>.from(e)))
            .toList();
        setState(() => _realActivities = parsed);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ApotekActivity> _getFilteredActivities() {
    return _isTest ? ApotekMockData.activities : _realActivities;
  }

  void _showActivityDetail(ApotekActivity act) {
    if (act.type == 'stok') {
      _showStockChangeDetailModal(act);
    } else if (act.type == 'pesanan') {
      _showOrderDetailModal(act);
    } else {
      _showAddMedicineDetailModal(act);
    }
  }

  // ── Detail Perubahan Stok Modal ──
  void _showStockChangeDetailModal(ApotekActivity act) {
    final meta = act.meta ?? <String, dynamic>{};
    final medName = (meta['nama_obat'] ?? 'Paracetamol 500 mg').toString();
    final kategori = (meta['kategori'] ?? 'Tablet Salut Selaput • Analgesik & Antipiretik').toString();
    final batchNo = (meta['no_batch'] ?? 'BATCH-2026-X89').toString();
    final satuan = (meta['satuan'] ?? 'Tablet').toString();
    final stokBatch = int.tryParse((meta['stok_batch'] ?? '20').toString()) ?? 20;
    final stokTotal = int.tryParse((meta['stok_total'] ?? '120').toString()) ?? 120;
    final stokBefore = (stokTotal - stokBatch) >= 0 ? (stokTotal - stokBatch) : 100;
    final apoteker = (meta['apoteker'] ?? 'Apt. Syita Nabila, S.Farm').toString();
    final sipa = (meta['sipa'] ?? '19940212/SIPA_35.73/2022/2041').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Memperbarui Stok Obat',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Audit Valid',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                act.timeText,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Divider(height: 24),

              Text(
                'Detail Obat',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kategori,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No. Batch: $batchNo',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _darkGreen,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Perubahan Stok',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    _buildRow('Penyesuaian', '+ $stokBatch $satuan'),
                    const Divider(height: 14),
                    _buildRow('Stok Sebelum', '$stokBefore $satuan'),
                    const Divider(height: 14),
                    _buildRow('Stok Akhir', '$stokTotal $satuan'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Informasi Audit & Petugas',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    _buildRow('Penanggung Jawab', apoteker),
                    const Divider(height: 14),
                    _buildRow('SIPA', sipa),
                    const Divider(height: 14),
                    _buildRow('Metode', 'Penyesuaian Manual / Masuk'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonDarkGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Tutup Detail',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatRp(int amount) {
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatted,00';
  }

  // ── Detail Memproses Pesanan Modal ──
  void _showOrderDetailModal(ApotekActivity act) {
    final meta = act.meta ?? <String, dynamic>{};
    final noPesanan = (meta['no_pesanan'] ?? 'TRX-2026-00981').toString();
    final namaPasien = (meta['nama_pasien'] ?? 'Andi Pratama').toString();
    final alamatPasien = (meta['alamat_pasien'] ?? 'Jl. Ijen No. 45, Klojen, Kota Malang').toString();
    final totalBayar = int.tryParse((meta['total_bayar'] ?? '65000').toString()) ?? 65000;
    final ongkir = int.tryParse((meta['ongkos_kirim'] ?? '10000').toString()) ?? 10000;
    final rawItems = (meta['items'] as List?) ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                act.title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$noPesanan • ${act.timeText}',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: _darkGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Divider(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaPasien,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alamatPasien,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Rincian Obat & Produk',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    if (rawItems.isNotEmpty) ...[
                      for (int i = 0; i < rawItems.length; i++) ...[
                        if (i > 0) const Divider(height: 14),
                        Builder(
                          builder: (_) {
                            final it = rawItems[i] is Map
                                ? Map<String, dynamic>.from(rawItems[i] as Map)
                                : <String, dynamic>{};
                            final mName = (it['nama_obat'] ?? 'Obat').toString();
                            final mQty = int.tryParse((it['jumlah'] ?? '1').toString()) ?? 1;
                            final mSub = double.tryParse((it['subtotal'] ?? '0').toString())?.round() ?? 0;
                            return _buildRow('$mName ($mQty unit)', _formatRp(mSub));
                          },
                        ),
                      ],
                    ] else ...[
                      _buildRow('Paracetamol 500 mg (2 strip)', 'Rp 20.000,00'),
                      const Divider(height: 14),
                      _buildRow('Amoxicillin 500 mg (1 strip)', 'Rp 18.000,00'),
                    ],
                    const Divider(height: 14),
                    _buildRow('Ongkos Kirim & Layanan', _formatRp(ongkir)),
                    const Divider(height: 16),
                    _buildRow('Total Transaksi', _formatRp(totalBayar), isBold: true),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _darkGreen,
                        side: const BorderSide(color: _darkGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mencetak struk transaksi...'),
                          ),
                        );
                      },
                      child: Text(
                        'Cetak Struk',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonDarkGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Membuka pelacakan kurir GIAT...'),
                          ),
                        );
                      },
                      child: Text(
                        'Lacak Kurir',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Detail Menambahkan Obat Baru Modal ──
  void _showAddMedicineDetailModal(ApotekActivity act) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rincian Registrasi Obat Baru',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'GIAT-SKU-9921 • BPOM Valid (GKL1805051217A1)',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: _darkGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Divider(height: 24),

              Text(
                'Cetirizine 10 mg',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tablet Salut Selaput • Antihistamin & Antialergi • Kimia Farma',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    _buildRow('Stok Awal', '50 Tablet (5 strip @ 10 tablet)'),
                    const Divider(height: 14),
                    _buildRow('Harga Beli (HPP)', 'Rp 4.500 / strip'),
                    const Divider(height: 14),
                    _buildRow('Harga Jual Apotek', 'Rp 7.500 / strip'),
                    const Divider(height: 14),
                    _buildRow(
                      'Estimasi Margin',
                      '+66.7% (Rp 3.000 / strip)',
                      isBold: true,
                    ),
                    const Divider(height: 14),
                    _buildRow('Kedaluwarsa Batch 1', '20 Agustus 2028'),
                    const Divider(height: 14),
                    _buildRow('Pendaftar', 'Apt. Sarah Kusuma, S.Farm'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonDarkGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isBold ? _darkGreen : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final acts = _getFilteredActivities();

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RiwayatAktivitasTopographyPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar (<- Kembali + Center Pill Title)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back,
                                size: 15,
                                color: Color(0xFF0F172A),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Kembali',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8.5,
                          ),
                          decoration: BoxDecoration(
                            color: _buttonDarkGreen,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _buttonDarkGreen.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'Riwayat Aktivitas',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Activity List
                Expanded(
                  child: _isLoading && acts.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: _darkGreen),
                        )
                      : acts.isEmpty
                          ? Center(
                              child: Text(
                                'Belum ada riwayat aktivitas tercatat.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            )
                          : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: acts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final act = acts[index];

                      IconData icon;
                      Color iconColor;
                      Color iconBg;

                      if (act.type == 'stok') {
                        icon = Icons.inventory_2_rounded;
                        iconColor = const Color(0xFFD97706);
                        iconBg = const Color(0xFFFEF3C7);
                      } else if (act.type == 'pesanan') {
                        icon = Icons.local_shipping_rounded;
                        iconColor = const Color(0xFF2563EB);
                        iconBg = const Color(0xFFEFF6FF);
                      } else {
                        icon = Icons.medication_rounded;
                        iconColor = const Color(0xFF16A34A);
                        iconBg = const Color(0xFFDCFCE7);
                      }

                      return GestureDetector(
                        onTap: () => _showActivityDetail(act),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.025),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            act.title,
                                            style: GoogleFonts.inter(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          act.timeText,
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            color: const Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      act.subtitle,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: const Color(0xFF475569),
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          'Lihat Aktivitas',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _darkGreen,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 10,
                                          color: _darkGreen,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiwayatAktivitasTopographyPainter extends CustomPainter {
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
