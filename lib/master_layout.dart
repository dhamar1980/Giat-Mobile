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
import 'widgets/giat_background.dart';
import 'widgets/app_brand_title.dart';
import 'services/pasien_api_service.dart';
import 'screens/pasien/notifikasi/pasien_notifikasi_screen.dart';

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

  // Notification data
  List<Map<String, dynamic>> _notifications = [
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

  int _unreadCount = 0;
  bool _isTopBarVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fetchNotificationState();
  }

  Future<void> _fetchNotificationState() async {
    try {
      final countRes = await PasienApiService().getNotifikasiUnreadCount();
      if (countRes.success && mounted) {
        setState(() {
          _unreadCount = countRes.data ?? 0;
        });
      }
    } catch (_) {}

    try {
      final notifRes = await PasienApiService().getNotifikasi();
      if (notifRes.success && notifRes.data != null && mounted) {
        final List<Map<String, dynamic>> parsedList = [];
        for (var e in notifRes.data!) {
          if (e is Map) {
            final id = e['id'];
            final title = e['judul'] ?? e['title'] ?? 'Notifikasi GIAT';
            final body = e['pesan'] ?? e['body'] ?? e['message'] ?? '';
            final isRead = e['is_read'] == true || e['read_at'] != null || e['is_read'] == 1;
            final dt = e['created_at'] != null ? DateTime.tryParse(e['created_at'].toString()) : null;
            final timeStr = dt != null ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}' : 'Baru saja';
            parsedList.add({
              'id': id,
              'title': title,
              'body': body,
              'time': timeStr,
              'isRead': isRead,
              'icon': Icons.notifications_rounded,
              'color': const Color(0xFF065A37),
            });
          }
        }
        if (parsedList.isNotEmpty) {
          setState(() {
            _notifications = parsedList;
          });
        }
      }
    } catch (_) {}
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
        _isTopBarVisible = true;
      });
      _fetchNotificationState();
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
          // ── 0. BACKGROUND TOPOGRAPHY (Figma 1018:5009) ──
          const Positioned.fill(
            child: GiatBackground(showGradient: false),
          ),

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

          // ── 2. TOPBAR: Tetap / Netap di pojok atas (GINJAL SEHAT di kiri, Pill di kanan) ──
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

  // ───────────────────────────────────────────────────────────────────────────
  // TOPBAR (Hanya di pojok kanan: Notifikasi di kiri, Profil di kanan, Transparan)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final hasUnread = _notifications.any((n) => n['isRead'] == false);
    final showBrandTitle = _currentIndex != 2; // Hide only on PRAGI (tab 2) which has light bg

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. App Brand Title ("GINJAL SEHAT") di kiri, sejajar dengan pill di kanan
          if (showBrandTitle)
            const AppBrandTitle()
          else
            const SizedBox.shrink(),

          // 2. Kapsul Notifikasi & Profil (Ukuran asli yang proporsional & nyaman dilihat)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Notifikasi (Lonceng di sisi kiri)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(5),
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        size: 24,
                        color: Color(0xFF1F2937),
                      ),
                      tooltip: 'Notifikasi',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PasienNotifikasiScreen(),
                          ),
                        ).then((_) {
                          if (mounted) _fetchNotificationState();
                        });
                      },
                    ),
                    if (_unreadCount > 0 || hasUnread)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _unreadCount > 9 ? '9+' : (_unreadCount > 0 ? '$_unreadCount' : ''),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF044E2F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, size: 22, color: Colors.white),
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
  // BOTTOM NAVIGATION BAR (Figma GIAT Standard)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomNavigationBar() {
    return PasienBottomNavbar(
      currentIndex: _currentIndex,
      onTap: _onTabSelected,
      userName: widget.userName,
    );
  }


}
