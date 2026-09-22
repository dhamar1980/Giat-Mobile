import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TAMBAH OBAT BARU APOTEK (Figma Node: 1100-24075)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekTambahObatScreen extends StatefulWidget {
  final VoidCallback? onMedicineAdded;

  const ApotekTambahObatScreen({
    super.key,
    this.onMedicineAdded,
  });

  @override
  State<ApotekTambahObatScreen> createState() => _ApotekTambahObatScreenState();
}

class _ApotekTambahObatScreenState extends State<ApotekTambahObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController(text: 'Analgesik & Antipiretik');
  final TextEditingController _doseCtrl = TextEditingController(text: '400 mg');
  final TextEditingController _packageCtrl = TextEditingController(text: 'Strip / Box');
  final TextEditingController _stockCtrl = TextEditingController(text: '50');
  final TextEditingController _buyPriceCtrl = TextEditingController(text: '12000');
  final TextEditingController _sellPriceCtrl = TextEditingController(text: '16500');
  final TextEditingController _batchCtrl = TextEditingController(text: 'BATCH-2026-N01');
  final TextEditingController _expCtrl = TextEditingController(text: '12 Des 2028');
  final TextEditingController _notesCtrl = TextEditingController(
    text: 'Diminum sesudah makan, maksimal 3 kali sehari. Hindari bagi pasien gangguan ginjal stadium lanjut.',
  );

  String _selectedForm = 'Tablet';
  String _selectedUnit = 'Tablet';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _doseCtrl.dispose();
    _packageCtrl.dispose();
    _stockCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _batchCtrl.dispose();
    _expCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _nameCtrl.clear();
      _categoryCtrl.text = 'Analgesik & Antipiretik';
      _doseCtrl.text = '500 mg';
      _packageCtrl.text = 'Strip / Box';
      _stockCtrl.text = '50';
      _buyPriceCtrl.text = '10000';
      _sellPriceCtrl.text = '15000';
      _batchCtrl.text = 'BATCH-2026-N01';
      _expCtrl.text = '12 Des 2028';
      _notesCtrl.clear();
    });
  }

  void _saveNewMedicine() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final category = _categoryCtrl.text.trim();
    final dose = _doseCtrl.text.trim();
    final package = _packageCtrl.text.trim();
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 50;
    final buy = int.tryParse(_buyPriceCtrl.text.trim()) ?? 10000;
    final sell = int.tryParse(_sellPriceCtrl.text.trim()) ?? 15000;
    final batch = _batchCtrl.text.trim().isEmpty ? 'BATCH-2026-A1' : _batchCtrl.text.trim();
    final exp = _expCtrl.text.trim().isEmpty ? '12 Des 2028' : _expCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    final newId = '#MED-${8845 + ApotekMockData.medicines.length}';

    final med = ApotekMedicine(
      id: newId,
      name: name,
      category: category,
      form: _selectedForm,
      dose: dose,
      packageUnit: package,
      stock: stock,
      stockUnit: _selectedUnit,
      buyPrice: buy,
      sellPrice: sell,
      expDate: exp,
      usageRule: notes.isNotEmpty ? notes : null,
      batches: [
        ApotekMedicineBatch(
          batchNo: batch,
          qtyText: '$stock $_selectedUnit',
          expDate: exp,
          status: 'Tersedia',
        ),
      ],
    );

    ApotekMockData.addMedicine(med);
    widget.onMedicineAdded?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Obat $name ($newId) berhasil didaftarkan ke katalog apotek.'),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
          'Tambah Obat Baru',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Live Preview Card (Figma Node 1100:24075) ──
                Text(
                  'Pratinjau Obat',
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Container(
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.medication_rounded, color: _darkGreen, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameCtrl.text.isEmpty ? 'Nama Belum Diisi' : _nameCtrl.text,
                              style: GoogleFonts.inter(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: _nameCtrl.text.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_categoryCtrl.text} • $_selectedForm',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Harga: Rp. ${_sellPriceCtrl.text.isEmpty ? "0" : _sellPriceCtrl.text} / ${_packageCtrl.text}',
                              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: _darkGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Section 1: Identitas & Sediaan ──
                Text(
                  'Identitas & Sediaan',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        label: 'Nama Obat*',
                        controller: _nameCtrl,
                        hint: 'e.g. Ibuprofen 400 mg',
                        validator: (v) => (v == null || v.isEmpty) ? 'Nama obat wajib diisi' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Kategori*',
                        controller: _categoryCtrl,
                        hint: 'e.g. Analgesik & Antipiretik',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bentuk Sediaan*', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _selectedForm,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAF9),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  items: ['Tablet', 'Kapsul', 'Sirup', 'Injeksi', 'Kaplet']
                                      .map((f) => DropdownMenuItem(value: f, child: Text(f, style: GoogleFonts.inter(fontSize: 13))))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedForm = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              label: 'Dosis / Kekuatan*',
                              controller: _doseCtrl,
                              hint: 'e.g. 400 mg',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Satuan Kemasan*',
                        controller: _packageCtrl,
                        hint: 'e.g. Strip / Box',
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Section 2: Stok & Finansial ──
                Text(
                  'Stok & Finansial',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              label: 'Stok Awal*',
                              controller: _stockCtrl,
                              keyboardType: TextInputType.number,
                              hint: '50',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Satuan Stok*', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _selectedUnit,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAF9),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  items: ['Tablet', 'Strip', 'Box', 'Botol', 'Kapsul']
                                      .map((u) => DropdownMenuItem(value: u, child: Text(u, style: GoogleFonts.inter(fontSize: 13))))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedUnit = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Harga Beli (Rp)*',
                              controller: _buyPriceCtrl,
                              keyboardType: TextInputType.number,
                              hint: 'Rp. 12.000',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              label: 'Harga Jual (Rp)*',
                              controller: _sellPriceCtrl,
                              keyboardType: TextInputType.number,
                              hint: 'Rp. 16.500',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Nomor Batch Awal*',
                              controller: _batchCtrl,
                              hint: 'BATCH-2026-N01',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              label: 'Kadaluwarsa*',
                              controller: _expCtrl,
                              hint: '12 Des 2028',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Section 3: Aturan & Catatan Khusus ──
                Text(
                  'Aturan & Catatan Khusus (Opsional)',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Contoh: Diminum sesudah makan, maksimal 3 kali sehari. Hindari bagi pasien gangguan ginjal stadium lanjut...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAF9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Info banner (Figma Node 1100:24075)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Gunakan formulir ini HANYA untuk membuat obat yang benar-benar baru di katalog apotek. Jika ingin menambah stok obat lama, buka Detail Obat lalu pilih Tambah Stok.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons: Simpan & Batal
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonDarkGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _saveNewMedicine,
                    child: Text(
                      'Simpan Obat Stok',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: _clearForm,
                    child: Text(
                      'Batal & Bersihkan Inputan',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAF9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
