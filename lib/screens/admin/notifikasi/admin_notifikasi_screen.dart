import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../akun/admin_akun_screen.dart';
import '../edukasi/admin_edukasi_screen.dart';
import '../models/admin_models.dart';
import '../widgets/admin_header.dart';

/// Halaman Notifikasi Masuk untuk Administrator (dibuka dari ikon lonceng di Header).
/// Khusus untuk menerima pemberitahuan sistem, pendaftaran akun, verifikasi, dll.
class AdminNotifikasiScreen extends StatefulWidget {
  const AdminNotifikasiScreen({super.key});

  @override
  State<AdminNotifikasiScreen> createState() => _AdminNotifikasiScreenState();
}

class _AdminNotifikasiScreenState extends State<AdminNotifikasiScreen> {
  static const _primaryGreen = Color(0xFF006D37);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _textColor = Color(0xFF091D2E);
  static const _subtextColor = Color(0xFF475569);
  static const _border = Color(0xFFE2E8F0);

  String _activeFilter = 'semua'; // 'semua' | 'unread'

  @override
  void initState() {
    super.initState();
    AdminStore.instance.fetchNotifications();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'akun':
        return Icons.person_add_alt_1_outlined;
      case 'akses':
        return Icons.verified_user_outlined;
      case 'edukasi':
        return Icons.menu_book_outlined;
      case 'sistem':
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getIconBgForType(String type) {
    switch (type) {
      case 'akun':
        return const Color(0xFFE0F2FE);
      case 'akses':
        return const Color(0xFFD5E8F0);
      case 'edukasi':
        return const Color(0xFFEDE9FE);
      case 'sistem':
      default:
        return const Color(0xFFDCFCE7);
    }
  }

  void _handleCardTap(BuildContext context, AdminNotificationItem item) {
    final store = AdminStore.instance;
    store.markNotificationRead(item.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _getIconBgForType(item.tipe),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        _getIconForType(item.tipe),
                        color: _textColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.judul,
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_outlined,
                              size: 13,
                              color: _subtextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.waktuText ?? adminTimeAgo(item.createdAt),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFFF1F5F9), thickness: 1),
              const SizedBox(height: 14),
              Text(
                'Detail Notifikasi',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _subtextColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.pesan,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: _textColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              if (item.tipe == 'akun' || item.tipe == 'akses')
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminAkunScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Buka Kelola Akun & Hak Akses',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else if (item.tipe == 'edukasi')
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminEdukasiScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Buka Kelola Edukasi Kesehatan',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryGreen,
                      side: const BorderSide(color: _primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final unreadCount = store.unreadNotificationsCount;
          final displayedList = _activeFilter == 'unread'
              ? store.notifications.where((n) => !n.isRead).toList()
              : store.notifications;

          return Scaffold(
            backgroundColor: _bgColor,
            body: Stack(
              children: [
                // ── Background Topography ──
                const Positioned.fill(
                  child: CustomPaint(painter: AdminTopographyPainter()),
                ),

                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top Header Bar (Kembali & Notifikasi stacked vertically) ──
                      AdminSubpageHeader(
                        title: 'Notifikasi',
                        trailing: unreadCount > 0
                            ? GestureDetector(
                                onTap: () {
                                  store.markAllNotificationsRead();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Semua notifikasi telah ditandai dibaca',
                                      ),
                                      backgroundColor: _primaryGreen,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.done_all_rounded,
                                        size: 14,
                                        color: _primaryGreen,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tandai Dibaca',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: _primaryGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : null,
                      ),

                      const SizedBox(height: 12),

                      // ── Filter Chips (Semua & Belum Dibaca) ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _buildChipButton(
                              title: 'Semua',
                              count: store.notifications.length,
                              isSelected: _activeFilter == 'semua',
                              onTap: () =>
                                  setState(() => _activeFilter = 'semua'),
                            ),
                            const SizedBox(width: 8),
                            _buildChipButton(
                              title: 'Belum Dibaca',
                              count: unreadCount,
                              isSelected: _activeFilter == 'unread',
                              onTap: () =>
                                  setState(() => _activeFilter = 'unread'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Daftar Kartu Notifikasi Masuk ──
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: displayedList.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  color: _primaryGreen,
                                  onRefresh: store.fetchNotifications,
                                  child: ListView.builder(
                                    itemCount: displayedList.length,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = displayedList[index];
                                      return _buildNotificationCard(
                                        context,
                                        item,
                                        store,
                                      );
                                    },
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
        },
      ),
    );
  }

  Widget _buildChipButton({
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryGreen : _border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : _subtextColor,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : _textColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AdminNotificationItem item,
    AdminStore store,
  ) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (_) {
        store.deleteNotification(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notifikasi "${item.judul}" dihapus'),
            backgroundColor: const Color(0xFF334155),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _handleCardTap(context, item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isRead
                  ? _border
                  : _primaryGreen.withValues(alpha: 0.35),
              width: item.isRead ? 0.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryGreen.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle decorative organic bubble on the left (Figma Bubbles)
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: CustomPaint(
                    painter: AdminCardBubblePainter(),
                  ),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container (Soft background with rounded corners)
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _getIconBgForType(item.tipe),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          _getIconForType(item.tipe),
                          color: _textColor,
                          size: 26,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Info Column: Title & Message
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.judul,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _textColor,
                                    ),
                                  ),
                                ),
                                if (!item.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: const BoxDecoration(
                                      color: _primaryGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.pesan,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: _subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Right Side: Time Pill Badge
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _textColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.waktuText ?? adminTimeAgo(item.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 40,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada notifikasi masuk',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pemberitahuan aktivitas sistem dan pengguna akan muncul di sini',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _subtextColor,
            ),
          ),
        ],
      ),
    );
  }
}

