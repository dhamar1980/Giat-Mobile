import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edukasi_detail_screen.dart';

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
  static const _darkGreen = Color(0xFF065A37);

  final List<Map<String, dynamic>> _articles = [
    {
      'id': '1',
      'title': 'Kenali Tanda-Tanda Penyakit Ginjal Sejak Dini',
      'category': 'Info CKD',
      'readTime': '4 mnt baca',
      'author': 'Tim Dokter GIAT',
      'date': '15 Sept 2026',
      'image': 'assets/images/kidneys.jpg',
      'content': 'Penyakit ginjal kronis (CKD) sering kali berkembang tanpa menimbulkan gejala yang mencolok pada tahap awal (sering disebut "silent disease"). Beberapa tanda awal meliputi perubahan frekuensi buang air kecil, urine berbusa, pembengkakan pada kaki atau wajah, serta rasa lelah yang berkepanjangan akibat penumpukan racun dalam darah.\n\nPencegahan terbaik adalah melakukan pemeriksaan rutin fungsi ginjal (tes darah kreatinin & eGFR serta tes urine protein), menjaga tekanan darah di bawah 130/80 mmHg, dan mengontrol kadar gula darah.',
    },
    {
      'id': '2',
      'title': 'Makanan & Nutrisi Sehat untuk Menjaga Fungsi Ginjal',
      'category': 'Nutrisi & Diet',
      'readTime': '5 mnt baca',
      'author': 'dr. Hendra Setiawan, Sp.GK',
      'date': '12 Sept 2026',
      'image': 'assets/images/kidneys.jpg',
      'content': 'Bagi pasien ginjal, pola makan yang tepat sangat krusial untuk memperlambat penurunan fungsi ginjal:\n\n1. Batasi Garam (Natrium): Maksimal 1 sendok teh garam dapur per hari untuk mencegah hipertensi dan penumpukan cairan.\n2. Pilih Protein Berkualitas: Konsumsi putih telur, ikan, atau ayam tanpa lemak dalam porsi terukur.\n3. Waspadai Kalium Berlebih: Jika kadar kalium tinggi, batasi pisang, alpukat, dan bayam, lalu gantilah dengan apel, pir, atau kembang kol.\n4. Cukupi Cairan Sesuai Anjuran: Jangan kurang dan jangan berlebih.',
    },
    {
      'id': '3',
      'title': 'Pentingnya Menjaga Tekanan Darah bagi Pasien Ginjal',
      'category': 'Pola Hidup',
      'readTime': '3 mnt baca',
      'author': 'Dr. Andi Pratama, Sp.PD-KGH',
      'date': '10 Sept 2026',
      'image': 'assets/images/kidneys.jpg',
      'content': 'Hipertensi dan kesehatan ginjal memiliki hubungan timbal balik yang sangat erat. Tekanan darah yang tinggi dapat merusak pembuluh darah kapiler halus (glomerulus) di dalam ginjal sehingga kemampuan menyaring racun menurun drastis.\n\nPastikan untuk meminum obat antihipertensi pelindung ginjal sesuai resep dokter, kurangi stres, tidur cukup 7-8 jam, dan lakukan olahraga ringan seperti jalan santai 30 menit setiap hari.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _articles.where((a) {
      return _selectedCat == 'Semua' || a['category'] == _selectedCat;
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
                      selectedColor: _darkGreen,
                      labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isSel ? Colors.white : const Color(0xFF475569)),
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
            child: ListView.builder(
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
                                child: Image.asset(
                                  art['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: const Color(0xFFDCFCE7),
                                    child: const Icon(Icons.health_and_safety_rounded, size: 48, color: _darkGreen),
                                  ),
                                ),
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
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(art['readTime'], style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(art['author'], style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                                ],
                              ),
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
