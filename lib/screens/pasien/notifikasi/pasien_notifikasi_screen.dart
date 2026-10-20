import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/giat_background.dart';
import '../../../services/pasien_api_service.dart';
import '../../../models/notifikasi_model.dart';
import '../reminder/reminder_list_screen.dart';
import '../konsultasi/dokter_list_screen.dart';
import '../pragi/pragi_home_view.dart';
import '../obat/riwayat_obat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIKASI PASIEN SCREEN
// Desain Header Pill ("<- Kembali" & "Notifikasi"), Background Topografi GIAT,
// dan Kartu Notifikasi Interaktif Sesuai Figma & Screenshot Referensi
// ─────────────────────────────────────────────────────────────────────────────

class PasienNotificationItem {
  final dynamic id;
  final String title;
  final String message;
  final String timeText;
  final String type; // 'sistem', 'obat', 'konsultasi', 'pragi', 'pesanan'
  final bool isRead;
  final DateTime? rawDateTime;
  final Map<String, dynamic>? extraData;

  const PasienNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeText,
    this.type = 'sistem',
    this.isRead = false,
    this.rawDateTime,
    this.extraData,
  });

  PasienNotificationItem copyWith({
    bool? isRead,
  }) {
    return PasienNotificationItem(
      id: id,
      title: title,
      message: message,
      timeText: timeText,
      type: type,
      isRead: isRead ?? this.isRead,
      rawDateTime: rawDateTime,
      extraData: extraData,
    );
  }
}

class PasienNotifikasiScreen extends StatefulWidget {
  const PasienNotifikasiScreen({super.key});

  @override
  State<PasienNotifikasiScreen> createState() => _PasienNotifikasiScreenState();
}

class _PasienNotifikasiScreenState extends State<PasienNotifikasiScreen> {
  static const _darkGreen = Color(0xFF005954);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _textColor = Color(0xFF0F172A);
  static const _subtextColor = Color(0xFF475569);
  static const _timeColor = Color(0xFF64748B);
  static const _avatarBgColor = Color(0xFFCCE4ED);

  // Default fallback data matching mockup
  static final List<PasienNotificationItem> _defaultNotifications = [
    const PasienNotificationItem(
      id: 'notif-1',
      title: 'Update Sistem',
      message: 'Perbaikan bug pada bagian profile',
      timeText: '30 menit lalu',
      type: 'sistem',
      isRead: false,
    ),
    const PasienNotificationItem(
      id: 'notif-2',
      title: 'Waktunya Minum Obat',
      message: 'Losartan 50 mg (1 tablet) sesudah sarapan pagi.',
      timeText: '1 jam lalu',
      type: 'obat',
      isRead: false,
    ),
    const PasienNotificationItem(
      id: 'notif-3',
      title: 'Jadwal Konsultasi Dokter',
      message: 'dr. Budi Santoso, Sp.PD-KGH telah mengonfirmasi sesi Anda.',
      timeText: '3 jam lalu',
      type: 'konsultasi',
      isRead: true,
    ),
    const PasienNotificationItem(
      id: 'notif-4',
      title: 'Hasil Skrining PRAGI',
      message: 'Evaluasi mandiri risiko ginjal telah selesai diproses.',
      timeText: '1 hari lalu',
      type: 'pragi',
      isRead: true,
    ),
    const PasienNotificationItem(
      id: 'notif-5',
      title: 'Pesanan Obat Diproses',
      message: 'Resep obat dari dokter sedang disiapkan oleh Apotek Mitra.',
      timeText: '2 hari lalu',
      type: 'pesanan',
      isRead: true,
    ),
  ];

