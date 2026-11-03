import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edukasi_detail_screen.dart';
import '../../../services/pasien_api_service.dart';
import '../../../services/supabase_admin_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUSAT EDUKASI KESEHATAN GINJAL (ARTIKEL & TIPS NUTRISI)
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
  static const _darkGreen = Color(0xFF065A37);

  List<Map<String, dynamic>> _articles = [];

  @override
  void initState() {
    super.initState();
    _loadEdukasiFromApi();
  }

  Future<void> _loadEdukasiFromApi() async {
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
                  : 'assets/images/kidneys.jpg',
              'content': item['konten']?.toString() ?? '',
            };
          }).toList();
        });
        return;
      }
    } catch (_) {}

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
        final b64 = commaIdx >= 0 ? img.substring(commaIdx + 1) : img;
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
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pusat Edukasi Ginjal',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
              ),
            ),
          ),

          // Category Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['Semua', 'Nutrisi & Diet', 'Pola Hidup', 'Info CKD'].map((cat) {
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
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide.none,
                      onSelected: (_) => setState(() => _selectedCat = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Article List
          Expanded(
            child: filtered.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
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
                                  ),
                                  child: Text(
                                    art['category'],
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
                                art['title'],
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
            ),
          ),
        ],
      ),
    );
  }
}
