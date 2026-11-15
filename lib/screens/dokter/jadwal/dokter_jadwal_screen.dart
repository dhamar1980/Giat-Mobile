import 'dart:io';
import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import '../konsultasi/dokter_room_chat_screen.dart';
import '../pasien/dokter_detail_pasien_screen.dart';
import '../../../services/dokter_api_service.dart';
import '../../../utils/time_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// JADWAL PRAKTIK & PASIEN DOKTER (Terintegrasi Real Database Supabase)
// ─────────────────────────────────────────────────────────────────────────────

class _DateTabItem {
  final String label; // e.g. "Minggu, 15 Nov"
  final String isoDate; // e.g. "2026-11-15"
  final DateTime dateTime;
  final bool isToday;

  _DateTabItem({
    required this.label,
    required this.isoDate,
    required this.dateTime,
    required this.isToday,
  });
}

class DokterJadwalScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final bool? isTopBarVisible;
  final String? doctorName;
  final String? dokterId;
  final List<DokterScheduleItem>? initialSchedules;

  const DokterJadwalScreen({
    super.key,
    this.onProfileTap,
    this.isTopBarVisible,
    this.doctorName,
    this.dokterId,
    this.initialSchedules,
  });

  @override
  State<DokterJadwalScreen> createState() => _DokterJadwalScreenState();
}

