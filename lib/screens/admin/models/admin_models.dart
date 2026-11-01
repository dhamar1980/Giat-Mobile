import 'package:flutter/material.dart';
import '../../../services/api_client.dart';
import '../../../services/supabase_admin_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN MODELS & API-CONNECTED STORE
// ─────────────────────────────────────────────────────────────────────────────
// Terhubung langsung ke REST API Backend Laravel (/api/admin/*):
//   - GET  /api/admin/dashboard
//   - GET  /api/admin/profile | PUT /api/admin/profile | PUT /api/admin/password
//   - GET  /api/admin/accounts | POST /api/admin/accounts | PUT /api/admin/accounts/{id}/role
//   - GET  /api/admin/edukasi | POST /api/admin/edukasi | PUT /api/admin/edukasi/{id} | DELETE /api/admin/edukasi/{id}
//   - GET  /api/admin/system-updates | POST /api/admin/system-updates
//   - GET  /api/admin/notifications | PATCH /api/admin/notifications/{id}/read | PATCH /api/admin/notifications/read-all | DELETE /api/admin/notifications/{id}
// ─────────────────────────────────────────────────────────────────────────────

/// Role pengguna yang bisa dikelola admin.
enum AdminUserRole { pasien, dokter, apotek, admin }

extension AdminUserRoleX on AdminUserRole {
  String get key => name; // nilai di kolom "user".role

