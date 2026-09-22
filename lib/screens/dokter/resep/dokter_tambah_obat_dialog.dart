import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FORM TAMBAH OBAT / RESEP BARU (Figma Node: 1620-7165 & 1008-19232)
// ─────────────────────────────────────────────────────────────────────────────

class DokterTambahObatScreen extends StatefulWidget {
  final DokterPatient patient;
  final DokterPrescriptionItem? initialItem;

  const DokterTambahObatScreen({
    super.key,
    required this.patient,
    this.initialItem,
  });

  @override
  State<DokterTambahObatScreen> createState() => _DokterTambahObatScreenState();
}

class _DokterTambahObatScreenState extends State<DokterTambahObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaObatCtrl;
  late final TextEditingController _dosisCtrl;
  late final TextEditingController _frekuensiCtrl;
  late final TextEditingController _jumlahCtrl;
  late final TextEditingController _durasiCtrl;
  late final TextEditingController _instruksiCtrl;

  String _selectedCaraPenggunaan = 'Sesudah Makan';
  final List<String> _caraPenggunaanOptions = [
    'Sesudah Makan',
    'Sebelum Makan',
    'Bersama Makan',
    'Pagi hari, Sesudah Makan',
    'Malam hari sebelum tidur',
  ];

  final List<String> _suggestedMedicines = [
    'Candesartan 8mg',
    'Candesartan 16mg',
    'Furosemide 40mg',
    'Amlodipine 5mg',
    'Amlodipine 10mg',
    'Ketosteril 600mg',
    'Natrium Bikarbonat 500mg',
    'Paracetamol 500mg',
    'Asam Folat 1mg',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _namaObatCtrl = TextEditingController(text: item?.medicineName ?? '');
    _dosisCtrl = TextEditingController(text: item?.dose ?? '');
    _frekuensiCtrl = TextEditingController(text: item?.frequency ?? '');
    _jumlahCtrl = TextEditingController(text: item?.quantity ?? '');
    _durasiCtrl = TextEditingController(text: item?.duration ?? '');
    _instruksiCtrl = TextEditingController(text: item?.specialNotes ?? '');
    if (item != null && _caraPenggunaanOptions.contains(item.usageTime)) {
      _selectedCaraPenggunaan = item.usageTime;
    }
  }

  @override
  void dispose() {
    _namaObatCtrl.dispose();
    _dosisCtrl.dispose();
    _frekuensiCtrl.dispose();
    _jumlahCtrl.dispose();
    _durasiCtrl.dispose();
    _instruksiCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final newItem = DokterPrescriptionItem(
      id: widget.initialItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      medicineName: _namaObatCtrl.text.trim(),
      dose: _dosisCtrl.text.trim(),
      frequency: _frekuensiCtrl.text.trim(),
      quantity: _jumlahCtrl.text.trim(),
      duration: _durasiCtrl.text.trim(),
      usageTime: _selectedCaraPenggunaan,
      specialNotes: _instruksiCtrl.text.trim().isEmpty ? null : _instruksiCtrl.text.trim(),
    );

    Navigator.of(context).pop(newItem);
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
          widget.initialItem != null ? 'Edit Obat' : 'Tambah Obat',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
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
                // ── Patient Info Card ──
                _buildPatientInfoCard(),

                const SizedBox(height: 24),

                Text(
                  'Detail Obat',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),

                // Nama Obat / Cari Obat
                _buildLabel('Cari / Nama Obat'),
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _namaObatCtrl.text),
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _suggestedMedicines;
                    }
                    return _suggestedMedicines.where(
                      (item) => item.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                    );
                  },
                  onSelected: (String selection) {
                    _namaObatCtrl.text = selection;
                  },
                  fieldViewBuilder: (context, fieldTextEditingController, fieldFocusNode, onFieldSubmitted) {
                    fieldTextEditingController.addListener(() {
                      _namaObatCtrl.text = fieldTextEditingController.text;
                    });
                    return TextFormField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: _inputDecoration(hint: 'Cari Obat....', prefixIcon: Icons.search_rounded),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama obat wajib diisi' : null,
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Grid 2x2 for Dosis, Frekuensi, Jumlah, Durasi
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Dosis'),
                          TextFormField(
                            controller: _dosisCtrl,
                            decoration: _inputDecoration(hint: 'e.g. 500mg'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Frekuensi'),
                          TextFormField(
                            controller: _frekuensiCtrl,
                            decoration: _inputDecoration(hint: 'e.g. 3 x 1'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Jumlah'),
                          TextFormField(
                            controller: _jumlahCtrl,
                            decoration: _inputDecoration(hint: 'e.g. 10 Tablet'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Durasi'),
                          TextFormField(
                            controller: _durasiCtrl,
                            decoration: _inputDecoration(hint: 'e.g. 5 hari'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Cara Penggunaan Dropdown
                _buildLabel('Cara Penggunaan'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCaraPenggunaan,
                      items: _caraPenggunaanOptions.map((e) {
                        return DropdownMenuItem<String>(
                          value: e,
                          child: Text(e, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A))),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCaraPenggunaan = val);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Instruksi Khusus (Opsional)
                _buildLabel('Instruksi Khusus (Opsional)'),
                TextFormField(
                  controller: _instruksiCtrl,
                  maxLines: 3,
                  decoration: _inputDecoration(hint: 'Tambahkan catatan khusus untuk pasien...'),
                ),

                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _save,
                    child: Text(
                      widget.initialItem != null ? 'Simpan Perubahan' : 'Tambah Obat',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF64748B), size: 20) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _darkGreen, width: 1.5)),
    );
  }

  Widget _buildPatientInfoCard() {
    final p = widget.patient;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                p.initials,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _darkGreen),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Usia: ${p.age} Tahun  •  Kelamin: ${p.gender}',
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Alamat: ${p.address}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
