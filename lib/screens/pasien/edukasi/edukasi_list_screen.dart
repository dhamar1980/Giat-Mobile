import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edukasi_detail_screen.dart';
import '../../../widgets/giat_background.dart';
import '../../../services/pasien_api_service.dart';
import '../../../services/supabase_admin_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUSAT EDUKASI KESEHATAN GINJAL (ARTIKEL & TIPS NUTRISI)
// Desain Header Pill ("<- Kembali" & "Pusat Edukasi Ginjal"), Background Topografi GIAT,
// Selaras dengan Halaman Notifikasi Pasien
// ─────────────────────────────────────────────────────────────────────────────

class EdukasiListScreen extends StatefulWidget {
  const EdukasiListScreen({super.key});

  @override
  State<EdukasiListScreen> createState() => _EdukasiListScreenState();
}

class _EdukasiListScreenState extends State<EdukasiListScreen> {
  String _selectedCat = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const _darkGreen = Color(0xFF005954);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _textColor = Color(0xFF0F172A);

  // Default fallback articles matching designs and tests
  static final List<Map<String, dynamic>> _defaultArticles = [
    {
      'id': '1',
      'title': 'Kenali Tanda-Tanda Penyakit Ginjal Sejak Dini',
      'category': 'Info CKD',
      'date': '15 Sept 2026',
      'image': 'assets/images/kidneys.jpg',
      'content': 'Penyakit ginjal kronis (CKD) sering kali berkembang tanpa menimbulkan gejala yang mencolok pada tahap awal (sering disebut "silent disease"). Beberapa tanda awal meliputi perubahan frekuensi buang air kecil, urine berbusa, pembengkakan pada kaki atau wajah, serta rasa lelah yang berkepanjangan akibat penumpukan racun dalam darah.\n\nPencegahan terbaik adalah melakukan pemeriksaan rutin fungsi ginjal (tes darah kreatinin & eGFR serta tes urine protein), menjaga tekanan darah di bawah 130/80 mmHg, dan mengontrol kadar gula darah.',
    },
    {
      'id': '2',
      'title': 'Makanan & Nutrisi Sehat untuk Menjaga Fungsi Ginjal',
      'category': 'Nutrisi & Diet',
      'date': '12 Sept 2026',
      'image': 'assets/images/kidneys.jpg',
      'content': 'Bagi pasien ginjal, pola makan yang tepat sangat krusial untuk memperlambat penurunan fungsi ginjal:\n\n1. Batasi Garam (Natrium): Maksimal 1 sendok teh garam dapur per hari untuk mencegah hipertensi dan penumpukan cairan.\n2. Pilih Protein Berkualitas: Konsumsi putih telur, ikan, atau ayam tanpa lemak dalam porsi terukur.\n3. Waspadai Kalium Berlebih: Jika kadar kalium tinggi, batasi pisang, alpukat, dan bayam, lalu gantilah dengan apel, pir, atau kembang kol.\n4. Cukupi Cairan Sesuai Anjuran: Jangan kurang dan jangan berlebih.',
    },
    {
      'id': '3',
      'title': 'Pentingnya Menjaga Tekanan Darah bagi Pasien Ginjal',
      'category': 'Pola Hidup',
      'date': '10 Sept 2026',
      'image': 'assets/images/kidneys.jpg',
      'content': 'Hipertensi dan kesehatan ginjal memiliki hubungan timbal balik yang sangat erat. Tekanan darah yang tinggi dapat merusak pembuluh darah kapiler halus (glomerulus) di dalam ginjal sehingga kemampuan menyaring racun menurun drastis.\n\nPastikan untuk meminum obat antihipertensi pelindung ginjal sesuai resep dokter, kurangi stres, tidur cukup 7-8 jam, dan lakukan olahraga ringan seperti jalan santai 30 menit setiap hari.',
    },
  ];

  late List<Map<String, dynamic>> _articles;

  @override
  void initState() {
    super.initState();
    _articles = List.from(_defaultArticles);
    _loadEdukasiFromApi();
  }

