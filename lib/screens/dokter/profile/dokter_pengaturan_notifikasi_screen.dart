import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PENGATURAN NOTIFIKASI DOKTER (Figma Node: 1008-18622)
// ─────────────────────────────────────────────────────────────────────────────

class DokterPengaturanNotifikasiScreen extends StatefulWidget {
  const DokterPengaturanNotifikasiScreen({super.key});

  @override
  State<DokterPengaturanNotifikasiScreen> createState() => _DokterPengaturanNotifikasiScreenState();
}

class _DokterPengaturanNotifikasiScreenState extends State<DokterPengaturanNotifikasiScreen> {
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);
  static const _darkGreen = Color(0xFF065A37);

  bool _konsultasiBaru = true;
  bool _pengingatJadwal = true;
  bool _updateSistem = false;

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
          'Notifikasi',
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atur bagaimana Anda menerima pembaruan dan peringatan untuk memastikan Anda tidak melewatkan informasi pasien yang penting.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 24),

              // Switch 1: Konsultasi Baru
              _buildNotificationSwitch(
                title: 'Konsultasi Baru',
                description: 'Dapatkan notifikasi instan saat pasien meminta konsultasi baru.',
                value: _konsultasiBaru,
                onChanged: (val) => setState(() => _konsultasiBaru = val),
              ),

              const SizedBox(height: 14),

              // Switch 2: Pengingat Jadwal
              _buildNotificationSwitch(
                title: 'Pengingat Jadwal',
                description: 'Pengingat untuk janji temu mendatang, 15 menit sebelum dimulai.',
                value: _pengingatJadwal,
                onChanged: (val) => setState(() => _pengingatJadwal = val),
              ),

              const SizedBox(height: 14),

              // Switch 3: Update Sistem
              _buildNotificationSwitch(
                title: 'Update Sistem',
                description: 'Notifikasi mengenai pemeliharaan aplikasi, fitur baru, dan perubahan kebijakan.',
                value: _updateSistem,
                onChanged: (val) => setState(() => _updateSistem = val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                    fontSize: 15,
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
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeColor: _darkGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
