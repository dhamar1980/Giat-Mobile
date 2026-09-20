import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/giat_auth_background.dart';

/// Halaman Syarat & Ketentuan (Figma Node: 1018:6059)
class SyaratKetentuanScreen extends StatelessWidget {
  const SyaratKetentuanScreen({super.key});

  static const _darkGreen = Color(0xFF044E2F);
  static const _cardGradientTop = Color(0xFF22B062);
  static const _cardGradientMid = Color(0xFF16964F);
  static const _cardGradientBot = Color(0xFF09522C);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      body: Stack(
        children: [
          // ── Background Gelombang Tetap Diam ──
          Positioned(
            top: 0,
            left: 0,
            width: screenSize.width,
            height: screenSize.height,
            child: GiatAuthBackground(
              screenSize: screenSize,
              showBottomWaves: false,
              baseColor: const Color(0xFFF7F9FF),
            ),
          ),

          // ── Layout Konten ──
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Header Bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tombol Kembali
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _darkGreen, width: 1.5),
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
                              const Icon(Icons.arrow_back, size: 15, color: Color(0xFF0F172A)),
                              const SizedBox(width: 5),
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

                      const SizedBox(height: 12),

                      // Badge Syarat & Ketentuan
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9.5),
                          decoration: BoxDecoration(
                            color: _darkGreen,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: _darkGreen.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'Syarat & Ketentuan',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Kartu Hijau Lengkung (Isi Syarat & Ketentuan) ──
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _cardGradientTop,
                          _cardGradientMid,
                          _cardGradientBot,
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 20,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                      child: Stack(
                        children: [
                          // Gelombang kontur bawah kartu
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GiatCardBottomWavePainter(
                                screenHeight: screenSize.height,
                              ),
                            ),
                          ),

                          // Scrollable Terms Content
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Syarat & Ketentuan Penggunaan Layanan GIAT',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Selamat datang di GIAT. Syarat & Ketentuan ini mengatur penggunaan aplikasi dan layanan GIAT.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                _buildSection(
                                  '1. Ketentuan Umum',
                                  'GIAT adalah platform telemedicine yang berfokus pada manajemen kesehatan ginjal. Dengan menggunakan aplikasi ini, Anda setuju untuk terikat dengan seluruh syarat dan ketentuan yang berlaku.',
                                ),
                                _buildSection(
                                  '2. Akun Pengguna',
                                  null,
                                  subsections: [
                                    _buildSubSection(
                                      '2.1 Akun Pasien',
                                      'Pasien dapat melakukan pendaftaran secara mandiri melalui aplikasi. Pengguna bertanggung jawab penuh atas keakuratan data dan keamanan informasi akun yang didaftarkan.',
                                    ),
                                    _buildSubSection(
                                      '2.2 Akun Tenaga Kesehatan',
                                      'Dokter dan Apoteker tidak dapat melakukan pendaftaran mandiri. Permohonan pembuatan akun harus diajukan melalui email resmi GIAT dengan melampirkan dokumen verifikasi profesi yang sah.',
                                    ),
                                    _buildSubSection(
                                      '2.3 Verifikasi Akun Tenaga Kesehatan',
                                      'GIAT akan melakukan proses verifikasi identitas dan kredensial profesional sebelum melakukan aktivasi akun tenaga kesehatan untuk menjamin keamanan layanan.',
                                    ),
                                  ],
                                ),
                                _buildSection(
                                  '3. Penggunaan Layanan',
                                  'Layanan GIAT mencakup akses ke konsultasi tenaga medis, pemantauan indikator kesehatan, serta pengingat jadwal pengobatan dan aktivitas.',
                                ),
                                _buildSection(
                                  '4. Konsultasi Kesehatan',
                                  'Konsultasi yang diberikan bersifat dukungan dan tidak menggantikan perawatan medis darurat. Dalam kondisi darurat, segera cari pertolongan medis melalui fasilitas kesehatan terdekat atau layanan darurat yang tersedia.',
                                ),
                                _buildSection(
                                  '5. Informasi Kesehatan',
                                  'Pengguna bertanggung jawab penuh atas keakuratan data kesehatan yang dimasukkan ke dalam aplikasi untuk keperluan pemantauan dan konsultasi.',
                                ),
                                _buildSection(
                                  '6. Layanan AI (PRAGI)',
                                  'Informasi yang diberikan oleh fitur AI merupakan bantuan informasi dan bukan pengganti diagnosis atau keputusan medis dari tenaga kesehatan. Selalu konsultasikan kondisi Anda dengan dokter profesional.',
                                ),
                                _buildSection(
                                  '7. Privasi dan Data Pengguna',
                                  'Kami berkomitmen melindungi data pribadi Anda. Informasi lebih lanjut dapat dilihat pada Kebijakan Privasi kami.',
                                ),
                                _buildSection(
                                  '8. Perubahan Ketentuan',
                                  'GIAT berhak untuk mengubah Syarat & Ketentuan ini kapan saja. Perubahan akan diberitahukan melalui aplikasi atau email terdaftar.',
                                ),
                                _buildSection(
                                  '9. Hubungi Kami',
                                  'Jika Anda memiliki pertanyaan terkait Syarat & Ketentuan ini, silakan hubungi Kontak GIAT di support@giathealth.id.',
                                ),

                                const SizedBox(height: 28),

                                // Tombol Selesai
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _darkGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      'Selesai',
                                      style: GoogleFonts.inter(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildSection(String title, String? content, {List<Widget>? subsections}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (content != null) ...[
            const SizedBox(height: 6),
            Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.45,
              ),
            ),
          ],
          ...?subsections,
        ],
      ),
    );
  }

  Widget _buildSubSection(String subTitle, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subTitle,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