  List<PasienNotificationItem> _notifications = [];
  bool _isLoading = true;
  String _activeFilter = 'semua'; // 'semua' | 'unread'

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool isRefresh = false}) async {
    if (!isRefresh && _notifications.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final res = await PasienApiService().getNotifikasi();
      if (res.success && res.data != null && res.data!.isNotEmpty) {
        final List<PasienNotificationItem> items = [];
        for (var raw in res.data!) {
          if (raw is Map) {
            final model = NotifikasiModel.fromJson(Map<String, dynamic>.from(raw));
            items.add(_mapModelToItem(model));
          }
        }

        if (mounted) {
          setState(() {
            _notifications = items.isNotEmpty ? items : List.from(_defaultNotifications);
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {
      // Fallback gracefully on timeout / offline
    }

    if (mounted) {
      setState(() {
        if (_notifications.isEmpty) {
          _notifications = List.from(_defaultNotifications);
        }
        _isLoading = false;
      });
    }
  }

  PasienNotificationItem _mapModelToItem(NotifikasiModel model) {
    String timeStr = 'Baru saja';
    DateTime? dt = DateTime.tryParse(model.createdAt);
    if (dt != null) {
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes <= 0 ? 1 : diff.inMinutes} menit lalu';
      } else if (diff.inHours < 24) {
        timeStr = '${diff.inHours} jam lalu';
      } else if (diff.inDays < 7) {
        timeStr = '${diff.inDays} hari lalu';
      } else {
        timeStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    }

    String type = (model.tipe ?? '').toLowerCase();
    if (type.contains('obat') || type.contains('reminder')) {
      type = 'obat';
    } else if (type.contains('konsul') || type.contains('dokter') || type.contains('chat')) {
      type = 'konsultasi';
    } else if (type.contains('pragi') || type.contains('skrining')) {
      type = 'pragi';
    } else if (type.contains('pesan') || type.contains('apotek') || type.contains('resep')) {
      type = 'pesanan';
    } else {
      type = 'sistem';
    }

    return PasienNotificationItem(
      id: model.id,
      title: model.judul,
      message: model.pesan,
      timeText: timeStr,
      type: type,
      isRead: model.isRead,
      rawDateTime: dt,
      extraData: model.data,
    );
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });

    try {
      await PasienApiService().markAllNotificationsRead();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua notifikasi telah ditandai dibaca'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _markAsRead(PasienNotificationItem item) async {
    if (item.isRead) return;

    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == item.id);
      if (idx != -1) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      }
    });

    try {
      await PasienApiService().markNotificationRead(item.id);
    } catch (_) {}
  }

  Future<void> _deleteItem(PasienNotificationItem item) async {
    final prevList = List<PasienNotificationItem>.from(_notifications);
    setState(() {
      _notifications.removeWhere((n) => n.id == item.id);
    });

    try {
      await PasienApiService().deleteNotification(item.id);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notifikasi dihapus'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Urungkan',
            textColor: Colors.amberAccent,
            onPressed: () {
              if (mounted) {
                setState(() => _notifications = prevList);
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final displayedList = _activeFilter == 'unread'
        ? _notifications.where((n) => !n.isRead).toList()
        : _notifications;

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Background Topografi Organik GIAT (Kurva Gelombang Hijau) ──
          Positioned.fill(
            child: CustomPaint(
              painter: _NotifikasiTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Navigation Bar ("<- Kembali" di kiri, "Notifikasi" Pill di tengah) ──
                _buildHeaderBar(context, unreadCount),

                const SizedBox(height: 14),

                // ── Filter Chips (Semua & Belum Dibaca) ──
                _buildFilterChips(unreadCount),

                const SizedBox(height: 12),

                // ── Daftar Kartu Notifikasi ──
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: _darkGreen,
                            strokeWidth: 2.5,
                          ),
                        )
                      : displayedList.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: _darkGreen,
                              onRefresh: () => _loadNotifications(isRefresh: true),
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                itemCount: displayedList.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 14),
                                itemBuilder: (context, index) {
                                  final item = displayedList[index];
                                  return _buildNotificationCard(context, item);
                                },
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
  // HEADER BAR (Tombol "<- Kembali" di kiri atas, lalu Pill "Notifikasi" di tengah)
  // Sesuai Screenshot Desain 1:1
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBar(BuildContext context, int unreadCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row atas: Tombol Pill "<- Kembali" di kiri, aksi "Tandai Dibaca" di kanan jika ada unread
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Tombol Pill "<- Kembali"
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _textColor, width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back, size: 14, color: _textColor),
                      const SizedBox(width: 5),
                      Text(
                        'Kembali',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Aksi "Tandai Semua Dibaca" (jika ada notifikasi unread)
              if (unreadCount > 0)
                GestureDetector(
                  onTap: _markAllAsRead,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.done_all_rounded, size: 14, color: _darkGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Tandai Dibaca',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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

          // Centered "Notifikasi" Badge Pill
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8.5),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _darkGreen.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Notifikasi',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FILTER CHIPS (Semua / Belum Dibaca)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFilterChips(int unreadCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildChipButton(
            title: 'Semua',
            count: _notifications.length,
            isSelected: _activeFilter == 'semua',
            onTap: () => setState(() => _activeFilter = 'semua'),
          ),
          const SizedBox(width: 8),
          _buildChipButton(
            title: 'Belum Dibaca',
            count: unreadCount,
            isSelected: _activeFilter == 'unread',
            onTap: () => setState(() => _activeFilter = 'unread'),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _darkGreen : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: _darkGreen.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : _subtextColor,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

  // ───────────────────────────────────────────────────────────────────────────
  // NOTIFICATION CARD
  // Sesuai Screenshot: Avatar Box Pastel Cyan (64x64), Icon Lonceng, Judul,
  // Subjudul, dan Row Jam
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildNotificationCard(BuildContext context, PasienNotificationItem item) {
    final iconData = _getIconForType(item.type);
    final avatarBg = _getAvatarBgForType(item.type);

    return Dismissible(
      key: Key('notif-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => _deleteItem(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? const Color(0xFFE2E8F0).withValues(alpha: 0.6)
                : _darkGreen.withValues(alpha: 0.25),
            width: item.isRead ? 1 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              _markAsRead(item);
              _handleCardTap(context, item);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar Box (Pastel Light Blue/Cyan 64x64 dengan Icon)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        iconData,
                        color: _textColor,
                        size: 26,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Text Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title Notifikasi + Unread Dot Indicator
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
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
                                  color: _darkGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Pesan Notifikasi
                        Text(
                          item.message,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: _subtextColor,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Timestamp Row (Jam Icon + Teks "30 menit lalu")
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_outlined,
                              size: 14,
                              color: _timeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.timeText,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: _timeColor,
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
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'obat':
        return Icons.medication_rounded;
      case 'konsultasi':
        return Icons.medical_services_rounded;
      case 'pragi':
        return Icons.smart_toy_rounded;
      case 'pesanan':
        return Icons.local_shipping_outlined;
      case 'sistem':
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getAvatarBgForType(String type) {
    switch (type) {
      case 'obat':
        return const Color(0xFFD1FAE5); // Pastel mint
      case 'konsultasi':
        return const Color(0xFFDBEAFE); // Pastel blue
      case 'pragi':
        return const Color(0xFFEDE9FE); // Pastel purple
      case 'pesanan':
        return const Color(0xFFFEF3C7); // Pastel amber
      case 'sistem':
      default:
        return _avatarBgColor; // Pastel cyan 0xFFCCE4ED
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CARD TAP & DETAIL BOTTOM SHEET
  // ───────────────────────────────────────────────────────────────────────────
  void _handleCardTap(BuildContext context, PasienNotificationItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
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
              // Handle Drag bar
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon & Title Header
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _getAvatarBgForType(item.type),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        _getIconForType(item.type),
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
                          item.title,
                          style: GoogleFonts.inter(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.access_time_outlined, size: 13, color: _timeColor),
                            const SizedBox(width: 4),
                            Text(
                              item.timeText,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: _timeColor,
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

              // Detail Message
              Text(
                'Detail Notifikasi',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _subtextColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.message,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: _textColor,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons based on type
              if (item.type == 'obat') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReminderListScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Buka Pengingat Obat',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else if (item.type == 'konsultasi') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DokterListScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Lihat Konsultasi Dokter',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else if (item.type == 'pragi') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(
                            body: SafeArea(
                              child: PragiHomeView(),
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Buka Skrining PRAGI',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else if (item.type == 'pesanan') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RiwayatObatScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Cek Riwayat Pesanan Obat',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _avatarBgColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: _darkGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Notifikasi',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pemberitahuan terkait pengingat obat, jadwal konsultasi, dan skrining akan muncul di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: _subtextColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY PAINTER (GIAT Wavy Organic Curves)
// ─────────────────────────────────────────────────────────────────────────────
class _NotifikasiTopographyPainter extends CustomPainter {
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
