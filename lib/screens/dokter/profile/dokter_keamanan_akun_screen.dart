import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dokter_ganti_kata_sandi_screen.dart';
import 'dokter_riwayat_perangkat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KEAMANAN AKUN DOKTER (Figma Node: 1008-18720)
// ─────────────────────────────────────────────────────────────────────────────

class DokterKeamananAkunScreen extends StatelessWidget {
  const DokterKeamananAkunScreen({super.key});

  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);
  static const _darkGreen = Color(0xFF065A37);

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
          'Keamanan Akun',
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
              // ── Menu 1: Ubah Kata Sandi ──
              _buildSecurityTile(
                context: context,
                icon: Icons.lock_outline_rounded,
                title: 'Ubah Kata Sandi',
                subtitle: 'Perbarui kredensial akses Anda secara berkala untuk keamanan.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DokterGantiKataSandiScreen()),
                  );
                },
              ),

              const SizedBox(height: 14),

              // ── Menu 2: Sesi Aktif ──
              _buildSecurityTile(
                context: context,
                icon: Icons.devices_other_rounded,
                title: 'Sesi Aktif',
                subtitle: 'Kelola perangkat yang saat ini masuk ke akun Anda.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DokterRiwayatPerangkatScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _darkGreen, size: 22),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
          ],
        ),
      ),
    );
  }
}