  Future<void> _loadEdukasiFromApi() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final pgRows = await SupabaseAdminService.instance.fetchEdukasi();
      if (pgRows.isNotEmpty && mounted) {
        setState(() {
          _articles = pgRows.map((item) {
            return {
              'id': item['id']?.toString() ?? '',
              'title': item['judul']?.toString() ?? 'Artikel Ginjal',
              'category': item['kategori']?.toString() ?? 'Info CKD',
              'date': item['penulis']?.toString() ?? 'Tim Medis GIAT',
              'image': (item['gambar_url']?.toString().isNotEmpty ?? false)
                  ? item['gambar_url'].toString()
                  : (item['gambar']?.toString().isNotEmpty ?? false)
                      ? item['gambar'].toString()
                      : 'assets/images/kidneys.jpg',
              'content': item['konten']?.toString() ?? '',
            };
          }).toList();
        });
        return;
      }
    } catch (_) {}

    try {
      final res = await PasienApiService().getEdukasiList(kategori: _selectedCat);
      if (res.success && res.data != null && res.data!.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          final apiArticles = res.data!.map((item) {
            if (item is Map<String, dynamic>) {
              return {
                'id': item['id']?.toString() ?? '1',
                'title': item['judul']?.toString() ?? item['title']?.toString() ?? 'Artikel Ginjal',
                'category': item['kategori']?.toString() ?? item['category']?.toString() ?? 'Info CKD',
                'date': item['tanggal']?.toString() ?? item['date']?.toString() ?? 'Hari ini',
                'image': item['gambar_url']?.toString() ?? item['gambar']?.toString() ?? item['image']?.toString() ?? 'assets/images/kidneys.jpg',
                'content': item['konten']?.toString() ?? item['content']?.toString() ?? '',
              };
            }
            return <String, dynamic>{};
          }).where((m) => m.isNotEmpty).toList();
          if (apiArticles.isNotEmpty) {
            _articles = apiArticles;
          }
        });
        return;
      }
    } catch (_) {}

    if (mounted && _articles.isEmpty) {
      setState(() {
        _articles = List.from(_defaultArticles);
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _buildCardImage(String img) {
    final fallback = Container(
      color: const Color(0xFFDCFCE7),
      child: const Icon(Icons.health_and_safety_rounded, size: 48, color: _darkGreen),
    );
    if (img.startsWith('data:image/')) {
      try {
        final commaIdx = img.indexOf(',');
        final b64 = (commaIdx >= 0 ? img.substring(commaIdx + 1) : img).replaceAll(RegExp(r'\s+'), '');
        return Image.memory(
          base64Decode(b64),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }
    if (img.startsWith('http')) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Image.asset(
      img,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER BAR (Tombol "<- Kembali" di kiri atas, lalu Pill "Pusat Edukasi Ginjal" di tengah)
  // Sesuai UI pada Halaman Notifikasi Pasien
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row atas: Tombol Pill "<- Kembali" di kiri
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _textColor, width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 14, color: _textColor),
                      const SizedBox(width: 5),
                      Text(
                        'Kembali',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Centered "Pusat Edukasi Ginjal" Badge Pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8.5),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _darkGreen.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Pusat Edukasi Ginjal',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SEARCH BAR (Pill Container dengan Shadow Halus di atas Topografi)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          style: GoogleFonts.inter(fontSize: 13.5, color: _textColor),
          decoration: InputDecoration(
            hintText: 'Cari artikel kesehatan ginjal...',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CATEGORY CHIPS (Horizontal Scrollable Chips)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCategoryChips() {
    final categories = ['Semua', 'Nutrisi & Diet', 'Pola Hidup', 'Info CKD'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: categories.map((cat) {
            final isSel = _selectedCat == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat),
                selected: isSel,
                showCheckmark: false,
                selectedColor: _darkGreen,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                  color: isSel ? Colors.white : const Color(0xFF475569),
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSel ? _darkGreen : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
                elevation: isSel ? 2 : 0,
                shadowColor: _darkGreen.withValues(alpha: 0.25),
                onSelected: (_) => setState(() => _selectedCat = cat),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ARTICLE LIST
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildArticleList(List<Map<String, dynamic>> filtered) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'Artikel tidak ditemukan',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final art = filtered[i];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EdukasiDetailScreen(article: art),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Stack(
                    children: [
                      Container(
                        height: 140,
                        width: double.infinity,
                        color: const Color(0xFFE2E8F0),
                        child: _buildCardImage(art['image']?.toString() ?? 'assets/images/kidneys.jpg'),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _darkGreen,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            art['category'] ?? 'Info CKD',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        art['title'] ?? '',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.3),
                      ),
                      if (art['date'] != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              art['date'],
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _articles.where((a) {
      final matchCat = _selectedCat == 'Semua' || a['category'] == _selectedCat;
      if (!matchCat) return false;
      if (_searchQuery.isNotEmpty) {
        final title = (a['title'] ?? '').toString().toLowerCase();
        final content = (a['content'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery) || content.contains(_searchQuery);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Background Topografi Organik GIAT (Kurva Gelombang Hijau) ──
          Positioned.fill(
            child: CustomPaint(
              painter: _EdukasiTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Navigation Bar ("<- Kembali" di kiri, "Pusat Edukasi Ginjal" Pill di tengah) ──
                _buildHeaderBar(context),

                // ── Search Bar ──
                _buildSearchBar(),

                // ── Category Chips ──
                _buildCategoryChips(),

                const SizedBox(height: 6),

                // ── Daftar Artikel ──
                Expanded(
                  child: _buildArticleList(filtered),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY PAINTER (GIAT Wavy Organic Curves)
// ─────────────────────────────────────────────────────────────────────────────
class _EdukasiTopographyPainter extends CustomPainter {
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
