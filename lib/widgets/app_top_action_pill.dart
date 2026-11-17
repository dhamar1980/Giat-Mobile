import 'dart:io';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/pasien_profile_state.dart';
import '../screens/dokter/models/dokter_models.dart';
import '../screens/apotek/models/apotek_models.dart';
import '../screens/pasien/notifikasi/pasien_notifikasi_screen.dart';
import '../screens/pasien/profile/profile_pasien_screen.dart';
import '../screens/dokter/notifikasi/dokter_notifikasi_screen.dart';
import '../screens/dokter/profile/dokter_profile_screen.dart';
import '../screens/apotek/notifikasi/apotek_notifikasi_screen.dart';
import '../screens/apotek/profile/apotek_profile_screen.dart';
import '../services/reminder_notification_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_admin_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KAPSUL AKSI ATAS KONSISTEN (Notifikasi & Profil untuk Pasien, Dokter, Apotek)
// Sesuai Desain Figma GIAT: Kapsul Putih, Shadow Halus, Lonceng & Avatar Bulat
// ─────────────────────────────────────────────────────────────────────────────

class PasienTopActionPill extends StatelessWidget {
  final String userName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final Widget? customLeading;

  const PasienTopActionPill({
    super.key,
    this.userName = 'Pasien',
    this.onNotificationTap,
    this.onProfileTap,
    this.customLeading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // 1. Notifikasi / Custom Leading (Lonceng atau Keranjang di sisi kiri)
          if (customLeading != null)
            customLeading!
          else
            ValueListenableBuilder<int>(
              valueListenable: ReminderNotificationService.instance.unreadCountNotifier,
              builder: (context, unreadCount, _) {
              final effectiveCount = unreadCount > 0
                  ? unreadCount
                  : StorageService().getUnreadNotificationCount();

              return Stack(
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
                    onPressed: onNotificationTap ??
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PasienNotifikasiScreen(),
                            ),
                          );
                        },
                  ),
                  if (effectiveCount > 0)
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
                            effectiveCount > 9 ? '9+' : '$effectiveCount',
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
              );
            },
          ),
          const SizedBox(width: 8),

          // 2. Profil Pasien (Avatar di sisi kanan)
          GestureDetector(
            onTap: onProfileTap ??
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePasienScreen(userName: userName),
                    ),
                  );
                },
            child: ListenableBuilder(
              listenable: PasienProfileState.instance,
              builder: (context, _) {
                final rawAvatar = PasienProfileState.instance.avatarPath;
                final resolved = ApiConfig.resolveImageUrl(rawAvatar);
                final hasPhoto = resolved.isNotEmpty &&
                    (resolved.startsWith('http') ||
                        (File(resolved).existsSync() && !resolved.startsWith('assets/')));

                return Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF044E2F),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasPhoto
                      ? (resolved.startsWith('http')
                          ? Image.network(
                              resolved,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.person_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            )
                          : Image.file(
                              File(resolved),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.person_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ))
                      : const Icon(
                          Icons.person_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DokterTopActionPill extends StatefulWidget {
  final String? doctorName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const DokterTopActionPill({
    super.key,
    this.doctorName,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  State<DokterTopActionPill> createState() => _DokterTopActionPillState();
}

class _DokterTopActionPillState extends State<DokterTopActionPill> {
  int _unreadCount = 0;

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    if (!_isTest) {
      _refreshUnreadBadge();
    }
  }

  Future<void> _refreshUnreadBadge() async {
    try {
      final count = await SupabaseAdminService.instance.fetchDokterUnreadNotificationCount(
        doctorName: widget.doctorName ?? DokterProfileState.instance.doctorName,
      );
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  if (widget.onNotificationTap != null) {
                    widget.onNotificationTap!();
                    return;
                  }
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => DokterNotifikasiScreen(
                            doctorName: widget.doctorName ?? DokterProfileState.instance.doctorName,
                          ),
                        ),
                      )
                      .then((_) => _refreshUnreadBadge());
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        _unreadCount > 99 ? '99+' : '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onProfileTap ??
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DokterProfileScreen(
                        doctorName: widget.doctorName ?? DokterProfileState.instance.doctorName,
                        onLogout: () => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
            child: ListenableBuilder(
              listenable: DokterProfileState.instance,
              builder: (context, _) {
                final rawAvatar = DokterProfileState.instance.avatarUrl;
                final resolved = ApiConfig.resolveImageUrl(rawAvatar);
                final hasPhoto = resolved.isNotEmpty &&
                    (resolved.startsWith('http') ||
                        (File(resolved).existsSync() && !resolved.startsWith('assets/')));

                return Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF044E2F),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasPhoto
                      ? (resolved.startsWith('http')
                          ? Image.network(
                              resolved,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.person_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            )
                          : Image.file(
                              File(resolved),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.person_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ))
                      : const Icon(
                          Icons.person_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ApotekTopActionPill extends StatefulWidget {
  final String? apotekerName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const ApotekTopActionPill({
    super.key,
    this.apotekerName,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  State<ApotekTopActionPill> createState() => _ApotekTopActionPillState();
}

class _ApotekTopActionPillState extends State<ApotekTopActionPill> {
  int _unreadCount = 0;

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    if (!_isTest) {
      _refreshUnreadBadge();
    }
  }

  Future<void> _refreshUnreadBadge() async {
    try {
      final count = await SupabaseAdminService.instance
          .fetchApotekUnreadNotificationCount(
        apotekName:
            widget.apotekerName ?? ApotekProfileState.instance.apotekerName,
      );
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifs = _isTest
        ? ApotekMockData.notifications.where((n) => !n.isRead).length
        : _unreadCount;

    return Container(
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
                  if (widget.onNotificationTap != null) {
                    widget.onNotificationTap!();
                    return;
                  }
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => ApotekNotifikasiScreen(
                            apotekerName: widget.apotekerName ??
                                ApotekProfileState.instance.apotekerName,
                          ),
                        ),
                      )
                      .then((_) => _refreshUnreadBadge());
                },
              ),
              if (unreadNotifs > 0)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        unreadNotifs > 99 ? '99+' : '$unreadNotifs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onProfileTap ??
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ApotekProfileScreen(
                        apotekerName: widget.apotekerName ??
                            ApotekProfileState.instance.apotekerName,
                        onLogout: () => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
            child: ListenableBuilder(
              listenable: ApotekProfileState.instance,
              builder: (context, _) {
                final rawAvatar = ApotekProfileState.instance.avatarPath;
                final resolved = ApiConfig.resolveImageUrl(rawAvatar);
                final hasPhoto = resolved.isNotEmpty &&
                    (resolved.startsWith('http') ||
                        (File(resolved).existsSync() &&
                            !resolved.startsWith('assets/')));

                return Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF044E2F),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasPhoto
                      ? (resolved.startsWith('http')
                          ? Image.network(
                              resolved,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.person_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            )
                          : Image.file(
                              File(resolved),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.person_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ))
                      : const Icon(
                          Icons.person_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
