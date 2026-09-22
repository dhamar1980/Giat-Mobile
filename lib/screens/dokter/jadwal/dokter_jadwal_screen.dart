import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import '../konsultasi/dokter_room_chat_screen.dart';
import '../pasien/dokter_detail_pasien_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// JADWAL PRAKTIK & PASIEN DOKTER (Figma Node: 1008-18439)
// ─────────────────────────────────────────────────────────────────────────────

class DokterJadwalScreen extends StatefulWidget {
  const DokterJadwalScreen({super.key});

  @override
  State<DokterJadwalScreen> createState() => _DokterJadwalScreenState();
}

class _DokterJadwalScreenState extends State<DokterJadwalScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  int _selectedDayIndex = 0;
  final List<String> _days = [
    'Senin, 01 Agu',
    'Selasa, 02 Agu',
    'Rabu, 03 Agu',
    'Kamis, 04 Agu',
    'Jumat, 05 Agu',
    'Sabtu, 06 Agu',
  ];

  DokterPatient _findPatient(String patientId) {
    return DokterMockData.patients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => DokterMockData.patients.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedules = DokterMockData.schedules;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Jadwal Pasien',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary Card: Jumlah Konsultasi Hari Ini ──
              _buildSummaryBanner(),

              const SizedBox(height: 22),

              // ── Date Selector ──
              Text(
                'Pilih Tanggal',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_days.length, (idx) {
                    final isSelected = _selectedDayIndex == idx;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDayIndex = idx),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? _darkGreen : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? _darkGreen : _border),
                          boxShadow: isSelected
                              ? [BoxShadow(color: _darkGreen.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]
                              : null,
                        ),
                        child: Text(
                          _days[idx],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // ── Schedule Timeline Cards ──
              ...schedules.map((sch) => _buildScheduleCard(sch)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065A37), Color(0xFF0B7D4E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF065A37).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Jumlah Konsultasi Hari Ini',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '04',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMiniCounter('Selesai', '02', const Color(0xFFDCFCE7), const Color(0xFF15803D)),
              const SizedBox(width: 8),
              _buildMiniCounter('Berlangsung', '01', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
              const SizedBox(width: 8),
              _buildMiniCounter('Mendatang', '01', const Color(0xFFE0E7FF), const Color(0xFF4338CA)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCounter(String label, String count, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.85)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(DokterScheduleItem sch) {
    Color badgeColor;
    Color badgeBg;
    if (sch.status == 'Selesai') {
      badgeBg = const Color(0xFFF1F5F9);
      badgeColor = const Color(0xFF64748B);
    } else if (sch.status == 'Aktif') {
      badgeBg = const Color(0xFFDCFCE7);
      badgeColor = const Color(0xFF15803D);
    } else {
      badgeBg = const Color(0xFFE0E7FF);
      badgeColor = const Color(0xFF4338CA);
    }

    final isAktif = sch.status == 'Aktif';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time column
          Column(
            children: [
              Text(
                sch.time,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'WIB',
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Vertical divider line
          Container(
            width: 2,
            height: 48,
            color: isAktif ? _darkGreen : const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 14),
          // Patient info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sch.patientName,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sch.status,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        sch.serviceType,
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action button
          if (isAktif)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonDarkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () {
                final patient = _findPatient(sch.patientId);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DokterRoomChatScreen(patient: patient)),
                );
              },
              child: Text('Mulai Chat', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            )
          else
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final patient = _findPatient(sch.patientId);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => DokterDetailPasienScreen(patient: patient)),
                );
              },
              child: Text('Detail', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
