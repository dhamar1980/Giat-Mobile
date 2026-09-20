import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TAMBAH REMINDER BARU (Figma Nodes: 771-4931 & 771-5091)
// Breakdown Kategori: Hanya ada 'Obat' dan 'Konsultasi'
// ─────────────────────────────────────────────────────────────────────────────

class TambahReminderScreen extends StatefulWidget {
  final String initialCategory;

  const TambahReminderScreen({
    super.key,
    this.initialCategory = 'Obat',
  });

  @override
  State<TambahReminderScreen> createState() => _TambahReminderScreenState();
}

class _TambahReminderScreenState extends State<TambahReminderScreen> {
  static const _primaryGreen = Color(0xFF006D37);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _textColor = Color(0xFF091D2E);

  late String _selectedCategory;

  // ── Controllers for Obat Category (Figma 771:4931) ──
  final _namaPengingatCtrl = TextEditingController();
  final _dosisCtrl = TextEditingController();
  DateTime _obatDate = DateTime.now();
  TimeOfDay _obatTime = const TimeOfDay(hour: 8, minute: 0);
  String _obatPengulangan = 'Setiap Hari';

  // ── Controllers for Konsultasi Category (Figma 771:5091) ──
  final _namaKonsultasiCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  DateTime? _konsultasiDate;
  TimeOfDay? _konsultasiTime;
  String _konsultasiPengulangan = 'Sekali Saja';
  final _catatanCtrl = TextEditingController();

  final List<String> _kategoriOptions = ['Obat', 'Konsultasi'];

  final List<String> _pengulanganObatOptions = [
    'Setiap Hari',
    'Sekali Saja',
    'Hari Kerja (Senin - Jumat)',
    'Akhir Pekan (Sabtu - Minggu)',
    'Kustom',
  ];

