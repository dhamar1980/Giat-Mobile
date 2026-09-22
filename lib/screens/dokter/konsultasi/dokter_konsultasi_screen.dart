import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import 'dokter_room_chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DAFTAR KONSULTASI DOKTER (Figma Node: 1008-17795, 1008-18178, 1008-17934)
// ─────────────────────────────────────────────────────────────────────────────

class DokterKonsultasiScreen extends StatefulWidget {
  const DokterKonsultasiScreen({super.key});

  @override
  State<DokterKonsultasiScreen> createState() => _DokterKonsultasiScreenState();
}

class _DokterKonsultasiScreenState extends State<DokterKonsultasiScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  int _selectedFilterIndex = 0; // 0: Semua, 1: Terjadwal, 2: Selesai
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DokterConsultation> _getFilteredConsultations() {
    final list = DokterMockData.consultations.where((item) {
      if (_selectedFilterIndex == 1) {
        return item.status == KonsultasiStatus.terjadwal;
      } else if (_selectedFilterIndex == 2) {
        return item.status == KonsultasiStatus.selesai;
      }
      return true;
    }).toList();

    if (_searchQuery.trim().isEmpty) return list;

    return list.where((item) {
      return item.patientName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  DokterPatient _findPatient(String patientId) {
    return DokterMockData.patients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => DokterMockData.patients.first,
    );
  }

  void _openChat(DokterConsultation item) {
    final patient = _findPatient(item.patientId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DokterRoomChatScreen(
          patient: patient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredConsultations();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Daftar Konsultasi',
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
            // Search Bar & Filter Tabs
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              color: Colors.white,
              child: Column(
                children: [
                  // Search TextField
                  Container(
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

                  const SizedBox(height: 14),

                  // Segmented Tabs: Semua, Terjadwal, Selesai
                  Row(
                    children: [
                      _buildTabItem(0, 'Semua'),
                      const SizedBox(width: 8),
                      _buildTabItem(1, 'Terjadwal'),
                      const SizedBox(width: 8),
                      _buildTabItem(2, 'Selesai'),
                    ],
                  ),
                ],
              ),
            ),

            // Consultation List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 10),
                          Text(
                            'Tidak ada konsultasi ditemukan.',
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildConsultationCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? _darkGreen : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationCard(DokterConsultation item) {
    String badgeText;
    Color badgeBg;
    Color badgeColor;
    String buttonText;
    bool isCompleted = item.status == KonsultasiStatus.selesai;

    switch (item.status) {
      case KonsultasiStatus.berlangsung:
        badgeText = 'Sedang Berlangsung';
        badgeBg = const Color(0xFFDCFCE7);
        badgeColor = const Color(0xFF15803D);
        buttonText = 'Mulai Chat';
        break;
      case KonsultasiStatus.terjadwal:
        badgeText = 'Terjadwal';
        badgeBg = const Color(0xFFFEF3C7);
        badgeColor = const Color(0xFFB45309);
        buttonText = 'Mulai Chat';
        break;
      case KonsultasiStatus.selesai:
        badgeText = 'Sudah Selesai';
        badgeBg = const Color(0xFFF1F5F9);
        badgeColor = const Color(0xFF64748B);
        buttonText = 'Lihat Riwayat Chat';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    item.initials,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: _darkGreen,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.patientName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Waktu Konsultasi: ${item.scheduledTimeText}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),

          if (item.messageCount > 0 && !isCompleted) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: _darkGreen),
                const SizedBox(width: 6),
                Text(
                  '${item.messageCount} Pesan',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _darkGreen),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: isCompleted
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _openChat(item),
                    child: Text(buttonText, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonDarkGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _openChat(item),
                    child: Text(buttonText, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ),
    );
  }
}
