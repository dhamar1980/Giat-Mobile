import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RIWAYAT PERANGKAT / SESI AKTIF (Figma Node: 1008-18892 / Screenshot 3)
// ─────────────────────────────────────────────────────────────────────────────

class DokterRiwayatPerangkatScreen extends StatefulWidget {
  const DokterRiwayatPerangkatScreen({super.key});

  @override
  State<DokterRiwayatPerangkatScreen> createState() => _DokterRiwayatPerangkatScreenState();
}

class _DokterRiwayatPerangkatScreenState extends State<DokterRiwayatPerangkatScreen> {
  static const _darkGreen = Color(0xFF044E2F);
  static const _redAlert = Color(0xFFB91C1C);
  static const _border = Color(0xFFE2E8F0);

  late List<DokterDeviceSession> _devices;

  @override
  void initState() {
    super.initState();
    _devices = List.from(DokterMockData.devices);
  }

  void _removeDevice(String id, String deviceName) {
    setState(() {
      _devices.removeWhere((d) => d.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$deviceName berhasil dikeluarkan dari sesi.',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _redAlert,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDevice = _devices.firstWhere(
      (d) => d.isCurrent,
      orElse: () => const DokterDeviceSession(
        id: 'dev-1',
        deviceName: 'Smartphoone Android',
        lastActive: 'Terakhir aktif hari ini, 18:42 WIB',
        location: 'Lokasi: Indonesia',
        isCurrent: true,
      ),
    );
    final otherDevices = _devices.where((d) => !d.isCurrent).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: Stack(
        children: [
          // Background Topography
          Positioned.fill(
            child: CustomPaint(
              painter: _RiwayatTopographyPainter(),
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

                  // ── Pill Title: Riwayat Perangkat (Screenshot 3) ──
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
                        'Riwayat Perangkat',
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

                  // ── Red Info Alert Row (Screenshot 3) ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info,
                        color: _redAlert,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Daftar perangkat yang saat ini sedang masuk ke akun GIAT Anda. Kelola atau keluarkan sesi yang tidak dikenali demi keamanan data klinis.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _redAlert,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Section 1: Perangkat Ini ──
                  Text(
                    'Perangkat Ini',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildDeviceCard(
                    device: currentDevice,
                    onKeluarkan: () => _removeDevice(currentDevice.id, currentDevice.deviceName),
                  ),

                  const SizedBox(height: 24),

                  // ── Section 2: Sesi Lainnya ──
                  Text(
                    'Sesi Lainnya',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (otherDevices.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Center(
                        child: Text(
                          'Tidak ada sesi perangkat lain yang aktif.',
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    ...otherDevices.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildDeviceCard(
                            device: d,
                            onKeluarkan: () => _removeDevice(d.id, d.deviceName),
                          ),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard({
    required DokterDeviceSession device,
    required VoidCallback onKeluarkan,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Light Cyan/Blue Square Icon Container
              Container(
                width: 60,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0E6ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(
                    Icons.phone_android_rounded,
                    color: Color(0xFF0F172A),
                    size: 28,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Device Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13.5,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            device.lastActive,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.location,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Red "Keluarkan Perangkat" Button (Screenshot 3)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _redAlert,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onKeluarkan,
              child: Text(
                'Keluarkan Perangkat',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiwayatTopographyPainter extends CustomPainter {
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

