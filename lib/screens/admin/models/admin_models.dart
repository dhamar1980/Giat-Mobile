import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN MODELS & LOCAL STORE
// ─────────────────────────────────────────────────────────────────────────────
// Struktur data mengikuti tabel Supabase:
//   - "user" (+ is_active) & admin           → AdminAccount
//   - edukasi_artikel                       → AdminEdukasi
//   - update_sistem                         → AdminSystemUpdate
//   - admin_log_hak_akses                   → AdminAccessLog
//
// Catatan: untuk tahap UI, data disimpan di memori (AdminStore). Saat API
// sudah siap, cukup ganti isi method di AdminStore dengan pemanggilan API.
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

  AdminAccount({
    required this.id,
    required this.nama,
    required this.email,
    this.noHp,
    required this.role,
    this.isActive = true,
    required this.createdAt,
    this.keterangan,
  });

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

  AdminSystemUpdate({
    required this.id,
    required this.versi,
    required this.judul,
    required this.deskripsi,
    required this.tipe,
    this.targetRole = 'semua',
    this.isPenting = false,
    required this.publishedAt,
  });

  String get targetLabel {
    switch (targetRole) {
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

  AdminAccessLog({required this.namaUser, required this.aksi, required this.waktu});
}

/// Model Notifikasi masuk untuk Administrator (dibuka melalui ikon lonceng).
class AdminNotificationItem {
  final String id;
  final String judul;
  final String pesan;
  final String tipe; // 'akun', 'akses', 'edukasi', 'sistem'
  final DateTime createdAt;
  bool isRead;

  AdminNotificationItem({
    required this.id,
    required this.judul,
    required this.pesan,
    this.tipe = 'sistem',
    required this.createdAt,
    this.isRead = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN STORE (state lokal yang bisa didengar oleh UI)
// ─────────────────────────────────────────────────────────────────────────────
class AdminStore extends ChangeNotifier {
  AdminStore._() {
    _seed();
  }
  static final AdminStore instance = AdminStore._();

  // Profil admin yang login
  String adminNama = 'Admin GIAT';
  String adminEmail = 'admin@gmail.com';
  String adminNoHp = '081200000001';
  String adminJabatan = 'Administrator Sistem';

  final List<AdminAccount> accounts = [];
  final List<AdminEdukasi> edukasi = [];
  final List<AdminSystemUpdate> updates = [];
  final List<AdminAccessLog> logs = [];
  final List<AdminNotificationItem> notifications = [];

  static const List<String> edukasiKategori = ['Info CKD', 'Nutrisi & Diet', 'Pola Hidup'];

  int countRole(AdminUserRole r) => accounts.where((a) => a.role == r).length;
  int get totalAccounts => accounts.length;
  int get activeAccounts => accounts.where((a) => a.isActive).length;
  int get publishedEdukasi => edukasi.where((e) => e.status == EdukasiStatus.published).length;
  int get unreadNotificationsCount => notifications.where((n) => !n.isRead).length;

  void syncAdminProfile({String? nama, String? email}) {
    if (nama != null && nama.isNotEmpty) adminNama = nama;
    if (email != null && email.isNotEmpty) adminEmail = email;
  }

  // ── Notifikasi Masuk (Ikon Lonceng) ──
  void markNotificationRead(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx >= 0 && !notifications[idx].isRead) {
      notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (final n in notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void deleteNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // ── Akun ──
  void addAccount(AdminAccount a) {
    accounts.insert(0, a);
    logs.insert(0, AdminAccessLog(namaUser: a.nama, aksi: 'Akun ${a.role.label} dibuat', waktu: DateTime.now()));
    notifyListeners();
  }

  void changeRole(AdminAccount a, AdminUserRole newRole) {
    if (a.role == newRole) return;
    final old = a.role;
    a.role = newRole;
    logs.insert(0, AdminAccessLog(namaUser: a.nama, aksi: 'Hak akses ${old.label} → ${newRole.label}', waktu: DateTime.now()));
    notifyListeners();
  }

  void setActive(AdminAccount a, bool active) {
    a.isActive = active;
    logs.insert(0, AdminAccessLog(namaUser: a.nama, aksi: active ? 'Akun diaktifkan' : 'Akun dinonaktifkan', waktu: DateTime.now()));
    notifyListeners();
  }

  // ── Edukasi ──
  void saveEdukasi(AdminEdukasi e) {
    final idx = edukasi.indexWhere((x) => x.id == e.id);
    if (idx >= 0) {
      edukasi[idx] = e;
    } else {
      edukasi.insert(0, e);
    }
    notifyListeners();
  }

  void deleteEdukasi(AdminEdukasi e) {
    edukasi.removeWhere((x) => x.id == e.id);
    notifyListeners();
  }

  // ── Update sistem ──
  void addUpdate(AdminSystemUpdate u) {
    updates.insert(0, u);
    notifyListeners();
  }

  void deleteUpdate(AdminSystemUpdate u) {
    updates.removeWhere((x) => x.id == u.id);
    notifyListeners();
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _seed() {
    final now = DateTime.now();
    accounts.addAll([
      AdminAccount(id: '1', nama: 'Siti Aisyah', email: 'siti.aisyah@gmail.com', noHp: '081234567801', role: AdminUserRole.pasien, createdAt: now.subtract(const Duration(days: 40)), keterangan: 'Pasien CKD Stadium 2'),
      AdminAccount(id: '2', nama: 'dr. Budi Santoso, Sp.PD', email: 'dr.budi.santoso@giat.id', noHp: '081234567802', role: AdminUserRole.dokter, createdAt: now.subtract(const Duration(days: 38)), keterangan: 'Spesialis Penyakit Dalam'),
      AdminAccount(id: '3', nama: 'Apotek Kimia Farma Dago', email: 'apotek.dago@kimiafarma.co.id', noHp: '0222500123', role: AdminUserRole.apotek, createdAt: now.subtract(const Duration(days: 35)), keterangan: 'Jl. Ir. H. Juanda No. 54, Bandung'),
      AdminAccount(id: '4', nama: 'Budi Prasetyo', email: 'budi.prasetyo@gmail.com', noHp: '081234567804', role: AdminUserRole.pasien, createdAt: now.subtract(const Duration(days: 20))),
      AdminAccount(id: '5', nama: 'dr. Anisa Putri', email: 'dr.anisa.putri@giat.id', noHp: '081234567805', role: AdminUserRole.dokter, createdAt: now.subtract(const Duration(days: 18)), keterangan: 'Dokter Umum'),
      AdminAccount(id: '6', nama: 'Nurul Hidayah', email: 'nurul.hidayah@gmail.com', role: AdminUserRole.pasien, createdAt: now.subtract(const Duration(days: 12))),
      AdminAccount(id: '7', nama: 'dr. Hendra Setiawan, Sp.PD-KGH', email: 'dr.hendra.setiawan@giat.id', role: AdminUserRole.dokter, createdAt: now.subtract(const Duration(days: 9)), keterangan: 'Konsultan Ginjal Hipertensi'),
      AdminAccount(id: '8', nama: 'Rina Wijaya', email: 'rina.wijaya@gmail.com', role: AdminUserRole.pasien, isActive: false, createdAt: now.subtract(const Duration(days: 6))),
      AdminAccount(id: '9', nama: 'Apotek K-24 Buah Batu', email: 'k24.buahbatu@gmail.com', noHp: '0227300456', role: AdminUserRole.apotek, createdAt: now.subtract(const Duration(days: 4)), keterangan: 'Jl. Buah Batu No. 120, Bandung'),
      AdminAccount(id: '10', nama: 'Dewi Lestari', email: 'dewi.lestari@gmail.com', role: AdminUserRole.pasien, createdAt: now.subtract(const Duration(days: 1))),
    ]);

    edukasi.addAll([
      AdminEdukasi(
        id: 'e1',
        judul: 'Kenali Tanda-Tanda Penyakit Ginjal Sejak Dini',
        kategori: 'Info CKD',
        ringkasan: 'CKD sering berkembang tanpa gejala. Kenali tanda awalnya agar bisa ditangani lebih cepat.',
        konten: 'Penyakit ginjal kronis (CKD) sering kali berkembang tanpa menimbulkan gejala yang mencolok pada tahap awal. Beberapa tanda awal meliputi perubahan frekuensi buang air kecil, urine berbusa, pembengkakan pada kaki atau wajah, serta rasa lelah berkepanjangan.\n\nPencegahan terbaik adalah pemeriksaan rutin fungsi ginjal, menjaga tekanan darah di bawah 130/80 mmHg, dan mengontrol gula darah.',
        gambar: 'assets/images/kidneys.jpg',
        penulis: 'Tim Medis GIAT',
        durasiBaca: 4,
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      AdminEdukasi(
        id: 'e2',
        judul: 'Makanan & Nutrisi Sehat untuk Menjaga Fungsi Ginjal',
        kategori: 'Nutrisi & Diet',
        ringkasan: 'Pola makan yang tepat membantu memperlambat penurunan fungsi ginjal.',
        konten: '1. Batasi garam maksimal 1 sendok teh per hari.\n2. Pilih protein berkualitas dalam porsi terukur.\n3. Waspadai kalium berlebih.\n4. Cukupi cairan sesuai anjuran dokter.',
        gambar: 'assets/images/kidneys.jpg',
        penulis: 'dr. Budi Santoso, Sp.PD',
        durasiBaca: 5,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      AdminEdukasi(
        id: 'e3',
        judul: 'Pentingnya Menjaga Tekanan Darah bagi Pasien Ginjal',
        kategori: 'Pola Hidup',
        ringkasan: 'Hipertensi dan ginjal saling berkaitan erat. Ini cara menjaganya.',
        konten: 'Tekanan darah tinggi dapat merusak glomerulus di dalam ginjal. Minum obat sesuai resep, kurangi stres, tidur cukup 7-8 jam, dan olahraga ringan 30 menit setiap hari.',
        gambar: 'assets/images/kidneys.jpg',
        penulis: 'Tim Medis GIAT',
        durasiBaca: 3,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ]);

    updates.addAll([
      AdminSystemUpdate(
        id: 'u1',
        versi: 'v1.0.0',
        judul: 'Peluncuran Modul Admin GIAT',
        deskripsi: 'Admin kini dapat mengelola akun pengguna, hak akses, edukasi kesehatan, serta mengirim notifikasi pembaruan sistem.',
        tipe: UpdateTipe.fitur,
        publishedAt: now.subtract(const Duration(hours: 3)),
      ),
      AdminSystemUpdate(
        id: 'u2',
        versi: 'v0.9.2',
        judul: 'Perbaikan Notifikasi Pengingat Obat',
        deskripsi: 'Memperbaiki notifikasi pengingat minum obat yang terkadang tidak muncul pada perangkat Android 14.',
        tipe: UpdateTipe.perbaikan,
        targetRole: 'pasien',
        publishedAt: now.subtract(const Duration(days: 5)),
      ),
      AdminSystemUpdate(
        id: 'u3',
        versi: 'v0.9.1',
        judul: 'Pemeliharaan Server Terjadwal',
        deskripsi: 'Server akan menjalani pemeliharaan pada Minggu pukul 01.00–03.00 WIB. Layanan konsultasi sementara tidak tersedia.',
        tipe: UpdateTipe.pemeliharaan,
        isPenting: true,
        publishedAt: now.subtract(const Duration(days: 12)),
      ),
    ]);

    logs.addAll([
      AdminAccessLog(namaUser: 'Dewi Lestari', aksi: 'Akun Pasien dibuat', waktu: now.subtract(const Duration(days: 1))),
      AdminAccessLog(namaUser: 'Rina Wijaya', aksi: 'Akun dinonaktifkan', waktu: now.subtract(const Duration(days: 2))),
      AdminAccessLog(namaUser: 'dr. Hendra Setiawan, Sp.PD-KGH', aksi: 'Hak akses Pasien → Dokter', waktu: now.subtract(const Duration(days: 9))),
    ]);

    notifications.addAll([
      AdminNotificationItem(
        id: 'an1',
        judul: 'Pendaftaran Akun Pasien Baru',
        pesan: 'Dewi Lestari (dewi.lestari@gmail.com) baru saja mendaftar sebagai Pasien di aplikasi GIAT.',
        tipe: 'akun',
        createdAt: now.subtract(const Duration(minutes: 25)),
        isRead: false,
      ),
      AdminNotificationItem(
        id: 'an2',
        judul: 'Permintaan Verifikasi Akun Apotek',
        pesan: 'Apotek K-24 Buah Batu telah melengkapi profil dan siap melayani pesanan resep.',
        tipe: 'akses',
        createdAt: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      AdminNotificationItem(
        id: 'an3',
        judul: 'Draft Artikel Edukasi Menunggu Review',
        pesan: 'Artikel "Pentingnya Menjaga Tekanan Darah bagi Pasien Ginjal" tersimpan sebagai draft dan siap dipublikasikan.',
        tipe: 'edukasi',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AdminNotificationItem(
        id: 'an4',
        judul: 'Laporan Kesehatan Sistem Harian',
        pesan: 'Seluruh layanan API, database Supabase, dan realtime chat berjalan normal (uptime 99.9%).',
        tipe: 'sistem',
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ]);
  }
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
