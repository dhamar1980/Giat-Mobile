import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../onboarding_screen.dart';
import '../../services/auth_service.dart';
import 'akun/admin_akun_screen.dart';
import 'edukasi/admin_edukasi_screen.dart';
import 'models/admin_models.dart';
import 'notifikasi/admin_notifikasi_screen.dart';
import 'profile/admin_profile_screen.dart';
import 'update_sistem/admin_update_sistem_screen.dart';
import 'widgets/admin_header.dart';

class AdminHomeScreen extends StatefulWidget {
  final String adminName;
  final String? adminEmail;

  const AdminHomeScreen({
    super.key,
    this.adminName = 'Admin GIAT',
    this.adminEmail,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _border = Color(0xFFE2E8F0);

  int _selectedIndex = 0; // 0: Home, 1: Kelola Akun, 2: Kelola Edukasi, 3: Update Notifikasi
  AdminUserRole? _akunRoleFilter;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    AdminStore.instance.syncAdminProfile(
      nama: widget.adminName,
      email: widget.adminEmail,
    );
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
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

  void _openAkun({AdminUserRole? roleFilter}) {
    setState(() {
      _akunRoleFilter = roleFilter;
      _selectedIndex = 1;
    });
  }

  void _openNotifikasi() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminNotifikasiScreen()),
    );
  }

  void _openUpdateSistem() {
    setState(() {
      _selectedIndex = 3;
    });
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminProfileScreen(onLogout: _handleLogout),
      ),
    );
  }

  Widget _buildTopActionPill(AdminStore store) {
    final hasUnreadNotif = store.unreadNotificationsCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
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
                padding: const EdgeInsets.all(5),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 23,
                  color: Color(0xFF1F2937),
                ),
                onPressed: _openNotifikasi,
              ),
              if (hasUnreadNotif)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 8.5,
                    height: 8.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _openProfile,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFF044E2F),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                size: 19,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final store = AdminStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final latestUpdate =
            store.updates.isNotEmpty ? store.updates.first : null;
        final topActionPill = _buildTopActionPill(store);

        return Scaffold(
          backgroundColor: _bgColor,
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              // Tab 0: Home Admin
              _buildHomeTab(store, latestUpdate),

              // Tab 1: Kelola Akun
              AdminAkunScreen(
                initialRoleFilter: _akunRoleFilter,
                trailingAction: topActionPill,
              ),

              // Tab 2: Kelola Edukasi
              AdminEdukasiScreen(
                trailingAction: topActionPill,
              ),

              // Tab 3: Update Notifikasi
              AdminUpdateSistemScreen(
                trailingAction: topActionPill,
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildHomeTab(AdminStore store, AdminSystemUpdate? latestUpdate) {
    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: AdminTopographyPainter()),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminCurvedHeader(
              title: 'Selamat Datang Kembali, ${store.adminNama}! 👋',
              subtitle:
                  'Kelola akun pengguna, hak akses, edukasi kesehatan & notifikasi sistem GIAT. ✨',
              trailingAction: _buildTopActionPill(store),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 3 Card Jumlah Akun (Dokter, Pasien, Apotek) ──
                        Row(
                          children: [
                            _buildRoleCountCard(
                              role: AdminUserRole.dokter,
                              count: store.countRole(AdminUserRole.dokter),
                            ),
                            const SizedBox(width: 10),
                            _buildRoleCountCard(
                              role: AdminUserRole.pasien,
                              count: store.countRole(AdminUserRole.pasien),
                            ),
                            const SizedBox(width: 10),
                            _buildRoleCountCard(
                              role: AdminUserRole.apotek,
                              count: store.countRole(AdminUserRole.apotek),
                            ),
                          ],
                        ),

                        if (latestUpdate != null) ...[
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Update Sistem Terkini',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              GestureDetector(
                                onTap: _openUpdateSistem,
                                child: Text(
                                  'Kirim Baru →',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _darkGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _openUpdateSistem,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: latestUpdate.tipe.color
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          latestUpdate.tipe.label,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: latestUpdate.tipe.color,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        adminTimeAgo(latestUpdate.publishedAt),
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    latestUpdate.judul,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    latestUpdate.deskripsi,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        // ── Riwayat Perubahan Hak Akses ──
                        Text(
                          'Riwayat Perubahan Hak Akses',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _border),
                          ),
                          child: Column(
                            children: List.generate(
                              store.logs.take(5).length,
                              (i) {
                                final log = store.logs[i];
                                final isLast =
                                    i == store.logs.take(5).length - 1;
                                return _buildTimelineItem(
                                  title: '${log.namaUser} — ${log.aksi}',
                                  time: adminTimeAgo(log.waktu),
                                  showLineBelow: !isLast,
                                  onTap: () => _openAkun(),
                                );
                              },
                            ),
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
      ],
    );
  }

  Widget _buildRoleCountCard({
    required AdminUserRole role,
    required int count,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _openAkun(roleFilter: role),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
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
                ),
                child: Icon(role.icon, size: 20, color: _darkGreen),
              ),
              const SizedBox(height: 6),
              Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _darkGreen,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Akun ${role.label}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR ADMIN (Home, Kelola Akun, Kelola Edukasi, Update Notifikasi)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.manage_accounts_rounded, 'Kelola Akun'),
              _buildNavItem(2, Icons.menu_book_rounded, 'Kelola Edukasi'),
              _buildNavItem(3, Icons.campaign_rounded, 'Update Notifikasi'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (index == 1) _akunRoleFilter = null;
            _selectedIndex = index;
          });
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _darkGreen : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String time,
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
                  decoration: const BoxDecoration(
                    color: _darkGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (showLineBelow)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFD1FAE5),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: showLineBelow ? 16 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
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
}
