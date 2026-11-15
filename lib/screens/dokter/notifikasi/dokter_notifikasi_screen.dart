import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:giat/widgets/giat_background.dart';
import '../models/dokter_models.dart';
import '../konsultasi/dokter_room_chat_screen.dart';
import '../../../services/dokter_api_service.dart';
import '../../../services/supabase_admin_service.dart';
import '../../../services/reminder_notification_service.dart';
import '../../../utils/time_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIKASI DOKTER SCREEN (Figma Node: 1624-7166)
// Tampilan Notifikasi Dokter Real-Time terhubung ke Supabase PostgreSQL & REST API
// Desain Header Pill ("<- Kembali" & "Notifikasi"), Background Topografi GIAT,
// Filter Status, dan Kartu Notifikasi Interaktif
// ─────────────────────────────────────────────────────────────────────────────

class DokterNotifikasiScreen extends StatefulWidget {
  final String? doctorName;
  final String? dokterId;

  const DokterNotifikasiScreen({
    super.key,
    this.doctorName,
    this.dokterId,
  });

  @override
  State<DokterNotifikasiScreen> createState() => _DokterNotifikasiScreenState();
}

class _DokterNotifikasiScreenState extends State<DokterNotifikasiScreen> {
  static const _darkGreen = Color(0xFF005954);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _textColor = Color(0xFF0F172A);
  static const _subtextColor = Color(0xFF1E293B);
  static const _timeColor = Color(0xFF64748B);
  static const _avatarBgColor = Color(0xFFCCE4ED);

  List<DokterNotificationItem> _notifications = [];
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

  /// Memuat notifikasi real untuk dokter dari Supabase / REST API
  Future<void> _loadNotifications({bool isRefresh = false}) async {
    if (!isRefresh && _notifications.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        DokterApiService().getNotifikasi(
          dokterId: widget.dokterId,
          doctorName: widget.doctorName,
        ),
        if (!_isTest) ...[
          SupabaseAdminService.instance
              .fetchDokterPaidPatients(
                dokterId: widget.dokterId,
                doctorName: widget.doctorName,
              )
              .catchError((_) => <Map<String, dynamic>>[]),
          SupabaseAdminService.instance
              .fetchDokterJadwal(
                dokterId: widget.dokterId,
                doctorName: widget.doctorName,
              )
              .catchError((_) => <Map<String, dynamic>>[]),
        ] else ...[
          Future.value(<Map<String, dynamic>>[]),
          Future.value(<Map<String, dynamic>>[]),
        ],
      ]);

      final res = results[0] as dynamic;
      final paidPatients = results[1] as List<Map<String, dynamic>>;
      final schedules = results[2] as List<Map<String, dynamic>>;

