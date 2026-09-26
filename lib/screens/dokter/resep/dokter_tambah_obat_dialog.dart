import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import '../notifikasi/dokter_notifikasi_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FORM TAMBAH / EDIT OBAT RESEP (Sesuai Desain Tambah Obat)
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
  static const _bgColor = Color(0xFFF7FBF8);
  static const _border = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaObatCtrl;
  late final TextEditingController _dosisCtrl;
  late final TextEditingController _frekuensiCtrl;
  late final TextEditingController _jumlahCtrl;
  late final TextEditingController _durasiCtrl;
  late final TextEditingController _instruksiCtrl;

  String? _selectedCaraPenggunaan;
  final List<String> _caraPenggunaanOptions = [
    'Sesudah Makan',
    'Sebelum Makan',
    'Bersama Makan',
    'Pagi hari, Sesudah Makan',
    'Malam hari sebelum tidur',
    'Pagi dan Malam hari',
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

  void _onMedicineSelected(String name) {
    _namaObatCtrl.text = name;

    // Auto-fill sensible defaults for known medicines if empty
    if (name.contains('Candesartan 8mg')) {
      if (_dosisCtrl.text.isEmpty) _dosisCtrl.text = '8mg';
      if (_jumlahCtrl.text.isEmpty) _jumlahCtrl.text = '10 Tablet';
      if (_frekuensiCtrl.text.isEmpty) _frekuensiCtrl.text = '1 x 1 hari';
      if (_durasiCtrl.text.isEmpty) _durasiCtrl.text = '10 hari';
      _selectedCaraPenggunaan ??= 'Sesudah Makan';
    } else if (name.contains('Furosemide 40mg')) {
      if (_dosisCtrl.text.isEmpty) _dosisCtrl.text = '40mg';
      if (_jumlahCtrl.text.isEmpty) _jumlahCtrl.text = '5 Tablet';
      if (_frekuensiCtrl.text.isEmpty) _frekuensiCtrl.text = '1 x 1 hari';
      if (_durasiCtrl.text.isEmpty) _durasiCtrl.text = '5 hari';
      _selectedCaraPenggunaan ??= 'Pagi hari, Sesudah Makan';
    } else if (name.contains('Amlodipine 5mg')) {
      if (_dosisCtrl.text.isEmpty) _dosisCtrl.text = '5mg';
      if (_jumlahCtrl.text.isEmpty) _jumlahCtrl.text = '10 Tablet';
      if (_frekuensiCtrl.text.isEmpty) _frekuensiCtrl.text = '1 x 1 hari';
      if (_durasiCtrl.text.isEmpty) _durasiCtrl.text = '10 hari';
      _selectedCaraPenggunaan ??= 'Sesudah Makan';
    }
    setState(() {});
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
      usageTime: _selectedCaraPenggunaan ?? 'Sesudah Makan',
      specialNotes: _instruksiCtrl.text.trim().isEmpty ? null : _instruksiCtrl.text.trim(),
    );

    Navigator.of(context).pop(newItem);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Topography Background ──
          Positioned.fill(
            child: CustomPaint(
              painter: _TambahObatTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Navigation Bar: Back & (Bell + Avatar) ──
                _buildTopNavigationBar(),

                const SizedBox(height: 14),

                // ── Screen Title Badge: "Tambah Obat" ──
                _buildTitlePill(widget.initialItem != null ? 'Edit Obat' : 'Tambah Obat'),

                const SizedBox(height: 14),

                // ── Scrollable Body ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Patient Info Card ──
                          _buildPatientHeaderCard(p),

                          const SizedBox(height: 20),

                          // ── Section Title: Detail Obat ──
                          Text(
                            'Detail Obat',
                            style: GoogleFonts.inter(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Search Field: Cari Obat.... ──
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
                              _onMedicineSelected(selection);
                            },
                            fieldViewBuilder: (context, fieldTextEditingController, fieldFocusNode, onFieldSubmitted) {
                              fieldTextEditingController.addListener(() {
                                _namaObatCtrl.text = fieldTextEditingController.text;
                              });
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: fieldTextEditingController,
                                  focusNode: fieldFocusNode,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Cari Obat....',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: Color(0xFF334155),
                                      size: 20,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama obat wajib diisi' : null,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // ── 2x2 Grid for Dosis & Jumlah, Frekuensi & Durasi ──
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Dosis'),
                                    _buildFormTextField(
                                      controller: _dosisCtrl,
                                      hint: 'e.g. 500mg',
                                      validatorMsg: 'Dosis wajib diisi',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Jumlah'),
                                    _buildFormTextField(
                                      controller: _jumlahCtrl,
                                      hint: 'e.g. 10 Tablet',
                                      validatorMsg: 'Jumlah wajib diisi',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Frekuensi'),
                                    _buildFormTextField(
                                      controller: _frekuensiCtrl,
                                      hint: 'e.g. 3 x 1',
                                      validatorMsg: 'Frekuensi wajib diisi',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel('Durasi'),
                                    _buildFormTextField(
                                      controller: _durasiCtrl,
                                      hint: 'e.g. 5 hari',
                                      validatorMsg: 'Durasi wajib diisi',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ── Cara Penggunaan Dropdown ──
                          _buildFieldLabel('Cara Penggunaan'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF334155)),
                                hint: Text(
                                  'Pilih Cara penggunaan...',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                value: _selectedCaraPenggunaan,
                                items: _caraPenggunaanOptions.map((e) {
                                  return DropdownMenuItem<String>(
                                    value: e,
                                    child: Text(
                                      e,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedCaraPenggunaan = val);
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── Instruksi Khusus (Opsional) ──
                          _buildFieldLabel('Instruksi Khusus (Opsional)'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                            ),
                            child: TextFormField(
                              controller: _instruksiCtrl,
                              maxLines: 3,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Tambahkan catatan khusus untuk pasien...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Tombol Tambah Obat (Solid Dark Green) ──
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _darkGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: _save,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.initialItem != null ? 'Simpan Perubahan' : 'Tambah Obat',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Tombol Kembali Berbentuk Pill
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 16, color: Color(0xFF0F172A)),
                  const SizedBox(width: 5),
                  Text(
                    'Kembali',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Bell Notification & User Profile Avatar Capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
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
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DokterNotifikasiScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: _darkGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitlePill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      decoration: BoxDecoration(
        color: _darkGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPatientHeaderCard(DokterPatient p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFD0E6ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                p.initials,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
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
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Usia: ${p.age} Tahun',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelamin: ${p.gender}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Alamat :${p.address}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
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

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String hint,
    required String validatorMsg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? validatorMsg : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY PAINTER UNTUK SCREEN TAMBAH OBAT
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
