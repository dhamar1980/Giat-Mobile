import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FORM INPUT CATATAN KESEHATAN GINJAL BARU
// ─────────────────────────────────────────────────────────────────────────────

class CatatKesehatanScreen extends StatefulWidget {
  const CatatKesehatanScreen({super.key});

  @override
  State<CatatKesehatanScreen> createState() => _CatatKesehatanScreenState();
}

class _CatatKesehatanScreenState extends State<CatatKesehatanScreen> {
  final _sistolCtrl = TextEditingController(text: '120');
  final _diastolCtrl = TextEditingController(text: '80');
  final _kreatininCtrl = TextEditingController(text: '1.5');
  final _cairanCtrl = TextEditingController(text: '250');
  final _catatanCtrl = TextEditingController();

  static const _darkGreen = Color(0xFF065A37);
  static const _buttonGreen = Color(0xFF044E2F);

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Catatan kesehatan berhasil disimpan! ✅'),
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
          'Catat Indikator Ginjal',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tekanan Darah Section
            Text('Tekanan Darah (mmHg)', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(controller: _sistolCtrl, hint: '120', label: 'Sistol'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('/', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                Expanded(
                  child: _buildInputField(controller: _diastolCtrl, hint: '80', label: 'Diastol'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Kreatinin
            Text('Kadar Kreatinin Serum (mg/dL)', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            _buildInputField(controller: _kreatininCtrl, hint: 'Contoh: 1.5', label: 'mg/dL'),

            const SizedBox(height: 20),

            // Asupan Cairan
            Text('Asupan Cairan Saat Ini (ml)', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            _buildInputField(controller: _cairanCtrl, hint: 'Contoh: 250', label: 'ml air'),

            const SizedBox(height: 20),

            // Catatan Keluhan
            Text('Catatan Gejala / Keluhan', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: TextField(
                controller: _catatanCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tuliskan kondisi tubuh, makanan yang baru dikonsumsi, atau keluhan lain...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
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
                child: Text('Simpan Data Kesehatan', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hint,
          suffixText: label,
          suffixStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
