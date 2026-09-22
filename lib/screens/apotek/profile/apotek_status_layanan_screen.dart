import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'apotek_jam_operasional_screen.dart';
import 'apotek_area_layanan_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STATUS LAYANAN APOTEK (Figma Node: 1100-26664)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekStatusLayananScreen extends StatefulWidget {
  const ApotekStatusLayananScreen({super.key});

  @override
  State<ApotekStatusLayananScreen> createState() => _ApotekStatusLayananScreenState();
}

class _ApotekStatusLayananScreenState extends State<ApotekStatusLayananScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  bool _isServiceActive = true;

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
          'Status Layanan',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Chat Bubble Info (Figma Node 1100:26664) ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065A37), Color(0xFF044E2F)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ketersediaan Toko',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF86EFAC),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isServiceActive ? const Color(0xFF22C55E) : const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isServiceActive ? 'Aktif' : 'Tutup Sementara',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Layanan Apotek',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isServiceActive
                          ? 'Apotek sedang tersedia dan dapat menerima pesanan pasien secara langsung.'
                          : 'Apotek sedang tidak menerima pesanan baru. Pasien akan dialihkan ke apotek mitra lain.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Material(
                      color: Colors.transparent,
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isServiceActive,
                        activeColor: const Color(0xFF22C55E),
                        title: Text(
                          'Penerimaan Pesanan Langsung',
                          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        subtitle: Text(
                          'Terhubung dengan antrean resep dokter',
                          style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white70),
                        ),
                        onChanged: (val) {
                          setState(() => _isServiceActive = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                val ? 'Layanan apotek diaktifkan.' : 'Layanan apotek dinonaktifkan sementara.',
                              ),
                              backgroundColor: _darkGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Jam Operasional Card (Figma Node 1100:26664) ──
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.schedule_rounded, color: _darkGreen, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Jam Operasional',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ApotekJamOperasionalScreen()),
                            );
                          },
                          child: Text(
                            'Ubah',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _darkGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Senin - Minggu  •  08.00 - 21.00 WIB',
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sedang Buka (Tutup dalam 4 jam)',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF16A34A), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Area Layanan Card (Figma Node 1100:26664) ──
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.location_on_rounded, color: Color(0xFF2563EB), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Area Layanan',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ApotekAreaLayananScreen()),
                            );
                          },
                          child: Text(
                            'Ubah',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _darkGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kota Malang, Kabupaten Malang, Kota Batu',
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pengantaran instan & reguler tersedia',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