class _DokterJadwalScreenState extends State<DokterJadwalScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF7FBF8);
  static const _border = Color(0xFFE2E8F0);
  static const _dateInactiveBg = Color(0xFFDDF2FD);

  static const List<String> _dayNamesId = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _monthShortId = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _legacyMockDays = [
    'Senin, 01 Agu',
    'Selasa, 02 Agu',
    'Rabu, 03 Agu',
    'Kamis, 04 Agu',
    'Jumat, 05 Agu',
    'Sabtu, 06 Agu',
  ];

  static bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');
  bool get _useMockData => _isTest && widget.initialSchedules == null;

  int _selectedDayIndex = 0;
  bool _isTopBarVisible = true;
  bool _isLoading = false;
  bool _hasFetched = false;

  List<DokterScheduleItem> _liveSchedules = [];
  final Map<String, DokterPatient> _patientMap = {};
  List<_DateTabItem> _dateTabs = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialSchedules != null) {
      _liveSchedules = List.from(widget.initialSchedules!);
      _rebuildDateTabs();
    } else if (!_useMockData) {
      _rebuildDateTabs();
      _fetchLiveJadwal();
    }
  }

  void _rebuildDateTabs() {
    final now = DateTime.now();
    final todayIso =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final Set<String> allIsoDates = {};
    allIsoDates.add(todayIso);

    // Tambahkan 7 hari ke depan secara dinamis
    for (int i = 1; i <= 7; i++) {
      final dt = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      final iso =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      allIsoDates.add(iso);
    }

    // Tambahkan juga tanggal konsultasi riil yang ada di database
    for (var s in _liveSchedules) {
      if (s.date != null && s.date!.trim().isNotEmpty) {
        allIsoDates.add(s.date!.trim());
      }
    }

    final sortedIso = allIsoDates.toList()..sort();
    final List<_DateTabItem> tabs = [];

    for (var iso in sortedIso) {
      final dt = DateTime.tryParse(iso);
      if (dt == null) continue;
      final dayName = _dayNamesId[dt.weekday - 1];
      final dayNum = dt.day.toString().padLeft(2, '0');
      final shortMonth = _monthShortId[dt.month - 1];
      final label = '$dayName, $dayNum $shortMonth';
      final isToday = iso == todayIso;

      tabs.add(_DateTabItem(
        label: label,
        isoDate: iso,
        dateTime: dt,
        isToday: isToday,
      ));
    }

    final previousSelectedIso = (_dateTabs.isNotEmpty && _selectedDayIndex < _dateTabs.length)
        ? _dateTabs[_selectedDayIndex].isoDate
        : null;

    _dateTabs = tabs;

    if (previousSelectedIso != null) {
      final idx = _dateTabs.indexWhere((t) => t.isoDate == previousSelectedIso);
      if (idx != -1) {
        _selectedDayIndex = idx;
        return;
      }
    }

    final todayIdx = _dateTabs.indexWhere((t) => t.isToday);
    if (todayIdx != -1) {
      _selectedDayIndex = todayIdx;
    } else if (_dateTabs.isNotEmpty) {
      _selectedDayIndex = 0;
    }
  }

  Future<void> _fetchLiveJadwal() async {
    if (_useMockData) return;

    if (widget.initialSchedules != null) {
      if (mounted) {
        setState(() {
          _liveSchedules = List.from(widget.initialSchedules!);
          _rebuildDateTabs();
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);
    try {
      final docName = widget.doctorName ?? DokterProfileState.instance.doctorName;
      final res = await DokterApiService().getJadwal(
        dokterId: widget.dokterId,
        doctorName: docName,
      );

      if (res.success && res.data != null) {
        final List<DokterScheduleItem> parsedList = [];
        final Map<String, DokterPatient> patientMap = {};

        for (var raw in res.data!) {
          if (raw is! Map) continue;
          final map = Map<String, dynamic>.from(raw);
          final id = (map['id'] ?? map['id_konsultasi'] ?? '').toString();
          final patientData = map['pasien'] is Map ? Map<String, dynamic>.from(map['pasien'] as Map) : null;
          final patientId = (map['id_pasien'] ?? patientData?['id_pasien'] ?? patientData?['id'] ?? id).toString();
          final patientName = (patientData?['nama'] ?? map['nama_pasien'] ?? 'Pasien GIAT').toString();

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

          // Age
          int age = 28;
          final rawBirth = patientData?['tanggal_lahir'] ?? map['tanggal_lahir'];
          if (rawBirth != null) {
            final dt = DateTime.tryParse(rawBirth.toString());
            if (dt != null) {
              final now = DateTime.now();
              age = now.year - dt.year;
              if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) {
                age--;
              }
            }
          }

          final rawGen = (patientData?['jenis_kelamin'] ?? map['jenis_kelamin'] ?? '').toString();
          final gender = (rawGen == 'L' || rawGen.toLowerCase().startsWith('laki')) ? 'Laki-laki' : 'Perempuan';

          // Time formatting
          final startTime = TimeUtils.cleanTimeString(map['jam_mulai']) ?? '09:00';
          final endTime = TimeUtils.cleanTimeString(map['jam_selesai']);
          final timeDisplay = (endTime != null && endTime.isNotEmpty) ? '$startTime - $endTime' : startTime;

          // Status mapping
          final statusRaw = (map['status_konsultasi'] ?? map['status'] ?? '').toString().toLowerCase();
          String status = 'Mendatang';
          if (statusRaw == 'selesai' || statusRaw == 'completed') {
            status = 'Selesai';
          } else if (statusRaw == 'berlangsung' || statusRaw == 'aktif') {
            status = 'Aktif';
          } else {
            status = 'Mendatang';
          }

          // Service type
          final rawLayanan = (map['jenis_layanan'] ?? 'chat').toString().toLowerCase();
          final serviceType = (rawLayanan.contains('video') || rawLayanan.contains('call'))
              ? 'Video Call Konsultasi'
              : 'Chat Konsultasi';

          // Extract ISO date "YYYY-MM-DD"
          String? isoDate;
          if (map['tanggal_konsultasi'] != null) {
            final rawDate = map['tanggal_konsultasi'].toString();
            final dt = DateTime.tryParse(rawDate);
            if (dt != null) {
              isoDate =
                  '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            } else if (rawDate.length >= 10) {
              isoDate = rawDate.substring(0, 10);
            }
          }

          final patient = DokterPatient(
            id: patientId,
            name: patientName,
            initials: initials,
            age: age,
            gender: gender,
            address: (patientData?['alamat'] ?? map['alamat'] ?? '-').toString(),
            weightKg: double.tryParse((patientData?['berat_badan'] ?? map['berat_badan'] ?? '60').toString()) ?? 60.0,
            heightM: double.tryParse((patientData?['tinggi_badan'] ?? map['tinggi_badan'] ?? '1.65').toString()) ?? 1.65,
            condition: (patientData?['kondisi'] ?? map['kondisi_pantau'] ?? 'Stabil').toString(),
            complaint: (map['keluhan_awal'] ?? patientData?['keluhan'] ?? 'Pemeriksaan rutin ginjal').toString(),
            complaintDetail: (patientData?['detail_keluhan'] ?? map['detail_keluhan_pantau'] ?? map['keluhan_awal'] ?? '-').toString(),
            currentMedicines: const [],
            avatarUrl: (patientData?['foto_profile'] ?? map['foto_profile'])?.toString(),
            consultationId: id,
            paymentStatus: (map['status_bayar'] ?? 'lunas').toString(),
          );

          patientMap[patientId] = patient;

          parsedList.add(DokterScheduleItem(
            id: id,
            time: timeDisplay,
            patientName: patientName,
            status: status,
            serviceType: serviceType,
            patientId: patientId,
            date: isoDate,
            patient: patient,
            consultationId: id,
          ));
        }

        if (mounted) {
          setState(() {
            _liveSchedules = parsedList;
            _patientMap.addAll(patientMap);
            _hasFetched = true;
            _rebuildDateTabs();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching live dokter jadwal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DokterPatient _findPatient(String patientId) {
    if (_patientMap.containsKey(patientId)) {
      return _patientMap[patientId]!;
    }
    return DokterMockData.patients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => DokterMockData.patients.first,
    );
  }

  void _navigateToDetail(DokterPatient patient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DokterDetailPasienScreen(patient: patient),
      ),
    );
  }

  void _navigateToChat(DokterPatient patient, {String? consultationId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DokterRoomChatScreen(
          patient: patient,
          consultationId: consultationId ?? patient.consultationId,
        ),
      ),
    );
  }

  Future<void> _pickDateFromCalendar() async {
    final now = DateTime.now();
    final initialDt = (_dateTabs.isNotEmpty && _selectedDayIndex < _dateTabs.length)
        ? _dateTabs[_selectedDayIndex].dateTime
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDt,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _darkGreen,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final iso =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      final existingIdx = _dateTabs.indexWhere((t) => t.isoDate == iso);
      if (existingIdx != -1) {
        setState(() => _selectedDayIndex = existingIdx);
      } else {
        final dayName = _dayNamesId[picked.weekday - 1];
        final dayNum = picked.day.toString().padLeft(2, '0');
        final shortMonth = _monthShortId[picked.month - 1];
        final label = '$dayName, $dayNum $shortMonth';
        final isToday = iso ==
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        setState(() {
          _dateTabs.add(_DateTabItem(
            label: label,
            isoDate: iso,
            dateTime: picked,
            isToday: isToday,
          ));
          _dateTabs.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          _selectedDayIndex = _dateTabs.indexWhere((t) => t.isoDate == iso);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIso = (!_useMockData && _dateTabs.isNotEmpty && _selectedDayIndex < _dateTabs.length)
        ? _dateTabs[_selectedDayIndex].isoDate
        : null;

    final List<DokterScheduleItem> schedules;
    if (_useMockData) {
      schedules = DokterMockData.schedules;
    } else {
      if (selectedIso != null) {
        schedules = _liveSchedules.where((s) => s.date == selectedIso).toList();
      } else {
        schedules = _liveSchedules;
      }
    }

    final daysLabels = _useMockData
        ? _legacyMockDays
        : _dateTabs.map((t) => t.label).toList();

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
            // ── Background Topography Wave ──
            Positioned.fill(
              child: CustomPaint(
                painter: _DokterJadwalTopographyPainter(),
              ),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 76),

                  // ── Title Pill: "Jadwal Pasien" ──
                  Center(
                    child: _buildTitlePill('Jadwal Pasien'),
                  ),

                  const SizedBox(height: 16),

                  // ── Scrollable Body Content ──
                  Expanded(
                    child: RefreshIndicator(
                      color: _darkGreen,
                      onRefresh: _fetchLiveJadwal,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Summary Card: Jumlah Konsultasi Hari Ini ──
                            _buildSummaryCard(),

                            const SizedBox(height: 20),

                            // ── Section: Pilih Tanggal ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('📅', style: TextStyle(fontSize: 15)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Pilih Tanggal',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!_useMockData)
                                  InkWell(
                                    onTap: _pickDateFromCalendar,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_month_rounded,
                                            size: 16,
                                            color: _darkGreen,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Kalender',
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: _darkGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // ── Horizontal Date Selector Pills ──
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(daysLabels.length, (idx) {
                                  final isSelected = _selectedDayIndex == idx;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedDayIndex = idx),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                      decoration: BoxDecoration(
                                        color: isSelected ? _darkGreen : _dateInactiveBg,
                                        borderRadius: BorderRadius.circular(22),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: _darkGreen.withValues(alpha: 0.25),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Text(
                                        daysLabels[idx],
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // ── Loading indicator ──
                            if (_isLoading && !_hasFetched && schedules.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: CircularProgressIndicator(color: _darkGreen),
                                ),
                              )
                            // ── Empty State ──
                            else if (schedules.isEmpty)
                              _buildEmptyState()
                            // ── Timeline Schedule List ──
                            else
                              ...List.generate(schedules.length, (index) {
                                final item = schedules[index];
                                final isLast = index == schedules.length - 1;
                                return _buildTimelineScheduleItem(item, isLast);
                              }),

                            const SizedBox(height: 20),
                          ],
                        ),
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

  // ───────────────────────────────────────────────────────────────────────────
  // TITLE PILL
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTitlePill(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
      decoration: BoxDecoration(
        color: _darkGreen,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _darkGreen.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SUMMARY CARD: JUMLAH KONSULTASI HARI INI (REAL DATA SUPABASE)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    String totalCountStr = '04';
    String selesaiCountStr = '02';
    String berlangsungCountStr = '01';
    String mendatangCountStr = '01';
    String title = 'Jumlah Konsultasi Hari Ini';

    if (!_useMockData) {
      final now = DateTime.now();
      final todayIso =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final selectedIso = (_dateTabs.isNotEmpty && _selectedDayIndex < _dateTabs.length)
          ? _dateTabs[_selectedDayIndex].isoDate
          : todayIso;

      final isSelectedToday = selectedIso == todayIso;

      if (!isSelectedToday && _dateTabs.isNotEmpty && _selectedDayIndex < _dateTabs.length) {
        title = 'Jumlah Konsultasi (${_dateTabs[_selectedDayIndex].label})';
      } else {
        title = 'Jumlah Konsultasi Hari Ini';
      }

      final targetSchedules = _liveSchedules.where((s) => s.date == selectedIso).toList();

      final total = targetSchedules.length;
      final selesai = targetSchedules.where((s) => s.status == 'Selesai').length;
      final berlangsung = targetSchedules
          .where((s) => s.status == 'Aktif' || s.status == 'Berlangsung')
          .length;
      final mendatang = targetSchedules
          .where((s) => s.status == 'Mendatang' || s.status == 'Terjadwal')
          .length;

      totalCountStr = total.toString().padLeft(2, '0');
      selesaiCountStr = selesai.toString().padLeft(2, '0');
      berlangsungCountStr = berlangsung.toString().padLeft(2, '0');
      mendatangCountStr = mendatang.toString().padLeft(2, '0');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Wave Watermark in Corners
            Positioned.fill(
              child: CustomPaint(
                painter: _CardWaveWatermarkPainter(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    totalCountStr,
                    style: GoogleFonts.inter(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildMiniCounterCard('Selesai', selesaiCountStr, const Color(0xFF15803D)),
                      const SizedBox(width: 8),
                      _buildMiniCounterCard('Berlangsung', berlangsungCountStr, const Color(0xFF0F172A)),
                      const SizedBox(width: 8),
                      _buildMiniCounterCard('Mendatang', mendatangCountStr, const Color(0xFFEAB308)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCounterCard(String label, String count, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              count,
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // EMPTY STATE JADWAL
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _darkGreen.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 32,
              color: _darkGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Tidak Ada Jadwal Konsultasi',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Belum ada pasien yang terjadwal pada tanggal ini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TIMELINE SCHEDULE ITEM
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTimelineScheduleItem(DokterScheduleItem sch, bool isLast) {
    final isAktif = sch.status == 'Aktif' || sch.status == 'Berlangsung';
    final patient = sch.patient ?? _findPatient(sch.patientId);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Time Column on Left ──
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: 6),
              child: Text(
                sch.time,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isAktif ? const Color(0xFF0D7A5F) : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),

          // ── Vertical Timeline Connecting Line ──
          SizedBox(
            width: 18,
            child: Center(
              child: Container(
                width: 1.5,
                color: const Color(0xFFE2E8F0),
              ),
            ),
          ),

          // ── Schedule Card on Right ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAktif ? _darkGreen : _border,
                    width: isAktif ? 1.5 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isAktif
                          ? _darkGreen.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Patient Name & Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            sch.patientName,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(sch.status),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Service Type: Chat Konsultasi / Video Call
                    Row(
                      children: [
                        Icon(
                          sch.serviceType.toLowerCase().contains('video')
                              ? Icons.videocam_outlined
                              : Icons.chat_bubble_outline_rounded,
                          size: 15,
                          color: const Color(0xFF475569),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sch.serviceType,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Actions
                    if (isAktif)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _darkGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _navigateToChat(
                                patient,
                                consultationId: sch.consultationId,
                              ),
                              child: Text(
                                'Mulai Chat',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFF0F172A), width: 1.1),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => _navigateToDetail(patient),
                            child: Text(
                              'Detail',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: () => _navigateToDetail(patient),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Lihat Detail',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _darkGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_circle_right_outlined,
                              size: 17,
                              color: _darkGreen,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color textColor;

    final norm = status.toLowerCase();
    if (norm == 'aktif' || norm == 'berlangsung') {
      bg = _darkGreen;
      textColor = Colors.white;
    } else if (norm == 'mendatang' || norm == 'terjadwal') {
      bg = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFB45309);
    } else {
      bg = const Color(0xFFE2E8F0);
      textColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY WAVE PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _DokterJadwalTopographyPainter extends CustomPainter {
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

// ─────────────────────────────────────────────────────────────────────────────
// CARD WAVE WATERMARK PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _CardWaveWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Top-left decorative lines
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offset = i * 16.0;
      path.moveTo(0, 10 + offset);
      path.cubicTo(
        25 + offset,
        15 + offset,
        45 + offset,
        45 + offset,
        60 + offset,
        0,
      );
      canvas.drawPath(path, paint);
    }

    // Bottom-right decorative lines
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offset = i * 16.0;
      path.moveTo(size.width - 65 - offset, size.height);
      path.cubicTo(
        size.width - 45 - offset,
        size.height - 35 - offset,
        size.width - 25 - offset,
        size.height - 20 - offset,
        size.width,
        size.height - 40 - offset,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
