import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/pasien/pasien_home_screen.dart';
import 'screens/pasien/konsultasi/dokter_list_screen.dart';
import 'screens/pasien/pragi/pragi_home_view.dart';
import 'screens/pasien/pantau/pantau_dashboard_screen.dart';
import 'screens/pasien/obat/daftar_obat_screen.dart';
import 'screens/pasien/profile/profile_pasien_screen.dart';
import 'screens/pasien/reminder/reminder_list_screen.dart';
import 'screens/pasien/widgets/pasien_bottom_navbar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MASTER LAYOUT GIAT (Persistent TopBar, Content Switcher, & Navbar)
// ─────────────────────────────────────────────────────────────────────────────

class MasterLayout extends StatefulWidget {
  final String userName;
  final int initialIndex;

  const MasterLayout({
    super.key,
    this.userName = 'Pasien',
    this.initialIndex = 0,
  });

  @override
  State<MasterLayout> createState() => _MasterLayoutState();
}

class _MasterLayoutState extends State<MasterLayout> {
  late int _currentIndex;

  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF6FAF7);

  // Simulated notification data
  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Waktunya Minum Obat',
      'body': 'Candesartan 8 mg (1 tablet) sesudah makan.',
      'time': '10 menit yang lalu',
      'isRead': false,
      'icon': Icons.medication_rounded,
      'color': Color(0xFF22C55E),
    },
    {
      'title': 'Konsultasi Mendatang',
      'body': 'Sesi dengan Dr. Anisa Putri dijadwalkan pukul 14:00 WIB.',
      'time': '1 jam yang lalu',
      'isRead': false,
      'icon': Icons.medical_services_rounded,
      'color': Color(0xFF3B82F6),
    },
    {
      'title': 'Hasil Skrining PRAGI Tersedia',
      'body': 'Evaluasi risiko ginjal mandiri Anda telah diperbarui.',
      'time': 'Kemarin',
      'isRead': true,
      'icon': Icons.smart_toy_rounded,
      'color': Color(0xFF8B5CF6),
    },
  ];

  bool _isTopBarVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
        _isTopBarVisible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. CONTENT: Mentok ke atas (Full Bleed) ──
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // Tab 0: Home Pasien
                PasienHomeScreen(
                  userName: widget.userName,
                  isEmbedded: true,
                  onNavigateTab: _onTabSelected,
                ),

                // Tab 1: Konsultasi Dokter
                DokterListScreen(
                  userName: widget.userName,
                  isEmbedded: true,
                ),

                // Tab 2: PRAGI AI Assistant & Screening
                const PragiHomeView(
                  isEmbedded: true,
                ),

                // Tab 3: Pantau Kesehatan Ginjal
                PantauDashboardScreen(
                  userName: widget.userName,
                  isEmbedded: true,
                ),

                // Tab 4: Jadwal & Stok Obat
                const DaftarObatScreen(
                  isEmbedded: true,
                ),
              ],
            ),
          ),

          // ── 2. TOPBAR: Tetap / Netap di pojok kanan atas ──
          Positioned(
            top: 0,
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

  // ───────────────────────────────────────────────────────────────────────────
  // TOPBAR (Hanya di pojok kanan: Notifikasi di kiri, Profil di kanan, Transparan)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final hasUnread = _notifications.any((n) => n['isRead'] == false);

    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                // 1. Notifikasi (Lonceng di sisi kiri)
                Stack(
                  children: [
                    GestureDetector(
                      onLongPress: _showNotificationsModal,
                      child: IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          size: 22,
                          color: Color(0xFF1F2937),
                        ),
                        tooltip: 'Reminder',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReminderListScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),

                // 2. Profil Pasien (Avatar di sisi kanan)
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM NAVIGATION BAR (Figma GIAT Standard)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNavigationBar() {
    return PasienBottomNavbar(
      currentIndex: _currentIndex,
      onTap: _onTabSelected,
      userName: widget.userName,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NOTIFICATION MODAL BOTTOM SHEET
  // ───────────────────────────────────────────────────────────────────────────
  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Notifikasi',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              for (var item in _notifications) {
                                item['isRead'] = true;
                              }
                            });
                            setState(() {});
                          },
                          child: Text(
                            'Tandai Semua Dibaca',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _darkGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Color(0xFFF1F5F9)),

                  // Notification List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notif = _notifications[index];
                        final isRead = notif['isRead'] as bool;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBBF7D0),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: (notif['color'] as Color).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  notif['icon'] as IconData,
                                  color: notif['color'] as Color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif['title'] as String,
                                            style: GoogleFonts.inter(
                                              fontSize: 13.5,
                                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          notif['time'] as String,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif['body'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: const Color(0xFF475569),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
