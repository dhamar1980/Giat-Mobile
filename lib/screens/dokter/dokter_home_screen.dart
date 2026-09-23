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
import '../../login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DOKTER HOME SCREEN (Figma Node: 1008-17556)
// ─────────────────────────────────────────────────────────────────────────────

class DokterHomeScreen extends StatefulWidget {
  final String doctorName;

  const DokterHomeScreen({
    super.key,
    this.doctorName = 'Dr. Andi Pratama',
  });

  @override
  State<DokterHomeScreen> createState() => _DokterHomeScreenState();
}

class _DokterHomeScreenState extends State<DokterHomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
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

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar dari Akun Dokter',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Dokter?',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text('Keluar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(String patientId) {
    final patient = DokterMockData.patients.firstWhere(
      (p) => p.id == patientId,
      orElse: () => DokterMockData.patients.first,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DokterRoomChatScreen(patient: patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _bgColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          const DokterKonsultasiScreen(),
          const DokterPasienScreen(),
          const DokterJadwalScreen(),
          DokterProfileScreen(
            doctorName: widget.doctorName,
            onLogout: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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

        SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Section with Chat Bubbles (Figma Node 1008:17556) ──
                  _buildHeaderSection(),

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
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER SECTION (Figma Node 1008:17556)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderSection() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF22C55E),
            Color(0xFF16A34A),
            Color(0xFF0D7A3E),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DokterHeaderCurvePainter(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Pill (Bell & Profile)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
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
                            icon: const Icon(Icons.notifications_none_rounded, size: 22, color: Color(0xFF1F2937)),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DokterNotifikasiScreen()),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() => _selectedIndex = 4);
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
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Chat Bubble Left (Selamat Datang Kembali) - White Background
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          0,
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
                        constraints: const BoxConstraints(maxWidth: 300),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Selamat Datang Kembali,\n${widget.doctorName} 👏🏻',
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF065A37),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.done_all_rounded,
                                size: 15,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Chat Bubble Right (Berikut ringkasan aktivitas...) - White Background
                Align(
                  alignment: Alignment.centerRight,
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
                        isLeft: false,
                        isSelected: false,
                      ),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.fromLTRB(16, 12, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Berikut ringkasan aktivitas Anda\nhari ini. ✨✨',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF065A37),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.done_all_rounded,
                                size: 15,
                                color: Color(0xFF38BDF8),
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

          // Card 1: Konsultasi (Budi Santoso)
          _buildConsultationActivityCard(),

          const SizedBox(height: 14),

          // Card 2: Membuat resep (Budi Santoso with medicine breakdown)
          _buildPrescriptionActivityCard(),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pesan Terbaru',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),

          // Message Card 1: Budi Santoso (BS)
          _buildMessageItem(
            initials: 'BS',
            name: 'Budi Santoso',
            message: '“Dok, saya sudah mengirim hasil lab”',
            time: '2 menit',
            patientId: 'p-1',
          ),

          const SizedBox(height: 12),

          // Message Card 2: Siti Wijaya (SW)
          _buildMessageItem(
            initials: 'SW',
            name: 'Siti Wijaya',
            message: '“Obat sudah diminum sesuai jadwal.”',
            time: '5 menit',
            patientId: 'p-2',
          ),
        ],
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
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
                            'Budi Santoso',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Konsultasi',
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
                          '14:00 - 14:30',
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

                // Item 2: Ahmad Hidayat
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ahmad Hidayat',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Konsultasi',
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
                          '15:00 - 15:30',
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
              ],
            ),
          ),
        ],
      ),
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
        setState(() => _selectedIndex = index);
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
        setState(() => _selectedIndex = 2);
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
    final paint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 6; i++) {
      final path = Path();
      final yOffset = size.height * 0.4 + (i * 70);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.3,
        yOffset - 30,
        size.width * 0.7,
        yOffset + 40,
        size.width,
        yOffset - 10,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DokterHeaderCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final yOffset = 40.0 + (i * 40);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.25,
        yOffset + 30,
        size.width * 0.75,
        yOffset - 30,
        size.width,
        yOffset + 20,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
