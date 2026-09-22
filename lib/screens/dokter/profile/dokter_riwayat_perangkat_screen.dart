import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RIWAYAT PERANGKAT / SESI AKTIF (Figma Node: 1008-18892)
// ─────────────────────────────────────────────────────────────────────────────

class DokterRiwayatPerangkatScreen extends StatefulWidget {
  const DokterRiwayatPerangkatScreen({super.key});

  @override
  State<DokterRiwayatPerangkatScreen> createState() => _DokterRiwayatPerangkatScreenState();
}

class _DokterRiwayatPerangkatScreenState extends State<DokterRiwayatPerangkatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  late List<DokterDeviceSession> _devices;

  @override
  void initState() {
    super.initState();
    _devices = List.from(DokterMockData.devices);
  }

  void _removeDevice(String id) {
    setState(() {
      _devices.removeWhere((d) => d.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perangkat berhasil dikeluarkan dari sesi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDevice = _devices.firstWhere((d) => d.isCurrent, orElse: () => _devices.first);
    final otherDevices = _devices.where((d) => !d.isCurrent).toList();

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
          'Riwayat Perangkat',
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
              Text(
                'Daftar perangkat yang saat ini sedang masuk ke akun GIAT Anda. Kelola atau keluarkan sesi yang tidak dikenali demi keamanan data klinis.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 24),

              // ── Perangkat Ini ──
              Text(
                'Perangkat Ini',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF10B981).withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.phone_android_rounded, color: _darkGreen, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                currentDevice.deviceName,
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Aktif Sekarang',
                                  style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: _darkGreen),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentDevice.lastActive,
                            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentDevice.location,
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Sesi Lainnya ──
              Text(
                'Sesi Lainnya',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

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
                ...otherDevices.map((d) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.laptop_chromebook_rounded, color: Color(0xFF475569), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.deviceName,
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      d.lastActive,
                                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      d.location,
                                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFECACA)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _removeDevice(d.id),
                              child: Text(
                                'Keluarkan Perangkat',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
