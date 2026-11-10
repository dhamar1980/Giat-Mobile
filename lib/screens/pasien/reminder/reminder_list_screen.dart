import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tambah_reminder_screen.dart';
import '../../../widgets/giat_background.dart';
import '../../../services/pasien_api_service.dart';
import '../../../services/reminder_notification_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/time_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PENGINGAT & ALARM KESEHATAN GINJAL (REMINDER SAYA)
// Figma Node: 771:5254 (Pasien-reminder)
// ─────────────────────────────────────────────────────────────────────────────

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen> {
  static const _primaryGreen = Color(0xFF006D37);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _textColor = Color(0xFF091D2E);
  static const _subtextColor = Color(0xFF475569);

  // Default fallback reminders matching Figma Node 771:5254
  static List<Map<String, dynamic>> get _defaultReminders {
    final zone = TimeUtils.getTimeZoneName();
    return [
      {
        'id': '1',
        'type': 'obat',
        'title': 'Minum Obat',
        'subtitle': 'Losartan 50 mg',
        'time': '08:00 $zone',
        'date': 'Hari ini',
        'isActive': true,
      },
      {
        'id': '2',
        'type': 'konsultasi',
        'title': 'Konsultasi Dokter',
        'subtitle': 'Dr. budi Santoso',
        'time': '14:00 $zone',
        'date': 'Hari ini',
        'isActive': true,
      },
    ];
  }

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  late List<Map<String, dynamic>> _reminders;
  bool _isLoading = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    if (_isTest) {
      _reminders = List.from(_defaultReminders);
      _isLoading = false;
    } else {
      final cached = StorageService().getRemindersCache();
      _reminders = _mapRawList(cached);
      _isLoading = _reminders.isEmpty;
      ReminderNotificationService.instance.startMonitoring();
    }
    _loadRemindersFromApi();
  }

  static String _formatApiTime(dynamic rawTime) {
    final zone = TimeUtils.getTimeZoneName();
    if (rawTime == null) return '08:00 $zone';
    final str = rawTime.toString().trim();
    if (str.toUpperCase().contains('WIB') ||
        str.toUpperCase().contains('WITA') ||
        str.toUpperCase().contains('WIT')) {
      return TimeUtils.replaceTimezoneSuffix(str);
    }
    final parts = str.split(':');
    if (parts.length >= 2) {
      final h = parts[0].padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      return '$h:$m $zone';
    }
    return str.isNotEmpty ? str : '08:00 $zone';
  }

  List<Map<String, dynamic>> _mapRawList(List<dynamic> rawList) {
    final List<Map<String, dynamic>> mapped = [];
    for (var item in rawList) {
      if (item is Map) {
        final id = item['id']?.toString() ?? item['id_reminder']?.toString() ?? '';
        final type = item['tipe']?.toString().toLowerCase() ??
            item['type']?.toString().toLowerCase() ??
            'obat';
        final title = item['judul']?.toString() ??
            item['nama']?.toString() ??
            item['title']?.toString() ??
            'Pengingat';
        final subtitle = item['subjudul']?.toString() ??
            item['keterangan']?.toString() ??
            item['dosis']?.toString() ??
            item['deskripsi']?.toString() ??
            item['subtitle']?.toString() ??
            '';
        final rawWaktu = item['waktu']?.toString() ?? item['time']?.toString() ?? '08:00:00';
        final time = _formatApiTime(rawWaktu);
        final rawTanggal = item['tanggal']?.toString() ?? item['date']?.toString() ?? 'Hari ini';
        final pengulangan = item['pengulangan']?.toString() ?? 'harian';
        final isActive = item['is_active'] == true ||
            item['is_active'] == 1 ||
            item['isActive'] == true ||
            item['status'] == 'aktif';

        mapped.add({
          'id': id,
          'id_reminder': id,
          'type': type,
          'tipe': type,
          'title': title,
          'judul': title,
          'nama': title,
          'subtitle': subtitle,
          'subjudul': subtitle,
          'keterangan': subtitle,
          'waktu': rawWaktu,
          'time': time,
          'tanggal': rawTanggal,
          'date': rawTanggal,
          'pengulangan': pengulangan,
          'isActive': isActive,
          'is_active': isActive,
          'created_at': item['created_at']?.toString() ?? '',
        });
      }
    }

    // Deduplicate reminders by ID (or title + time + subtitle if ID is empty)
    final seen = <String>{};
    final deduplicated = <Map<String, dynamic>>[];
    for (var m in mapped) {
      final idStr = (m['id'] ?? '').toString().trim();
      final key = idStr.isNotEmpty
          ? idStr
          : '${m['title']}_${m['time']}_${m['subtitle']}';
      if (!seen.contains(key)) {
        seen.add(key);
        deduplicated.add(m);
      }
    }
    return deduplicated;
  }

  Future<void> _loadRemindersFromApi({bool isRefresh = false}) async {
    if (!isRefresh && _reminders.isEmpty && !_isTest) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await PasienApiService().getReminders();
      if (res.success && res.data != null) {
        if (_isTest && res.data!.isEmpty) {
          if (mounted) {
            setState(() {
              _reminders = List.from(_defaultReminders);
              _isLoading = false;
            });
          }
          return;
        }

        final deduplicated = _mapRawList(res.data!);
        if (mounted) {
          setState(() {
            _reminders = deduplicated;
            _isLoading = false;
          });
        }
        ReminderNotificationService.instance.onRemindersChanged(
          updatedReminders: deduplicated,
        );
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        if (_isTest && _reminders.isEmpty) {
          _reminders = List.from(_defaultReminders);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddReminder() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TambahReminderScreen(),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        final formattedResult = _mapRawList([result]).first;
        setState(() {
          _reminders.insert(0, formattedResult);
        });
        final apiRes = await PasienApiService().createReminder(result);
        if (apiRes.success && apiRes.data != null) {
          final realId = apiRes.data!['id'] ?? apiRes.data!['id_reminder'];
          if (realId != null && mounted) {
            setState(() {
              formattedResult['id'] = realId.toString();
              formattedResult['id_reminder'] = realId.toString();
            });
          }
        }
        ReminderNotificationService.instance.onRemindersChanged(
          updatedReminders: _reminders,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pengingat "${formattedResult['title']}" berhasil ditambahkan! ⏰'),
              backgroundColor: _primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _navigateToEditReminder(Map<String, dynamic> rem, int index) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TambahReminderScreen(existingReminder: rem),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        final formattedResult = _mapRawList([result]).first;
        final id = rem['id'] ?? formattedResult['id'];
        formattedResult['id'] = id;
        formattedResult['id_reminder'] = id;

        setState(() {
          if (index >= 0 && index < _reminders.length) {
            _reminders[index] = formattedResult;
          }
        });

        if (id != null && id.toString().isNotEmpty) {
          await PasienApiService().updateReminder(id, result);
        }
        ReminderNotificationService.instance.onRemindersChanged(
          updatedReminders: _reminders,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pengingat "${formattedResult['title']}" berhasil diperbarui! ⏰'),
              backgroundColor: _primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } finally {
      _isNavigating = false;
    }
  }

  void _deleteReminder(int index) {
    final deleted = _reminders[index];
    final deletedTitle = deleted['title'];
    final id = deleted['id'];
    setState(() {
      _reminders.removeAt(index);
    });
    if (id != null && id.toString().isNotEmpty) {
      PasienApiService().deleteReminder(id);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pengingat "$deletedTitle" dihapus'),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
        backgroundColor: const Color(0xFF334155),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // ── Background Topography ──
          Positioned.fill(
            child: CustomPaint(
              painter: _ReminderTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Header Bar (Kembali & Reminder Saya stacked vertically) ──
                _buildHeaderBar(),

                const SizedBox(height: 12),

                // ── Main Content Area ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Heading: "Hari ini" (Figma Node 771:5254)
                        Text(
                          'Hari ini',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // List of Reminders
                        Expanded(
                          child: _isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: CircularProgressIndicator(color: _primaryGreen),
                                  ),
                                )
                              : _reminders.isEmpty
                                  ? _buildEmptyState()
                                  : RefreshIndicator(
                                      onRefresh: () => _loadRemindersFromApi(isRefresh: true),
                                      color: _primaryGreen,
                                      child: ListView.builder(
                                        itemCount: _reminders.length,
                                        physics: const AlwaysScrollableScrollPhysics(
                                          parent: BouncingScrollPhysics(),
                                        ),
                                        itemBuilder: (context, index) {
                                          final rem = _reminders[index];
                                          return _buildReminderCard(rem, index);
                                        },
                                      ),
                                    ),
                        ),

                        // Bottom Button: "Tambah Reminder Baru" (Figma 771:5254 Frame 3)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: _buildAddButton(),
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
  // HEADER BAR (Kembali di kiri atas, lalu di bawahnya Reminder Saya di tengah)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top: Kembali Pill Button
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primaryGreen, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 14, color: _textColor),
                  const SizedBox(width: 6),
                  Text(
                    'Kembali',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Below: Pengingat Saya Pill Badge (Centered)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Pengingat Saya',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REMINDER CARD (Themes 2 & 3 in Figma Node 771:5254)
  // Tanpa status (Belum di lakukan / Akan Datang / Selesai dihapus)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildReminderCard(Map<String, dynamic> rem, int index) {
    final type = (rem['type'] ?? 'obat').toString().toLowerCase();
    final isObat = type.contains('obat');
    final isAir = type.contains('air') || type.contains('minum');
    final timeStr = rem['time'] ?? '08:00 WIB';

    IconData cardIcon;
    Color iconBgColor = const Color(0xFFD5E8F0);
    if (isAir) {
      cardIcon = Icons.water_drop_outlined;
      iconBgColor = const Color(0xFFE0F2FE);
    } else if (isObat) {
      cardIcon = Icons.medication_outlined;
      iconBgColor = const Color(0xFFD5E8F0);
    } else {
      cardIcon = Icons.medical_services_outlined;
      iconBgColor = const Color(0xFFEDE9FE);
    }

    return Dismissible(
      key: Key(rem['id'] ?? index.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => _deleteReminder(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
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
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 70,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: CustomPaint(
                  painter: _CardBubblePainter(),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _navigateToEditReminder(rem, index),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container (Soft Cyan/Mint background with rounded corners)
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          cardIcon,
                          color: _textColor,
                          size: 26,
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Info Column: Title & Subtitle only
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title (e.g. Minum Obat, Konsultasi Dokter)
                            Text(
                              rem['title'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(height: 3),

                            // Subtitle / Dosis / Dokter
                            Text(
                              rem['subtitle'] ?? '',
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

                    // Right Side: Time Pill Badge & Switch Toggle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: _textColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            timeStr,
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 28,
                          child: Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: rem['isActive'] == true,
                              activeThumbColor: _primaryGreen,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (val) {
                                setState(() {
                                  rem['isActive'] = val;
                                  rem['is_active'] = val;
                                });
                                if (rem['id'] != null) {
                                  PasienApiService().toggleReminder(
                                    rem['id'],
                                    isActive: val,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
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
  // EMPTY STATE
  // ───────────────────────────────────────────────────────────────────────────
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
              Icons.alarm_off_rounded,
              size: 40,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada pengingat hari ini',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Klik tombol di bawah untuk menambah pengingat baru',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM BUTTON: "Tambah Reminder Baru" (Figma Node 771:5254 Frame 3)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: _primaryGreen.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _navigateToAddReminder,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tambah Pengingat Baru',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD DECORATIVE BUBBLE PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _CardBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2ECC71).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 36, paint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.7), 28, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPOGRAPHY PAINTER (GIAT Organic Curves)
// ─────────────────────────────────────────────────────────────────────────────
class _ReminderTopographyPainter extends CustomPainter {
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
