import 'package:giat/widgets/giat_background.dart';
import 'package:giat/widgets/giat_header_style.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'jadwalkan_konsultasi_screen.dart';
import '../../../services/storage_service.dart';
import '../../../services/konsultasi_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL PROFIL DOKTER (Sesuai Referensi UI Figma GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class DokterDetailScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final String userName;

  const DokterDetailScreen({
    super.key,
    required this.doctor,
    this.userName = 'Pasien',
  });

  @override
  State<DokterDetailScreen> createState() => _DokterDetailScreenState();
}

class _DokterDetailScreenState extends State<DokterDetailScreen> {
  static const _primaryGreen = Color(0xFF065A37);
  static const _darkGreen = Color(0xFF044E2F);
  static const _emeraldGreen = Color(0xFF10B981);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorder = Color(0xFFE2E8F0);

  int _selectedRating = 3;
  late final TextEditingController _ulasanController;

  @override
  void initState() {
    super.initState();
    _ulasanController = TextEditingController();
    _loadExistingRating();
  }

  Future<void> _loadExistingRating() async {
    final docId = widget.doctor['id']?.toString() ?? 'budi_santoso';
    final saved = await StorageService().getDoctorRating(docId);
    if (saved != null && mounted) {
      setState(() {
        if (saved['rating'] is int) {
          _selectedRating = saved['rating'] as int;
        }
        if (saved['ulasan'] != null && saved['ulasan'].toString().isNotEmpty) {
          _ulasanController.text = saved['ulasan'].toString();
        }
      });
    }
  }

  @override
  void dispose() {
    _ulasanController.dispose();
    super.dispose();
  }

  static const _defaultPhoto =
      'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=500';

  String get _doctorName {
    final name = widget.doctor['name']?.toString() ?? '';
    return name.isNotEmpty ? name : 'Dr. Budi Santoso';
  }

  String get _doctorFullNameForQuestion {
    final name = _doctorName;
    if (name.startsWith('Dr. ')) {
      return 'Dokter ${name.substring(4)}';
    } else if (name.startsWith('dr. ')) {
      return 'Dokter ${name.substring(4)}';
    } else if (!name.toLowerCase().startsWith('dokter')) {
      return 'Dokter $name';
    }
    return name;
  }

  String get _specialty {
    final s = widget.doctor['specialty']?.toString() ?? '';
    return s.isNotEmpty ? s : 'Spesialis Ginjal & Hipertensi';
  }

  String get _avatarUrl {
    final url = widget.doctor['avatarUrl']?.toString() ?? '';
    if (url.isNotEmpty && url.startsWith('http')) {
      return url;
    }
    return _defaultPhoto;
  }

  String get _rating {
    final r = widget.doctor['rating'];
    if (r != null) return r.toString();
    return '4.9';
  }

