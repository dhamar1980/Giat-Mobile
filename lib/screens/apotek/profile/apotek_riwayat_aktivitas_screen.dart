import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RIWAYAT AKTIVITAS & AUDIT APOTEK (Figma Nodes: 1100-24543, 24691, 24887, 25028)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekRiwayatAktivitasScreen extends StatefulWidget {
  const ApotekRiwayatAktivitasScreen({super.key});

  @override
  State<ApotekRiwayatAktivitasScreen> createState() => _ApotekRiwayatAktivitasScreenState();
}

class _ApotekRiwayatAktivitasScreenState extends State<ApotekRiwayatAktivitasScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  int _selectedFilter = 0; // 0: Semua, 1: Hari ini, 2: Minggu ini, 3: Kemarin & Sebelumnya

  void _showActivityDetail(ApotekActivity act) {
    if (act.type == 'stok') {
      _showStockChangeDetailModal(act);
    } else if (act.type == 'pesanan') {
      _showOrderDetailModal(act);
    } else {
      _showAddMedicineDetailModal(act);
    }
  }

  // ── Detail Perubahan Stok Modal (Figma Node 1100:24691) ──
  void _showStockChangeDetailModal(ApotekActivity act) {
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
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Memperbarui Stok Obat',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                    child: Text('Audit Valid', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _darkGreen)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '01 September 2026, 14:10 WIB',
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
              ),
              const Divider(height: 24),

              // Detail Obat
              Text('Detail Obat', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF8FAF9), borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paracetamol 500 mg', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Tablet Salut Selaput • Analgesik & Antipiretik', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Text('No. Batch: BATCH-2026-X89', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _darkGreen)),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Perubahan Stok Card
              Text('Perubahan Stok', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF8FAF9), borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: Column(
                  children: [
                    _buildRow('Penyesuaian', '+ 20 Tablet'),
                    const Divider(height: 14),
                    _buildRow('Stok Sebelum', '100 Tablet'),
                    const Divider(height: 14),
                    _buildRow('Stok Akhir', '120 Tablet'),
                    const Divider(height: 14),
                    _buildRow('Kapasitas vs Terkini', '120 / 150 Maks (80% Terisi)'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Petugas
              Text('Informasi Audit & Petugas', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF8FAF9), borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: Column(
                  children: [
                    _buildRow('Penanggung Jawab', 'Apt. Syita Nabila, S.Farm'),
                    const Divider(height: 14),
                    _buildRow('SIPA', '19940212/SIPA_35.73/2022/2041'),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Tutup Detail', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Detail Memproses Pesanan Modal (Figma Node 1100:24887) ──
  void _showOrderDetailModal(ApotekActivity act) {
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
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Detail Memproses Pesanan',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text('TRX-2026-00981 • INV/20260901/MP/0981', style: GoogleFonts.inter(fontSize: 12.5, color: _darkGreen, fontWeight: FontWeight.w600)),
              const Divider(height: 24),

              // Pasien Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF8FAF9), borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Andi Pratama (PXL-MLG-90214)', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Jl. Ijen No. 45, Klojen, Kota Malang', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Rincian Produk
              Text('Rincian Obat & Produk', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF8FAF9), borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: Column(
                  children: [
                    _buildRow('Paracetamol 500 mg (2 strip)', 'Rp 20.000,00'),
                    const Divider(height: 14),
                    _buildRow('Amoxicillin 500 mg (1 strip)', 'Rp 18.000,00'),
                    const Divider(height: 14),
                    _buildRow('Vitamin C 500 mg IPI (1 botol)', 'Rp 12.000,00'),
                    const Divider(height: 14),
                    _buildRow('Biaya Layanan & Kemas', 'Rp 5.000,00'),
                    const Divider(height: 14),
                    _buildRow('Ongkos Kirim (Same Day)', 'Rp 10.000,00'),
                    const Divider(height: 16),
                    _buildRow('Total Transaksi', 'Rp 65.000,00', isBold: true),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mencetak struk transaksi...')));
                      },
                      child: Text('Cetak Struk', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonDarkGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membuka pelacakan kurir GIAT...')));
                      },
                      child: Text('Lacak Kurir', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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

  // ── Detail Menambahkan Obat Baru Modal (Figma Node 1100:25028) ──
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
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rincian Registrasi Obat Baru',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              Text('GIAT-SKU-9921 • BPOM Valid (GKL1805051217A1)', style: GoogleFonts.inter(fontSize: 12.5, color: _darkGreen, fontWeight: FontWeight.w600)),
              const Divider(height: 24),

              Text('Cetirizine 10 mg', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Tablet Salut Selaput • Antihistamin & Antialergi • Kimia Farma', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF8FAF9), borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                child: Column(
                  children: [
                    _buildRow('Stok Awal', '50 Tablet (5 strip @ 10 tablet)'),
                    const Divider(height: 14),
                    _buildRow('Harga Beli (HPP)', 'Rp 4.500 / strip'),
                    const Divider(height: 14),
                    _buildRow('Harga Jual Apotek', 'Rp 7.500 / strip'),
                    const Divider(height: 14),
                    _buildRow('Estimasi Margin', '+66.7% (Rp 3.000 / strip)', isBold: true),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Tutup', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
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
    final acts = ApotekMockData.activities;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Riwayat Aktivitas',
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
            // Tabs (Semua, Hari ini, Minggu ini, Kemarin & Sebelumnya)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTab(0, 'Semua'),
                    const SizedBox(width: 8),
                    _buildTab(1, 'Hari ini'),
                    const SizedBox(width: 8),
                    _buildTab(2, 'Minggu ini'),
                    const SizedBox(width: 8),
                    _buildTab(3, 'Kemarin & Sebelumnya'),
                  ],
                ),
              ),
            ),

            // Activity List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
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
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                            child: Icon(icon, color: iconColor, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _darkGreen),
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
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _darkGreen : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
