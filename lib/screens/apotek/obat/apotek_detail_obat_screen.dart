import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';
import '../notifikasi/apotek_notifikasi_screen.dart';
import '../profile/apotek_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL OBAT & TAMBAH STOK APOTEK (Revisi Sesuai Screenshot 1 & 2)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekDetailObatScreen extends StatefulWidget {
  final ApotekMedicine medicine;
  final VoidCallback? onStockUpdated;
  final VoidCallback? onOpenProfile;

  const ApotekDetailObatScreen({
    super.key,
    required this.medicine,
    this.onStockUpdated,
    this.onOpenProfile,
  });

  @override
  State<ApotekDetailObatScreen> createState() => _ApotekDetailObatScreenState();
}

class _ApotekDetailObatScreenState extends State<ApotekDetailObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _qtyCtrl = TextEditingController(text: '50');
  final TextEditingController _buyPriceCtrl = TextEditingController();
  final TextEditingController _sellPriceCtrl = TextEditingController();
  final TextEditingController _batchCtrl = TextEditingController(text: 'BATCH-2026-X89');
  final TextEditingController _expCtrl = TextEditingController(text: '14 Okt 2026');
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.medicine.stockUnit;
    _buyPriceCtrl.text = _formatRupiah(widget.medicine.buyPrice);
    _sellPriceCtrl.text = _formatRupiah(widget.medicine.sellPrice);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _buyPriceCtrl.dispose();
    _sellPriceCtrl.dispose();
    _batchCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  String _formatRupiah(int amount) {
    final str = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp. $str';
  }

  int _parsePrice(String input, int fallback) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? fallback;
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
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final formatted = '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      setState(() {
        _expCtrl.text = formatted;
      });
    }
  }

  void _saveStockIncrement() {
    if (!_formKey.currentState!.validate()) return;

    final qty = int.tryParse(_qtyCtrl.text.replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0;
    final buy = _parsePrice(_buyPriceCtrl.text, widget.medicine.buyPrice);
    final sell = _parsePrice(_sellPriceCtrl.text, widget.medicine.sellPrice);
    final batchNo = _batchCtrl.text.trim().isEmpty
        ? 'BATCH-${DateTime.now().year}-N${widget.medicine.batches.length + 1}'
        : _batchCtrl.text.trim();
    final expDate = _expCtrl.text.trim().isEmpty ? '14 Okt 2026' : _expCtrl.text.trim();

    ApotekMockData.addStockBatch(
      medicineId: widget.medicine.id,
      batchNo: batchNo,
      expDate: expDate,
      quantity: qty,
      buyPrice: buy,
      sellPrice: sell,
    );

    widget.medicine.buyPrice = buy;
    widget.medicine.sellPrice = sell;

    setState(() {});
    widget.onStockUpdated?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil menambahkan stok $qty $_selectedUnit untuk ${widget.medicine.name}.'),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final med = widget.medicine;
    final unreadNotifs = ApotekMockData.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topography Curves (Screenshot 1 & 2)
          Positioned.fill(
            child: CustomPaint(
              painter: _DetailObatTopographyPainter(),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
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

                  // ── 2. Screen Title Pill: "Detail Obat" (Screenshot 1) ──
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
                        'Detail Obat',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── 3. Medicine Header Card (Screenshot 1) ──
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Green square container with composite clipboard-prescription icon
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: _darkGreen,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: _DetailPrescriptionSquareIcon(size: 32, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.id,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                med.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Stok: ${med.stock} ${med.stockUnit}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _darkGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            med.form,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ── 4. Section: Rincian Tambah Stok (Screenshot 1) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Rincian Tambah Stok',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _darkGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Batch Masuk',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Jumlah Tambahan*
                          _buildFieldLabel('Jumlah Tambahan'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _qtyCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(hint: '50'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),

                          const SizedBox(height: 14),

                          // Satuan*
                          _buildFieldLabel('Satuan'),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                            decoration: _buildInputDecoration(hint: 'Pilih Satuan'),
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            items: ['Tablet', 'Strip', 'Box', 'Botol', 'Kapsul', 'Kaplet']
                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedUnit = val);
                            },
                          ),

                          const SizedBox(height: 14),

                          // Harga Beli Satuan*
                          _buildFieldLabel('Harga Beli Satuan'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _buyPriceCtrl,
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(hint: 'Rp. 3.500'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),

                          const SizedBox(height: 14),

                          // Harga Jual Satuan*
                          _buildFieldLabel('Harga Jual Satuan'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _sellPriceCtrl,
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(hint: 'Rp. 5.000'),
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),

                          const SizedBox(height: 14),

                          // Tanggal Kadaluwarsa Batch Baru*
                          _buildFieldLabel('Tanggal Kadaluwarsa Batch Baru'),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _pickExpDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _expCtrl,
                                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                                decoration: _buildInputDecoration(
                                  hint: 'Pilih Tanggal',
                                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF0F172A)),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Nomor Batch Baru*
                          _buildFieldLabel('Nomor Batch Baru'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _batchCtrl,
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                            decoration: _buildInputDecoration(
                              hint: 'BATCH-2026-X89',
                              prefixIcon: const Icon(Icons.tag_rounded, size: 20, color: Color(0xFF0F172A)),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                          ),

                          const SizedBox(height: 20),

                          // Tombol Simpan Tambahan Stok (Screenshot 1)
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
                              onPressed: _saveStockIncrement,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.save_outlined, size: 20, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Simpan Tambahan Stok',
                                    style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 5. Section: Riwayat Batch Terakhir (Screenshot 2) ──
                  Text(
                    'Riwayat Batch Terakhir',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
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
                    child: med.batches.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Belum ada riwayat batch untuk obat ini.',
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < med.batches.length; i++) ...[
                                if (i > 0) const SizedBox(height: 18),
                                _buildBatchRow(med.batches[i]),
                              ],
                            ],
                          ),
                  ),
                ],
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

  InputDecoration _buildInputDecoration({required String hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF94A3B8)),
      prefixIcon: prefixIcon,
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

  Widget _buildBatchRow(ApotekMedicineBatch batch) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                batch.batchNo,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                batch.status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          batch.qtyText,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Exp: ${batch.expDate}',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSITE PRESCRIPTION SQUARE ICON (Clipboard + Pill + Pen in Screenshot 1)
// ─────────────────────────────────────────────────────────────────────────────

class _DetailPrescriptionSquareIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _DetailPrescriptionSquareIcon({
    this.size = 32,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Clipboard outline
          Positioned(
            left: 1,
            top: 1,
            child: Icon(
              Icons.assignment_outlined,
              size: size * 0.92,
              color: color,
            ),
          ),
          // Pill symbol in center
          Positioned(
            left: size * 0.22,
            top: size * 0.32,
            child: Transform.rotate(
              angle: -0.7,
              child: Icon(
                Icons.medication_rounded,
                size: size * 0.38,
                color: color,
              ),
            ),
          ),
          // Small pen symbol at bottom right
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              Icons.edit,
              size: size * 0.36,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY CURVE PAINTER FOR OBAT DETAIL
// ─────────────────────────────────────────────────────────────────────────────

class _DetailObatTopographyPainter extends CustomPainter {
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