  String get _experience {
    final exp = widget.doctor['experience']?.toString() ?? '';
    if (exp.contains('15')) return '15+';
    if (exp.isNotEmpty) {
      final numbers = RegExp(r'\d+').firstMatch(exp)?.group(0);
      if (numbers != null) return '$numbers+';
    }
    return '15+';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Background Topography Lines ──
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundTopographyPainter(),
            ),
          ),

          // ── Main Content ──
          SingleChildScrollView(
            child: Column(
              children: [
                // 1. Curved Green Hero Header
                _buildCurvedHeroHeader(context),

                // 2. Body Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Informasi Penilaian
                      _buildPenilaianSection(),

                      const SizedBox(height: 16),

                      // Card: Beri Penilaian (Rating & Ulasan Dokter)
                      _buildBeriPenilaianCard(),

                      const SizedBox(height: 20),

                      // Section: Informasi Tambahan
                      _buildInformasiTambahanSection(),

                      const SizedBox(height: 20),

                      // Section: Jadwal Praktik
                      _buildJadwalPraktikSection(),

                      const SizedBox(height: 20),

                      // Section: Tentang Dokter
                      _buildTentangDokterSection(),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. CURVED GREEN HERO HEADER
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildCurvedHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: GiatHeaderStyle.backgroundGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(42),
          bottomRight: Radius.circular(42),
        ),
        child: Stack(
          children: [
            // Topography curves inside header
            Positioned.fill(
              child: CustomPaint(
                painter: _HeaderWavePainter(),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
                child: Column(
                  children: [
                    // Top Bar: [← Kembali] Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_back,
                                size: 16,
                                color: Color(0xFF0F172A),
                              ),
                              const SizedBox(width: 4),
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
                    ),

                    const SizedBox(height: 10),

                    // Doctor Avatar with ring and online dot
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 106,
                            height: 106,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                _avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFDCFCE7),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 56,
                                    color: _primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Online Status Dot (green circle with white ring)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _emeraldGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Doctor Name
                    Text(
                      _doctorName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Specialty
                    Text(
                      _specialty,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Online Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: _emeraldGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _darkGreen,
                            ),
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
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. INFORMASI PENILAIAN
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildPenilaianSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Penilaian',
          style: GoogleFonts.inter(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 1: 4.9 Ulasan Pasien
            Expanded(
              child: _buildPenilaianCard(
                iconWidget: const Icon(
                  Icons.stars_rounded,
                  size: 28,
                  color: Color(0xFF00796B),
                ),
                value: _rating,
                label: 'Ulasan Pasien',
              ),
            ),
            const SizedBox(width: 14),
            // Card 2: 15+ Tahun Pengalaman
            Expanded(
              child: _buildPenilaianCard(
                iconWidget: const Icon(
                  Icons.work_history_rounded,
                  size: 26,
                  color: Color(0xFF00796B),
                ),
                value: _experience,
                label: 'Tahun Pengalaman',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPenilaianCard({
    required Widget iconWidget,
    required String value,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Subtle wave background decoration
            Positioned(
              left: 0,
              top: 0,
              child: CustomPaint(
                size: const Size(80, 80),
                painter: _CardTopographyPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(child: iconWidget),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
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

  // ─────────────────────────────────────────────────────────────────────────────
  // 2B. CARD BERI PENILAIAN (RATING & ULASAN)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildBeriPenilaianCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Subtle wave background decoration in top-left
            Positioned(
              left: 0,
              top: 0,
              child: CustomPaint(
                size: const Size(120, 100),
                painter: _CardTopographyPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title: Beri Penilaian
                  Text(
                    'Beri Penilaian',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _darkGreen,
                      letterSpacing: -0.2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle question with doctor's name
                  Text(
                    'Bagaimana pengalaman konsultasimu dengan $_doctorFullNameForQuestion?',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F172A),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5 Star Rating Row (Interactive)
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final isFilled = index < _selectedRating;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _selectedRating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(
                              Icons.star_rounded,
                              size: 44,
                              color: isFilled
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Helper hint
                  Center(
                    child: Text(
                      'Ketuk bintang untuk menilai',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Label: Ulasan (opsional)
                  Text(
                    'Ulasan (opsional)',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Review text input
                  TextField(
                    controller: _ulasanController,
                    maxLines: 3,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ceritakan pengalamanmu...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Button: Konsultasi Sekarang
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _darkGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _onKonsultasiSekarang,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Konsultasi Sekarang',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Secondary Button: Kirim Penilaian Saja
                  Center(
                    child: TextButton.icon(
                      onPressed: _onKirimPenilaianSaja,
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: _primaryGreen,
                      ),
                      label: Text(
                        'Kirim Penilaian Saja',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _primaryGreen,
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
    );
  }

  Future<void> _onKirimPenilaianSaja() async {
    final docId = widget.doctor['id']?.toString() ?? 'budi_santoso';
    final rating = _selectedRating;
    final ulasan = _ulasanController.text.trim();

    // 1. Simpan ke local cache agar langsung tersimpan di device
    await StorageService().saveDoctorRating(
      doctorId: docId,
      rating: rating,
      ulasan: ulasan,
    );

    // 2. Simpan ke Database Supabase via KonsultasiApiService (tabel: ulasan_dokter / konsultasi)
    try {
      final res = await KonsultasiApiService().beriRatingDokter(
        doctorId: docId,
        konsultasiId: widget.doctor['konsultasi_id'] ?? widget.doctor['id_konsultasi'],
        rating: rating,
        ulasan: ulasan,
        namaPasien: widget.userName,
      );
      debugPrint('⭐ Hasil simpan rating ke Supabase: ${res.message}');
    } catch (e) {
      debugPrint('⚠️ Gagal simpan rating ke API/Supabase: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Penilaian ($rating★) dan ulasan Anda berhasil disimpan ke database!',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: _darkGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onKonsultasiSekarang() async {
    final docId = widget.doctor['id']?.toString() ?? 'budi_santoso';
    final rating = _selectedRating;
    final ulasan = _ulasanController.text.trim();

    // 1. Simpan ke local cache agar langsung tersimpan di device
    await StorageService().saveDoctorRating(
      doctorId: docId,
      rating: rating,
      ulasan: ulasan,
    );

    // 2. Simpan ke Database Supabase via KonsultasiApiService (tabel: ulasan_dokter / konsultasi)
    try {
      final res = await KonsultasiApiService().beriRatingDokter(
        doctorId: docId,
        konsultasiId: widget.doctor['konsultasi_id'] ?? widget.doctor['id_konsultasi'],
        rating: rating,
        ulasan: ulasan,
        namaPasien: widget.userName,
      );
      debugPrint('⭐ Hasil simpan rating ke Supabase: ${res.message}');
    } catch (e) {
      debugPrint('⚠️ Gagal simpan rating ke API/Supabase: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Penilaian Anda ($rating★) telah dicatat. Membuka jadwal konsultasi...',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: _darkGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    if (!mounted) return;
    final booked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JadwalkanKonsultasiScreen(
          doctor: widget.doctor,
          userName: widget.userName,
        ),
      ),
    );
    if (booked == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. INFORMASI TAMBAHAN
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildInformasiTambahanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informasi Tambahan',
          style: GoogleFonts.inter(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Row 1: Spesialisasi
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.health_and_safety_outlined,
                        color: _primaryGreen,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spesialisasi',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Penyakit Dalam, Ginjal, Hipertensi, Hemodialisis',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Row 2: Informasi Praktik
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.medical_information_outlined,
                        color: _primaryGreen,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Praktik',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Layanan Telemedice Video & Chat',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF475569),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. JADWAL PRAKTIK
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildJadwalPraktikSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: Color(0xFF0F172A),
            ),
            const SizedBox(width: 8),
            Text(
              'Jadwal Praktik',
              style: GoogleFonts.inter(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTimelineItem(
                day: 'Senin - Jumat',
                time: '09:00 - 16:00',
                isLast: false,
              ),
              _buildTimelineItem(
                day: 'Sabtu',
                time: '09:00 - 13:00',
                isLast: false,
              ),
              _buildTimelineItem(
                day: 'Senin - Jumat',
                time: 'Tutup',
                isLast: true,
                isClosed: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String day,
    required String time,
    required bool isLast,
    bool isClosed = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator (dot + line)
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _emeraldGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFF86EFAC),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Day label
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Text(
                day,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ),

          // Time slot or status
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isClosed ? FontWeight.w700 : FontWeight.w500,
                color: isClosed ? const Color(0xFFEF4444) : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. TENTANG DOKTER
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTentangDokterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 19,
              color: Color(0xFF0F172A),
            ),
            const SizedBox(width: 8),
            Text(
              'Tentang Dokter',
              style: GoogleFonts.inter(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'Dokter yang memberikan layanan konsultasi kesehatan secara daring melalui GIAT. Berkomitmen untuk memberikan penanganan medis yang akurat dan empati bagi pasien dengan gangguan ginjal dan tekanan darah tinggi.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF334155),
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }


}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS: TOPOGRAPHY & WAVES
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundTopographyPainter extends CustomPainter {
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

class _HeaderWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final yOffset = 20.0 + (i * 45);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.3,
        yOffset - 25,
        size.width * 0.7,
        yOffset + 30,
        size.width,
        yOffset - 5,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offset = i * 15.0;
      path.moveTo(0, 10 + offset);
      path.cubicTo(
        size.width * 0.4,
        offset - 5,
        size.width * 0.6,
        offset + 25,
        size.width,
        offset + 10,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
