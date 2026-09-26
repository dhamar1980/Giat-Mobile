import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PENGATURAN NOTIFIKASI DOKTER (Figma Node: 1008-18622 / Screenshot 5)
// ─────────────────────────────────────────────────────────────────────────────

class DokterPengaturanNotifikasiScreen extends StatefulWidget {
  const DokterPengaturanNotifikasiScreen({super.key});

  @override
  State<DokterPengaturanNotifikasiScreen> createState() => _DokterPengaturanNotifikasiScreenState();
}

class _DokterPengaturanNotifikasiScreenState extends State<DokterPengaturanNotifikasiScreen> {
  static const _darkGreen = Color(0xFF044E2F);
  static const _activeSwitchGreen = Color(0xFF22C55E);
  static const _border = Color(0xFFE2E8F0);

  bool _konsultasiBaru = true;
  bool _pengingatJadwal = true;
  bool _updateSistem = true;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: Stack(
        children: [
          // Background Topography
          Positioned.fill(
            child: CustomPaint(
              painter: _NotifikasiTopographyPainter(),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Navigation Row (<- Kembali) ──
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, size: 15, color: Color(0xFF0F172A)),
                          const SizedBox(width: 5),
                          Text(
                            'Kembali',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Pill Title: Notifikasi (Screenshot 5) ──
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
                        'Notifikasi',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Subtitle Description ──
                  Text(
                    'Atur bagaimana Anda menerima pembaruan dan peringatan untuk memastikan Anda tidak melewatkan informasi pasien yang penting.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: const Color(0xFF475569),
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Unified Switches Card (Screenshot 5) ──
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Switch 1: Konsultasi Baru
                        _buildSwitchItem(
                          title: 'Konsultasi Baru',
                          description: 'Dapatkan notifikasi instan saat pasien meminta konsultasi baru.',
                          value: _konsultasiBaru,
                          onChanged: (val) => setState(() => _konsultasiBaru = val),
                        ),

                        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),

                        // Switch 2: Pengingat Jadwal
                        _buildSwitchItem(
                          title: 'Pengingat Jadwal',
                          description: 'Pengingat untuk janji temu mendatang, 15 menit sebelum dimulai.',
                          value: _pengingatJadwal,
                          onChanged: (val) => setState(() => _pengingatJadwal = val),
                        ),

                        const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),

                        // Switch 3: Update Sistem
                        _buildSwitchItem(
                          title: 'Update Sistem',
                          description: 'Notifikasi mengenai pemeliharaan aplikasi, fitur baru, dan perubahan kebijakan.',
                          value: _updateSistem,
                          onChanged: (val) => setState(() => _updateSistem = val),
                        ),
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

  Widget _buildSwitchItem({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              activeColor: Colors.white,
              activeTrackColor: _activeSwitchGreen,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFCBD5E1),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifikasiTopographyPainter extends CustomPainter {
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