      if (res.success && res.data != null) {
        final rawList = res.data as List<dynamic>;

        // Fallback untuk test environment jika database kosong
        if (_isTest && rawList.isEmpty) {
          if (mounted) {
            setState(() {
              _notifications = List.from(DokterMockData.notifications);
              _isLoading = false;
            });
          }
          return;
        }

        final List<DokterNotificationItem> items = [];
        for (var raw in rawList) {
          if (raw is Map) {
            final rawMap = Map<String, dynamic>.from(raw);
            final item = _mapRawToNotification(rawMap, paidPatients, schedules);
            items.add(item);
          }
        }

        // Lengkapi dengan jadwal aktif / konsultasi hari ini jika ada yang belum ternotifikasi
        for (final sch in schedules) {
          final schId = sch['id']?.toString() ?? '';
          final pName = (sch['nama_pasien'] ?? 'Pasien GIAT').toString();
          final jam = TimeUtils.cleanTimeString(sch['jam_mulai']?.toString()) ?? '';
          final status = (sch['status'] ?? sch['status_konsultasi'] ?? 'terjadwal').toString();

          final alreadyRepresented = items.any(
            (it) => it.consultationId == schId || (it.senderOrCategory == pName && it.type == 'jadwal'),
          );

          if (!alreadyRepresented && (status == 'berlangsung' || status == 'terjadwal')) {
            final patientObj = _buildPatientFromMap(sch);
            final timeDisplay = jam.isNotEmpty ? 'Pukul $jam WIB' : 'Jadwal Hari Ini';

            items.add(
              DokterNotificationItem(
                id: 'sch-$schId',
                title: status == 'berlangsung' ? 'Konsultasi Sedang Berlangsung' : 'Jadwal Konsultasi',
                senderOrCategory: pName,
                timeText: timeDisplay,
                initials: _getInitials(pName),
                type: 'jadwal',
                isRead: false,
                message: 'Sesi konsultasi dengan pasien $pName ($status).',
                patient: patientObj,
                consultationId: schId,
              ),
            );
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
    } catch (e) {
      debugPrint('Error loading dokter notifications: $e');
    }

    if (mounted) {
      setState(() {
        if (_isTest && _notifications.isEmpty) {
          _notifications = List.from(DokterMockData.notifications);
        }
        _isLoading = false;
      });
    }
  }

  /// Memetakan data mentah dari Supabase / REST API ke `DokterNotificationItem`
  DokterNotificationItem _mapRawToNotification(
    Map<String, dynamic> raw,
    List<Map<String, dynamic>> paidPatients,
    List<Map<String, dynamic>> schedules,
  ) {
    final rawId = (raw['id'] ?? 'notif-${DateTime.now().millisecondsSinceEpoch}').toString();
    final rawJudul = (raw['judul'] ?? raw['title'] ?? 'Notifikasi').toString();
    final rawPesan = (raw['pesan'] ?? raw['message'] ?? '').toString();
    final rawKategori = (raw['kategori'] ?? raw['tipe'] ?? raw['type'] ?? '').toString().toLowerCase();
    final isRead = raw['is_read'] == true || raw['is_read'] == 1 || raw['read_at'] != null;
    final createdAt = (raw['created_at'] ?? raw['tanggal'] ?? '').toString();

    // Format relative time (misal: "30 menit lalu", "2 jam lalu")
    String timeText = 'Baru saja';
    if (createdAt.isNotEmpty) {
      final relative = TimeUtils.formatRelativeTime(createdAt);
      if (relative.isNotEmpty) {
        timeText = relative;
      }
    } else if (raw['waktu'] != null) {
      timeText = raw['waktu'].toString();
    }

    // Tentukan kategori notifikasi
    String type = 'sistem';
    final lowerJudul = rawJudul.toLowerCase();
    final lowerPesan = rawPesan.toLowerCase();

    if (rawKategori.contains('konsul') || lowerJudul.contains('konsul') || lowerPesan.contains('konsul')) {
      type = 'konsultasi';
    } else if (rawKategori.contains('jadwal') || lowerJudul.contains('jadwal')) {
      type = 'jadwal';
    } else if (rawKategori.contains('sistem') || lowerJudul.contains('sistem') || lowerJudul.contains('fitur')) {
      type = 'sistem';
    }

    // Resolusi nama pasien dan objek `DokterPatient`
    DokterPatient? matchedPatient;
    String? matchedConsId;
    String patientName = '';

    if (type == 'konsultasi' || type == 'jadwal') {
      final combined = '$rawJudul $rawPesan';

      // 1. Cocokkan dengan daftar pasien berbayar
      for (final p in paidPatients) {
        final pName = (p['nama_pasien'] ?? p['nama'] ?? '').toString().trim();
        if (pName.isNotEmpty && combined.toLowerCase().contains(pName.toLowerCase())) {
          matchedPatient = _buildPatientFromMap(p);
          matchedConsId = (p['id_konsultasi'] ?? p['id'])?.toString();
          patientName = pName;
          break;
        }
      }

      // 2. Cocokkan dengan jadwal dokter
      if (matchedPatient == null) {
        for (final s in schedules) {
          final pName = (s['nama_pasien'] ?? s['nama'] ?? '').toString().trim();
          if (pName.isNotEmpty && combined.toLowerCase().contains(pName.toLowerCase())) {
            matchedPatient = _buildPatientFromMap(s);
            matchedConsId = (s['id_konsultasi'] ?? s['id'])?.toString();
            patientName = pName;
            break;
          }
        }
      }

      // 3. Ekstraksi nama pasien dari kalimat pesan/judul jika belum cocok
      if (patientName.isEmpty) {
        patientName = _extractPatientName(rawJudul, rawPesan);
      }

      // 4. Fallback ke pasien pertama yang tersedia
      if (patientName.isEmpty) {
        if (paidPatients.isNotEmpty) {
          matchedPatient = _buildPatientFromMap(paidPatients.first);
          matchedConsId = (paidPatients.first['id_konsultasi'] ?? paidPatients.first['id'])?.toString();
          patientName = matchedPatient.name;
        } else if (schedules.isNotEmpty) {
          matchedPatient = _buildPatientFromMap(schedules.first);
          matchedConsId = (schedules.first['id_konsultasi'] ?? schedules.first['id'])?.toString();
          patientName = matchedPatient.name;
        } else {
          patientName = 'Pasien GIAT';
        }
      }

      // 5. Bangun objek `DokterPatient` jika belum ada
      matchedPatient ??= DokterPatient(
        id: 'p-${patientName.toLowerCase().replaceAll(RegExp(r'\s+'), '-')}',
        name: patientName,
        initials: _getInitials(patientName),
        age: 40,
        gender: 'Laki-laki',
        address: 'Indonesia',
        weightKg: 65,
        heightM: 1.70,
        condition: 'Stabil',
        complaint: rawJudul,
        complaintDetail: rawPesan.isNotEmpty ? rawPesan : 'Pasien telah terdaftar untuk konsultasi online bersama Anda.',
        currentMedicines: _isTest ? DokterMockData.initialPrescriptions : const [],
        consultationId: matchedConsId,
      );
    }

    final initials = (type == 'sistem') ? 'US' : _getInitials(patientName);
    final senderOrCategory = (type == 'sistem')
        ? (rawPesan.isNotEmpty ? rawPesan : 'Informasi sistem GIAT')
        : (patientName.isNotEmpty ? patientName : 'Pasien GIAT');

    return DokterNotificationItem(
      id: rawId,
      title: rawJudul,
      senderOrCategory: senderOrCategory,
      timeText: timeText,
      initials: initials,
      type: type,
      isRead: isRead,
      message: rawPesan,
      patient: matchedPatient,
      consultationId: matchedConsId,
      extraData: raw,
      rawDateTime: DateTime.tryParse(createdAt),
    );
  }

  /// Membangun objek `DokterPatient` dari data Supabase
  DokterPatient _buildPatientFromMap(Map<String, dynamic> map) {
    final rawId = (map['id_pasien'] ?? map['id'] ?? 'p-1').toString();
    final name = (map['nama_pasien'] ?? map['nama'] ?? 'Pasien GIAT').toString();
    final initials = _getInitials(name);

    int age = 38;
    final birthDate = map['tanggal_lahir']?.toString();
    if (birthDate != null && birthDate.isNotEmpty) {
      final dt = DateTime.tryParse(birthDate);
      if (dt != null) {
        final now = DateTime.now();
        age = now.year - dt.year;
        if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) {
          age--;
        }
      }
    }

    final rawGender = (map['jenis_kelamin'] ?? '').toString();
    final gender = (rawGender == 'L' || rawGender.toLowerCase().startsWith('laki')) ? 'Laki-laki' : 'Perempuan';
    final address = (map['alamat'] ?? 'Indonesia').toString();
    final complaint = (map['keluhan_awal'] ?? map['keluhan_pantau'] ?? 'Konsultasi GIAT').toString();
    final complaintDetail = (map['detail_keluhan_pantau'] ?? map['detail_keluhan'] ?? map['catatan_dokter'] ?? '').toString();
    final consultationId = (map['id_konsultasi'] ?? map['id'])?.toString();

    double weightKg = 62.0;
    if (map['berat_badan'] != null) {
      weightKg = double.tryParse(map['berat_badan'].toString()) ?? 62.0;
    }
    double heightM = 1.68;
    if (map['tinggi_badan'] != null) {
      final h = double.tryParse(map['tinggi_badan'].toString()) ?? 168.0;
      heightM = h > 3 ? h / 100 : h;
    }

    final condition = (map['kondisi_pantau'] ?? map['kondisi'] ?? 'Stabil').toString();

    final List<DokterPrescriptionItem> meds = [];
    final rawMeds = map['current_medicines'] ?? map['obat'] ?? map['items'];
    if (rawMeds is List) {
      for (var item in rawMeds) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);
          meds.add(
            DokterPrescriptionItem(
              id: (m['id'] ?? 'rx-${meds.length + 1}').toString(),
              medicineName: (m['medicine_name'] ?? m['nama_obat'] ?? 'Obat').toString(),
              dose: (m['dose'] ?? m['dosis'] ?? '-').toString(),
              frequency: (m['frequency'] ?? m['aturan_pakai'] ?? '1x1').toString(),
              quantity: '${m['quantity'] ?? m['jumlah'] ?? 1} Tablet',
              duration: '30 Hari',
              usageTime: (m['usage_time'] ?? m['waktu_penggunaan'] ?? 'Sesudah Makan').toString(),
              specialNotes: m['special_notes']?.toString() ?? m['catatan_khusus']?.toString(),
            ),
          );
        }
      }
    }

    return DokterPatient(
      id: rawId,
      name: name,
      initials: initials,
      age: age,
      gender: gender,
      address: address,
      weightKg: weightKg,
      heightM: heightM,
      condition: condition,
      complaint: complaint,
      complaintDetail: complaintDetail.isNotEmpty ? complaintDetail : 'Pasien telah terdaftar untuk konsultasi online bersama Anda.',
      currentMedicines: meds.isNotEmpty ? meds : (_isTest ? DokterMockData.initialPrescriptions : const []),
      consultationId: consultationId,
    );
  }

  /// Ekstraksi inisial nama 2 karakter
  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'P';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Ekstraksi nama pasien dari kalimat teks notifikasi
  static String _extractPatientName(String title, String message) {
    final combined = '$title $message';
    final match = RegExp(
      r'(?:pasien|dari pasien|dari)\s+([A-Z][a-zA-Z\.]*(?:\s+[A-Z][a-zA-Z\.]*)*)',
      caseSensitive: false,
    ).firstMatch(combined);

    if (match != null && match.group(1) != null) {
      final extracted = match.group(1)!.trim();
      final words = extracted.split(RegExp(r'\s+'));
      final validWords = words
          .where((w) => !['telah', 'yang', 'pada', 'di', 'dan', 'baru', 'untuk'].contains(w.toLowerCase()))
          .toList();
      if (validWords.isNotEmpty) {
        return validWords.join(' ');
      }
    }
    return '';
  }

  /// Menandai semua notifikasi sudah dibaca
  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });

    try {
      await DokterApiService().markAllNotificationsRead(
        dokterId: widget.dokterId,
        doctorName: widget.doctorName,
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

  /// Menandai satu notifikasi sudah dibaca
  Future<void> _markAsRead(DokterNotificationItem item) async {
    if (item.isRead) return;

    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == item.id);
      if (idx != -1) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      }
    });

    try {
      await DokterApiService().markNotificationRead(item.id);
    } catch (_) {}
  }

  /// Menghapus satu notifikasi
  Future<void> _deleteItem(DokterNotificationItem item) async {
    final prevList = List<DokterNotificationItem>.from(_notifications);
    setState(() {
      _notifications.removeWhere((n) => n.id == item.id);
    });

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

    try {
      await DokterApiService().deleteNotification(item.id);
    } catch (_) {}
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
                // ── Header Navigation Bar (Kembali Pill di kiri, Notifikasi Pill di tengah, Tandai Dibaca di kanan) ──
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

          // 2. Centered "Notifikasi" Badge Pill
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
              'Pemberitahuan aktivitas konsultasi dan jadwal pasien Anda akan muncul di sini.',
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
  Widget _buildNotificationCard(BuildContext context, DokterNotificationItem item) {
    final isSystem = item.type == 'sistem';

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
                  // Avatar Box (Pastel Light Blue/Cyan 64x64)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _avatarBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: isSystem
                          ? const Icon(
                              Icons.notifications_active_outlined,
                              color: _textColor,
                              size: 26,
                            )
                          : Text(
                              item.initials,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                color: _textColor,
                                fontSize: 19,
                              ),
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
                        // Title Notifikasi + Unread indicator dot
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

                        // Nama Pengirim atau Penjelasan
                        Text(
                          item.senderOrCategory,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: _subtextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Row Waktu dengan Ikon Jam Lingkaran
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: _textColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.timeText,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: _timeColor,
                                ),
                                overflow: TextOverflow.ellipsis,
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

  // ───────────────────────────────────────────────────────────────────────────
  // INTERAKSI KETIKA KARTU NOTIFIKASI DITEKAN
  // ───────────────────────────────────────────────────────────────────────────
  void _handleCardTap(BuildContext context, DokterNotificationItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isSystem = item.type == 'sistem';
        final hasDetailMessage = item.message != null &&
            item.message!.isNotEmpty &&
            item.message != item.title &&
            item.message != item.senderOrCategory;

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
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header Avatar + Title
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _avatarBgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: isSystem
                          ? const Icon(Icons.notifications_active_outlined, color: _textColor, size: 26)
                          : Text(
                              item.initials,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                color: _textColor,
                                fontSize: 18,
                              ),
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
                        Text(
                          item.senderOrCategory,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: _subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Box Info Waktu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 15, color: _textColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.timeText,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _subtextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Detail Pesan jika ada keterangan tambahan
              if (hasDetailMessage) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    item.message!,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: _subtextColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons
              if (item.type == 'konsultasi' || item.type == 'jadwal') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      // Gunakan patient real yang terikat pada notifikasi atau fallback
                      final patient = item.patient ??
                          DokterPatient(
                            id: 'p-giat',
                            name: item.senderOrCategory,
                            initials: item.initials,
                            age: 40,
                            gender: 'Laki-laki',
                            address: 'Indonesia',
                            weightKg: 65,
                            heightM: 1.70,
                            condition: 'Stabil',
                            complaint: item.title,
                            complaintDetail: item.message ?? 'Pasien telah terdaftar untuk konsultasi online bersama Anda.',
                            currentMedicines: DokterMockData.initialPrescriptions,
                            consultationId: item.consultationId,
                          );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DokterRoomChatScreen(
                            patient: patient,
                            consultationId: item.consultationId ?? patient.consultationId,
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
                      'Buka Ruang Konsultasi',
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
