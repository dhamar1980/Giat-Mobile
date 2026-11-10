import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/dokter_models.dart';
import 'notifikasi/dokter_notifikasi_screen.dart';
import 'konsultasi/dokter_konsultasi_screen.dart';
import 'konsultasi/dokter_room_chat_screen.dart';
import 'pasien/dokter_pasien_screen.dart';
import 'jadwal/dokter_jadwal_screen.dart';
import 'profile/dokter_profile_screen.dart';
import 'resep/dokter_review_resep_sheet.dart';
import '../../onboarding_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/giat_background.dart';
import '../../widgets/app_brand_title.dart';
import '../../widgets/giat_header_style.dart';
import '../../services/dokter_api_service.dart';
import '../../utils/time_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DOKTER HOME SCREEN (Figma Node: 1008-17556)
// ─────────────────────────────────────────────────────────────────────────────

class DokterHomeScreen extends StatefulWidget {
  final String doctorName;
  final int initialIndex;
  final Function(int)? onNavigateTab;
  final Map<String, dynamic>? initialDashboardData;

  const DokterHomeScreen({
    super.key,
    this.doctorName = 'Dr. Andi Pratama',
    this.initialIndex = 0,
    this.onNavigateTab,
    this.initialDashboardData,
  });

  @override
  State<DokterHomeScreen> createState() => _DokterHomeScreenState();
}

