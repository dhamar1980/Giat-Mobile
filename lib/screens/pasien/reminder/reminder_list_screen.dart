import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tambah_reminder_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PENGINGAT & ALARM KESEHATAN GINJAL (REMINDER SAYA)
// Figma Node: 771:5254 (Pasien-reminder)
// ─────────────────────────────────────────────────────────────────────────────

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  static const _primaryGreen = Color(0xFF006D37);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _textColor = Color(0xFF091D2E);
  static const _subtextColor = Color(0xFF475569);

  // Initial reminders matching Figma Node 771:5254
  final List<Map<String, dynamic>> _reminders = [
    {
      'id': '1',
      'type': 'obat',
      'title': 'Minum Obat',
      'subtitle': 'Losartan 50 mg',
      'time': '08:00 WIB',
      'date': 'Hari ini',
      'isActive': true,
    },
    {
      'id': '2',
      'type': 'konsultasi',
      'title': 'Konsultasi Dokter',
      'subtitle': 'Dr. budi Santoso',
      'time': '14:00 WIB',
      'date': 'Hari ini',
      'isActive': true,
    },
  ];

  Future<void> _navigateToAddReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TambahReminderScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _reminders.insert(0, result);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengingat "${result['title']}" berhasil ditambahkan! ⏰'),
            backgroundColor: _primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _deleteReminder(int index) {
    final deletedTitle = _reminders[index]['title'];
    setState(() {
      _reminders.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pengingat "$deletedTitle" dihapus'),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
        backgroundColor: const Color(0xFF334155),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                // ── Top Header Bar (Kembali & Reminder Saya stacked vertically) ──
                _buildHeaderBar(),

                const SizedBox(height: 12),

                // ── Main Content Area ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Heading: "Hari ini" (Figma Node 771:5254)
                        Text(
                          'Hari ini',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // List of Reminders
                        Expanded(
                          child: _reminders.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  itemCount: _reminders.length,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final rem = _reminders[index];
                                    return _buildReminderCard(rem, index);
                                  },
                                ),
                        ),

                        // Bottom Button: "Tambah Reminder Baru" (Figma 771:5254 Frame 3)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: _buildAddButton(),
                        ),
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
  // HEADER BAR (Kembali di kiri atas, lalu di bawahnya Reminder Saya di tengah)
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

          // 2. Below: Reminder Saya Pill Badge (Centered)
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
                'Reminder Saya',
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
  // REMINDER CARD (Themes 2 & 3 in Figma Node 771:5254)
  // Tanpa status (Belum di lakukan / Akan Datang / Selesai dihapus)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildReminderCard(Map<String, dynamic> rem, int index) {
    final isObat = rem['type'] == 'obat';
    final timeStr = rem['time'] ?? '08:00 WIB';

    return Dismissible(
      key: Key(rem['id'] ?? index.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => _deleteReminder(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: _primaryGreen.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle decorative organic bubble on the left (Figma Bubbles)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 70,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: CustomPaint(
                  painter: _CardBubblePainter(),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Container (Soft Cyan/Mint background with rounded corners)
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        isObat ? Icons.medication_outlined : Icons.medical_services_outlined,
                        color: _textColor,
                        size: 26,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Info Column: Title & Subtitle only
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title (e.g. Minum Obat, Konsultasi Dokter)
                          Text(
                            rem['title'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Subtitle / Dosis / Dokter
                          Text(
                            rem['subtitle'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: _subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Side (Top): Time Pill Badge (Navy Background with White Text)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _textColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      timeStr,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.alarm_off_rounded,
              size: 40,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada pengingat hari ini',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Klik tombol di bawah untuk menambah pengingat baru',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM BUTTON: "Tambah Reminder Baru" (Figma Node 771:5254 Frame 3)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: _primaryGreen.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _navigateToAddReminder,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tambah Reminder Baru',
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
// CARD DECORATIVE BUBBLE PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _CardBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2ECC71).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 36, paint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.7), 28, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
