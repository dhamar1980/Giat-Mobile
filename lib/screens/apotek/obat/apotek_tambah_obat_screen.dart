import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';
import '../notifikasi/apotek_notifikasi_screen.dart';
import '../profile/apotek_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TAMBAH OBAT BARU APOTEK (Revisi Sesuai Screenshot 3 & 4)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekTambahObatScreen extends StatefulWidget {
  final VoidCallback? onMedicineAdded;
  final VoidCallback? onOpenProfile;

  const ApotekTambahObatScreen({
    super.key,
    this.onMedicineAdded,
    this.onOpenProfile,
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

  final TextEditingController _nameCtrl = TextEditingController(text: 'Ibuprofen 400 mg');
  final TextEditingController _doseCtrl = TextEditingController(text: '400 mg');
  final TextEditingController _packageCtrl = TextEditingController(text: 'Strip / Box');
  final TextEditingController _stockCtrl = TextEditingController(text: '50');
  final TextEditingController _expCtrl = TextEditingController();
  final TextEditingController _buyPriceCtrl = TextEditingController(text: 'Rp. 12.000,00');
  final TextEditingController _sellPriceCtrl = TextEditingController(text: 'Rp. 16.500,00');
  final TextEditingController _notesCtrl = TextEditingController();

  String _selectedCategory = 'Analgesik';
  String _selectedForm = 'Tablet';

  final List<String> _categoryOptions = [
    'Analgesik',
    'Antibiotik',
    'Antihipertensi',
    'Antidiabetes',
    'Antasida',
    'Vitamin & Suplemen',
  ];

  final List<String> _formOptions = [
    'Tablet',
    'Kapsul',
    'Sirup',
    'Kaplet',
    'Injeksi',
    'Salep',
    'Tetes',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _packageCtrl.dispose();
    _stockCtrl.dispose();
    _expCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _nameCtrl.clear();
      _selectedCategory = 'Analgesik';
      _selectedForm = 'Tablet';
      _doseCtrl.clear();
      _packageCtrl.clear();
      _stockCtrl.clear();
      _expCtrl.clear();
      _buyPriceCtrl.clear();
      _sellPriceCtrl.clear();
      _notesCtrl.clear();
    });
  }

  Future<void> _pickExpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _darkGreen,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final monthStr = picked.month.toString().padLeft(2, '0');
      final dayStr = picked.day.toString().padLeft(2, '0');
      final formatted = '$monthStr/$dayStr/${picked.year}';
      setState(() {
        _expCtrl.text = formatted;
      });
    }
  }

  int _parsePrice(String input, int fallback) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? fallback;
  }

  void _saveNewMedicine() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final category = _selectedCategory;
    final dose = _doseCtrl.text.trim().isEmpty ? '400 mg' : _doseCtrl.text.trim();
    final package = _packageCtrl.text.trim().isEmpty ? 'Strip / Box' : _packageCtrl.text.trim();
    final stock = int.tryParse(_stockCtrl.text.replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 50;
    final buy = _parsePrice(_buyPriceCtrl.text, 12000);
    final sell = _parsePrice(_sellPriceCtrl.text, 16500);
    final exp = _expCtrl.text.trim().isEmpty ? '12/31/2028' : _expCtrl.text.trim();
    final notes = _notesCtrl.text.trim();

    final newId = '#MED-${8845 + ApotekMockData.medicines.length}';
    final batchNo = 'BATCH-${DateTime.now().year}-N01';

    final med = ApotekMedicine(
      id: newId,
      name: name,
      category: category,
      form: _selectedForm,
      dose: dose,
      packageUnit: package,
      stock: stock,
      stockUnit: _selectedForm,
      buyPrice: buy,
      sellPrice: sell,
      expDate: exp,
      imagePath: 'assets/images/antasida_strip.jpg',
      usageRule: notes.isNotEmpty ? notes : null,
      batches: [
        ApotekMedicineBatch(
          batchNo: batchNo,
          qtyText: '$stock $_selectedForm',
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
    final unreadNotifs = ApotekMockData.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topography Curves (Screenshot 3 & 4)
          Positioned.fill(
            child: CustomPaint(
              painter: _TambahObatTopographyPainter(),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Top Navigation Bar (Kembali & Notif/Profile Pill) ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Pill Button (< Kembali)
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

                        // Action Pill (Bell & Profile)
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
                              Stack(
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
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ApotekNotifikasiScreen(),
                                        ),
                                      ).then((_) => setState(() {}));
                                    },
                                  ),
                                  if (unreadNotifs > 0)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFDC2626),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  if (widget.onOpenProfile != null) {
                                    widget.onOpenProfile!();
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ApotekProfileScreen(showBackButton: true),
                                      ),
                                    );
                                  }
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
                    ),

                    const SizedBox(height: 16),

                    // ── 2. Screen Title Pill: "Tambah Obat Baru" (Screenshot 3) ──
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
                          'Tambah Obat Baru',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── 3. Red Warning Info (Screenshot 3) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_rounded,
                          color: Color(0xFFDC2626),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gunakan formulir ini HANYA untuk membuat obat yang benar-benar baru di katalog apotek. Jika ingin menambah stok obat lama, buka Detail Obat lalu pilih Tambah Stok.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFDC2626),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── 4. Live Preview Card: Pratinjau Obat (Screenshot 3) ──
                    Container(
                      padding: const EdgeInsets.all(14),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/images/antasida_strip.jpg',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.medication_rounded, color: _darkGreen, size: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pratinjau Obat',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _nameCtrl.text.trim().isEmpty ? 'Nama Belum Diisi' : _nameCtrl.text.trim(),
                                  style: GoogleFonts.inter(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _packageCtrl.text.trim().isEmpty ? 'Strip / Box' : _packageCtrl.text.trim(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _selectedCategory,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── 5. Section 1: Identitas & Sediaan (Screenshot 3) ──
                    Text(
                      'Identitas & Sediaan',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nama Obat*
                          _buildFieldLabel('Nama Obat'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameCtrl,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(hint: 'Ibuprofen 400 mg'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),

                          const SizedBox(height: 14),

                          // Kategori*
                          _buildFieldLabel('Kategori'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                            decoration: _buildInputDecoration(hint: 'Pilih Kategori'),
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            items: _categoryOptions
                                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),

                          const SizedBox(height: 14),

                          // Bentuk Sediaan*
                          _buildFieldLabel('Bentuk Sediaan'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedForm,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                            decoration: _buildInputDecoration(hint: 'Pilih Bentuk'),
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            items: _formOptions
                                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedForm = val);
                            },
                          ),

                          const SizedBox(height: 14),

                          // Dosis / Kekuatan*
                          _buildFieldLabel('Dosis / Kekuatan'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _doseCtrl,
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(hint: '400 mg'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),

                          const SizedBox(height: 14),

                          // Satuan Kemasan*
                          _buildFieldLabel('Satuan Kemasan'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _packageCtrl,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(hint: 'Strip / Box'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── 6. Section 2: Stok & Finansial (Screenshot 4) ──
                    Text(
                      'Stok & Finansial',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stok Awal*
                          _buildFieldLabel('Stok Awal'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _stockCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(
                              hint: '50',
                              suffix: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  'Unit',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),

                          const SizedBox(height: 14),

                          // Kadaluwarsa*
                          _buildFieldLabel('Kadaluwarsa'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _pickExpDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _expCtrl,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                                decoration: _buildInputDecoration(hint: 'mm/dd/yyyy'),
                                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Harga Beli (Rp)*
                          _buildFieldLabel('Harga Beli (Rp)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _buyPriceCtrl,
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(hint: 'Rp. 12.000,00'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),

                          const SizedBox(height: 14),

                          // Harga Jual (Rp)*
                          _buildFieldLabel('Harga Jual (Rp)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _sellPriceCtrl,
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(hint: 'Rp. 16.500,00'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── 7. Section 3: Aturan & Catatan Khusus (Screenshot 4) ──
                    Text(
                      'Aturan & Catatan Khusus',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Opsional',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText:
                                  'Contoh: Diminum sesudah makan, maksimal 3 kali sehari. Hindari bagi pasien gangguan ginjal stadium lanjut',
                              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAF9),
                              contentPadding: const EdgeInsets.all(14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: _darkGreen, width: 1.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── 8. Buttons: Simpan & Batal (Screenshot 4) ──
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_outlined, size: 20, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Simpan Obat Stok',
                              style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: _buttonDarkGreen, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _clearForm,
                        child: Text(
                          'Batal & Bersihkan Inputan',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _buttonDarkGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
        children: const [
          TextSpan(
            text: '*',
            style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, Widget? prefixIcon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF94A3B8)),
      prefixIcon: prefixIcon,
      suffix: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _darkGreen, width: 1.3),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY CURVE PAINTER FOR TAMBAH OBAT SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _TambahObatTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    GiatBackgroundPainter.paintBackground(
      canvas,
      size,
      showGradient: true,
      showLines: true,
    );
    }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