  final List<String> _pengulanganKonsultasiOptions = [
    'Sekali Saja',
    'Setiap Minggu',
    'Setiap Bulan',
    'Kustom',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _namaPengingatCtrl.dispose();
    _dosisCtrl.dispose();
    _namaKonsultasiCtrl.dispose();
    _lokasiCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

  Future<void> _pickDate({required bool isObat}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isObat ? _obatDate : (_konsultasiDate ?? now),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: _textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isObat) {
          _obatDate = picked;
        } else {
          _konsultasiDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isObat}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isObat ? _obatTime : (_konsultasiTime ?? const TimeOfDay(hour: 10, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: _textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isObat) {
          _obatTime = picked;
        } else {
          _konsultasiTime = picked;
        }
      });
    }
  }

  void _simpanReminder() {
    if (_selectedCategory == 'Obat') {
      final nama = _namaPengingatCtrl.text.trim();
      if (nama.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan masukkan nama pengingat obat')),
        );
        return;
      }
      final dosis = _dosisCtrl.text.trim().isNotEmpty
          ? _dosisCtrl.text.trim()
          : 'Sesuai anjuran dokter';

      final newReminder = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'obat',
        'title': nama,
        'subtitle': dosis,
        'time': _formatTime(_obatTime),
        'date': _formatDate(_obatDate),
        'pengulangan': _obatPengulangan,
        'status': 'Belum di lakukan',
        'isActive': true,
      };

      Navigator.pop(context, newReminder);
    } else {
      // Konsultasi
      final nama = _namaKonsultasiCtrl.text.trim();
      if (nama.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan masukkan nama konsultasi')),
        );
        return;
      }
      final lokasi = _lokasiCtrl.text.trim().isNotEmpty
          ? _lokasiCtrl.text.trim()
          : 'Klinik / RS Rekanan';

      final timeStr = _konsultasiTime != null ? _formatTime(_konsultasiTime!) : '10:00 WIB';
      final dateStr = _konsultasiDate != null ? _formatDate(_konsultasiDate!) : _formatDate(DateTime.now());

      final newReminder = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'konsultasi',
        'title': nama,
        'subtitle': lokasi,
        'time': timeStr,
        'date': dateStr,
        'pengulangan': _konsultasiPengulangan,
        'catatan': _catatanCtrl.text.trim(),
        'status': 'Akan Datang',
        'isActive': true,
      };

      Navigator.pop(context, newReminder);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Background Topography ──
          Positioned.fill(
            child: CustomPaint(
              painter: _ReminderTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header Bar with Kembali & Title Badge ──
                _buildHeaderBar(),

                const SizedBox(height: 14),

                // ── Scrollable Form Content ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Pilih Kategori (Obat / Konsultasi)
                        _buildCategoryDropdown(),

                        const SizedBox(height: 20),

                        // 2. Dynamic Form Based on Category
                        if (_selectedCategory == 'Obat')
                          _buildObatForm()
                        else
                          _buildKonsultasiForm(),

                        const SizedBox(height: 30),

                        // 3. Simpan Reminder Button
                        _buildSubmitButton(),

                        const SizedBox(height: 40),
                      ],
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

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER BAR (Kembali button & Title Badge Pill)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top: Kembali Pill Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primaryGreen, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 14, color: _textColor),
                  const SizedBox(width: 6),
                  Text(
                    'Kembali',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Below: Center Title Pill Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Tambah Reminder Baru',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CATEGORY DROPDOWN (Hanya Obat & Konsultasi)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Kategori',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textColor),
              items: _kategoriOptions.map((cat) {
                final isObat = cat == 'Obat';
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(
                        isObat ? Icons.medication_rounded : Icons.medical_services_rounded,
                        color: _primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        cat,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _textColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FORM: OBAT (Figma Node 771:4931)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildObatForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Nama Pengingat
        Text(
          'Nama Pengingat',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textColor),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _namaPengingatCtrl,
          hintText: 'Contoh: Minum Obat Losartan',
          icon: Icons.medication_outlined,
        ),

        const SizedBox(height: 18),

        // 2. Keterangan / Dosis
        Text(
          'Keterangan / Dosis',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textColor),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _dosisCtrl,
          hintText: 'Contoh: 50 mg, sesudah makan',
          icon: Icons.edit_note_rounded,
          maxLines: 3,
        ),

        const SizedBox(height: 18),

        // 3. Tanggal & Waktu (2 Kolom)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textColor),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickDate(isObat: true),
                    child: _buildPickerBox(
                      text: _formatDate(_obatDate),
                      icon: Icons.calendar_today_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waktu',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textColor),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickTime(isObat: true),
                    child: _buildPickerBox(
                      text: _formatTime(_obatTime),
                      icon: Icons.access_time_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 4. Pilih Pengulangan
        Text(
          'Pilih Pengulangan',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textColor),
        ),
        const SizedBox(height: 8),
        _buildDropdownSelector(
          currentValue: _obatPengulangan,
          items: _pengulanganObatOptions,
          onChanged: (val) {
            if (val != null) setState(() => _obatPengulangan = val);
          },
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FORM: KONSULTASI (Figma Node 771:5091)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKonsultasiForm() {
    final dateDisplay = _konsultasiDate != null ? _formatDate(_konsultasiDate!) : 'mm/dd/yy';
    final timeDisplay = _konsultasiTime != null ? _formatTime(_konsultasiTime!) : '-- : --';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Nama Konsultasi
        Text(
          'Nama Konsultasi',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textColor),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _namaKonsultasiCtrl,
          hintText: 'Misal: Konsultasi Dokter Nefrologi',
          icon: Icons.medical_services_outlined,
        ),

        const SizedBox(height: 18),

        // 2. Lokasi / Link Pertemuan
        Text(
          'Lokasi / Link Pertemuan',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textColor),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _lokasiCtrl,
          hintText: 'Misal: RS Permata atau Zoom Link',
          icon: Icons.location_on_outlined,
          maxLines: 3,
        ),

        const SizedBox(height: 18),

        // 3. Tanggal & Waktu (2 Kolom)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textColor),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickDate(isObat: false),
                    child: _buildPickerBox(
                      text: dateDisplay,
                      icon: Icons.calendar_today_rounded,
                      isPlaceholder: _konsultasiDate == null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waktu',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textColor),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickTime(isObat: false),
                    child: _buildPickerBox(
                      text: timeDisplay,
                      icon: Icons.access_time_rounded,
                      isPlaceholder: _konsultasiTime == null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // 4. Pengulangan
        Text(
          'Pengulangan',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textColor),
        ),
        const SizedBox(height: 8),
        _buildDropdownSelector(
          currentValue: _konsultasiPengulangan,
          items: _pengulanganKonsultasiOptions,
          onChanged: (val) {
            if (val != null) setState(() => _konsultasiPengulangan = val);
          },
        ),

        const SizedBox(height: 18),

        // 5. Catatan Tambahan (Opsional)
        Text(
          'Catatan Tambahan (Opsional)',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: _textColor),
        ),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _catatanCtrl,
          hintText: 'Tambahkan catatan untuk dokter atau \npengingat diri sendiri...',
          icon: Icons.notes_rounded,
          maxLines: 3,
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(fontSize: 13, color: _textColor),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 10),
            child: Icon(icon, color: const Color(0xFF64748B), size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPickerBox({
    required String text,
    required IconData icon,
    bool isPlaceholder = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: isPlaceholder ? FontWeight.w400 : FontWeight.w500,
                color: isPlaceholder ? const Color(0xFF94A3B8) : _textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSelector({
    required String currentValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _textColor),
          items: items.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(
                opt,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: _primaryGreen.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _simpanReminder,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Simpan Reminder',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY PAINTER (GIAT Organic Curves)
// ─────────────────────────────────────────────────────────────────────────────
class _ReminderTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (int i = 0; i < 7; i++) {
      final path = Path();
      final yOffset = size.height * 0.15 + (i * 85);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.25,
        yOffset - 40,
        size.width * 0.7,
        yOffset + 50,
        size.width,
        yOffset - 20,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
