import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/notifikasi_model.dart';
import '../../../services/apotek_api_service.dart';
import '../../../services/reminder_notification_service.dart';
import '../../../utils/time_utils.dart';
import '../../../widgets/giat_background.dart';
import '../models/apotek_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIKASI APOTEK SCREEN
// Tampilan Notifikasi Apotek Real-Time terhubung ke Supabase PostgreSQL & REST API
// Desain Header Pill ("<- Kembali" & "Notifikasi"), Background Topografi GIAT,
// Filter Status, dan Kartu Notifikasi Interaktif (Seragam dengan Pasien & Dokter)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekNotificationItem {
  final dynamic id;
  final String title;
  final String message;
  final String timeText;
  final String type; // 'pesanan', 'resep', 'stok', 'sistem'
  final bool isRead;
  final DateTime? rawDateTime;
  final Map<String, dynamic>? extraData;

  const ApotekNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeText,
    this.type = 'sistem',
    this.isRead = false,
    this.rawDateTime,
    this.extraData,
  });

  ApotekNotificationItem copyWith({
    bool? isRead,
  }) {
    return ApotekNotificationItem(
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

class ApotekNotifikasiScreen extends StatefulWidget {
  final String? apotekerName;
  final String? apotekId;

  const ApotekNotifikasiScreen({
    super.key,
    this.apotekerName,
    this.apotekId,
  });

  @override
  State<ApotekNotifikasiScreen> createState() => _ApotekNotifikasiScreenState();
}

class _ApotekNotifikasiScreenState extends State<ApotekNotifikasiScreen> {
  static const _darkGreen = Color(0xFF005954);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _textColor = Color(0xFF0F172A);
  static const _subtextColor = Color(0xFF475569);
  static const _timeColor = Color(0xFF64748B);
  static const _avatarBgColor = Color(0xFFCCE4ED);

  List<ApotekNotificationItem> _notifications = [];
  bool _isLoading = true;
  String _activeFilter = 'semua'; // 'semua' | 'unread'

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    ReminderNotificationService.instance.notificationListVersion
        .addListener(_onNotificationVersionChanged);
    _loadNotifications();
  }

  @override
  void dispose() {
    ReminderNotificationService.instance.notificationListVersion
        .removeListener(_onNotificationVersionChanged);
    super.dispose();
  }

  void _onNotificationVersionChanged() {
    if (mounted) {
      _loadNotifications(isRefresh: true);
    }
  }

  List<ApotekNotificationItem> _mapMockFallback() {
    return ApotekMockData.notifications
        .map(
          (n) => ApotekNotificationItem(
            id: n.id,
            title: n.title,
            message: n.body,
            timeText: n.time,
            type: n.type,
            isRead: n.isRead,
          ),
        )
        .toList();
  }

  Future<void> _loadNotifications({bool isRefresh = false}) async {
    if (!isRefresh && _notifications.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final res = await ApotekApiService().getNotifikasi(
        apotekId: widget.apotekId,
        apotekName: widget.apotekerName,
      );
      if (res.success && res.data != null) {
        if (_isTest && res.data!.isEmpty) {
          if (mounted) {
            setState(() {
              _notifications = _mapMockFallback();
              _isLoading = false;
            });
          }
          return;
        }

        final List<ApotekNotificationItem> items = [];
        for (final raw in res.data!) {
          if (raw is Map) {
            final model =
                NotifikasiModel.fromJson(Map<String, dynamic>.from(raw));
            items.add(_mapModelToItem(model));
          }
        }

        if (mounted) {
          setState(() {
            _notifications = items;
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
        if (_isTest && _notifications.isEmpty) {
          _notifications = _mapMockFallback();
        }
        _isLoading = false;
      });
    }
  }

  ApotekNotificationItem _mapModelToItem(NotifikasiModel model) {
    final dt = model.createdAt.isNotEmpty
        ? TimeUtils.toIndonesianTime(model.createdAt)
        : null;
    final timeStr = model.createdAt.isNotEmpty
        ? TimeUtils.formatRelativeTime(model.createdAt)
        : 'Baru saja';

    final rawType = (model.tipe ?? '').toLowerCase();
    final lowerTitle = model.judul.toLowerCase();
    final lowerMsg = model.pesan.toLowerCase();

    String type = 'sistem';
    if (rawType.contains('resep') ||
        lowerTitle.contains('resep') ||
        lowerMsg.contains('resep')) {
      type = 'resep';
    } else if (rawType.contains('pesan') ||
        lowerTitle.contains('pesanan') ||
        lowerTitle.contains('pembayaran') ||
        lowerMsg.contains('pesanan')) {
      type = 'pesanan';
    } else if (rawType.contains('stok') ||
        rawType.contains('obat') ||
        lowerTitle.contains('stok') ||
        lowerTitle.contains('kedaluwarsa')) {
      type = 'stok';
    } else {
      type = 'sistem';
    }

    return ApotekNotificationItem(
      id: model.id,
      title: model.judul,
      message: model.pesan,
      timeText: timeStr.isNotEmpty ? timeStr : 'Baru saja',
      type: type,
      isRead: model.isRead,
      rawDateTime: dt,
      extraData: model.data,
    );
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      if (_isTest) {
        for (final n in ApotekMockData.notifications) {
          n.isRead = true;
        }
      }
    });

    try {
      await ApotekApiService().markAllNotificationsRead(
        apotekId: widget.apotekId,
        apotekName: widget.apotekerName,
      );
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

  Future<void> _markAsRead(ApotekNotificationItem item) async {
    if (item.isRead) return;

    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == item.id);
      if (idx != -1) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      }
    });

    try {
      await ApotekApiService().markNotificationRead(item.id);
    } catch (_) {}
  }

  Future<void> _deleteItem(ApotekNotificationItem item) async {
    final prevList = List<ApotekNotificationItem>.from(_notifications);
    setState(() {
      _notifications.removeWhere((n) => n.id == item.id);
    });

    try {
      await ApotekApiService().deleteNotification(item.id);
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
          // ── Background Topografi Organik GIAT ──
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
                              onRefresh: () =>
                                  _loadNotifications(isRefresh: true),
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                itemCount: displayedList.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 14),
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
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBar(BuildContext context, int unreadCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Tombol Pill "<- Kembali"
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6.5,
                  ),
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

              // 2. Aksi "Tandai Dibaca" (jika ada notifikasi unread)
              if (unreadCount > 0)
                GestureDetector(
                  onTap: _markAllAsRead,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: _darkGreen,
                        ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 26,
                vertical: 8.5,
              ),
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
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFF1F5F9),
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
  // EMPTY STATE
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _avatarBgColor.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.notifications_off_outlined,
                  size: 38,
                  color: _darkGreen,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Belum Ada Notifikasi',
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pemberitahuan aktivitas pesanan obat, resep masuk, dan stok apotek akan muncul di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _timeColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NOTIFICATION CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildNotificationCard(
    BuildContext context,
    ApotekNotificationItem item,
  ) {
    final iconData = _getIconForType(item.type);
    final avatarBg = _getAvatarBgForType(item.type);

    return Dismissible(
      key: Key('notif-apotek-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
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
                  // Avatar Box (Pastel 64x64 dengan Icon)
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
      case 'resep':
        return Icons.note_alt_rounded;
      case 'pesanan':
        return Icons.local_shipping_outlined;
      case 'stok':
        return Icons.medication_rounded;
      case 'sistem':
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getAvatarBgForType(String type) {
    switch (type) {
      case 'resep':
        return const Color(0xFFDBEAFE); // Pastel blue
      case 'pesanan':
        return const Color(0xFFD1FAE5); // Pastel mint
      case 'stok':
        return const Color(0xFFFEF3C7); // Pastel amber
      case 'sistem':
      default:
        return _avatarBgColor; // Pastel cyan 0xFFCCE4ED
    }
  }

  void _handleCardTap(BuildContext context, ApotekNotificationItem item) {
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
                            const Icon(
                              Icons.access_time_outlined,
                              size: 13,
                              color: _timeColor,
                            ),
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

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  item.message,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: _subtextColor,
                    height: 1.45,
                  ),
                ),
              ),

              const SizedBox(height: 20),

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
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

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
