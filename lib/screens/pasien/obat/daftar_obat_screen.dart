import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tambah_obat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DAFTAR OBAT & JADWAL PENGOBATAN PASIEN
// ─────────────────────────────────────────────────────────────────────────────

class DaftarObatScreen extends StatefulWidget {
  final bool isEmbedded;

  const DaftarObatScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<DaftarObatScreen> createState() => _DaftarObatScreenState();
}

class _DaftarObatScreenState extends State<DaftarObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonGreen = Color(0xFF044E2F);
  static const _bubbleGreen = Color(0xFF22C55E);

  int _selectedDayIndex = 2; // e.g. Rabu
  final List<String> _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  final List<String> _dates = ['14', '15', '16', '17', '18', '19', '20'];

  final List<Map<String, dynamic>> _medications = [
    {
      'id': '1',
      'name': 'Candesartan 8 mg',
      'category': 'Pelindung Ginjal & Tensi',
      'timeCategory': 'Pagi (08:00 WIB)',
      'timing': '08:00 WIB',
      'instruction': '1 Tablet • Sesudah Makan',
      'stock': 14,
      'isTaken': true,
    },
    {
      'id': '2',
      'name': 'Asam Folat 1 mg',
      'category': 'Suplemen Eritropoiesis',
      'timeCategory': 'Pagi (08:00 WIB)',
      'timing': '08:00 WIB',
      'instruction': '1 Tablet • Sesudah Makan',
      'stock': 20,
      'isTaken': true,
    },
    {
      'id': '3',
      'name': 'Kalsium Karbonat 500 mg',
      'category': 'Pengikat Fosfat Ginjal',
      'timeCategory': 'Siang (13:00 WIB)',
      'timing': '13:00 WIB',
      'instruction': '1 Tablet • Bersama Makanan',
      'stock': 5,
      'isTaken': false,
    },
    {
      'id': '4',
      'name': 'Atorvastatin 10 mg',
      'category': 'Kontrol Profil Lipid',
      'timeCategory': 'Malam (20:00 WIB)',
      'timing': '20:00 WIB',
      'instruction': '1 Tablet • Sebelum Tidur',
      'stock': 12,
      'isTaken': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkGreen, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Jadwal & Stok Obat',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.receipt_long_rounded, color: _darkGreen),
                  tooltip: 'Tebus Resep ke Apotek',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Membuka layanan tebus resep apotek GIAT...')),
                    );
                  },
                ),
              ],
            ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEmbedded) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  widget.isEmbedded ? (MediaQuery.of(context).padding.top + 72) : 20,
                  20,
                  4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jadwal & Stok Obat',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.receipt_long_rounded, color: _darkGreen, size: 22),
                        tooltip: 'Tebus Resep ke Apotek',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Membuka layanan tebus resep apotek GIAT...')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Calendar Day Strip
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final isSel = _selectedDayIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = i),
                    child: Container(
                      width: 44,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? _darkGreen : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSel ? _darkGreen : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _days[i],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSel ? Colors.white70 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dates[i],
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isSel ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // Sisa Stok Warning Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kalsium Karbonat sisa 5 tablet',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF991B1B)),
                          ),
                          Text(
                            'Segera tebus resep sebelum obat habis.',
                            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFFB91C1C)),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Membuka pesanan obat apotek...')),
                        );
                      },
                      child: Text('Tebus', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626))),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Medication List Grouped
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Jadwal Obat Hari Ini',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: _medications.map((med) => _buildMedCard(med)).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _buttonGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Tambah Obat', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TambahObatScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedCard(Map<String, dynamic> med) {
    final isTaken = med['isTaken'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isTaken ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication_rounded,
              color: isTaken ? _darkGreen : const Color(0xFF64748B),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med['name'],
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    decoration: isTaken ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  med['category'],
                  style: GoogleFonts.inter(fontSize: 11.5, color: _darkGreen, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      med['timing'],
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '•  ${med['instruction']}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sisa stok: ${med['stock']} tablet',
                  style: GoogleFonts.inter(fontSize: 11, color: med['stock'] <= 5 ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => med['isTaken'] = !isTaken);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(!isTaken ? '${med['name']} berhasil ditandai sudah diminum! ✅' : 'Status minum obat dibatalkan'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isTaken ? _bubbleGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isTaken ? _bubbleGreen : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isTaken ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
            ),
          ),
        ],
      ),
    );
  }
}
