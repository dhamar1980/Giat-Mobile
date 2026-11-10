import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/pasien/notifikasi/pasien_notifikasi_screen.dart';
import '../utils/time_utils.dart';
import 'navigation_service.dart';
import 'storage_service.dart';
import 'supabase_admin_service.dart';

/// Service penjadwalan & pemicu notifikasi otomatis untuk fitur "Pengingat Saya" (Pasien).
/// Memantau jadwal pengingat aktif secara real-time dan ketika waktunya tiba:
/// 1. Menyimpan notifikasi baru ke tabel `notifikasi` di Supabase PostgreSQL & cache lokal.
/// 2. Memperbarui badge jumlah notifikasi belum dibaca secara live.
/// 3. Menampilkan banner pop-up notifikasi in-app + suara pengingat.
class ReminderNotificationService {
  ReminderNotificationService._();
  static final ReminderNotificationService instance =
      ReminderNotificationService._();

  Timer? _timer;
  bool _isChecking = false;
  DateTime? _lastRemoteFetch;
  OverlayEntry? _activeBannerEntry;
  Timer? _bannerDismissTimer;

  /// Notifier jumlah notifikasi belum dibaca untuk badge lonceng
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  /// Notifier versi daftar notifikasi (bertambah saat ada notifikasi baru / perubahan status)
  final ValueNotifier<int> notificationListVersion = ValueNotifier<int>(0);

