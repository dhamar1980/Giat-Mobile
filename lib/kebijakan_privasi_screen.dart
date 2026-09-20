import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/giat_auth_background.dart';

/// Halaman Kebijakan Privasi (Figma Node: 1018:6155)
class KebijakanPrivasiScreen extends StatelessWidget {
  const KebijakanPrivasiScreen({super.key});

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

                      // Badge Kebijakan Privasi
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
                            'Kebijakan Privasi',
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

                // ── Kartu Hijau Lengkung (Isi Kebijakan Privasi) ──
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

                          // Scrollable Privacy Content
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kebijakan Privasi GIAT',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Terakhir diperbarui: 24 September 2026',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Kami di GIAT berkomitmen penuh melindungi kerahasiaan dan keamanan data pribadi serta informasi medis Anda sesuai standar privasi kesehatan tertinggi.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                _buildSection(
                                  '1. Informasi yang Kami Kumpulkan',
                                  null,
                                  subsections: [
                                    _buildSubSection(
                                      '1.1 Data Identitas Akun',
                                      'Kami mengumpulkan informasi pendaftaran dasar seperti nama, email, nomor telepon, dan tanggal lahir untuk membuat dan mengelola akun Anda.',
                                    ),
                                    _buildSubSection(
                                      '1.2 Data Kesehatan',
                                      'Informasi medis yang Anda unggah, riwayat gejala, tingkat GFR, tekanan darah, dan catatan laboratorium lainnya dicatat untuk keperluan pemantauan medis.',
                                    ),
                                    _buildSubSection(
                                      '1.3 Data Aktivitas',
                                      'Kami dapat mencatat aktivitas penggunaan aplikasi untuk peningkatan layanan dan keamanan sistem.',
                                    ),
                                    _buildSubSection(
                                      '1.4 Data Tenaga Kesehatan',
                                      'Informasi profesional bagi tenaga medis yang diverifikasi untuk praktik telemedis.',
                                    ),
                                  ],
                                ),
                                _buildSection(
                                  '2. Penggunaan Informasi',
                                  'Informasi yang dikumpulkan digunakan semata-mata untuk menyediakan layanan telemedis, memfasilitasi komunikasi dokter-pasien, dan personalisasi pemantauan kesehatan ginjal Anda.',
                                ),
                                _buildSection(
                                  '3. Data Kesehatan',
                                  'Data kesehatan Anda diperlakukan dengan standar keamanan dan privasi tertinggi. Data ini hanya dibagikan kepada tenaga kesehatan dengan persetujuan eksplisit Anda.',
                                ),
                                _buildSection(
                                  '4. Data Konsultasi dan Layanan Kesehatan',
                                  'Catatan percakapan, resep, dan ringkasan telekonsultasi dienkripsi dan disimpan secara terpusat. Informasi ini hanya dapat diakses oleh Anda dan tenaga medis yang menangani.',
                                ),
                                _buildSection(
                                  '5. Data Tenaga Kesehatan',
                                  'Proses registrasi dan verifikasi kredensial medis untuk tenaga kesehatan dilakukan secara manual dan aman. Pertanyaan dapat diajukan via email ke support@giathealth.id.',
                                ),
                                _buildSection(
                                  '6. Penggunaan Fitur AI PRAGI',
                                  'Penting! Fitur AI PRAGI berfungsi sebagai asisten informasi belaka. Layanan ini bukan merupakan diagnosis medis profesional. Keputusan medis tetap merupakan kewenangan penuh dokter bersertifikat.',
                                ),
                                _buildSection(
                                  '7. Penyimpanan dan Keamanan Data',
                                  'GIAT menggunakan enkripsi standar industri dan penyimpanan cloud aman (AES-256) untuk melindungi data pribadi dan medis pengguna dari akses yang tidak sah.',
                                ),
                                _buildSection(
                                  '8. Berbagi Informasi',
                                  'Kami menerapkan kontrol akses berbasis peran. Informasi tidak dibagikan dengan pihak ketiga (seperti pengiklan), melainkan terbatas antara Anda, sistem kami, dan tenaga kesehatan pilihan Anda.',
                                ),
                                _buildSection(
                                  '9. Hak dan Pilihan Pengguna',
                                  'Anda memiliki hak untuk melihat, memperbarui, atau meminta penghapusan permanen dari rekam medis dan data akun Anda melalui pengaturan aplikasi.',
                                ),
                                _buildSection(
                                  '10. Cookies dan Teknologi Serupa',
                                  'Aplikasi menggunakan token sesi autentikasi alih-alih cookies konvensional guna menjamin keamanan tinggi untuk interaksi mobile Anda.',
                                ),
                                _buildSection(
                                  '11. Perubahan Kebijakan Privasi',
                                  'Kami dapat memperbarui kebijakan ini secara berkala. Pengguna akan diberitahu terkait perubahan material melalui notifikasi dalam aplikasi setidaknya 30 hari sebelumnya.',
                                ),
                                _buildSection(
                                  '12. Hubungi Kami',
                                  'Jika Anda memiliki pertanyaan mengenai praktik privasi kami, silakan hubungi privacy@giathealth.id.',
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
