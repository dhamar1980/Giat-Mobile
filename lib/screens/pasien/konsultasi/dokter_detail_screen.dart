import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'konsultasi_chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL DOKTER & JADWAL KONSULTASI
// ─────────────────────────────────────────────────────────────────────────────

class DokterDetailScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DokterDetailScreen({super.key, required this.doctor});

  @override
  State<DokterDetailScreen> createState() => _DokterDetailScreenState();
}

class _DokterDetailScreenState extends State<DokterDetailScreen> {
  int _selectedSlot = 0;
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonGreen = Color(0xFF044E2F);

  final List<String> _slots = [
    'Hari ini, 14:00 WIB',
    'Hari ini, 16:30 WIB',
    'Besok, 09:00 WIB',
    'Besok, 13:00 WIB',
  ];

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;

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
          'Profil Dokter',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.person_rounded, size: 48, color: _darkGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc['name'],
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          doc['specialty'],
                          style: GoogleFonts.inter(fontSize: 12.5, color: _darkGreen, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc['hospital'],
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Statistics Row
            Row(
              children: [
                _buildStatBox('Pasien', '1.200+', Icons.people_outline_rounded),
                const SizedBox(width: 12),
                _buildStatBox('Pengalaman', doc['experience'], Icons.work_outline_rounded),
                const SizedBox(width: 12),
                _buildStatBox('Rating', '${doc['rating']} ⭐', Icons.star_outline_rounded),
              ],
            ),

            const SizedBox(height: 22),

            // Tentang Dokter
            Text(
              'Tentang Dokter',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              'Berpengalaman dalam menangani pencegahan, diagnosis, serta manajemen terapi penyakit ginjal kronis (CKD), hipertensi ginjal, dan penyesuaian asupan gizi medis pasien.',
              style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF475569), height: 1.5),
            ),

            const SizedBox(height: 22),

            // Pilih Jadwal Konsultasi
            Text(
              'Pilih Jadwal Sesi',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_slots.length, (i) {
                final isSel = _selectedSlot == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSlot = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? _buttonGreen : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSel ? _buttonGreen : const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      _slots[i],
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biaya Konsultasi',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
                Text(
                  doc['fee'],
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: _buttonGreen),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KonsultasiChatScreen(doctorName: doc['name']),
                    ),
                  );
                },
                child: Text('Mulai Chat Sekarang', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _darkGreen, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
