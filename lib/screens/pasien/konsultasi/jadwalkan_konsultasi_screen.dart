import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../profile/profile_pasien_screen.dart';
import 'pembayaran_konsultasi_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN JADWALKAN KONSULTASI BARU (Sesuai Referensi UI GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class JadwalkanKonsultasiScreen extends StatefulWidget {
  final Map<String, dynamic>? doctor;
  final String userName;

  const JadwalkanKonsultasiScreen({
    super.key,
    this.doctor,
    this.userName = 'Pasien',
  });

  @override
  State<JadwalkanKonsultasiScreen> createState() => _JadwalkanKonsultasiScreenState();
}

class _JadwalkanKonsultasiScreenState extends State<JadwalkanKonsultasiScreen> {
  static const _darkGreen = Color(0xFF044E2F);
  static const _primaryGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF7FAF8);
  static const _cardBorderColor = Color(0xFFE2E8F0);

  int _selectedDateIndex = 0;
  String _selectedTime = '14.00';

  final List<Map<String, dynamic>> _dateList = [
    {'day': 'Senin', 'date': '01 Agu', 'fullDate': 'Senin, 01 Agustus 2026', 'isFull': false},
    {'day': 'Selasa', 'date': '02 Agu', 'fullDate': 'Selasa, 02 Agustus 2026', 'isFull': true},
    {'day': 'Rabu', 'date': '03 Agu', 'fullDate': 'Rabu, 03 Agustus 2026', 'isFull': false},
    {'day': 'Kamis', 'date': '04 Agu', 'fullDate': 'Kamis, 04 Agustus 2026', 'isFull': false},
    {'day': 'Jumat', 'date': '05 Agu', 'fullDate': 'Jumat, 05 Agustus 2026', 'isFull': false},
    {'day': 'Sabtu', 'date': '06 Agu', 'fullDate': 'Sabtu, 06 Agustus 2026', 'isFull': false},
  ];

  final List<Map<String, dynamic>> _timeSlots = [
    {'time': '09.00', 'isAvailable': false, 'status': 'Penuh'},
    {'time': '10.00', 'isAvailable': true, 'status': 'Tersedia'},
    {'time': '11.00', 'isAvailable': false, 'status': 'Penuh'},
    {'time': '13.00', 'isAvailable': true, 'status': 'Tersedia'},
    {'time': '14.00', 'isAvailable': true, 'status': 'Dipilih'},
    {'time': '15.00', 'isAvailable': true, 'status': 'Tersedia'},
    {'time': '16.00', 'isAvailable': true, 'status': 'Tersedia'},
  ];

  String _formatTimeRange(String startTime) {
    final parts = startTime.split('.');
    if (parts.length == 2) {
      int hour = int.tryParse(parts[0]) ?? 14;
      int minute = int.tryParse(parts[1]) ?? 0;
      int endMinute = minute + 30;
      int endHour = hour;
      if (endMinute >= 60) {
        endHour += 1;
        endMinute -= 60;
      }
      final endHourStr = endHour.toString().padLeft(2, '0');
      final endMinStr = endMinute.toString().padLeft(2, '0');
      return '$startTime – $endHourStr.$endMinStr WIB (30 Menit)';
    }
    return '$startTime – 14.30 WIB (30 Menit)';
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor ?? {};
    final docName = doc['name'] ?? 'Dr. Anisa Putri';
    final docSpecialty = doc['specialty'] ?? 'Dokter Umum';
    final docHospital = doc['hospital'] ?? 'RS Kedung Dowo';
    final docExp = doc['experience'] ?? '10 thn pengalaman';
    final docRating = doc['rating'] != null ? '${doc['rating']}' : '4.9';
    final docPrice = doc['price'] ?? 'Rp 150.000';
    final docAvatar = doc['avatarUrl'] ??
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300';

    final selectedDateObj = _dateList[_selectedDateIndex];
    final formattedDate = selectedDateObj['fullDate'] as String;
    final formattedTime = _formatTimeRange(_selectedTime);

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _KonsultasiTopographyPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDoctorCard(
                          name: docName,
                          specialty: docSpecialty,
                          hospital: docHospital,
                          experience: docExp,
                          rating: docRating,
                          price: docPrice,
                          avatarUrl: docAvatar,
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle(
                          icon: Icons.calendar_today_outlined,
                          title: 'Pilih Tanggal Konsultasi',
                        ),
                        const SizedBox(height: 12),
                        _buildDateSelector(),
                        const SizedBox(height: 22),
                        _buildSectionTitle(
                          icon: Icons.access_time_rounded,
                          title: 'Pilih Waktu',
                        ),
                        const SizedBox(height: 12),
                        _buildTimeSlotGrid(),
                        const SizedBox(height: 22),
                        _buildRingkasanJadwalSection(
                          doctorName: docName,
                          selectedDate: formattedDate,
                          selectedTime: formattedTime,
                          price: docPrice,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildBottomStickyButton(
                  context,
                  doctor: {
                    ...doc,
                    'name': docName,
                    'specialty': docSpecialty,
                    'hospital': docHospital,
                    'experience': docExp,
                    'rating': docRating,
                    'price': docPrice,
                    'avatarUrl': docAvatar,
                  },
                  selectedDate: formattedDate,
                  selectedTime: formattedTime,
                  price: docPrice,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF0F172A), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 16, color: Color(0xFF0F172A)),
                      const SizedBox(width: 6),
                      Text(
                        'Kembali',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: Color(0xFF1F2937),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tidak ada notifikasi baru.')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePasienScreen(userName: widget.userName),
                          ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: _darkGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _darkGreen.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Jadwalkan Konsultasi Baru',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard({
    required String name,
    required String specialty,
    required String hospital,
    required String experience,
    required String rating,
    required String price,
    required String avatarUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: avatarUrl.startsWith('http')
                        ? Image.network(
                            avatarUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.person_rounded, size: 36, color: _primaryGreen),
                            ),
                          )
                        : Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.person_rounded, size: 36, color: _primaryGreen),
                          ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      specialty,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$hospital • $experience',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Color(0xFF047857),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Biaya Konsultasi',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: price,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: _darkGreen,
                          ),
                        ),
                        TextSpan(
                          text: ' / 30 mnt',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F172A)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_dateList.length, (index) {
          final item = _dateList[index];
          final isSelected = _selectedDateIndex == index;
          final isFull = item['isFull'] == true;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                if (isFull) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Jadwal konsultasi pada ${item['day']} sudah penuh.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                setState(() {
                  _selectedDateIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _darkGreen : const Color(0xFFE8F0FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _darkGreen : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _darkGreen.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isFull
                    ? RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${item['day']}, ${item['date']} ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            TextSpan(
                              text: '(Penuh)',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        '${item['day']}, ${item['date']}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 20) / 3;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _timeSlots.map((slot) {
            final timeStr = slot['time'] as String;
            final isAvailable = slot['isAvailable'] as bool;
            final isSelected = _selectedTime == timeStr;

            Color bgColor;
            Color borderColor;
            Color timeColor;
            Color statusColor;
            String statusText;

            if (isSelected) {
              bgColor = _darkGreen;
              borderColor = _darkGreen;
              timeColor = Colors.white;
              statusColor = const Color(0xFFA7F3D0);
              statusText = 'Dipilih';
            } else if (!isAvailable) {
              bgColor = const Color(0xFFEEF3FA);
              borderColor = Colors.transparent;
              timeColor = const Color(0xFF94A3B8);
              statusColor = const Color(0xFFDC2626);
              statusText = 'Penuh';
            } else {
              bgColor = Colors.white;
              borderColor = const Color(0xFFE2E8F0);
              timeColor = const Color(0xFF0F172A);
              statusColor = const Color(0xFF10B981);
              statusText = 'Tersedia';
            }

            return SizedBox(
              width: itemWidth,
              child: GestureDetector(
                onTap: () {
                  if (!isAvailable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Slot waktu pukul $timeStr sudah penuh.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _selectedTime = timeStr;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _darkGreen.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: timeColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRingkasanJadwalSection({
    required String doctorName,
    required String selectedDate,
    required String selectedTime,
    required String price,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: Color(0xFF059669),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Ringkasan Jadwal Konsultasi',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F6FD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE7F5), width: 1),
          ),
          child: Column(
            children: [
              _buildSummaryRow(label: 'Dokter', value: doctorName),
              const SizedBox(height: 12),
              _buildSummaryRow(label: 'Tanggal', value: selectedDate),
              const SizedBox(height: 12),
              _buildSummaryRow(
                label: 'Waktu',
                value: selectedTime,
                valueColor: _darkGreen,
                valueWeight: FontWeight.w700,
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                label: 'Biaya Konsultasi',
                value: price,
                valueColor: const Color(0xFF0F172A),
                valueWeight: FontWeight.w800,
                valueSize: 16,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Color(0xFF047857),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tautan telekonsultasi video call GIAT akan aktif otomatis 10 menit sebelum jadwal konsultasi dimulai.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF334155),
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color valueColor = const Color(0xFF0F172A),
    FontWeight valueWeight = FontWeight.w600,
    double valueSize = 13.5,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: valueSize,
              fontWeight: valueWeight,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStickyButton(
    BuildContext context, {
    required Map<String, dynamic> doctor,
    required String selectedDate,
    required String selectedTime,
    required String price,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _darkGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PembayaranKonsultasiScreen(
                  doctor: doctor,
                  selectedDate: selectedDate,
                  selectedTime: selectedTime,
                  price: price,
                  userName: widget.userName,
                ),
              ),
            );

            if (result == true && context.mounted) {
              Navigator.pop(context, true);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lanjutkan Pembayaran',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_circle_right_outlined,
                size: 20,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: TOPOGRAPHY BACKGROUND LINES
// ─────────────────────────────────────────────────────────────────────────────

class _KonsultasiTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (int i = 0; i < 10; i++) {
      final path = Path();
      final yOffset = 20.0 + (i * 90);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.35,
        yOffset - 35,
        size.width * 0.65,
        yOffset + 45,
        size.width,
        yOffset - 15,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
