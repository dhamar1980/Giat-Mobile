import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import 'dokter_detail_pasien_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DAFTAR PASIEN DOKTER (Figma Node: 1008-18310)
// ─────────────────────────────────────────────────────────────────────────────

class DokterPasienScreen extends StatefulWidget {
  const DokterPasienScreen({super.key});

  @override
  State<DokterPasienScreen> createState() => _DokterPasienScreenState();
}

class _DokterPasienScreenState extends State<DokterPasienScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DokterPatient> _getFilteredPatients() {
    final list = DokterMockData.patients;
    if (_searchQuery.trim().isEmpty) return list;
    return list.where((p) {
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.gender.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openPatientDetail(DokterPatient patient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DokterDetailPasienScreen(patient: patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredPatients();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Daftar Pasien',
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
        child: Column(
          children: [
            // Search Bar Container
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Cari Pasien...',
                    hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            // Patient Cards List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada pasien ditemukan.',
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        return _buildPatientListItem(p);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientListItem(DokterPatient p) {
    return GestureDetector(
      onTap: () => _openPatientDetail(p),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  p.initials,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _darkGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.age} Tahun  •  ${p.gender}',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
