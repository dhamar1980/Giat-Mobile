import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FORM TAMBAH RESEP / OBAT GINJAL BARU
// ─────────────────────────────────────────────────────────────────────────────

class TambahObatScreen extends StatefulWidget {
  const TambahObatScreen({super.key});

  @override
  State<TambahObatScreen> createState() => _TambahObatScreenState();
}

class _TambahObatScreenState extends State<TambahObatScreen> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '30');

  String _frequency = '1x Sehari';
  String _mealRule = 'Sesudah Makan';
  String _time = '08:00 WIB';

  static const _darkGreen = Color(0xFF065A37);
  static const _buttonGreen = Color(0xFF044E2F);

  void _handleSave() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama obat tidak boleh kosong!')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Obat "${_nameCtrl.text.trim()}" berhasil ditambahkan ke jadwal! ✅'),
        backgroundColor: _darkGreen,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Obat Baru',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama Obat
            Text('Nama Obat', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            _buildInput(controller: _nameCtrl, hint: 'Contoh: Candesartan, Kalsium Karbonat...'),

            const SizedBox(height: 18),

            // Dosis & Satuan
            Text('Dosis / Kekuatan', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            _buildInput(controller: _dosageCtrl, hint: 'Contoh: 8 mg, 500 mg, 1 tablet...'),

            const SizedBox(height: 18),

            // Frekuensi
            Text('Frekuensi Minum', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['1x Sehari', '2x Sehari', '3x Sehari', 'Bila Perlu'].map((f) {
                final isSel = _frequency == f;
                return ChoiceChip(
                  label: Text(f),
                  selected: isSel,
                  selectedColor: _darkGreen,
                  labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: isSel ? Colors.white : const Color(0xFF334155)),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: isSel ? _darkGreen : const Color(0xFFCBD5E1)),
                  onSelected: (_) => setState(() => _frequency = f),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Aturan Makan
            Text('Aturan Konsumsi', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Sebelum Makan', 'Sesudah Makan', 'Bersama Makanan', 'Sebelum Tidur'].map((r) {
                final isSel = _mealRule == r;
                return ChoiceChip(
                  label: Text(r),
                  selected: isSel,
                  selectedColor: _darkGreen,
                  labelStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: isSel ? Colors.white : const Color(0xFF334155)),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: isSel ? _darkGreen : const Color(0xFFCBD5E1)),
                  onSelected: (_) => setState(() => _mealRule = r),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Stok Obat
            Text('Jumlah Stok Obat (Tablet/Kapsul)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            _buildInput(controller: _stockCtrl, hint: '30', isNumber: true),

            const SizedBox(height: 32),

            // Save
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _handleSave,
                child: Text('Simpan Jadwal Obat', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
