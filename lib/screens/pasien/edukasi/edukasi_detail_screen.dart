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
                  // Badge & Date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          article['category'] ?? 'Edukasi',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _darkGreen),
                        ),
                      ),
                      if (article['date'] != null) ...[
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 5),
                            Text(
                              article['date'],
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Title
                  Text(
                    article['title'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 16),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
