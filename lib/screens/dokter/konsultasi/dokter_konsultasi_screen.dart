import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import '../notifikasi/dokter_notifikasi_screen.dart';
import '../profile/dokter_profile_screen.dart';
import 'dokter_room_chat_screen.dart';
import '../../../utils/time_utils.dart';
import '../../../services/konsultasi_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DAFTAR KONSULTASI DOKTER (Sesuai Desain Figma / Image 1, 2, 3)
// ─────────────────────────────────────────────────────────────────────────────

class DokterKonsultasiScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final bool? isTopBarVisible;

  const DokterKonsultasiScreen({
    super.key,
    this.onProfileTap,
    this.isTopBarVisible,
  });

  @override
  State<DokterKonsultasiScreen> createState() => _DokterKonsultasiScreenState();
}

class _DokterKonsultasiScreenState extends State<DokterKonsultasiScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _filterInactiveBg = Color(0xFFE0F2FE); // Soft light blue pill
  static const _filterInactiveText = Color(0xFF1E293B);

  int _selectedFilterIndex = 0; // 0: Semua, 1: Terjadwal, 2: Selesai
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isTopBarVisible = true;
  List<DokterConsultation> _liveConsultations = [];
  final Map<String, DokterPatient> _livePatientMap = {};

  bool get _effectiveTopBarVisible => widget.isTopBarVisible ?? _isTopBarVisible;

  @override
  void initState() {
    super.initState();
    _fetchLiveConsultations();
  }

  Future<void> _fetchLiveConsultations() async {
    try {
      final res = await KonsultasiApiService().getRiwayatDokter();
      if (res.success && res.data != null && res.data!.isNotEmpty) {
        final List<DokterConsultation> parsedList = [];
        for (var item in res.data!) {
          if (item is! Map) continue;
          final map = Map<String, dynamic>.from(item);

          final id = (map['id'] ?? map['id_konsultasi'] ?? '').toString();
          final pasienData = map['pasien'] is Map ? Map<String, dynamic>.from(map['pasien'] as Map) : null;
          final patientId = (map['id_pasien'] ?? pasienData?['id_pasien'] ?? pasienData?['id'] ?? id).toString();
          final patientName = (pasienData?['nama'] ?? map['nama_pasien'] ?? 'Pasien').toString();

          // Initials
          String initials = 'P';
          final parts = patientName.trim().split(RegExp(r'\s+'));
          if (parts.isNotEmpty && parts[0].isNotEmpty) {
            if (parts.length == 1) {
              initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
            } else {
              initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
            }
          }

          // Status
          final statusStr = (map['status'] ?? map['status_konsultasi'] ?? '').toString().toLowerCase();
          KonsultasiStatus status;
          if (statusStr == 'selesai' || statusStr == 'completed') {
            status = KonsultasiStatus.selesai;
          } else if (statusStr == 'terjadwal' || statusStr == 'scheduled' || statusStr == 'menunggu' || statusStr == 'pending') {
            status = KonsultasiStatus.terjadwal;
          } else {
            status = KonsultasiStatus.berlangsung;
          }

          // Scheduled time text
          String timeText = 'Hari ini';
          final tgl = map['tanggal_konsultasi'];
          final jmMulai = map['jam_mulai']?.toString();
          if (jmMulai != null && jmMulai.isNotEmpty) {
            final timeOnly = jmMulai.length >= 5 ? jmMulai.substring(0, 5) : jmMulai;
            timeText = '$timeOnly WIB';
          } else if (tgl != null) {
            timeText = TimeUtils.formatDate(tgl, useIndonesianMonth: true);
          }

          // Message count & last message
          final msgCount = int.tryParse((map['pesan_count'] ?? map['unread_count'] ?? 0).toString()) ?? 0;
          final lastMsg = (map['last_message'] ?? map['keluhan_awal'] ?? map['isi_konsultasi'] ?? 'Konsultasi GIAT').toString();
          final lastTime = TimeUtils.formatChatTime(map['updated_at'] ?? map['created_at']);

          // Calculate Age
          int age = 26;
          if (pasienData?['tanggal_lahir'] != null) {
            final dt = DateTime.tryParse(pasienData!['tanggal_lahir'].toString());
            if (dt != null) {
              final now = DateTime.now();
              age = now.year - dt.year;
              if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) {
                age--;
              }
            }
          }

          final rawGender = (pasienData?['jenis_kelamin'] ?? '').toString();
          final gender = (rawGender == 'L' || rawGender.toLowerCase().startsWith('laki')) ? 'Laki-laki' : 'Perempuan';

          final avatarUrl = (pasienData?['foto_profile'] ?? pasienData?['foto_profil'])?.toString();

          final patientObj = DokterPatient(
            id: patientId,
            name: patientName,
            initials: initials,
            age: age,
            gender: gender,
            address: (pasienData?['alamat'] ?? 'Kota Bandung').toString(),
            weightKg: 55.0,
            heightM: 1.65,
            condition: 'Pasien Ginjal',
            complaint: (map['keluhan_awal'] ?? map['isi_konsultasi'] ?? 'Konsultasi Ginjal').toString(),
            complaintDetail: (map['keluhan_awal'] ?? map['isi_konsultasi'] ?? '').toString(),
            currentMedicines: const [],
            avatarUrl: avatarUrl,
            avatarBgColor: const Color(0xFFCFE8F3),
            avatarTextColor: const Color(0xFF0F172A),
          );
          _livePatientMap[patientId] = patientObj;

          parsedList.add(
            DokterConsultation(
              id: id,
              patientName: patientName,
              initials: initials,
              status: status,
              scheduledTimeText: timeText,
              messageCount: msgCount,
              lastMessage: lastMsg,
              lastTime: lastTime,
              patientId: patientId,
              avatarUrl: avatarUrl,
              patient: patientObj,
            ),
          );
        }

        if (mounted) {
          setState(() {
            _liveConsultations = parsedList;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching live consultations: $e');
    }
  }

  List<DokterConsultation> get _allConsultations {
    if (_liveConsultations.isNotEmpty) {
      final existingIds = _liveConsultations.map((c) => c.id).toSet();
      final existingNames = _liveConsultations.map((c) => c.patientName.toLowerCase()).toSet();
      final extraMocks = DokterMockData.consultations.where((m) =>
          !existingIds.contains(m.id) && !existingNames.contains(m.patientName.toLowerCase())
      ).toList();
      return [..._liveConsultations, ...extraMocks];
    }
    return DokterMockData.consultations;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DokterConsultation> _getFilteredConsultations() {
    final all = _allConsultations;
    List<DokterConsultation> list;

    if (_selectedFilterIndex == 1) {
      // Terjadwal tab
      list = all.where((item) => item.status == KonsultasiStatus.terjadwal).toList();
    } else if (_selectedFilterIndex == 2) {
      // Selesai tab
      list = all.where((item) => item.status == KonsultasiStatus.selesai).toList();
    } else {
      // Semua tab: Matches all items except purely mock c-3 if mock-only
      if (_liveConsultations.isEmpty) {
        list = all.where((item) => item.id != 'c-3').toList();
      } else {
        list = all;
      }
    }

    if (_searchQuery.trim().isEmpty) return list;

    return list.where((item) {
      return item.patientName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  DokterPatient _findPatient(String patientId) {
    if (_livePatientMap.containsKey(patientId)) {
      return _livePatientMap[patientId]!;
    }
    return DokterMockData.patients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => DokterMockData.patients.first,
    );
  }

  void _openChat(DokterConsultation item) {
    final patient = item.patient ?? _findPatient(item.patientId);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DokterRoomChatScreen(
          patient: patient,
          consultationId: item.id,
        ),
      ),
    ).then((_) {
      if (mounted) _fetchLiveConsultations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredConsultations();

    return Scaffold(
      backgroundColor: _bgColor,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            final pixels = notification.metrics.pixels;
            if (pixels > 20) {
              if (_isTopBarVisible) setState(() => _isTopBarVisible = false);
            } else if (pixels <= 5) {
              if (!_isTopBarVisible) setState(() => _isTopBarVisible = true);
            }
          }
          return false;
        },
        child: Stack(
          children: [
            // ── Wavy Topography Background ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 240,
              child: CustomPaint(
                painter: _KonsultasiHeaderTopographyPainter(),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 76),

                  // ── Centered Pill Badge: "Daftar Konsultasi" ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                  decoration: BoxDecoration(
                    color: _darkGreen,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _darkGreen.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Daftar Konsultasi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Search Bar: "Cari Pasien..." ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Cari Pasien...',
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Segmented Filter Pills: Semua, Terjadwal, Selesai ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildFilterPill(0, 'Semua'),
                      const SizedBox(width: 10),
                      _buildFilterPill(1, 'Terjadwal'),
                      const SizedBox(width: 10),
                      _buildFilterPill(2, 'Selesai'),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Consultation Cards List ──
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchLiveConsultations,
                    color: _darkGreen,
                    child: filtered.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                              Center(
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
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: filtered.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _buildConsultationCard(item);
                            },
                          ),
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

  // Segmented Pill Item
  Widget _buildFilterPill(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? _darkGreen : _filterInactiveBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _darkGreen.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : _filterInactiveText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Consultation Card matching Image 1, 2, 3
  Widget _buildConsultationCard(DokterConsultation item) {
    final isCompleted = item.status == KonsultasiStatus.selesai;
    final isOngoing = item.status == KonsultasiStatus.berlangsung;
    final isScheduled = item.status == KonsultasiStatus.terjadwal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar box with initials and soft light blue background (or network photo)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFE8F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                      ? Image.network(
                          item.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              item.initials,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            item.initials,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Patient Info & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.patientName,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Status Indicator
                    if (isOngoing)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Sedang Berlangsung',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (isScheduled)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: _darkGreen,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Terjadwal',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _darkGreen,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Sudah Selesai',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _darkGreen,
                        ),
                      ),

                    const SizedBox(height: 4),
                    Text(
                      'Waktu Konsultasi: ${TimeUtils.replaceTimezoneSuffix(item.scheduledTimeText)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Unread Badge (e.g. "2 Pesan" on Budi Santoso)
              if (item.messageCount > 0 && isOngoing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB91C1C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.messageCount} Pesan',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Button: Solid Green
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonDarkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _openChat(item),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCompleted ? 'Lihat Riwayat Chat' : 'Mulai Chat',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationProfileCapsule() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DokterNotifikasiScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (widget.onProfileTap != null) {
                widget.onProfileTap!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DokterProfileScreen(
                      doctorName: DokterProfileState.instance.doctorName,
                      onLogout: () => Navigator.of(context).pop(),
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF044E2F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY BACKGROUND PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _KonsultasiHeaderTopographyPainter extends CustomPainter {
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
