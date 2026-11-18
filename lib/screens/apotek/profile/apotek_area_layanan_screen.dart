import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/apotek_api_service.dart';
import '../../../widgets/giat_background.dart';
import '../models/apotek_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CAKUPAN AREA LAYANAN APOTEK (Tanpa Header Hijau & Tanpa Bubble Chat)
// Seragam dengan UI Pasien / Dokter
// ─────────────────────────────────────────────────────────────────────────────

class ApotekAreaLayananScreen extends StatefulWidget {
  const ApotekAreaLayananScreen({super.key});

  @override
  State<ApotekAreaLayananScreen> createState() =>
      _ApotekAreaLayananScreenState();
}

class _ApotekAreaLayananScreenState extends State<ApotekAreaLayananScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF7FAF8);
  static const _border = Color(0xFFE2E8F0);

  List<ApotekCoverageArea> _areas = ApotekMockData.areas;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    if (_isTest) return;
    try {
      final res = await ApotekApiService().getAreaLayanan();
      if (res.success && res.data != null && res.data!.isNotEmpty && mounted) {
        final parsed = res.data!.whereType<Map>().map((e) {
          final m = Map<String, dynamic>.from(e);
          return ApotekCoverageArea(
            name: (m['nama_area'] ?? 'Kota Jember').toString(),
            details: (m['detail'] ?? 'Layanan pengantaran obat kurir farmasi Jember').toString(),
            isActive: m['is_active'] == true,
          );
        }).toList();
        if (parsed.isNotEmpty) {
          setState(() => _areas = parsed);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleAll() {
    final hasInactive = _areas.any((a) => !a.isActive);
    setState(() {
      for (final a in _areas) {
        a.isActive = hasInactive;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _areas.where((a) => a.isActive).length;
    final filtered = _areas.where((a) {
      if (_query.trim().isEmpty) return true;
      return a.name.toLowerCase().contains(_query.toLowerCase()) ||
          a.details.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _AreaLayananTopographyPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar (<- Kembali + Center Pill Title)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7.5,
                          ),
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
                              const Icon(
                                Icons.arrow_back,
                                size: 15,
                                color: Color(0xFF0F172A),
                              ),
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
                      const SizedBox(height: 14),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8.5,
                          ),
                          decoration: BoxDecoration(
                            color: _buttonDarkGreen,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _buttonDarkGreen.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'Area Layanan',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Summary & Search Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$activeCount Wilayah Dipilih',
                                    style: GoogleFonts.inter(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cakupan Wilayah Kabupaten & Kota Jember',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _toggleAll,
                              child: Text(
                                'Atur Semua',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _darkGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (val) => setState(() => _query = val),
                            decoration: InputDecoration(
                              hintText: 'Cari kota, kecamatan, atau wilayah...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Area List
                Expanded(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final area = filtered[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: area.isActive
                                ? const Color(0xFFBBF7D0)
                                : _border,
                          ),
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: area.isActive
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.location_city_rounded,
                                color: area.isActive
                                    ? _darkGreen
                                    : const Color(0xFF94A3B8),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    area.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    area.details,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: area.isActive,
                              activeColor: _darkGreen,
                              onChanged: (val) {
                                setState(() => area.isActive = val);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Save
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: _border)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonDarkGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (!_isTest) {
                          await ApotekApiService().updateAreaLayanan({
                            'areas': _areas
                                .map((a) => {
                                      'nama_area': a.name,
                                      'detail': a.details,
                                      'is_active': a.isActive,
                                    })
                                .toList(),
                          });
                          await ApotekProfileState.instance.loadProfile();
                        }
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$activeCount area layanan berhasil diperbarui dan aktif.',
                            ),
                            backgroundColor: _darkGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Simpan Area Layanan',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
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
}

class _AreaLayananTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    GiatBackgroundPainter.paintBackground(
      canvas,
      size,
      showGradient: false,
      showLines: true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