  /// Notifier versi daftar reminder (bertambah saat reminder ditambah/diubah/dihapus)
  final ValueNotifier<int> reminderListVersion = ValueNotifier<int>(0);

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  /// Mulai pemantauan berkala pengingat pasien (setiap 5 detik)
  void startMonitoring() {
    if (_isTest) return;
    unreadCountNotifier.value = StorageService().getUnreadNotificationCount();
    refreshUnreadCount();
    checkDueReminders(forceRemote: true);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      checkDueReminders();
    });
  }

  /// Hentikan pemantauan berkala
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dipanggil saat daftar pengingat berubah (tambah / edit / toggle / hapus)
  Future<void> onRemindersChanged({
    List<Map<String, dynamic>>? updatedReminders,
  }) async {
    reminderListVersion.value++;
    if (_isTest) return;
    await checkDueReminders(
      remindersOverride: updatedReminders,
      forceRemote: updatedReminders == null,
    );
  }

  /// Dipanggil saat daftar notifikasi berubah (dibaca / dihapus)
  Future<void> onNotificationsChanged() async {
    notificationListVersion.value++;
    if (_isTest) return;
    await refreshUnreadCount();
  }

  /// Segarkan counter notifikasi belum dibaca dari Supabase & cache lokal
  Future<int> refreshUnreadCount() async {
    if (_isTest) {
      final cached = StorageService().getUnreadNotificationCount();
      unreadCountNotifier.value = cached;
      return cached;
    }
    try {
      final count = await SupabaseAdminService.instance
          .fetchPasienUnreadNotificationCount();
      await StorageService().saveUnreadNotificationCount(count);
      unreadCountNotifier.value = count;
      return count;
    } catch (_) {
      final cached = StorageService().getUnreadNotificationCount();
      unreadCountNotifier.value = cached;
      return cached;
    }
  }

  /// Periksa apakah ada pengingat aktif yang sudah tiba waktunya
  Future<void> checkDueReminders({
    List<Map<String, dynamic>>? remindersOverride,
    bool forceRemote = false,
    bool allowInTest = false,
  }) async {
    if ((!allowInTest && _isTest) || _isChecking) return;
    _isChecking = true;

    try {
      final role = (await StorageService().getRole())?.toLowerCase() ?? 'pasien';
      if (role != 'pasien') {
        return;
      }

      List<Map<String, dynamic>> reminders = [];
      final nowUtc = DateTime.now().toUtc();
      final shouldFetchRemote = !_isTest &&
          (forceRemote ||
              _lastRemoteFetch == null ||
              nowUtc.difference(_lastRemoteFetch!).inSeconds >= 20);

      if (remindersOverride != null) {
        reminders = remindersOverride;
      } else if (shouldFetchRemote) {
        try {
          final remote =
              await SupabaseAdminService.instance.fetchPasienReminders();
          _lastRemoteFetch = nowUtc;
          reminders = remote;
          await StorageService().saveRemindersCache(remote);
        } catch (_) {
          reminders = StorageService().getRemindersCache();
        }
      } else {
        reminders = StorageService().getRemindersCache();
        if (reminders.isEmpty) {
          try {
            final remote =
                await SupabaseAdminService.instance.fetchPasienReminders();
            _lastRemoteFetch = nowUtc;
            reminders = remote;
            await StorageService().saveRemindersCache(remote);
          } catch (_) {}
        }
      }

      if (reminders.isEmpty) return;

      final now = TimeUtils.nowInUserZone;
      final todayIso =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final notifiedKeys = StorageService().getNotifiedReminderKeys();

      for (final rem in reminders) {
        final isActive = rem['is_active'] == true ||
            rem['is_active'] == 1 ||
            rem['isActive'] == true ||
            rem['status']?.toString().toLowerCase() == 'aktif';
        if (!isActive) continue;

        final remId =
            (rem['id'] ?? rem['id_reminder'] ?? '').toString().trim();
        if (remId.isEmpty) continue;

        final rawTime = (rem['waktu'] ?? rem['time'] ?? '').toString().trim();
        final timeMatch =
            RegExp(r'(\d{1,2})[:.](\d{1,2})').firstMatch(rawTime);
        if (timeMatch == null) continue;

        final hour = (int.tryParse(timeMatch.group(1)!) ?? 8).clamp(0, 23);
        final minute = (int.tryParse(timeMatch.group(2)!) ?? 0).clamp(0, 59);

        final repeat =
            (rem['pengulangan'] ?? 'harian').toString().toLowerCase();
        final rawDate =
            (rem['tanggal'] ?? rem['date'] ?? todayIso).toString().trim();
        final remDateIso = _extractIsoDate(rawDate, todayIso);

        // Cek apakah jadwal berlaku untuk hari ini
        final bool appliesToday;
        if (repeat.contains('hari')) {
          appliesToday = remDateIso.compareTo(todayIso) <= 0;
        } else {
          appliesToday = remDateIso == todayIso;
        }
        if (!appliesToday) continue;

        final scheduledToday =
            DateTime(now.year, now.month, now.day, hour, minute);

        // Belum waktunya
        if (now.isBefore(scheduledToday)) continue;

        final hhMm =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        final notifKey = '${remId}_${todayIso}_$hhMm';

        // Sudah pernah dinotifikasi untuk jadwal hari ini pada jam tersebut
        if (notifiedKeys.contains(notifKey)) continue;

        // Pastikan pengingat yang baru dibuat untuk jam yang sudah lewat jauh hari ini
        // (misal buat pengingat jam 08:00 pagi saat malam jam 20:30) tidak langsung
        // salah bunyi malam ini, melainkan bunyi besok jam 08:00 pagi.
        final minutesSinceScheduled =
            now.difference(scheduledToday).inMinutes;
        bool shouldTriggerNow = minutesSinceScheduled <= 3;

        if (!shouldTriggerNow) {
          final rawCreated = rem['created_at']?.toString() ?? '';
          if (rawCreated.isNotEmpty) {
            final createdLocal = TimeUtils.toIndonesianTime(rawCreated);
            if (!createdLocal.isAfter(
              scheduledToday.add(const Duration(minutes: 2)),
            )) {
              shouldTriggerNow = true;
            }
          } else {
            shouldTriggerNow = true;
          }
        }

        if (!shouldTriggerNow) continue;

        // Tandai sudah dinotifikasi agar tidak berulang di hari yang sama
        notifiedKeys.add(notifKey);
        await StorageService().markReminderNotified(notifKey);

        // Susun pesan notifikasi
        final tipe =
            (rem['tipe'] ?? rem['type'] ?? 'obat').toString().toLowerCase();
        final title =
            (rem['judul'] ?? rem['nama'] ?? rem['title'] ?? 'Pengingat')
                .toString()
                .trim();
        final subtitle = (rem['subjudul'] ??
                rem['subtitle'] ??
                rem['keterangan'] ??
                rem['dosis'] ??
                '')
            .toString()
            .trim();
        final timeLabel = '$hhMm ${TimeUtils.getTimeZoneName()}';

        String notifTitle;
        String notifBody;
        String kategori;

        if (tipe.contains('konsul')) {
          notifTitle = title.toLowerCase().contains('konsul')
              ? 'Waktunya $title'
              : 'Pengingat Konsultasi: $title';
          notifBody = subtitle.isNotEmpty
              ? '$subtitle • Jadwal konsultasi pukul $timeLabel telah tiba.'
              : 'Jadwal pengingat konsultasi Anda pukul $timeLabel telah tiba.';
          kategori = 'konsultasi';
        } else if (tipe.contains('air')) {
          notifTitle = 'Waktunya $title';
          notifBody = subtitle.isNotEmpty
              ? '$subtitle • Jadwal pukul $timeLabel.'
              : 'Saatnya memenuhi kebutuhan cairan harian Anda ($timeLabel).';
          kategori = 'obat';
        } else {
          notifTitle = title.toLowerCase().startsWith('minum')
              ? 'Waktunya $title'
              : 'Waktunya Minum Obat: $title';
          notifBody = subtitle.isNotEmpty
              ? '$subtitle • Jadwal pengingat pukul $timeLabel telah tiba.'
              : 'Saatnya minum obat sesuai jadwal pengingat Anda pukul $timeLabel.';
          kategori = 'obat';
        }

        // 1. Simpan ke tabel `notifikasi` di Supabase & cache lokal
        Map<String, dynamic>? createdNotif;
        if (!_isTest) {
          try {
            createdNotif =
                await SupabaseAdminService.instance.createPasienNotification(
              judul: notifTitle,
              pesan: notifBody,
              kategori: kategori,
            );
          } catch (e) {
            debugPrint('⚠️ Gagal simpan notifikasi reminder ke Supabase: $e');
          }
        }

        final notifRecord = createdNotif ??
            <String, dynamic>{
              'id': 'rem_notif_${DateTime.now().millisecondsSinceEpoch}',
              'judul': notifTitle,
              'pesan': notifBody,
              'kategori': kategori,
              'tipe': kategori,
              'is_read': false,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            };

        await StorageService().addNotificationToCache(notifRecord);

        // 2. Update unread badge & daftar notifikasi
        await refreshUnreadCount();
        notificationListVersion.value++;

        // 3. Jika waktunya baru saja tiba (<= 15 menit), tampilkan pop-up banner & bunyi
        if (minutesSinceScheduled <= 15 && !_isTest) {
          _playAlertSound();
          _showInAppReminderBanner(
            title: notifTitle,
            body: notifBody,
            kategori: kategori,
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ ReminderNotificationService check error: $e');
    } finally {
      _isChecking = false;
    }
  }

  String _extractIsoDate(String rawDate, String fallbackIso) {
    if (rawDate.isEmpty || rawDate.toLowerCase() == 'hari ini') {
      return fallbackIso;
    }
    final isoMatch =
        RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(rawDate);
    if (isoMatch != null) {
      final y = isoMatch.group(1)!.padLeft(4, '0');
      final m = isoMatch.group(2)!.padLeft(2, '0');
      final d = isoMatch.group(3)!.padLeft(2, '0');
      return '$y-$m-$d';
    }
    final parsed = TimeUtils.parseBirthDate(rawDate);
    if (parsed != null) {
      return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    }
    return fallbackIso;
  }

  Future<void> _playAlertSound() async {
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    try {
      final player = AudioPlayer();
      await player.setVolume(0.7);
      await player.play(AssetSource('sounds/ringtone.mp3'));
      Future.delayed(const Duration(seconds: 3), () {
        player.stop().catchError((_) {});
        player.dispose().catchError((_) {});
      });
    } catch (_) {}
  }

  void _showInAppReminderBanner({
    required String title,
    required String body,
    required String kategori,
  }) {
    final navState = NavigationService.navigatorKey.currentState;
    final overlay = navState?.overlay;
    if (overlay == null) return;

    _dismissActiveBanner();

    final isKonsul = kategori.toLowerCase().contains('konsul');
    final iconData = isKonsul
        ? Icons.medical_services_rounded
        : Icons.medication_rounded;

    _activeBannerEntry = OverlayEntry(
      builder: (ctx) {
        final topPad = MediaQuery.of(ctx).padding.top + 10;
        return Positioned(
          top: topPad,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -30 * (1 - value)),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {
                  _dismissActiveBanner();
                  navState?.push(
                    MaterialPageRoute(
                      builder: (_) => const PasienNotifikasiScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF065A37),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF34D399).withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          iconData,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'PENGINGAT SAYA',
                                    style: GoogleFonts.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Baru saja',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              body,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.92),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ketuk untuk membuka Notifikasi →',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        onPressed: _dismissActiveBanner,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_activeBannerEntry!);
    _bannerDismissTimer = Timer(const Duration(seconds: 6), () {
      _dismissActiveBanner();
    });
  }

  void _dismissActiveBanner() {
    _bannerDismissTimer?.cancel();
    _bannerDismissTimer = null;
    try {
      _activeBannerEntry?.remove();
    } catch (_) {}
    _activeBannerEntry = null;
  }
}