  String get label {
    switch (this) {
      case AdminUserRole.pasien:
        return 'Pasien';
      case AdminUserRole.dokter:
        return 'Dokter';
      case AdminUserRole.apotek:
        return 'Apotek';
      case AdminUserRole.admin:
        return 'Admin';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminUserRole.pasien:
        return Icons.personal_injury_outlined;
      case AdminUserRole.dokter:
        return Icons.medical_services_outlined;
      case AdminUserRole.apotek:
        return Icons.local_pharmacy_outlined;
      case AdminUserRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  Color get color {
    switch (this) {
      case AdminUserRole.pasien:
        return const Color(0xFF0EA5E9);
      case AdminUserRole.dokter:
        return const Color(0xFF16A34A);
      case AdminUserRole.apotek:
        return const Color(0xFFF59E0B);
      case AdminUserRole.admin:
        return const Color(0xFF7C3AED);
    }
  }

  Color get softColor => color.withValues(alpha: 0.12);

  String get description {
    switch (this) {
      case AdminUserRole.pasien:
        return 'Akses PRAGI, pantau kesehatan, konsultasi & beli obat';
      case AdminUserRole.dokter:
        return 'Akses konsultasi pasien, jadwal praktik & penulisan resep';
      case AdminUserRole.apotek:
        return 'Akses verifikasi resep, pesanan & manajemen stok obat';
      case AdminUserRole.admin:
        return 'Akses penuh pengelolaan sistem GIAT';
    }
  }

  static AdminUserRole fromKey(String? key) {
    switch ((key ?? '').toLowerCase()) {
      case 'dokter':
        return AdminUserRole.dokter;
      case 'apotek':
      case 'apoteker':
        return AdminUserRole.apotek;
      case 'admin':
        return AdminUserRole.admin;
      default:
        return AdminUserRole.pasien;
    }
  }
}

class AdminAccount {
  final String id;
  String nama;
  String email;
  String? noHp;
  AdminUserRole role;
  bool isActive;
  final DateTime createdAt;

  /// Info tambahan sesuai role (spesialisasi / alamat apotek / dll)
  String? keterangan;
  String? fotoProfile;

  AdminAccount({
    required this.id,
    required this.nama,
    required this.email,
    this.noHp,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.keterangan,
    this.fotoProfile,
  });

  factory AdminAccount.fromJson(Map<String, dynamic> json) {
    return AdminAccount(
      id: (json['id'] ?? '').toString(),
      nama: (json['nama'] ?? 'Pengguna GIAT').toString(),
      email: (json['email'] ?? '').toString(),
      noHp: json['no_hp']?.toString(),
      role: AdminUserRoleX.fromKey(json['role']?.toString()),
      isActive: json['is_active'] == null ? true : (json['is_active'] == true || json['is_active'] == 1),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      keterangan: json['keterangan']?.toString(),
      fotoProfile: json['foto_profile']?.toString(),
    );
  }

  String get initials {
    final parts = nama
        .replaceAll(RegExp(r'^(dr\.|Apt\.|Apotek)\s*', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

enum EdukasiStatus { published, draft }

class AdminEdukasi {
  final String id;
  String judul;
  String kategori;
  String ringkasan;
  String konten;
  String gambar;
  String penulis;
  int durasiBaca;
  EdukasiStatus status;
  final DateTime createdAt;
  DateTime updatedAt;

  AdminEdukasi({
    required this.id,
    required this.judul,
    required this.kategori,
    required this.ringkasan,
    required this.konten,
    required this.gambar,
    required this.penulis,
    this.durasiBaca = 3,
    this.status = EdukasiStatus.published,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory AdminEdukasi.fromJson(Map<String, dynamic> json) {
    final created = DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    final updated = DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toLocal() ?? created;
    final rawImg = (json['gambar_url'] ?? json['gambar'] ?? '').toString().trim();
    return AdminEdukasi(
      id: (json['id'] ?? '').toString(),
      judul: (json['judul'] ?? '').toString(),
      kategori: (json['kategori'] ?? 'Info CKD').toString(),
      ringkasan: (json['ringkasan'] ?? '').toString(),
      konten: (json['konten'] ?? '').toString(),
      gambar: rawImg.isNotEmpty ? rawImg : 'assets/images/kidneys.jpg',
      penulis: (json['penulis'] ?? 'Tim Medis GIAT').toString(),
      durasiBaca: int.tryParse(json['durasi_baca']?.toString() ?? '4') ?? 4,
      status: EdukasiStatus.published,
      createdAt: created,
      updatedAt: updated,
    );
  }
}

enum UpdateTipe { fitur, perbaikan, pemeliharaan }

extension UpdateTipeX on UpdateTipe {
  String get label {
    switch (this) {
      case UpdateTipe.fitur:
        return 'Fitur Baru';
      case UpdateTipe.perbaikan:
        return 'Perbaikan Bug';
      case UpdateTipe.pemeliharaan:
        return 'Pemeliharaan';
    }
  }

  IconData get icon {
    switch (this) {
      case UpdateTipe.fitur:
        return Icons.auto_awesome_rounded;
      case UpdateTipe.perbaikan:
        return Icons.build_circle_outlined;
      case UpdateTipe.pemeliharaan:
        return Icons.engineering_outlined;
    }
  }

  Color get color {
    switch (this) {
      case UpdateTipe.fitur:
        return const Color(0xFF16A34A);
      case UpdateTipe.perbaikan:
        return const Color(0xFF0EA5E9);
      case UpdateTipe.pemeliharaan:
        return const Color(0xFFF59E0B);
    }
  }

  static UpdateTipe fromKey(String? key) {
    switch ((key ?? '').toLowerCase()) {
      case 'perbaikan':
        return UpdateTipe.perbaikan;
      case 'pemeliharaan':
        return UpdateTipe.pemeliharaan;
      default:
        return UpdateTipe.fitur;
    }
  }
}

class AdminSystemUpdate {
  final String id;
  String versi;
  String judul;
  String deskripsi;
  UpdateTipe tipe;

  /// 'semua' | 'pasien' | 'dokter' | 'apotek'
  String targetRole;
  bool isPenting;
  final DateTime publishedAt;
  final String? waktuText;

  AdminSystemUpdate({
    required this.id,
    required this.versi,
    required this.judul,
    required this.deskripsi,
    required this.tipe,
    this.targetRole = 'semua',
    this.isPenting = false,
    required this.publishedAt,
    this.waktuText,
  });

  factory AdminSystemUpdate.fromJson(Map<String, dynamic> json) {
    return AdminSystemUpdate(
      id: (json['id'] ?? '').toString(),
      versi: (json['versi'] ?? '').toString(),
      judul: (json['judul'] ?? '').toString(),
      deskripsi: (json['deskripsi'] ?? '').toString(),
      tipe: UpdateTipeX.fromKey(json['tipe']?.toString()),
      targetRole: (json['target_role'] ?? 'semua').toString(),
      isPenting: json['is_penting'] == true || json['is_penting'] == 1,
      publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      waktuText: json['waktu']?.toString(),
    );
  }

  String get targetLabel {
    switch (targetRole.toLowerCase()) {
      case 'pasien':
        return 'Pasien';
      case 'dokter':
        return 'Dokter';
      case 'apotek':
        return 'Apotek';
      default:
        return 'Semua Pengguna';
    }
  }
}

class AdminAccessLog {
  final String namaUser;
  final String aksi;
  final DateTime waktu;
  final String? waktuText;

  AdminAccessLog({
    required this.namaUser,
    required this.aksi,
    required this.waktu,
    this.waktuText,
  });

  factory AdminAccessLog.fromJson(Map<String, dynamic> json) {
    return AdminAccessLog(
      namaUser: (json['nama_user'] ?? '').toString(),
      aksi: (json['aksi'] ?? '').toString(),
      waktu: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      waktuText: json['waktu']?.toString(),
    );
  }
}

/// Model Notifikasi masuk untuk Administrator (dibuka melalui ikon lonceng).
class AdminNotificationItem {
  final String id;
  final String judul;
  final String pesan;
  final String tipe; // 'akun', 'akses', 'edukasi', 'sistem'
  final DateTime createdAt;
  final String? waktuText;
  bool isRead;

  AdminNotificationItem({
    required this.id,
    required this.judul,
    required this.pesan,
    this.tipe = 'sistem',
    required this.createdAt,
    this.waktuText,
    this.isRead = false,
  });

  factory AdminNotificationItem.fromJson(Map<String, dynamic> json) {
    return AdminNotificationItem(
      id: (json['id'] ?? '').toString(),
      judul: (json['judul'] ?? '').toString(),
      pesan: (json['pesan'] ?? '').toString(),
      tipe: (json['tipe'] ?? json['kategori'] ?? 'sistem').toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      waktuText: json['waktu']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN STORE (state reaktif terhubung langsung ke Supabase PostgreSQL & REST API)
// Tanpa data dummy: seluruh data bersumber 100% real dari database Supabase GIAT
// ─────────────────────────────────────────────────────────────────────────────
class AdminStore extends ChangeNotifier {
  AdminStore._();
  static final AdminStore instance = AdminStore._();

  final ApiClient _api = ApiClient();
  final SupabaseAdminService _supabase = SupabaseAdminService.instance;

  bool isLoading = false;

  // Profil admin yang login
  String adminNama = 'Admin GIAT';
  String adminEmail = 'admin@gmail.com';
  String adminNoHp = '081234567890';
  String adminJabatan = 'Super Administrator Sistem GIAT';
  String? adminFotoProfile;

  final List<AdminAccount> accounts = [];
  final List<AdminEdukasi> edukasi = [];
  final List<AdminSystemUpdate> updates = [];
  final List<AdminAccessLog> logs = [];
  final List<AdminNotificationItem> notifications = [];

  final Map<AdminUserRole, int> _roleCountsFromApi = {};

  static const List<String> edukasiKategori = ['Info CKD', 'Nutrisi & Diet', 'Pola Hidup'];

  /// Role pengguna yang dikelola pada halaman Kelola Akun (tanpa Admin)
  static const List<AdminUserRole> managedRoles = [
    AdminUserRole.pasien,
    AdminUserRole.dokter,
    AdminUserRole.apotek,
  ];

  int countRole(AdminUserRole r) {
    if (accounts.isNotEmpty) {
      return accounts.where((a) => a.role == r).length;
    }
    return _roleCountsFromApi[r] ?? 0;
  }

  int get totalAccounts => accounts.isNotEmpty
      ? accounts.where((a) => a.role != AdminUserRole.admin).length
      : ((_roleCountsFromApi[AdminUserRole.pasien] ?? 0) +
          (_roleCountsFromApi[AdminUserRole.dokter] ?? 0) +
          (_roleCountsFromApi[AdminUserRole.apotek] ?? 0));
  int get activeAccounts => accounts.where((a) => a.isActive).length;
  int get publishedEdukasi => edukasi.where((e) => e.status == EdukasiStatus.published).length;
  int get unreadNotificationsCount => notifications.where((n) => !n.isRead).length;

  void syncAdminProfile({String? nama, String? email, String? noHp, String? jabatan, String? fotoProfile}) {
    if (nama != null && nama.isNotEmpty) adminNama = nama;
    if (email != null && email.isNotEmpty) adminEmail = email;
    if (noHp != null && noHp.isNotEmpty) adminNoHp = noHp;
    if (jabatan != null && jabatan.isNotEmpty) adminJabatan = jabatan;
    if (fotoProfile != null && fotoProfile.isNotEmpty) adminFotoProfile = fotoProfile;
  }

  // ── Sinkronisasi Penuh dengan Database Real Supabase PostgreSQL ──
  Future<void> fetchAllFromApi() async {
    isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        fetchProfile(),
        fetchAccounts(),
        fetchEdukasi(),
        fetchSystemUpdates(),
        fetchDashboard(),
        fetchNotifications(),
      ]);
    } catch (e) {
      debugPrint('AdminStore.fetchAllFromApi warning: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Memuat data dashboard real dari Supabase (`admin_access_logs`, `system_updates`, `admin`)
  Future<void> fetchDashboard() async {
    try {
      final rawLogs = await _supabase.fetchAccessLogs();
      logs
        ..clear()
        ..addAll(rawLogs.map((m) => AdminAccessLog.fromJson(m)));
      notifyListeners();
      return;
    } catch (pgErr) {
      debugPrint('AdminStore.fetchDashboard Supabase fallback to HTTP: $pgErr');
    }

    try {
      final response = await _api.dio.get('/admin/dashboard');
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        final data = body['data'] as Map;

        if (data['admin'] is Map) {
          final adm = data['admin'] as Map;
          syncAdminProfile(
            nama: adm['nama']?.toString(),
            email: adm['email']?.toString(),
            noHp: adm['no_hp']?.toString(),
            jabatan: adm['jabatan']?.toString(),
            fotoProfile: adm['foto_profile']?.toString(),
          );
        }

        if (data['counts'] is Map) {
          final c = data['counts'] as Map;
          _roleCountsFromApi[AdminUserRole.dokter] = int.tryParse('${c['dokter'] ?? 0}') ?? 0;
          _roleCountsFromApi[AdminUserRole.pasien] = int.tryParse('${c['pasien'] ?? 0}') ?? 0;
          _roleCountsFromApi[AdminUserRole.apotek] = int.tryParse('${c['apotek'] ?? 0}') ?? 0;
          _roleCountsFromApi[AdminUserRole.admin] = int.tryParse('${c['admin'] ?? 0}') ?? 0;
        }

        if (data['access_logs'] is List) {
          final rawLogs = data['access_logs'] as List;
          logs
            ..clear()
            ..addAll(
              rawLogs
                  .whereType<Map>()
                  .map((m) => AdminAccessLog.fromJson(Map<String, dynamic>.from(m))),
            );
        }

        if (data['latest_update'] is Map) {
          final latest = AdminSystemUpdate.fromJson(
            Map<String, dynamic>.from(data['latest_update'] as Map),
          );
          final existingIdx = updates.indexWhere((u) => u.id == latest.id);
          if (existingIdx >= 0) {
            updates[existingIdx] = latest;
          } else {
            updates.insert(0, latest);
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('AdminStore.fetchDashboard error: $e');
    }
  }

  /// Memuat profil Admin real dari tabel `admin` & `"user"` di Supabase
  Future<void> fetchProfile() async {
    try {
      final data = await _supabase.fetchAdminProfile(email: adminEmail);
      if (data != null) {
        syncAdminProfile(
          nama: data['nama']?.toString(),
          email: data['email']?.toString(),
          noHp: data['no_hp']?.toString(),
          jabatan: data['jabatan']?.toString(),
          fotoProfile: data['foto_profile']?.toString(),
        );
        notifyListeners();
        return;
      }
    } catch (pgErr) {
      debugPrint('AdminStore.fetchProfile Supabase fallback to HTTP: $pgErr');
    }

    try {
      final response = await _api.dio.get('/admin/profile');
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        final data = body['data'] as Map;
        syncAdminProfile(
          nama: data['nama']?.toString(),
          email: data['email']?.toString(),
          noHp: data['no_hp']?.toString(),
          jabatan: data['jabatan']?.toString(),
          fotoProfile: data['foto_profile']?.toString(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AdminStore.fetchProfile error: $e');
    }
  }

  /// Memperbarui profil Admin ke database Supabase
  Future<bool> updateAdminProfile({
    required String nama,
    required String email,
    required String noHp,
    required String jabatan,
  }) async {
    syncAdminProfile(nama: nama, email: email, noHp: noHp, jabatan: jabatan);
    notifyListeners();

    try {
      final ok = await _supabase.updateAdminProfile(
        nama: nama,
        email: email,
        noHp: noHp,
        jabatan: jabatan,
      );
      if (ok) {
        await fetchAccounts();
        return true;
      }
    } catch (pgErr) {
      debugPrint('AdminStore.updateAdminProfile Supabase fallback: $pgErr');
    }

    try {
      final response = await _api.dio.put(
        '/admin/profile',
        data: {
          'nama': nama,
          'email': email,
          'no_hp': noHp,
          'jabatan': jabatan,
        },
      );
      final body = response.data;
      if (body is Map && body['data'] is Map) {
        final data = body['data'] as Map;
        syncAdminProfile(
          nama: data['nama']?.toString(),
          email: data['email']?.toString(),
          noHp: data['no_hp']?.toString(),
          jabatan: data['jabatan']?.toString(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('AdminStore.updateAdminProfile error: $e');
      return false;
    }
  }

  /// Memperbarui kata sandi Admin di database Supabase
  /// Mengembalikan `null` jika berhasil, atau pesan error jika gagal.
  Future<String?> updateAdminPassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      return await _supabase.updateAdminPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (pgErr) {
      debugPrint('AdminStore.updateAdminPassword Supabase fallback: $pgErr');
    }

    try {
      final response = await _api.dio.put(
        '/admin/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      );
      final body = response.data;
      if (body is Map && body['success'] == true) {
        return null;
      }
      return (body is Map ? body['message']?.toString() : null) ?? 'Gagal memperbarui kata sandi';
    } catch (e) {
      return ApiClient.getErrorMessage(e);
    }
  }

  /// POST /api/admin/logout
  Future<void> logoutAdmin() async {
    try {
      await _api.dio.post('/admin/logout').timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Memuat daftar akun pengguna real (Pasien, Dokter, Apotek) dari Supabase
  Future<void> fetchAccounts({String? role, String? search}) async {
    try {
      final rawList = await _supabase.fetchAccounts();
      accounts
        ..clear()
        ..addAll(
          rawList
              .map((m) => AdminAccount.fromJson(m))
              .where((a) => a.role != AdminUserRole.admin),
        );
      notifyListeners();
      return;
    } catch (pgErr) {
      debugPrint('AdminStore.fetchAccounts Supabase fallback to HTTP: $pgErr');
    }

    try {
      final queryParams = <String, dynamic>{};
      if (role != null && role.isNotEmpty && role.toLowerCase() != 'semua') {
        queryParams['role'] = role.toLowerCase();
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _api.dio.get(
        '/admin/accounts',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final body = response.data;
      if (body is Map && body['success'] == true) {
        final countsMap = (body['counts'] is Map)
            ? body['counts'] as Map
            : (body['data'] is Map && (body['data'] as Map)['counts'] is Map)
                ? (body['data'] as Map)['counts'] as Map
                : null;
        if (countsMap != null) {
          _roleCountsFromApi[AdminUserRole.dokter] = int.tryParse('${countsMap['dokter'] ?? 0}') ?? 0;
          _roleCountsFromApi[AdminUserRole.pasien] = int.tryParse('${countsMap['pasien'] ?? 0}') ?? 0;
          _roleCountsFromApi[AdminUserRole.apotek] = int.tryParse('${countsMap['apotek'] ?? 0}') ?? 0;
          _roleCountsFromApi[AdminUserRole.admin] = int.tryParse('${countsMap['admin'] ?? 0}') ?? 0;
        }

        List? rawList;
        if (body['data'] is Map && (body['data'] as Map)['accounts'] is List) {
          rawList = (body['data'] as Map)['accounts'] as List;
        } else if (body['data'] is List) {
          rawList = body['data'] as List;
        }

        if (rawList != null) {
          accounts
            ..clear()
            ..addAll(
              rawList
                  .whereType<Map>()
                  .map((m) => AdminAccount.fromJson(Map<String, dynamic>.from(m)))
                  .where((a) => a.role != AdminUserRole.admin),
            );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('AdminStore.fetchAccounts error: $e');
    }
  }

  /// Memuat daftar artikel edukasi kesehatan real dari tabel `edukasi_artikel` di Supabase
  Future<void> fetchEdukasi({String? kategori, String? search}) async {
    try {
      final rawList = await _supabase.fetchEdukasi();
      edukasi
        ..clear()
        ..addAll(rawList.map((m) => AdminEdukasi.fromJson(m)));
      notifyListeners();
      return;
    } catch (pgErr) {
      debugPrint('AdminStore.fetchEdukasi Supabase fallback to HTTP: $pgErr');
    }

    try {
      final queryParams = <String, dynamic>{};
      if (kategori != null && kategori.isNotEmpty && kategori != 'Semua') {
        queryParams['kategori'] = kategori;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _api.dio.get(
        '/admin/edukasi',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final body = response.data;
      if (body is Map && body['success'] == true) {
        List? rawList;
        if (body['data'] is List) {
          rawList = body['data'] as List;
        } else if (body['data'] is Map && (body['data'] as Map)['edukasi'] is List) {
          rawList = (body['data'] as Map)['edukasi'] as List;
        }
        if (rawList != null) {
          edukasi
            ..clear()
            ..addAll(
              rawList
                  .whereType<Map>()
                  .map((m) => AdminEdukasi.fromJson(Map<String, dynamic>.from(m))),
            );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('AdminStore.fetchEdukasi error: $e');
    }
  }

  /// Memuat riwayat update sistem real dari tabel `system_updates` di Supabase
  Future<void> fetchSystemUpdates({UpdateTipe? tipe}) async {
    try {
      final rawList = await _supabase.fetchSystemUpdates();
      updates
        ..clear()
        ..addAll(rawList.map((m) => AdminSystemUpdate.fromJson(m)));
      notifyListeners();
      return;
    } catch (pgErr) {
      debugPrint('AdminStore.fetchSystemUpdates Supabase fallback to HTTP: $pgErr');
    }

    try {
      final response = await _api.dio.get(
        '/admin/system-updates',
        queryParameters: tipe != null ? {'tipe': tipe.name} : null,
      );
      final body = response.data;
      if (body is Map && body['success'] == true) {
        List? rawList;
        if (body['data'] is List) {
          rawList = body['data'] as List;
        } else if (body['data'] is Map && (body['data'] as Map)['updates'] is List) {
          rawList = (body['data'] as Map)['updates'] as List;
        }
        if (rawList != null) {
          updates
            ..clear()
            ..addAll(
              rawList
                  .whereType<Map>()
                  .map((m) => AdminSystemUpdate.fromJson(Map<String, dynamic>.from(m))),
            );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('AdminStore.fetchSystemUpdates error: $e');
    }
  }

  /// Memuat daftar notifikasi masuk Admin real dari tabel `notifikasi` di Supabase
  Future<void> fetchNotifications() async {
    try {
      final rawList = await _supabase.fetchAdminNotifications();
      notifications
        ..clear()
        ..addAll(rawList.map((m) => AdminNotificationItem.fromJson(m)));
      notifyListeners();
      return;
    } catch (pgErr) {
      debugPrint('AdminStore.fetchNotifications Supabase fallback to HTTP: $pgErr');
    }

    try {
      final response = await _api.dio.get('/admin/notifications');
      final body = response.data;
      if (body is Map && body['success'] == true) {
        List? rawList;
        if (body['data'] is Map && (body['data'] as Map)['notifications'] is List) {
          rawList = (body['data'] as Map)['notifications'] as List;
        } else if (body['data'] is List) {
          rawList = body['data'] as List;
        }
        if (rawList != null) {
          notifications
            ..clear()
            ..addAll(
              rawList
                  .whereType<Map>()
                  .map((m) => AdminNotificationItem.fromJson(Map<String, dynamic>.from(m))),
            );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('AdminStore.fetchNotifications error: $e');
    }
  }

  // ── Notifikasi Masuk (Ikon Lonceng) ──
  Future<void> markNotificationRead(String id) async {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx >= 0 && !notifications[idx].isRead) {
      notifications[idx].isRead = true;
      notifyListeners();
    }
    try {
      await _supabase.markNotificationRead(id);
      return;
    } catch (_) {}
    try {
      await _api.dio.patch('/admin/notifications/$id/read');
    } catch (e) {
      debugPrint('AdminStore.markNotificationRead error: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    for (final n in notifications) {
      n.isRead = true;
    }
    notifyListeners();
    try {
      await _supabase.markAllNotificationsRead();
      return;
    } catch (_) {}
    try {
      await _api.dio.patch('/admin/notifications/read-all');
    } catch (e) {
      debugPrint('AdminStore.markAllNotificationsRead error: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    try {
      await _supabase.deleteNotification(id);
      return;
    } catch (_) {}
    try {
      await _api.dio.delete('/admin/notifications/$id');
    } catch (e) {
      debugPrint('AdminStore.deleteNotification error: $e');
    }
  }

  // ── Akun ──
  /// Menambahkan akun baru ke database Supabase
  Future<void> addAccount(AdminAccount a, {String password = 'password123'}) async {
    accounts.insert(0, a);
    logs.insert(
      0,
      AdminAccessLog(
        namaUser: a.nama,
        aksi: 'Akun ${a.role.label} dibuat',
        waktu: DateTime.now(),
      ),
    );
    notifyListeners();

    try {
      final createdMap = await _supabase.createAccount(
        nama: a.nama,
        email: a.email,
        noHp: a.noHp,
        role: a.role.key,
        keterangan: a.keterangan,
        password: password,
      );
      if (createdMap != null) {
        final created = AdminAccount.fromJson(createdMap);
        final idx = accounts.indexWhere((x) => x.id == a.id);
        if (idx >= 0) {
          accounts[idx] = created;
        }
        notifyListeners();
      }
      await Future.wait([
        fetchAccounts(),
        fetchDashboard(),
        fetchNotifications(),
      ]);
      return;
    } catch (pgErr) {
      debugPrint('AdminStore.addAccount Supabase fallback to HTTP: $pgErr');
    }

    try {
      final response = await _api.dio.post(
        '/admin/accounts',
        data: {
          'nama': a.nama,
          'email': a.email,
          'no_hp': a.noHp,
          'role': a.role.key,
          'keterangan': a.keterangan,
          'password': password,
        },
      );
      final body = response.data;
      if (body is Map && body['data'] is Map) {
        final created = AdminAccount.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
        final idx = accounts.indexWhere((x) => x.id == a.id);
        if (idx >= 0) {
          accounts[idx] = created;
        }
        notifyListeners();
      }
      await Future.wait([
        fetchDashboard(),
        fetchNotifications(),
      ]);
    } catch (e) {
      debugPrint('AdminStore.addAccount error: $e');
    }
  }

  /// Mengubah hak akses (role) akun di database Supabase
  Future<void> changeRole(AdminAccount a, AdminUserRole newRole) async {
    if (a.role == newRole) return;
    final old = a.role;
    a.role = newRole;
    logs.insert(
      0,
      AdminAccessLog(
        namaUser: a.nama,
        aksi: 'Hak akses ${old.label} → ${newRole.label}',
        waktu: DateTime.now(),
      ),
    );
    notifyListeners();

    try {
      await _supabase.changeAccountRole(
        userId: a.id,
        nama: a.nama,
        oldRole: old.key,
        newRole: newRole.key,
        noHp: a.noHp,
        keterangan: a.keterangan,
      );
      await Future.wait([
        fetchAccounts(),
        fetchDashboard(),
        fetchNotifications(),
      ]);
      return;
    } catch (pgErr) {
      debugPrint('AdminStore.changeRole Supabase fallback to HTTP: $pgErr');
    }

    try {
      await _api.dio.put(
        '/admin/accounts/${a.id}/role',
        data: {'role': newRole.key},
      );
      await fetchDashboard();
    } catch (e) {
      debugPrint('AdminStore.changeRole error: $e');
    }
  }

  void setActive(AdminAccount a, bool active) {
    a.isActive = active;
    logs.insert(
      0,
      AdminAccessLog(
        namaUser: a.nama,
        aksi: active ? 'Akun diaktifkan' : 'Akun dinonaktifkan',
        waktu: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // ── Edukasi ──
  /// Menyimpan (tambah / edit) artikel edukasi ke tabel `edukasi_artikel` di Supabase
  Future<void> saveEdukasi(AdminEdukasi e) async {
    final idx = edukasi.indexWhere((x) => x.id == e.id);
    final isExisting = idx >= 0;
    if (isExisting) {
      edukasi[idx] = e;
    } else {
      edukasi.insert(0, e);
    }
    notifyListeners();

    try {
      final savedMap = await _supabase.saveEdukasi(
        id: e.id,
        judul: e.judul,
        kategori: e.kategori,
        ringkasan: e.ringkasan,
        konten: e.konten,
        penulis: e.penulis,
        durasiBaca: e.durasiBaca,
        gambar: e.gambar,
        isUpdate: isExisting,
      );
      if (savedMap != null) {
        final saved = AdminEdukasi.fromJson(savedMap);
        final currentIdx = edukasi.indexWhere((x) => x.id == e.id);
        if (currentIdx >= 0) {
          edukasi[currentIdx] = saved;
          notifyListeners();
        }
      }
      return;
    } catch (pgErr) {
      debugPrint('AdminStore.saveEdukasi Supabase fallback to HTTP: $pgErr');
    }

    final payload = {
      'judul': e.judul,
      'kategori': e.kategori,
      'ringkasan': e.ringkasan,
      'konten': e.konten,
      'penulis': e.penulis,
      'durasi_baca': e.durasiBaca,
      'gambar': e.gambar,
    };

    try {
      final response = isExisting
          ? await _api.dio.put('/admin/edukasi/${e.id}', data: payload)
          : await _api.dio.post('/admin/edukasi', data: payload);
      final body = response.data;
      if (body is Map && body['data'] is Map) {
        final saved = AdminEdukasi.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
        final currentIdx = edukasi.indexWhere((x) => x.id == e.id);
        if (currentIdx >= 0) {
          edukasi[currentIdx] = saved;
          notifyListeners();
        }
      }
    } catch (err) {
      debugPrint('AdminStore.saveEdukasi error: $err');
    }
  }

  /// Menghapus artikel edukasi dari tabel `edukasi_artikel` di Supabase
  Future<void> deleteEdukasi(AdminEdukasi e) async {
    edukasi.removeWhere((x) => x.id == e.id);
    notifyListeners();
    try {
      await _supabase.deleteEdukasi(e.id);
      return;
    } catch (pgErr) {
      debugPrint('AdminStore.deleteEdukasi Supabase fallback to HTTP: $pgErr');
    }
    try {
      await _api.dio.delete('/admin/edukasi/${e.id}');
    } catch (err) {
      debugPrint('AdminStore.deleteEdukasi error: $err');
    }
  }

  // ── Update sistem ──
  /// Mengirim & mempublikasikan notifikasi update sistem baru ke tabel `system_updates` di Supabase
  Future<void> addUpdate(AdminSystemUpdate u) async {
    updates.insert(0, u);
    notifyListeners();

    try {
      final createdMap = await _supabase.createSystemUpdate(
        tipe: u.tipe.name,
        targetRole: u.targetRole,
        judul: u.judul,
        deskripsi: u.deskripsi,
      );
      if (createdMap != null) {
        final created = AdminSystemUpdate.fromJson(createdMap);
        final idx = updates.indexWhere((x) => x.id == u.id);
        if (idx >= 0) {
          updates[idx] = created;
          notifyListeners();
        }
      }
      return;
    } catch (pgErr) {
      debugPrint('AdminStore.addUpdate Supabase fallback to HTTP: $pgErr');
    }

    try {
      final response = await _api.dio.post(
        '/admin/system-updates',
        data: {
          'tipe': u.tipe.name,
          'target_role': u.targetRole,
          'judul': u.judul,
          'deskripsi': u.deskripsi,
        },
      );
      final body = response.data;
      if (body is Map && body['data'] is Map) {
        final created = AdminSystemUpdate.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
        final idx = updates.indexWhere((x) => x.id == u.id);
        if (idx >= 0) {
          updates[idx] = created;
          notifyListeners();
        }
      }
      await fetchDashboard();
    } catch (e) {
      debugPrint('AdminStore.addUpdate error: $e');
    }
  }

  void deleteUpdate(AdminSystemUpdate u) {
    updates.removeWhere((x) => x.id == u.id);
    notifyListeners();
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// UTIL WAKTU
// ─────────────────────────────────────────────────────────────────────────────
const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String adminFormatDate(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

String adminTimeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return adminFormatDate(d);
}
