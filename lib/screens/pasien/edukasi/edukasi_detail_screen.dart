import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL BACAAN ARTIKEL EDUKASI GINJAL
// ─────────────────────────────────────────────────────────────────────────────

class EdukasiDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;

  const EdukasiDetailScreen({super.key, required this.article});

  static const _darkGreen = Color(0xFF065A37);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded, color: _darkGreen),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Artikel disimpan ke daftar bacaan! 🔖')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: _darkGreen),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membagikan tautan artikel...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            Container(
              height: 220,
              width: double.infinity,
              color: const Color(0xFFE2E8F0),
              child: Image.asset(
                article['image'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFDCFCE7),
                  child: const Center(
                    child: Icon(Icons.health_and_safety_rounded, size: 64, color: _darkGreen),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge & Read Time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article['category'],
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _darkGreen),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '•  ${article['readTime']}',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    article['title'],
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Author & Date
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded, size: 20, color: _darkGreen),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article['author'],
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                          ),
                          Text(
                            article['date'],
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // Article Content
                  Text(
                    article['content'],
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      color: const Color(0xFF334155),
                      height: 1.7,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tips Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, color: _darkGreen, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pesan PRAGI untuk Anda:',
                                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: _darkGreen),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Selalu diskusikan perubahan pola makan atau asupan suplemen dengan Dokter Anda sebelum memulainya.',
                                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF166534), height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}
