import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/apotek_models.dart';
import 'notifikasi/apotek_notifikasi_screen.dart';
import 'pesanan/apotek_pesanan_screen.dart';
import 'resep/apotek_resep_screen.dart';
import 'obat/apotek_obat_screen.dart';
import 'profile/apotek_profile_screen.dart';
import '../../login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APOTEKER HOME SCREEN (Figma Node: 1100-18253)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekerHomeScreen extends StatefulWidget {
  final String apotekerName;

  const ApotekerHomeScreen({
    super.key,
    this.apotekerName = 'Budi',
  });

  @override
  State<ApotekerHomeScreen> createState() => _ApotekerHomeScreenState();
}

class _ApotekerHomeScreenState extends State<ApotekerHomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _pesananInitialTab = 0;
  int _resepInitialTab = 0;
  String _obatInitialFilter = 'Semua';

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Colors based on Figma design
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bubbleGreen = Color(0xFF22C55E);
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
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar dari Akun Apoteker',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Apoteker?',
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

  void _switchToTab(int tabIndex, {int? pesananTab, int? resepTab, String? obatFilter}) {
    setState(() {
      _selectedIndex = tabIndex;
      if (pesananTab != null) _pesananInitialTab = pesananTab;
      if (resepTab != null) _resepInitialTab = resepTab;
      if (obatFilter != null) _obatInitialFilter = obatFilter;
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          ApotekPesananScreen(
            key: ValueKey('pesanan-$_pesananInitialTab'),
            initialTabIndex: _pesananInitialTab,
            onNavigateToTab: (tab) => _switchToTab(tab),
          ),
          ApotekResepScreen(
            key: ValueKey('resep-$_resepInitialTab'),
            initialTabIndex: _resepInitialTab,
            onNavigateToOrderTab: (tab) {
              _switchToTab(1, pesananTab: tab);
            },
          ),
          ApotekObatScreen(
            key: ValueKey('obat-$_obatInitialFilter'),
            initialFilter: _obatInitialFilter,
          ),
          ApotekProfileScreen(
            apotekerName: widget.apotekerName,
            onLogout: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeTab() {
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Background Topography
        Positioned.fill(
          child: CustomPaint(
            painter: _ApotekerTopographyPainter(),
          ),
        ),

        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Section with Chat Bubbles ──
                  _buildHeaderSection(topPadding),

                  const SizedBox(height: 20),

                  // ── Section 1: Perlu Perhatian (3 Cards) ──
                  _buildAttentionSection(),

                  const SizedBox(height: 24),

                  // ── Section 2: Aktivitas Terbaru (Timeline) ──
                  _buildRecentActivitySection(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER SECTION (Mockup: Green gradient, action pill & white chat bubbles)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderSection(double topPadding) {
    final unreadNotifs = ApotekMockData.notifications.where((n) => !n.isRead).length;

    return ClipPath(
      clipper: _ApotekerHeaderClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF22C55E),
              Color(0xFF16A34A),
              Color(0xFF065A37),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ApotekerHeaderCurvePainter(),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 8, 20, 46),
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
                            Stack(
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
                                      MaterialPageRoute(builder: (_) => const ApotekNotifikasiScreen()),
                                    ).then((_) => setState(() {}));
                                  },
                                ),
                                if (unreadNotifs > 0)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDC2626),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _switchToTab(4),
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

                  const SizedBox(height: 16),

                  // Chat Bubble 1 (Left Aligned - White Bubble)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildChatBubble(
                      isLeft: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang Kembali,\n${widget.apotekerName}! 👋',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF065A37),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Spacer(),
                              Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF38BDF8)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Chat Bubble 2 (Right Aligned - White Bubble)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildChatBubble(
                      isLeft: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Semoga aktivitas hari ini\ndiberikan kelancaran ya... ✨✨',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF065A37),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Spacer(),
                              Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF38BDF8)),
                            ],
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
      ),
    );
  }

  Widget _buildChatBubble({
    required bool isLeft,
    required Widget child,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 290),
          padding: const EdgeInsets.fromLTRB(16, 12, 14, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isLeft ? const Radius.circular(4) : const Radius.circular(16),
              bottomRight: isLeft ? const Radius.circular(16) : const Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: child,
        ),
        // WhatsApp style speech bubble tail
        Positioned(
          bottom: 0,
          left: isLeft ? -7 : null,
          right: isLeft ? null : -7,
          child: CustomPaint(
            size: const Size(8, 12),
            painter: _ChatTailPainter(isLeft: isLeft),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 1: PERLU PERHATIAN (3 Summary Cards)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAttentionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perlu Perhatian',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Card 1: 12 Pesanan belum diproses (Dark Green)
              Expanded(
                child: _buildAttentionCard(
                  count: '12',
                  title: 'Pesanan belum\ndiproses',
                  bgColor: const Color(0xFF065A37),
                  textColor: Colors.white,
                  countColor: Colors.white,
                  borderColor: null,
                  watermarkColor: Colors.white.withOpacity(0.08),
                  onTap: () => _switchToTab(1, pesananTab: 0),
                ),
              ),
              const SizedBox(width: 10),

              // Card 2: 5 Resep belum diterima (Light Mint/Blue with dark border)
              Expanded(
                child: _buildAttentionCard(
                  count: '5',
                  title: 'Resep belum\nditerima',
                  bgColor: const Color(0xFFF0FDF9),
                  textColor: const Color(0xFF1E293B),
                  countColor: const Color(0xFF0F172A),
                  borderColor: const Color(0xFF065A37).withOpacity(0.85),
                  watermarkColor: const Color(0xFF065A37).withOpacity(0.06),
                  onTap: () => _switchToTab(2, resepTab: 0),
                ),
              ),
              const SizedBox(width: 10),

              // Card 3: 3 Stok Menipis (Soft Red/Pink)
              Expanded(
                child: _buildAttentionCard(
                  count: '3',
                  title: 'Stok Menipis',
                  bgColor: const Color(0xFFFEF2F2),
                  textColor: const Color(0xFFDC2626),
                  countColor: const Color(0xFFDC2626),
                  borderColor: const Color(0xFFFCA5A5),
                  watermarkColor: const Color(0xFFDC2626).withOpacity(0.06),
                  onTap: () => _switchToTab(3, obatFilter: 'Stock Menipis'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionCard({
    required String count,
    required String title,
    required Color bgColor,
    required Color textColor,
    required Color countColor,
    required Color? borderColor,
    required Color watermarkColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null ? Border.all(color: borderColor, width: 1.2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CardWavePainter(color: watermarkColor),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        count,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: countColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 2: AKTIVITAS TERBARU (Timeline / Stepper Card)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRecentActivitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivitas Terbaru',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: CustomPaint(
                      size: const Size(120, 80),
                      painter: _CardWavePainter(color: const Color(0xFF10B981).withOpacity(0.08)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    child: Column(
                      children: [
                        _buildTimelineItem(
                          title: 'Resep #RX-00110 telah diterima',
                          time: '10 menit lalu',
                          circleColor: const Color(0xFF065A37),
                          showLineBelow: true,
                          onTap: () => _switchToTab(2, resepTab: 1),
                        ),
                        _buildTimelineItem(
                          title: 'Resep #ORD-00124 selesai',
                          time: '25 menit lalu',
                          circleColor: const Color(0xFF22C55E),
                          showLineBelow: true,
                          onTap: () => _switchToTab(1, pesananTab: 2),
                        ),
                        _buildTimelineItem(
                          title: 'Stok Paracetamol 500 mg menipis',
                          time: '1 jam lalu',
                          circleColor: const Color(0xFFDC2626),
                          showLineBelow: false,
                          onTap: () => _switchToTab(3, obatFilter: 'Stock Menipis'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String time,
    required Color circleColor,
    required bool showLineBelow,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
                if (showLineBelow)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFF10B981),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: showLineBelow ? 20 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 12,
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR (Mockup design: 5 items with center elevated Resep)
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
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.receipt_long_outlined, 'Pesanan'),
              _buildCenterResepButton(),
              _buildNavItem(3, Icons.local_hospital_outlined, 'Obat'),
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
              width: 22,
              height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 9),
          Icon(
            icon,
            size: 24,
            color: isSelected ? _darkGreen : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 4),
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

  Widget _buildCenterResepButton() {
    final isSelected = _selectedIndex == 2;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = 2);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF044E2F),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF044E2F).withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.assignment_turned_in_rounded, size: 24, color: Colors.white),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Resep',
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
// CUSTOM CLIPPERS & PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _ApotekerHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 35);
    // Smooth asymmetric curve matching mockup
    path.cubicTo(
      size.width * 0.25,
      size.height + 18,
      size.width * 0.65,
      size.height - 45,
      size.width,
      size.height - 25,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ChatTailPainter extends CustomPainter {
  final bool isLeft;
  const _ChatTailPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardWavePainter extends CustomPainter {
  final Color color;
  const _CardWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final yOffset = size.height * 0.2 + (i * 20);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.3,
        yOffset - 15,
        size.width * 0.7,
        yOffset + 15,
        size.width,
        yOffset - 5,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ApotekerTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 10; i++) {
      final path = Path();
      final yOffset = size.height * 0.35 + (i * 65);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.3,
        yOffset - 25,
        size.width * 0.65,
        yOffset + 35,
        size.width,
        yOffset - 15,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ApotekerHeaderCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final yOffset = 30.0 + (i * 45);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.25,
        yOffset + 35,
        size.width * 0.75,
        yOffset - 35,
        size.width,
        yOffset + 25,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

