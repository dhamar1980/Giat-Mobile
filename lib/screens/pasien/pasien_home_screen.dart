import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'reminder/reminder_list_screen.dart';
import 'profile/profile_pasien_screen.dart';
import 'edukasi/edukasi_list_screen.dart';
import 'edukasi/edukasi_detail_screen.dart';
import 'widgets/pasien_bottom_navbar.dart';
import '../../master_layout.dart';
import '../../widgets/giat_background.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PASIEN HOME SCREEN (Figma Node: 771-5845)
// ─────────────────────────────────────────────────────────────────────────────

class PasienHomeScreen extends StatefulWidget {
  final String userName;
  final bool isEmbedded;
  final ValueChanged<int>? onNavigateTab;

  const PasienHomeScreen({
    super.key,
    this.userName = 'Pasien',
    this.isEmbedded = false,
    this.onNavigateTab,
  });

  @override
  State<PasienHomeScreen> createState() => _PasienHomeScreenState();
}

class _PasienHomeScreenState extends State<PasienHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // Colors based on Figma design
  static const _darkGreen = Color(0xFF065A37);
  static const _chatBubbleGreen = Color(0xFF006D37);
  static const _chatBubbleCheckBlue = Color(0xFF34A0FF);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Header Section with Green Arc & Chat Bubbles (Fixed at top, does not scroll) ──
        _buildHeaderSection(),

        // ── Scrollable Body Content Below Header ──
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Quick Access Menu: 4 Circular Buttons (Mobile JKN Style) ──
                    _buildQuickActionMenu(),

                    const SizedBox(height: 22),

                    // ── Section 1: Pengingat Hari Ini ──
                    _buildReminderSection(),

                    const SizedBox(height: 24),

                    // ── Section 2: Edukasi Untukmu ──
                    _buildEducationSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HomeTopographyPainter(),
            ),
          ),
          Positioned.fill(
            child: content,
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topography
          Positioned.fill(
            child: CustomPaint(
              painter: _HomeTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(child: content),

                // ── Bottom Navigation Bar ──
                _buildBottomNavigationBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER SECTION (Figma Node 771:5845)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderSection() {
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
              painter: _HeaderCurvePainter(),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              widget.isEmbedded
                  ? (MediaQuery.of(context).padding.top + 78)
                  : (MediaQuery.of(context).padding.top + 16),
              20,
              36,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Pill (Bell & Profile) - hidden in embedded MasterLayout mode
                if (!widget.isEmbedded) ...[
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
                              color: Colors.black.withValues(alpha: 0.08),
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
                                  icon: const Icon(Icons.notifications_none_rounded, size: 22, color: Color(0xFF1F2937)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ReminderListScreen(),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
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
                  const SizedBox(height: 12),
                ],

                // Single Chat Bubble
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                      ),
                      border: Border.all(
                        color: _chatBubbleGreen,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _chatBubbleGreen.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Selamat Datang Kembali, ${widget.userName} 👋🏻',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _chatBubbleGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rawat ginjal hari ini demi masa depan. Langkah kecilmu menjaga ginjal tetap sehat. ✨✨',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: _chatBubbleGreen.withValues(alpha: 0.9),
                            height: 1.35,
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

  // ───────────────────────────────────────────────────────────────────────────
  // NAVIGATION HELPER (Tab switcher / Screen router)
  // ───────────────────────────────────────────────────────────────────────────
  void _navigateToTab(int tabIndex) {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(tabIndex);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MasterLayout(
            userName: widget.userName,
            initialIndex: tabIndex,
          ),
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // QUICK ACTION MENU (4 Menu Cepat Konsisten - Rounded Box Style)
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

          // 2. Skrining Resiko Penyakit CKD
          Expanded(
            child: _QuickMenuRoundedItem(
              label: 'Skrining Resiko\nPenyakit CKD',
              iconWidget: Image.asset(
                'assets/images/pragi.png',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.smart_toy_rounded,
                  color: _darkGreen,
                  size: 27,
                ),
              ),
              onTap: () => _navigateToTab(2),
            ),
          ),

          // 3. Pantau
          Expanded(
            child: _QuickMenuRoundedItem(
              label: 'Pantau',
              iconWidget: const Icon(
                Icons.monitor_heart_rounded,
                color: _darkGreen,
                size: 27,
              ),
              onTap: () => _navigateToTab(3),
            ),
          ),

          // 4. Obat
          Expanded(
            child: _QuickMenuRoundedItem(
              label: 'Obat',
              iconWidget: const Icon(
                Icons.medication_rounded,
                color: _darkGreen,
                size: 27,
              ),
              onTap: () => _navigateToTab(4),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REMINDERS SECTION (Figma Node 771:5845)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildReminderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengingat Hari Ini',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReminderListScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'Lihat Semua',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_circle_right_outlined, size: 16, color: _darkGreen),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Card 1: Minum Obat
          _buildReminderCard(
            icon: Icons.medication_rounded,
            iconBg: const Color(0xFF065A37),
            title: 'Minum Obat',
            time: '08:00 WIB',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReminderListScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // Card 2: Kontrol Kesehatan
          _buildReminderCard(
            icon: Icons.calendar_month_rounded,
            iconBg: const Color(0xFF065A37),
            title: 'Kontrol Kesehatan',
            time: 'Besok, 10:00 WIB',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReminderListScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String time,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(painter: _SubtleCardOverlayPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          time,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
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
  // EDUCATION SECTION (Figma Node 771:5845)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edukasi Untukmu',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EdukasiListScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'Lihat Semua',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_circle_right_outlined, size: 16, color: _darkGreen),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildEducationCard(
                title: 'Kenali Tanda-Tanda Penyakit Ginjal Sejak Dini',
                category: 'Artikel',
                imagePath: 'assets/images/kidneys.jpg',
                isAsset: true,
              ),
              const SizedBox(width: 14),
              _buildEducationCard(
                title: 'Makanan & Pola Hidup Sehat untuk Ginjal Kuat',
                category: 'Nutrisi',
                imagePath: 'assets/images/kidneys.jpg',
                isAsset: true,
              ),
              const SizedBox(width: 14),
              _buildEducationCard(
                title: 'Pentingnya Cukup Minum Air Putih Setiap Hari',
                category: 'Tips Sehat',
                imagePath: 'assets/images/kidneys.jpg',
                isAsset: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEducationCard({
    required String title,
    required String category,
    required String imagePath,
    bool isAsset = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EdukasiDetailScreen(
              article: {
                'title': title,
                'category': category,
                'date': '15 Sept 2026',
                'image': imagePath,
                'content': 'Menjaga kesehatan ginjal membutuhkan pemantauan rutin, pembatasan garam dapur, dan kontrol tekanan darah serta fungsi penyaringan ginjal.',
              },
            ),
          ),
        );
      },
      child: Container(
        width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0),
                  ),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFD1FAE5),
                      child: const Center(
                        child: Icon(Icons.health_and_safety_rounded, size: 48, color: _darkGreen),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _darkGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                  height: 1.3,
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
  // BOTTOM NAVIGATION BAR (Figma Node 1100:33127)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNavigationBar() {
    return PasienBottomNavbar(
      currentIndex: 0,
      userName: widget.userName,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTERS FOR SUBTLE WAVY BACKGROUND PATTERNS
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    GiatBackgroundPainter.paintBackground(
      canvas,
      size,
      showGradient: true,
      showLines: true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
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

class _SubtleCardOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.9, size.width, size.height * 0.4);
    canvas.drawPath(path, paint);
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
            height: 32,
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
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