class _DokterHomeScreenState extends State<DokterHomeScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  bool _isTopBarVisible = true;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activitySummaryKey = GlobalKey();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Colors based on Figma design
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bubbleDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);

  static bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');
  bool get _shouldShowRealData => widget.initialDashboardData != null || !_isTest;

  bool _isLoading = false;
  List<Map<String, dynamic>> _liveRecentMessages = [];
  List<Map<String, dynamic>> _liveTodaySchedules = [];
  Map<String, dynamic>? _liveLatestConsultation;
  Map<String, dynamic>? _liveLatestPrescription;
  final Map<String, DokterPatient> _patientCache = {};

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    DokterProfileState.instance.syncFromUser(name: widget.doctorName);
    DokterProfileState.instance.loadProfile(fallbackName: widget.doctorName);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
    if (widget.initialDashboardData != null) {
      _applyDashboardData(widget.initialDashboardData!);
    } else {
      _fetchLiveDashboard();
    }
  }

  Future<void> _fetchLiveDashboard({bool showLoading = false}) async {
    if (_isTest) return;
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await DokterApiService().getDashboard(doctorName: widget.doctorName);
      if (res.success && res.data != null && mounted) {
        _applyDashboardData(res.data!);
      }
    } catch (e) {
      debugPrint('Error fetching live dokter dashboard: $e');
    } finally {
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyDashboardData(Map<String, dynamic> data) {
    final docData = data['dokter'];
    if (docData is Map) {
      final docMap = Map<String, dynamic>.from(docData);
      DokterProfileState.instance.syncFromUser(
        name: docMap['nama']?.toString(),
        spec: docMap['spesialisasi']?.toString(),
        inst: docMap['institusi']?.toString(),
        str: docMap['no_str']?.toString(),
        sip: docMap['no_sip']?.toString(),
        avatar: docMap['foto_profil']?.toString() ?? docMap['foto_profile']?.toString(),
      );
    }

    final rawMessages = data['pesan_terbaru'];
    final List<Map<String, dynamic>> parsedMessages = [];
    if (rawMessages is List) {
      final Set<String> seenPatients = {};
      for (var item in rawMessages) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          final pName = (m['nama_pasien'] ?? m['id_pasien'] ?? '').toString().toLowerCase().trim();
          if (pName.isNotEmpty && !seenPatients.contains(pName)) {
            seenPatients.add(pName);
            parsedMessages.add(m);
          }
        }
      }
    }

    final rawSchedules = data['jadwal_hari_ini'];
    final List<Map<String, dynamic>> parsedSchedules = [];
    if (rawSchedules is List) {
      final Set<String> seenSchedulePatients = {};
      for (var item in rawSchedules) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          final pName = (m['nama_pasien'] ?? m['id_pasien'] ?? '').toString().toLowerCase().trim();
          if (pName.isNotEmpty && !seenSchedulePatients.contains(pName)) {
            seenSchedulePatients.add(pName);
            parsedSchedules.add(m);
          }
        }
      }
    }

    Map<String, dynamic>? latestConsultation;
    if (data['konsultasi_terbaru'] is Map) {
      latestConsultation = Map<String, dynamic>.from(data['konsultasi_terbaru'] as Map);
    } else if (data['ringkasan_aktivitas'] is Map && (data['ringkasan_aktivitas'] as Map)['konsultasi'] is Map) {
      latestConsultation = Map<String, dynamic>.from((data['ringkasan_aktivitas'] as Map)['konsultasi'] as Map);
    }

    Map<String, dynamic>? latestPrescription;
    if (data['resep_terbaru'] is List && (data['resep_terbaru'] as List).isNotEmpty) {
      final firstRx = (data['resep_terbaru'] as List).first;
      if (firstRx is Map) {
        latestPrescription = Map<String, dynamic>.from(firstRx);
      }
    } else if (data['ringkasan_aktivitas'] is Map && (data['ringkasan_aktivitas'] as Map)['resep'] is Map) {
      latestPrescription = Map<String, dynamic>.from((data['ringkasan_aktivitas'] as Map)['resep'] as Map);
    }

    setState(() {
      _liveRecentMessages = parsedMessages;
      _liveTodaySchedules = parsedSchedules;
      _liveLatestConsultation = latestConsultation;
      _liveLatestPrescription = latestPrescription;
    });
  }

  DokterPatient _resolvePatientFromMap(
    Map<String, dynamic> map, {
    String fallbackId = 'p-1',
    String fallbackName = 'Pasien',
  }) {
    final rawId = (map['id_pasien'] ?? map['id'] ?? fallbackId).toString();
    if (_patientCache.containsKey(rawId)) {
      return _patientCache[rawId]!;
    }

    final name = (map['nama_pasien'] ?? map['nama'] ?? fallbackName).toString();
    String initials = 'P';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      if (parts.length == 1) {
        initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      } else {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
    }

    int age = 35;
    final birthDate = map['tanggal_lahir']?.toString();
    if (birthDate != null && birthDate.isNotEmpty) {
      final dt = DateTime.tryParse(birthDate);
      if (dt != null) {
        final now = DateTime.now();
        age = now.year - dt.year;
        if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) {
          age--;
        }
      }
    }

    final rawGender = (map['jenis_kelamin'] ?? '').toString();
    final gender = (rawGender == 'L' || rawGender.toLowerCase().startsWith('laki')) ? 'Laki-laki' : 'Perempuan';
    final address = (map['alamat'] ?? 'Indonesia').toString();
    final complaint = (map['keluhan_awal'] ?? map['diagnosis'] ?? 'Konsultasi GIAT').toString();
    final complaintDetail = (map['keluhan_awal'] ?? map['catatan_dokter'] ?? '').toString();
    final avatarUrl = (map['foto_profile'] ?? map['foto_profil'])?.toString();

    final List<DokterPrescriptionItem> medicines = [];
    final rawObat = map['obat'] ?? map['items'];
    if (rawObat is List) {
      for (var it in rawObat) {
        if (it is Map) {
          final m = Map<String, dynamic>.from(it);
          medicines.add(
            DokterPrescriptionItem(
              id: (m['id'] ?? 'rx-${medicines.length + 1}').toString(),
              medicineName: (m['nama_obat'] ?? 'Obat').toString(),
              dose: (m['dosis'] ?? '-').toString(),
              frequency: (m['aturan_pakai'] ?? '1x1').toString(),
              quantity: '${m['jumlah'] ?? 1} Tablet',
              duration: (m['durasi'] ?? '5 hari').toString(),
              usageTime: (m['waktu_penggunaan'] ?? m['waktu_minum'] ?? 'Sesudah Makan').toString(),
              specialNotes: m['catatan_khusus']?.toString() ?? m['catatan']?.toString(),
            ),
          );
        }
      }
    }

    final patient = DokterPatient(
      id: rawId,
      name: name,
      initials: initials,
      age: age,
      gender: gender,
      address: address,
      weightKg: 58.0,
      heightM: 1.65,
      condition: 'Pasien Ginjal',
      complaint: complaint,
      complaintDetail: complaintDetail,
      currentMedicines: medicines,
      avatarUrl: avatarUrl,
      avatarBgColor: const Color(0xFFE0F2FE),
      avatarTextColor: const Color(0xFF0369A1),
    );

    _patientCache[rawId] = patient;
    return patient;
  }

  void _navigateToChatWithPatient(DokterPatient patient, {String? consultationId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DokterRoomChatScreen(
          patient: patient,
          consultationId: consultationId,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant DokterHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doctorName != widget.doctorName) {
      DokterProfileState.instance.syncFromUser(name: widget.doctorName);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await AuthService().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  void _navigateToChat(String patientId, {String? consultationId}) {
    if (_patientCache.containsKey(patientId)) {
      _navigateToChatWithPatient(_patientCache[patientId]!, consultationId: consultationId);
      return;
    }
    final patient = DokterMockData.patients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => DokterMockData.patients.first,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DokterRoomChatScreen(
          patient: patient,
          consultationId: consultationId,
        ),
      ),
    );
  }

  void _navigateToTab(int tabIndex) {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(tabIndex);
    }
    setState(() {
      _selectedIndex = tabIndex;
      _isTopBarVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeTab(),
                DokterKonsultasiScreen(
                  onProfileTap: () => setState(() {
                    _selectedIndex = 4;
                    _isTopBarVisible = true;
                  }),
                ),
                DokterPasienScreen(
                  onProfileTap: () => setState(() {
                    _selectedIndex = 4;
                    _isTopBarVisible = true;
                  }),
                ),
                DokterJadwalScreen(
                  onProfileTap: () => setState(() {
                    _selectedIndex = 4;
                    _isTopBarVisible = true;
                  }),
                ),
                DokterProfileScreen(
                  doctorName: widget.doctorName,
                  onLogout: _handleLogout,
                ),
              ],
            ),
          ),
          // Topbar overlay tetap / netap (hidden on Profile tab 4)
          if (_selectedIndex != 4)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _buildTopBar(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTopBar() {
    final showBrandTitle = _selectedIndex == 0; // Tab 0 is Home Dokter

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. App Brand Title ("GINJAL SEHAT") di kiri, sejajar dengan pill di kanan
          if (showBrandTitle)
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AppBrandTitle(),
              ),
            )
          else
            const SizedBox.shrink(),

          // 2. Kapsul Notifikasi & Profil (Ukuran asli yang proporsional)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(5),
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    size: 24,
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
                    setState(() {
                      _selectedIndex = 4;
                      _isTopBarVisible = true;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF044E2F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 22,
                      color: Colors.white,
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

  Widget _buildHomeTab() {
    return Stack(
      children: [
        // Background Topography
        Positioned.fill(
          child: CustomPaint(
            painter: _DokterTopographyPainter(),
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Section with Chat Bubbles (Fixed at top, does NOT scroll) ──
            _buildHeaderSection(),

            // ── Scrollable Body Content Below Header ──
            Expanded(
              child: RefreshIndicator(
                color: _darkGreen,
                onRefresh: () => _fetchLiveDashboard(showLoading: false),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Quick Access Menu: 3 Rounded Buttons (Konsultasi, Pasien, Jadwal) ──
                          _buildQuickActionMenu(),

                          const SizedBox(height: 20),

                          // ── Section 1: Pesan Terbaru (Figma Node 1008:17556) ──
                          _buildRecentMessagesSection(),

                          const SizedBox(height: 20),

                          // ── Section 2: Jadwal Hari Ini (Figma Node 1008:17556) ──
                          _buildTodayScheduleTimelineSection(),

                          const SizedBox(height: 24),

                          // ── Section 3: Ringkasan Aktivitas Hari Ini (Figma Node 1008:17556 - Variant 2) ──
                          KeyedSubtree(
                            key: _activitySummaryKey,
                            child: _buildActivitySummarySection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // QUICK ACTION MENU (3 Menu Cepat Dokter: Konsultasi, Pasien, Jadwal)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActionMenu() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Konsultasi
          Expanded(
            child: _QuickMenuRoundedItem(
              label: 'Konsultasi',
              iconWidget: const Icon(
                Icons.medical_services_rounded,
                color: _darkGreen,
                size: 27,
              ),
              onTap: () => _navigateToTab(1),
            ),
          ),

          // 2. Pasien
          Expanded(
            child: _QuickMenuRoundedItem(
              label: 'Pasien',
              iconWidget: const Icon(
                Icons.people_alt_rounded,
                color: _darkGreen,
                size: 27,
              ),
              onTap: () => _navigateToTab(2),
            ),
          ),

          // 3. Jadwal
          Expanded(
            child: _QuickMenuRoundedItem(
              label: 'Jadwal',
              iconWidget: const Icon(
                Icons.calendar_today_rounded,
                color: _darkGreen,
                size: 27,
              ),
              onTap: () => _navigateToTab(3),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER SECTION (Figma Node 1008:17556)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderSection() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: GiatHeaderStyle.headerDecoration,
      child: Stack(
        children: [
          const GiatHeaderCurvesOverlay(),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 86, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Single Chat Bubble
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (_activitySummaryKey.currentContext != null) {
                        Scrollable.ensureVisible(
                          _activitySummaryKey.currentContext!,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    child: CustomPaint(
                      painter: const _DokterChatBubblePainter(
                        isLeft: true,
                        isSelected: false,
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 340),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListenableBuilder(
                              listenable: DokterProfileState.instance,
                              builder: (context, _) {
                                final displayName = DokterProfileState.instance.doctorName.isNotEmpty
                                    ? DokterProfileState.instance.doctorName
                                    : widget.doctorName;
                                return Text(
                                  'Selamat Datang Kembali, $displayName 👏🏻',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF065A37),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Berikut ringkasan aktivitas Anda hari ini. ✨✨',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF065A37).withValues(alpha: 0.9),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 3: RINGKASAN AKTIVITAS HARI INI (Figma Node 1008:17556 - Variant 2)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildActivitySummarySection() {
    final hasRealConsultation = _shouldShowRealData && _liveLatestConsultation != null;
    final hasRealPrescription = _shouldShowRealData && _liveLatestPrescription != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Berikut Ringkasan aktivitas Anda hari ini.',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),

          // Card 1: Konsultasi (Real data jika ada, fallback ke Budi Santoso untuk test)
          if (hasRealConsultation)
            _buildLiveConsultationActivityCard(_liveLatestConsultation!)
          else
            _buildConsultationActivityCard(),

          const SizedBox(height: 14),

          // Card 2: Membuat resep (Real data jika ada, fallback ke Budi Santoso untuk test)
          if (hasRealPrescription)
            _buildLivePrescriptionActivityCard(_liveLatestPrescription!)
          else
            _buildPrescriptionActivityCard(),
        ],
      ),
    );
  }

  Widget _buildLiveConsultationActivityCard(Map<String, dynamic> item) {
    final patientName = (item['nama_pasien'] ?? 'Pasien').toString();
    final patient = _resolvePatientFromMap(item, fallbackName: patientName);
    final complaint = (item['keluhan_awal'] ?? 'Follow-up kesehatan ginjal pasien').toString();
    final consultationId = item['id']?.toString();

    String timeStr = '14:00 WIB';
    final cleanTime = TimeUtils.cleanTimeString(item['jam_mulai']);
    if (cleanTime != null && cleanTime.isNotEmpty) {
      timeStr = '$cleanTime WIB';
    }

    return GestureDetector(
      onTap: () => _navigateToChatWithPatient(patient, consultationId: consultationId),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                    patientName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Konsultasi',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              complaint,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF475569),
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF0F172A)),
                const SizedBox(width: 6),
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePrescriptionActivityCard(Map<String, dynamic> item) {
    final patientName = (item['nama_pasien'] ?? 'Pasien').toString();
    final patient = _resolvePatientFromMap(item, fallbackName: patientName);
    final diagnosis = (item['diagnosis'] ?? item['catatan_dokter'] ?? 'Penerbitan resep obat elektronik').toString();

    String timeStr = '14:00 WIB';
    final createdAt = item['created_at'];
    if (createdAt != null) {
      timeStr = TimeUtils.formatChatTime(createdAt);
    }

    final rawObat = item['obat'] ?? item['items'];
    final List<Map<String, dynamic>> obatList = [];
    if (rawObat is List) {
      for (var o in rawObat) {
        if (o is Map) {
          obatList.add(Map<String, dynamic>.from(o));
        }
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DokterReviewResepScreen(
              patient: patient,
              initialItems: patient.currentMedicines.isNotEmpty ? patient.currentMedicines : null,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                    patientName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Membuat resep',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              diagnosis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF475569),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF0F172A)),
                const SizedBox(width: 6),
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Prescription items container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  if (obatList.isNotEmpty) ...[
                    for (int i = 0; i < obatList.length; i++) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              (obatList[i]['nama_obat'] ?? 'Obat').toString(),
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF044E2F),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${obatList[i]['jumlah'] ?? 1} Tablet',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${obatList[i]['dosis'] ?? '1x1'} • ${obatList[i]['aturan_pakai'] ?? obatList[i]['waktu_penggunaan'] ?? 'Diminum sesudah makan'}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      if (i < obatList.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
                        ),
                    ],
                  ] else ...[
                    Text(
                      'Belum ada rincian obat.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
                  ),

                  // Total Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${obatList.length} item obat',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
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

  Widget _buildConsultationActivityCard() {
    return GestureDetector(
      onTap: () => _navigateToChat('p-1'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                    'Budi Santoso',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Konsultasi',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Follow-up CKD Stage 3, Review hasil lab terbaru.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF475569),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF0F172A)),
                const SizedBox(width: 6),
                Text(
                  '14:00 WIB',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionActivityCard() {
    return GestureDetector(
      onTap: () {
        final patient = DokterMockData.patients.firstWhere(
          (p) => p.id == 'p-1',
          orElse: () => DokterMockData.patients.first,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DokterReviewResepScreen(patient: patient),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                    'Budi Santoso',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Membuat resep',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Membuat resep',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF0F172A)),
                const SizedBox(width: 6),
                Text(
                  '14:00 WIB',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Prescription items container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  // Item 1: Paracetamol 500 mg
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Paracetamol 500 mg',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF044E2F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '2 Tablet',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Align(
                        alignment: Alignment.centerLeft,
                    child: Text(
                      'Tablet • 10 tablet',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
                  ),

                  // Item 2: Amoxicillin 500 mg
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Amoxicillin 500 mg',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF044E2F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '1 Tablet',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Kapsul • 30 kapsul',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
                  ),

                  // Total Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '2 item obat',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
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

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 1: PESAN TERBARU (Figma Node 1008:17556)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRecentMessagesSection() {
    final hasRealMessages = _shouldShowRealData && _liveRecentMessages.isNotEmpty;
    final messagesToShow = hasRealMessages ? _liveRecentMessages : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pesan Terbaru',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              if (!_isTest)
                GestureDetector(
                  onTap: () => _navigateToTab(1), // Tab 1: Konsultasi
                  child: Row(
                    children: [
                      Text(
                        'Buka Chat',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _darkGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_circle_right_outlined, color: _darkGreen, size: 16),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (hasRealMessages) ...[
            for (var msg in messagesToShow!) ...[
              _buildLiveMessageCard(msg),
              const SizedBox(height: 12),
            ],
          ] else if (_shouldShowRealData && !_isLoading && _liveRecentMessages.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _cardBorderColor),
              ),
              child: Center(
                child: Text(
                  'Belum ada pesan terbaru dari pasien.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Fallback for tests & initial render
            _buildMessageItem(
              initials: 'BS',
              name: 'Budi Santoso',
              message: '“Dok, saya sudah mengirim hasil lab”',
              time: '2 menit',
              patientId: 'p-1',
            ),

            const SizedBox(height: 12),

            _buildMessageItem(
              initials: 'SW',
              name: 'Siti Wijaya',
              message: '“Obat sudah diminum sesuai jadwal.”',
              time: '5 menit',
              patientId: 'p-2',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveMessageCard(Map<String, dynamic> msg) {
    final patientName = (msg['nama_pasien'] ?? 'Pasien').toString();
    final patient = _resolvePatientFromMap(msg, fallbackName: patientName);
    final rawText = (msg['pesan'] ?? 'Konsultasi').toString();
    final displayText = rawText.startsWith('“') ? rawText : '“$rawText”';
    final timeStr = TimeUtils.formatChatTime(msg['created_at']);
    final consultationId = msg['id_konsultasi']?.toString();

    return GestureDetector(
      onTap: () => _navigateToChatWithPatient(patient, consultationId: consultationId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorderColor),
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
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  patient.initials,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0369A1),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          patientName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          timeStr,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayText,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem({
    required String initials,
    required String name,
    required String message,
    required String time,
    required String patientId,
  }) {
    return GestureDetector(
      onTap: () => _navigateToChat(patientId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorderColor),
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
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0369A1),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          time,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
  // SECTION 2: JADWAL HARI INI (Figma Node 1008:17556)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTodayScheduleTimelineSection() {
    final hasRealSchedules = _shouldShowRealData && _liveTodaySchedules.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Jadwal Hari ini',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 3),
                child: Row(
                  children: [
                    Text(
                      'Lihat Semua Jadwal',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_circle_right_outlined, color: _darkGreen, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (hasRealSchedules) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cardBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (int i = 0; i < _liveTodaySchedules.length; i++) ...[
                    _buildLiveScheduleTimelineItem(
                      _liveTodaySchedules[i],
                      isLast: i == _liveTodaySchedules.length - 1,
                    ),
                    if (i < _liveTodaySchedules.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ] else if (_shouldShowRealData && !_isLoading && _liveTodaySchedules.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cardBorderColor),
              ),
              child: Center(
                child: Text(
                  'Tidak ada jadwal konsultasi untuk hari ini.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Fallback for tests & initial render
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _cardBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Item 1: Budi Santoso
                  _buildMockTimelineItem(
                    name: 'Budi Santoso',
                    service: 'Konsultasi',
                    time: '14:00 - 14:30',
                    dotColor: const Color(0xFF10B981),
                    showLine: true,
                  ),
                  // Item 2: Ahmad Hidayat
                  _buildMockTimelineItem(
                    name: 'Ahmad Hidayat',
                    service: 'Konsultasi',
                    time: '15:00 - 15:30',
                    dotColor: const Color(0xFFCBD5E1),
                    showLine: false,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveScheduleTimelineItem(Map<String, dynamic> item, {required bool isLast}) {
    final patientName = (item['nama_pasien'] ?? 'Pasien').toString();
    final patient = _resolvePatientFromMap(item, fallbackName: patientName);
    final status = (item['status'] ?? '').toString().toLowerCase();
    final isOngoing = status == 'berlangsung';
    final isDone = status == 'selesai';
    final dotColor = isOngoing
        ? const Color(0xFF10B981)
        : (isDone ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1));

    String timeRange = 'Hari ini';
    final start = TimeUtils.cleanTimeString(item['jam_mulai']);
    final end = TimeUtils.cleanTimeString(item['jam_selesai']);
    if (start != null && end != null) {
      timeRange = '$start - $end WIB';
    } else if (start != null) {
      timeRange = '$start WIB';
    }

    final serviceType = (item['jenis_layanan'] == 'video' ? 'Video Call' : 'Konsultasi');
    final consultationId = item['id']?.toString();

    return InkWell(
      onTap: () => _navigateToChatWithPatient(patient, consultationId: consultationId),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 38,
                  color: const Color(0xFFE2E8F0),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  serviceType,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                timeRange,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockTimelineItem({
    required String name,
    required String service,
    required String time,
    required Color dotColor,
    required bool showLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 38,
                color: const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                service,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR (Figma Node 1008:17556)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.medical_services_outlined, 'Konsultasi'),
              _buildCenterPasienButton(),
              _buildNavItem(3, Icons.calendar_today_rounded, 'Jadwal'),
              _buildNavItem(4, Icons.person_outline_rounded, 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _isTopBarVisible = true;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Container(
              width: 20,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 7),
          Icon(
            icon,
            size: 22,
            color: isSelected ? _darkGreen : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? _darkGreen : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPasienButton() {
    final isSelected = _selectedIndex == 2;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = 2;
          _isTopBarVisible = true;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF044E2F).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF044E2F),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.people_alt_rounded, size: 21, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Pasien',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? _darkGreen : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _DokterChatBubblePainter extends CustomPainter {
  final bool isLeft;
  final Color color;
  final bool isSelected;

  const _DokterChatBubblePainter({
    required this.isLeft,
    this.color = Colors.white,
    this.isSelected = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const r = 16.0;
    final w = size.width;
    final h = size.height;
    final path = Path();

    if (isLeft) {
      // Chat Bubble with Tail at Bottom-Left (Figma Design)
      path.moveTo(6 + r, 0);
      path.lineTo(w - r, 0);
      path.arcToPoint(Offset(w, r), radius: const Radius.circular(r));
      path.lineTo(w, h - r);
      path.arcToPoint(Offset(w - r, h), radius: const Radius.circular(r));
      path.lineTo(16, h);
      // Tail curving down & out to bottom-left
      path.quadraticBezierTo(5, h + 2, 0, h + 5);
      path.quadraticBezierTo(4, h - 3, 6, h - 10);
      path.lineTo(6, r);
      path.arcToPoint(Offset(6 + r, 0), radius: const Radius.circular(r));
    } else {
      // Chat Bubble with Tail at Bottom-Right (Figma Design)
      path.moveTo(r, 0);
      path.lineTo(w - 6 - r, 0);
      path.arcToPoint(Offset(w - 6, r), radius: const Radius.circular(r));
      path.lineTo(w - 6, h - 10);
      // Tail curving down & out to bottom-right
      path.quadraticBezierTo(w - 4, h - 3, w, h + 5);
      path.quadraticBezierTo(w - 5, h + 2, w - 16, h);
      path.lineTo(r, h);
      path.arcToPoint(Offset(0, h - r), radius: const Radius.circular(r));
      path.lineTo(0, r);
      path.arcToPoint(Offset(r, 0), radius: const Radius.circular(r));
    }
    path.close();

    // Draw shadow
    canvas.drawShadow(
      path,
      Colors.black.withOpacity(0.12),
      isSelected ? 8 : 4,
      false,
    );

    // Draw bubble background
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    if (isSelected) {
      final borderPaint = Paint()
        ..color = const Color(0xFF044E2F).withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DokterChatBubblePainter oldDelegate) {
    return oldDelegate.isLeft != isLeft ||
        oldDelegate.color != color ||
        oldDelegate.isSelected != isSelected;
  }
}

class _DokterTopographyPainter extends CustomPainter {
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
// QUICK MENU ROUNDED ITEM COMPONENT (Interactive Bouncing Rounded Box + Label)
// ─────────────────────────────────────────────────────────────────────────────

class _QuickMenuRoundedItem extends StatefulWidget {
  final String label;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _QuickMenuRoundedItem({
    required this.label,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  State<_QuickMenuRoundedItem> createState() => _QuickMenuRoundedItemState();
}

class _QuickMenuRoundedItemState extends State<_QuickMenuRoundedItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: _isPressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeInOut,
            child: Container(
              width: 56,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE8F8F0),
                    Color(0xFFD1FAE5),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFBBEFD7),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF065A37).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(child: widget.iconWidget),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                  height: 1.25,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

