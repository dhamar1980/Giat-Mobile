import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import '../constants/api_constants.dart';
import '../utils/time_utils.dart';
import 'storage_service.dart';

/// Service koneksi langsung ke Database PostgreSQL Supabase GIAT (`auaejgogiyfrefsurahd`)
/// Memastikan seluruh data pada modul Admin 100% merupakan data real dari Supabase.
class SupabaseAdminService {
  SupabaseAdminService._();
  static final SupabaseAdminService instance = SupabaseAdminService._();

  Connection? _connection;
  Future<Connection>? _openingFuture;

  Future<Connection> _getConnection() async {
    if (_connection != null && _connection!.isOpen) {
      return _connection!;
    }
    if (_openingFuture != null) {
      return _openingFuture!;
    }
    _openingFuture = _openConnection();
    try {
      _connection = await _openingFuture!;
      return _connection!;
    } finally {
      _openingFuture = null;
    }
  }

  Future<Connection> _openConnection() async {
    final endpoints = <Map<String, dynamic>>[
      {
        'host': ApiConstants.supabasePoolerHost,
        'port': ApiConstants.supabaseDirectPort, // 5432 Session Pooler (IPv4 & IPv6)
        'user': ApiConstants.supabasePoolerUser,
        'queryMode': QueryMode.extended,
      },
      {
        'host': ApiConstants.supabasePoolerHost,
        'port': ApiConstants.supabasePoolerPort, // 6543 Transaction Pooler
        'user': ApiConstants.supabasePoolerUser,
        'queryMode': QueryMode.simple,
      },
      {
        'host': ApiConstants.supabaseDirectHost,
        'port': ApiConstants.supabaseDirectPort, // 5432 Direct Host (IPv6)
        'user': ApiConstants.supabaseDirectUser,
        'queryMode': QueryMode.extended,
      },
    ];

    Object? lastErr;
    for (final ep in endpoints) {
      try {
        final conn = await Connection.open(
          Endpoint(
            host: ep['host'] as String,
            port: ep['port'] as int,
            database: ApiConstants.supabaseDatabase,
            username: ep['user'] as String,
            password: ApiConstants.supabasePassword,
          ),
          settings: ConnectionSettings(
            sslMode: SslMode.require,
            connectTimeout: const Duration(seconds: 8),
            queryTimeout: const Duration(seconds: 15),
            queryMode: ep['queryMode'] as QueryMode,
          ),
        );
        debugPrint(
          '✅ [Supabase PG] Connected to ${ep['host']}:${ep['port']}',
        );
        return conn;
      } catch (e) {
        lastErr = e;
        debugPrint(
          '⚠️ [Supabase PG] Endpoint ${ep['host']}:${ep['port']} failed: $e',
        );
      }
    }
    throw Exception('Gagal terhubung ke Supabase PostgreSQL: $lastErr');
  }

  Future<Result> _exec(String sql, {Map<String, dynamic>? parameters}) async {
    try {
      final conn = await _getConnection();
      return await conn.execute(
        Sql.named(sql),
        parameters: parameters ?? const {},
      );
    } catch (e) {
      // Reconnect once if connection was dropped
      _connection = null;
      final conn = await _getConnection();
      return await conn.execute(
        Sql.named(sql),
        parameters: parameters ?? const {},
      );
    }
  }

  /// Helper untuk menjalankan query fleksibel (khusus service internal/test)
  Future<List<Map<String, dynamic>>> executeQuery(String sql, [Map<String, dynamic>? parameters]) async {
    final res = await _exec(sql, parameters: parameters);
    return res.map((r) => _normalizeMap(r.toColumnMap())).toList();
  }

  /// Login pengguna langsung ke tabel `"user"` di Supabase (dengan verifikasi bcrypt)
  Future<Map<String, dynamic>?> authenticateUser({
    required String email,
    required String password,
  }) async {
    final res = await _exec(
      r'''
      SELECT
        TRIM(u.id) AS id,
        u.email,
        u.role,
        COALESCE(d.nama, p.nama, ap.nama_apotek, ad.nama, split_part(u.email, '@', 1)) AS nama,
        COALESCE(d.no_hp, p.no_hp, ap.no_hp, ad.no_hp) AS no_hp,
        COALESCE(d.foto_profile, p.foto_profile, ap.foto_profile, ad.foto_profile) AS foto_profile,
        ad.jabatan,
        d.spesialisasi,
        d.institusi AS instansi,
        d.no_str,
        d.no_sip,
        p.alamat,
        p.jenis_kelamin,
        p.nik,
        (extensions.crypt(@pass, replace(u.password, '$2y$', '$2a$')) = replace(u.password, '$2y$', '$2a$')) AS valid_pass
      FROM "user" u
      LEFT JOIN dokter d ON TRIM(d.id_dokter) = TRIM(u.id)
      LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(u.id)
      LEFT JOIN apotek ap ON TRIM(ap.id_apotek) = TRIM(u.id)
      LEFT JOIN admin ad ON TRIM(ad.id_admin) = TRIM(u.id)
      WHERE LOWER(TRIM(u.email)) = LOWER(TRIM(@email))
      LIMIT 1
      ''',
      parameters: {
        'email': email.trim(),
        'pass': password,
      },
    );

    if (res.isEmpty) return null;
    final row = res.first.toColumnMap();
    if (row['valid_pass'] != true) return null;
    return row;
  }

  /// Mengambil ID Admin utama dari tabel `admin`
  Future<String?> _getPrimaryAdminId() async {
    final res = await _exec(
      'SELECT TRIM(id_admin) AS id_admin FROM admin ORDER BY created_at ASC LIMIT 1',
    );
    if (res.isEmpty) return null;
    return res.first.toColumnMap()['id_admin']?.toString();
  }

  /// Mengambil profil Admin dari tabel `admin` & `"user"`
  Future<Map<String, dynamic>?> fetchAdminProfile({String? email}) async {
    final res = await _exec(
      '''
      SELECT
        TRIM(a.id_admin) AS id_admin,
        a.nama,
        COALESCE(u.email, 'admin@gmail.com') AS email,
        COALESCE(a.no_hp, '') AS no_hp,
        COALESCE(a.jabatan, 'Super Administrator Sistem GIAT') AS jabatan,
        a.foto_profile
      FROM admin a
      LEFT JOIN "user" u ON TRIM(u.id) = TRIM(a.id_admin)
      ORDER BY a.created_at ASC
      LIMIT 1
      ''',
    );
    if (res.isEmpty) return null;
    return res.first.toColumnMap();
  }

  /// Memperbarui profil Admin di tabel `admin` & `"user"`
  Future<bool> updateAdminProfile({
    required String nama,
    required String email,
    required String noHp,
    required String jabatan,
  }) async {
    final adminId = await _getPrimaryAdminId();
    if (adminId == null) return false;

    await _exec(
      '''
      UPDATE admin
      SET nama = @nama,
          no_hp = @noHp,
          jabatan = @jabatan,
          updated_at = NOW()
      WHERE TRIM(id_admin) = @id
      ''',
      parameters: {
        'id': adminId,
        'nama': nama,
        'noHp': noHp,
        'jabatan': jabatan,
      },
    );

    await _exec(
      '''
      UPDATE "user"
      SET email = @email,
          keterangan = @jabatan,
          updated_at = NOW()
      WHERE TRIM(id) = @id
      ''',
      parameters: {
        'id': adminId,
        'email': email,
        'jabatan': jabatan,
      },
    );

    return true;
  }

  /// Memperbarui password Admin di tabel `"user"`
  /// Mengembalikan `null` jika berhasil, atau pesan error jika gagal
  Future<String?> updateAdminPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final adminId = await _getPrimaryAdminId();
    if (adminId == null) return 'Data akun admin tidak ditemukan';

    final check = await _exec(
      r'''
      SELECT (extensions.crypt(@currentPass, replace(password, '$2y$', '$2a$')) = replace(password, '$2y$', '$2a$')) AS is_valid
      FROM "user"
      WHERE TRIM(id) = @id
      LIMIT 1
      ''',
      parameters: {
        'id': adminId,
        'currentPass': currentPassword,
      },
    );

    if (check.isEmpty || check.first.toColumnMap()['is_valid'] != true) {
      return 'Kata sandi saat ini tidak sesuai';
    }

    await _exec(
      r'''
      UPDATE "user"
      SET password = replace(extensions.crypt(@newPass, extensions.gen_salt('bf', 12)), '$2a$', '$2y$'),
          updated_at = NOW()
      WHERE TRIM(id) = @id
      ''',
      parameters: {
        'id': adminId,
        'newPass': newPassword,
      },
    );

    return null;
  }

  /// Mengambil seluruh daftar akun pengguna real (Pasien, Dokter, Apotek) dari Supabase (`"user"` JOIN `dokter`, `pasien`, `apotek`)
  Future<List<Map<String, dynamic>>> fetchAccounts() async {
    final res = await _exec(
      '''
      SELECT
        TRIM(u.id) AS id,
        u.email,
        u.role,
        u.is_active,
        u.created_at,
        COALESCE(d.nama, p.nama, ap.nama_apotek, split_part(u.email, '@', 1)) AS nama,
        COALESCE(d.no_hp, p.no_hp, ap.no_hp) AS no_hp,
        COALESCE(d.foto_profile, p.foto_profile, ap.foto_profile) AS foto_profile,
        COALESCE(
          NULLIF(u.keterangan, ''),
          CASE
            WHEN u.role = 'dokter' AND d.id_dokter IS NOT NULL THEN
              CASE
                WHEN d.institusi IS NOT NULL AND d.institusi <> '' THEN d.spesialisasi || ' • ' || d.institusi
                ELSE d.spesialisasi
              END
            WHEN u.role = 'apotek' AND ap.id_apotek IS NOT NULL THEN ap.alamat
            WHEN u.role = 'pasien' AND p.id_pasien IS NOT NULL THEN p.alamat
            ELSE NULL
          END
        ) AS keterangan
      FROM "user" u
      LEFT JOIN dokter d ON TRIM(d.id_dokter) = TRIM(u.id)
      LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(u.id)
      LEFT JOIN apotek ap ON TRIM(ap.id_apotek) = TRIM(u.id)
      WHERE LOWER(TRIM(u.role)) IN ('pasien', 'dokter', 'apotek')
      ORDER BY u.created_at DESC
      ''',
    );

    return res.map((r) => _normalizeMap(r.toColumnMap())).toList();
  }

  /// Menambahkan akun baru ke Supabase (`"user"` + tabel profil role + `admin_access_logs` + `notifikasi`)
  Future<Map<String, dynamic>?> createAccount({
    required String nama,
    required String email,
    String? noHp,
    required String role,
    String? keterangan,
    required String password,
  }) async {
    final uuidRes = await _exec('SELECT gen_random_uuid()::text AS id');
    final newId = uuidRes.first.toColumnMap()['id'].toString().trim();

    await _exec(
      r'''
      INSERT INTO "user" (id, email, password, role, auth_provider, is_active, keterangan, created_at, updated_at)
      VALUES (
        @id,
        @email,
        replace(extensions.crypt(@password, extensions.gen_salt('bf', 12)), '$2a$', '$2y$'),
        @role,
        'local',
        true,
        @keterangan,
        NOW(),
        NOW()
      )
      ''',
      parameters: {
        'id': newId,
        'email': email.trim().toLowerCase(),
        'password': password,
        'role': role,
        'keterangan': keterangan,
      },
    );

    await _upsertRoleProfile(
      userId: newId,
      role: role,
      nama: nama,
      noHp: noHp,
      keterangan: keterangan,
    );

    final roleLabel = _roleLabel(role);
    await _exec(
      '''
      INSERT INTO admin_access_logs (id, id_user, nama_user, aksi, role_awal, role_baru, created_at)
      VALUES (gen_random_uuid()::text, @userId, @nama, @aksi, NULL, @role, NOW())
      ''',
      parameters: {
        'userId': newId,
        'nama': nama,
        'aksi': 'Akun $roleLabel dibuat',
        'role': role,
      },
    );

    final adminId = await _getPrimaryAdminId();
    if (adminId != null) {
      await _exec(
        '''
        INSERT INTO notifikasi (id, id_user, judul, pesan, kategori, is_read, created_at)
        VALUES (
          gen_random_uuid()::text,
          @adminId,
          @judul,
          @pesan,
          'akun',
          false,
          NOW()
        )
        ''',
        parameters: {
          'adminId': adminId,
          'judul': 'Pendaftaran Akun $roleLabel Baru',
          'pesan': '$nama ($email) telah ditambahkan sebagai $roleLabel di ekosistem GIAT.',
        },
      );
    }

    return {
      'id': newId,
      'nama': nama,
      'email': email.trim().toLowerCase(),
      'no_hp': noHp,
      'role': role,
      'is_active': true,
      'keterangan': keterangan,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Mengubah hak akses (role) akun di Supabase
  Future<void> changeAccountRole({
    required String userId,
    required String nama,
    required String oldRole,
    required String newRole,
    String? noHp,
    String? keterangan,
  }) async {
    await _exec(
      '''
      UPDATE "user"
      SET role = @newRole,
          updated_at = NOW()
      WHERE TRIM(id) = @id
      ''',
      parameters: {
        'id': userId.trim(),
        'newRole': newRole,
      },
    );

    await _upsertRoleProfile(
      userId: userId.trim(),
      role: newRole,
      nama: nama,
      noHp: noHp,
      keterangan: keterangan,
    );

    final oldLabel = _roleLabel(oldRole);
    final newLabel = _roleLabel(newRole);

    await _exec(
      '''
      INSERT INTO admin_access_logs (id, id_user, nama_user, aksi, role_awal, role_baru, created_at)
      VALUES (gen_random_uuid()::text, @userId, @nama, @aksi, @oldRole, @newRole, NOW())
      ''',
      parameters: {
        'userId': userId.trim(),
        'nama': nama,
        'aksi': 'Hak akses $oldLabel → $newLabel',
        'oldRole': oldRole,
        'newRole': newRole,
      },
    );

    final adminId = await _getPrimaryAdminId();
    if (adminId != null) {
      await _exec(
        '''
        INSERT INTO notifikasi (id, id_user, judul, pesan, kategori, is_read, created_at)
        VALUES (
          gen_random_uuid()::text,
          @adminId,
          'Perubahan Hak Akses Pengguna',
          @pesan,
          'akses',
          false,
          NOW()
        )
        ''',
        parameters: {
          'adminId': adminId,
          'pesan': 'Hak akses akun $nama telah diperbarui dari $oldLabel menjadi $newLabel.',
        },
      );
    }
  }

  Future<void> _upsertRoleProfile({
    required String userId,
    required String role,
    required String nama,
    String? noHp,
    String? keterangan,
  }) async {
    switch (role.toLowerCase()) {
      case 'dokter':
        final exists = await _exec(
          'SELECT 1 FROM dokter WHERE TRIM(id_dokter) = @id LIMIT 1',
          parameters: {'id': userId},
        );
        if (exists.isEmpty) {
          await _exec(
            '''
            INSERT INTO dokter (id_dokter, nama, spesialisasi, institusi, no_hp, tarif_konsultasi, created_at, updated_at)
            VALUES (@id, @nama, @spesialisasi, 'RS Mitra GIAT', @noHp, 100000, NOW(), NOW())
            ''',
            parameters: {
              'id': userId,
              'nama': nama,
              'spesialisasi': (keterangan != null && keterangan.isNotEmpty)
                  ? keterangan
                  : 'Dokter Spesialis Penyakit Dalam',
              'noHp': noHp,
            },
          );
        }
        break;
      case 'apotek':
        final exists = await _exec(
          'SELECT 1 FROM apotek WHERE TRIM(id_apotek) = @id LIMIT 1',
          parameters: {'id': userId},
        );
        if (exists.isEmpty) {
          await _exec(
            '''
            INSERT INTO apotek (id_apotek, nama_apotek, penanggung_jawab, no_hp, alamat, status_layanan, created_at, updated_at)
            VALUES (@id, @nama, @nama, @noHp, @alamat, true, NOW(), NOW())
            ''',
            parameters: {
              'id': userId,
              'nama': nama,
              'noHp': noHp,
              'alamat': keterangan ?? 'Bandung',
            },
          );
        }
        break;
      case 'admin':
        final exists = await _exec(
          'SELECT 1 FROM admin WHERE TRIM(id_admin) = @id LIMIT 1',
          parameters: {'id': userId},
        );
        if (exists.isEmpty) {
          await _exec(
            '''
            INSERT INTO admin (id_admin, nama, no_hp, jabatan, created_at, updated_at)
            VALUES (@id, @nama, @noHp, @jabatan, NOW(), NOW())
            ''',
            parameters: {
              'id': userId,
              'nama': nama,
              'noHp': noHp,
              'jabatan': keterangan ?? 'Administrator Sistem GIAT',
            },
          );
        }
        break;
      case 'pasien':
      default:
        final exists = await _exec(
          'SELECT 1 FROM pasien WHERE TRIM(id_pasien) = @id LIMIT 1',
          parameters: {'id': userId},
        );
        if (exists.isEmpty) {
          await _exec(
            '''
            INSERT INTO pasien (id_pasien, nama, no_hp, alamat, created_at, updated_at)
            VALUES (@id, @nama, @noHp, @alamat, NOW(), NOW())
            ''',
            parameters: {
              'id': userId,
              'nama': nama,
              'noHp': noHp,
              'alamat': keterangan,
            },
          );
        }
        break;
    }
  }

  /// Mengambil daftar artikel edukasi kesehatan real dari tabel `edukasi_artikel`
  Future<List<Map<String, dynamic>>> fetchEdukasi() async {
    final res = await _exec(
      '''
      SELECT
        TRIM(id) AS id,
        judul,
        kategori,
        COALESCE(ringkasan, '') AS ringkasan,
        konten,
        COALESCE(gambar_url, '') AS gambar_url,
        COALESCE(penulis, 'Tim Medis GIAT') AS penulis,
        COALESCE(durasi_baca, durasi_baca_menit, 4) AS durasi_baca,
        COALESCE(status, 'published') AS status,
        created_at,
        COALESCE(updated_at, created_at) AS updated_at
      FROM edukasi_artikel
      ORDER BY created_at DESC
      ''',
    );
    return res.map((r) => _normalizeMap(r.toColumnMap())).toList();
  }

  /// Menyimpan (tambah / edit) artikel edukasi ke tabel `edukasi_artikel` di Supabase
  Future<Map<String, dynamic>?> saveEdukasi({
    String? id,
    required String judul,
    required String kategori,
    required String ringkasan,
    required String konten,
    required String penulis,
    required int durasiBaca,
    required String gambar,
    required bool isUpdate,
  }) async {
    final trimmed = gambar.trim();
    final String gambarUrl;
    if (trimmed.startsWith('data:image/') ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('assets/')) {
      gambarUrl = trimmed;
    } else if (trimmed.isNotEmpty) {
      gambarUrl = trimmed;
    } else {
      gambarUrl = 'assets/images/kidneys.jpg';
    }

    if (isUpdate && id != null && id.isNotEmpty) {
      await _exec(
        '''
        UPDATE edukasi_artikel
        SET judul = @judul,
            kategori = @kategori,
            ringkasan = @ringkasan,
            konten = @konten,
            penulis = @penulis,
            durasi_baca = @durasi,
            durasi_baca_menit = @durasi,
            gambar_url = @gambar,
            updated_at = NOW()
        WHERE TRIM(id) = @id
        ''',
        parameters: {
          'id': id.trim(),
          'judul': judul,
          'kategori': kategori,
          'ringkasan': ringkasan,
          'konten': konten,
          'penulis': penulis,
          'durasi': durasiBaca,
          'gambar': gambarUrl,
        },
      );
      return {
        'id': id.trim(),
        'judul': judul,
        'kategori': kategori,
        'ringkasan': ringkasan,
        'konten': konten,
        'penulis': penulis,
        'durasi_baca': durasiBaca,
        'gambar_url': gambarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };
    } else {
      final uuidRes = await _exec('SELECT gen_random_uuid()::text AS id');
      final newId = uuidRes.first.toColumnMap()['id'].toString().trim();
      final adminId = await _getPrimaryAdminId();

      await _exec(
        '''
        INSERT INTO edukasi_artikel (
          id, judul, kategori, ringkasan, konten, gambar_url, penulis,
          durasi_baca, durasi_baca_menit, status, id_admin, created_at, updated_at
        )
        VALUES (
          @id, @judul, @kategori, @ringkasan, @konten, @gambar, @penulis,
          @durasi, @durasi, 'published', @adminId, NOW(), NOW()
        )
        ''',
        parameters: {
          'id': newId,
          'judul': judul,
          'kategori': kategori,
          'ringkasan': ringkasan,
          'konten': konten,
          'gambar': gambarUrl,
          'penulis': penulis,
          'durasi': durasiBaca,
          'adminId': adminId,
        },
      );

      return {
        'id': newId,
        'judul': judul,
        'kategori': kategori,
        'ringkasan': ringkasan,
        'konten': konten,
        'penulis': penulis,
        'durasi_baca': durasiBaca,
        'gambar_url': gambarUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Menghapus artikel edukasi dari tabel `edukasi_artikel` di Supabase
  Future<void> deleteEdukasi(String id) async {
    await _exec(
      'DELETE FROM edukasi_artikel WHERE TRIM(id) = @id',
      parameters: {'id': id.trim()},
    );
  }

  /// Mengambil riwayat update sistem yang sudah dipublikasikan dari tabel `system_updates`
  Future<List<Map<String, dynamic>>> fetchSystemUpdates() async {
    final res = await _exec(
      '''
      SELECT
        TRIM(id) AS id,
        judul,
        deskripsi,
        tipe,
        target_role,
        target_label,
        published_at,
        created_at
      FROM system_updates
      ORDER BY published_at DESC
      ''',
    );
    return res.map((r) => _normalizeMap(r.toColumnMap())).toList();
  }

  /// Mengirim & mempublikasikan notifikasi update sistem baru ke tabel `system_updates`
  Future<Map<String, dynamic>?> createSystemUpdate({
    required String tipe,
    required String targetRole,
    required String judul,
    required String deskripsi,
  }) async {
    final uuidRes = await _exec('SELECT gen_random_uuid()::text AS id');
    final newId = uuidRes.first.toColumnMap()['id'].toString().trim();
    final targetLabel = _targetLabel(targetRole);
    final normalizedTarget = targetRole.trim().toLowerCase();
    final tipeLabel = _tipeLabel(tipe);
    final notifTitle = '[$tipeLabel] $judul';

    await _exec(
      '''
      INSERT INTO system_updates (
        id, judul, deskripsi, tipe, target_role, target_label, published_at, created_at, updated_at
      )
      VALUES (
        @id, @judul, @deskripsi, @tipe, @targetRole, @targetLabel, NOW(), NOW(), NOW()
      )
      ''',
      parameters: {
        'id': newId,
        'judul': judul,
        'deskripsi': deskripsi,
        'tipe': tipe,
        'targetRole': normalizedTarget,
        'targetLabel': targetLabel,
      },
    );

    // Distribusikan juga ke tabel notifikasi pengguna agar terbaca oleh Pasien/Dokter/Apotek
    try {
      if (normalizedTarget == 'semua') {
        await _exec(
          '''
          INSERT INTO notifikasi (id, id_user, judul, pesan, kategori, is_read, created_at)
          SELECT gen_random_uuid()::text, TRIM(u.id), @judul, @pesan, 'sistem', false, NOW()
          FROM "user" u
          WHERE LOWER(TRIM(u.role)) IN ('pasien', 'dokter', 'apotek')
          ''',
          parameters: {
            'judul': notifTitle,
            'pesan': deskripsi,
          },
        );
      } else {
        await _exec(
          '''
          INSERT INTO notifikasi (id, id_user, judul, pesan, kategori, is_read, created_at)
          SELECT gen_random_uuid()::text, TRIM(u.id), @judul, @pesan, 'sistem', false, NOW()
          FROM "user" u
          WHERE LOWER(TRIM(u.role)) = @role
          ''',
          parameters: {
            'judul': notifTitle,
            'pesan': deskripsi,
            'role': normalizedTarget,
          },
        );
      }
    } catch (e) {
      debugPrint('createSystemUpdate fan-out warning: $e');
    }

    return {
      'id': newId,
      'judul': judul,
      'deskripsi': deskripsi,
      'tipe': tipe,
      'target_role': targetRole,
      'target_label': targetLabel,
      'published_at': DateTime.now().toIso8601String(),
    };
  }

  /// Mengambil riwayat perubahan hak akses dari tabel `admin_access_logs`
  Future<List<Map<String, dynamic>>> fetchAccessLogs() async {
    final res = await _exec(
      '''
      SELECT
        TRIM(id) AS id,
        TRIM(id_user) AS id_user,
        nama_user,
        aksi,
        role_awal,
        role_baru,
        created_at
      FROM admin_access_logs
      ORDER BY created_at DESC
      LIMIT 25
      ''',
    );
    return res.map((r) => _normalizeMap(r.toColumnMap())).toList();
  }

  /// Mengambil daftar notifikasi masuk khusus Admin dari tabel `notifikasi`
  Future<List<Map<String, dynamic>>> fetchAdminNotifications() async {
    final adminId = await _getPrimaryAdminId();
    final res = await _exec(
      '''
      SELECT
        TRIM(id) AS id,
        TRIM(id_user) AS id_user,
        judul,
        pesan,
        COALESCE(kategori, 'sistem') AS tipe,
        is_read,
        created_at
      FROM notifikasi
      WHERE (@adminId IS NOT NULL AND TRIM(id_user) = @adminId)
         OR kategori IN ('akun', 'akses', 'edukasi', 'sistem')
      ORDER BY created_at DESC
      ''',
      parameters: {'adminId': adminId},
    );
    return res.map((r) => _normalizeMap(r.toColumnMap())).toList();
  }

  /// Menandai 1 notifikasi masuk Admin sudah dibaca
  Future<void> markNotificationRead(String id) async {
    await _exec(
      'UPDATE notifikasi SET is_read = true WHERE TRIM(id) = @id',
      parameters: {'id': id.trim()},
    );
  }

  /// Menandai seluruh notifikasi masuk Admin sudah dibaca
  Future<void> markAllNotificationsRead() async {
    final adminId = await _getPrimaryAdminId();
    await _exec(
      '''
      UPDATE notifikasi
      SET is_read = true
      WHERE (@adminId IS NOT NULL AND TRIM(id_user) = @adminId)
         OR kategori IN ('akun', 'akses', 'edukasi', 'sistem')
      ''',
      parameters: {'adminId': adminId},
    );
  }

  /// Menghapus 1 notifikasi masuk Admin dari Supabase
  Future<void> deleteNotification(String id) async {
    await _exec(
      'DELETE FROM notifikasi WHERE TRIM(id) = @id',
      parameters: {'id': id.trim()},
    );
  }

  // ===========================================================================
  // MODUL PASIEN: PENGINGAT SAYA (REMINDERS) & NOTIFIKASI REAL SUPABASE
  // ===========================================================================

  /// Menentukan ID Pasien (`id_pasien` / `user.id`) yang sedang login di Supabase
  Future<String?> resolveCurrentPasienId({String? overridePasienId}) async {
    if (overridePasienId != null && overridePasienId.trim().length >= 30) {
      return overridePasienId.trim();
    }

    final user = await StorageService().getUser();
    if (user != null) {
      final rawId = user.id.trim();
      if (rawId.length >= 30) {
        await _ensurePasienProfileExists(
          userId: rawId,
          nama: user.nama.isNotEmpty ? user.nama : 'Pasien GIAT',
          noHp: user.noHp,
          alamat: user.alamat,
        );
        return rawId;
      }

      final email = user.email.trim().toLowerCase();
      if (email.isNotEmpty) {
        final byEmail = await _exec(
          '''
          SELECT TRIM(u.id) AS id, COALESCE(p.nama, split_part(u.email, '@', 1)) AS nama
          FROM "user" u
          LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(u.id)
          WHERE LOWER(TRIM(u.email)) = @email
          LIMIT 1
          ''',
          parameters: {'email': email},
        );
        if (byEmail.isNotEmpty) {
          final row = byEmail.first.toColumnMap();
          final foundId = row['id']?.toString().trim();
          if (foundId != null && foundId.isNotEmpty) {
            await _ensurePasienProfileExists(
              userId: foundId,
              nama: row['nama']?.toString() ?? user.nama,
              noHp: user.noHp,
              alamat: user.alamat,
            );
            return foundId;
          }
        }
      }

      final nama = user.nama.trim();
      if (nama.isNotEmpty && nama.toLowerCase() != 'pasien') {
        final byNama = await _exec(
          'SELECT TRIM(id_pasien) AS id_pasien FROM pasien WHERE LOWER(TRIM(nama)) = LOWER(@nama) LIMIT 1',
          parameters: {'nama': nama},
        );
        if (byNama.isNotEmpty) {
          final foundId = byNama.first.toColumnMap()['id_pasien']?.toString().trim();
          if (foundId != null && foundId.isNotEmpty) return foundId;
        }
      }
    }

    // Fallback ke pasien utama di tabel pasien (Siti Aisyah)
    final primary = await _exec(
      'SELECT TRIM(id_pasien) AS id_pasien FROM pasien ORDER BY created_at ASC LIMIT 1',
    );
    if (primary.isNotEmpty) {
      return primary.first.toColumnMap()['id_pasien']?.toString().trim();
    }
    return null;
  }

  Future<void> _ensurePasienProfileExists({
    required String userId,
    required String nama,
    String? noHp,
    String? alamat,
  }) async {
    try {
      final exists = await _exec(
        'SELECT 1 FROM pasien WHERE TRIM(id_pasien) = @id LIMIT 1',
        parameters: {'id': userId.trim()},
      );
      if (exists.isEmpty) {
        await _exec(
          '''
          INSERT INTO pasien (id_pasien, nama, no_hp, alamat, created_at, updated_at)
          VALUES (@id, @nama, @noHp, @alamat, NOW(), NOW())
          ''',
          parameters: {
            'id': userId.trim(),
            'nama': nama,
            'noHp': noHp,
            'alamat': alamat,
          },
        );
      }
    } catch (_) {}
  }

  static String _normalizeTimeForDb(dynamic rawTime) {
    if (rawTime == null) return '08:00:00';
    final str = rawTime.toString().trim();
    final match = RegExp(r'(\d{1,2})[:.](\d{1,2})(?:[:.](\d{1,2}))?').firstMatch(str);
    if (match != null) {
      final h = (int.tryParse(match.group(1)!) ?? 8).clamp(0, 23).toString().padLeft(2, '0');
      final m = (int.tryParse(match.group(2)!) ?? 0).clamp(0, 59).toString().padLeft(2, '0');
      final s = (int.tryParse(match.group(3) ?? '0') ?? 0).clamp(0, 59).toString().padLeft(2, '0');
      return '$h:$m:$s';
    }
    return '08:00:00';
  }

  static String _normalizeDateForDb(dynamic rawDate) {
    final now = TimeUtils.nowInUserZone;
    final todayIso =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (rawDate == null) return todayIso;
    final str = rawDate.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'hari ini') return todayIso;

    final isoMatch = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(str);
    if (isoMatch != null) {
      final y = isoMatch.group(1)!.padLeft(4, '0');
      final m = isoMatch.group(2)!.padLeft(2, '0');
      final d = isoMatch.group(3)!.padLeft(2, '0');
      return '$y-$m-$d';
    }

    final parsed = TimeUtils.parseBirthDate(str);
    if (parsed != null) {
      return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
    }
    return todayIso;
  }

  /// Mengambil daftar pengingat pasien real dari tabel `reminders` di Supabase
  Future<List<Map<String, dynamic>>> fetchPasienReminders({
    String? pasienId,
    bool onlyToday = false,
  }) async {
    final resolvedId = await resolveCurrentPasienId(overridePasienId: pasienId);
    if (resolvedId == null) return [];

    final res = await _exec(
      '''
      SELECT
        TRIM(id) AS id,
        TRIM(id) AS id_reminder,
        TRIM(id_pasien) AS id_pasien,
        COALESCE(tipe, 'obat') AS tipe,
        judul,
        judul AS nama,
        judul AS title,
        COALESCE(subjudul, '') AS subjudul,
        COALESCE(subjudul, '') AS keterangan,
        COALESCE(subjudul, '') AS dosis,
        COALESCE(subjudul, '') AS subtitle,
        waktu::text AS waktu,
        COALESCE(tanggal::text, CURRENT_DATE::text) AS tanggal,
        COALESCE(pengulangan, 'harian') AS pengulangan,
        COALESCE(status, 'aktif') AS status,
        COALESCE(is_active, true) AS is_active,
        created_at,
        COALESCE(updated_at, created_at) AS updated_at
      FROM reminders
      WHERE TRIM(id_pasien) = @pasienId
      ORDER BY waktu ASC, created_at DESC
      ''',
      parameters: {'pasienId': resolvedId},
    );

    final list = res.map((r) {
      final m = _normalizeMap(r.toColumnMap());
      m['type'] = m['tipe'];
      m['isActive'] = m['is_active'] == true;
      return m;
    }).toList();

    if (!onlyToday) return list;

    final now = TimeUtils.nowInUserZone;
    final todayIso =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return list.where((m) {
      final isActive = m['is_active'] == true || m['isActive'] == true;
      if (!isActive) return false;
      final repeat = (m['pengulangan'] ?? 'harian').toString().toLowerCase();
      final dateStr = (m['tanggal'] ?? todayIso).toString().split(' ').first;
      if (repeat.contains('hari')) return true;
      return dateStr == todayIso;
    }).toList();
  }

  /// Menyimpan pengingat baru pasien ke tabel `reminders` di Supabase
  Future<Map<String, dynamic>?> createPasienReminder(
    Map<String, dynamic> data, {
    String? pasienId,
  }) async {
    final resolvedId = await resolveCurrentPasienId(overridePasienId: pasienId);
    if (resolvedId == null) return null;

    final uuidRes = await _exec('SELECT gen_random_uuid()::text AS id');
    final newId = uuidRes.first.toColumnMap()['id'].toString().trim();

    final tipe = (data['tipe'] ?? data['type'] ?? 'obat').toString().trim().toLowerCase();
    final judul = (data['judul'] ?? data['nama'] ?? data['title'] ?? 'Pengingat').toString().trim();
    final subjudul = (data['subjudul'] ?? data['subtitle'] ?? data['keterangan'] ?? data['dosis'] ?? '').toString().trim();
    final waktu = _normalizeTimeForDb(data['waktu'] ?? data['time']);
    final tanggal = _normalizeDateForDb(data['tanggal'] ?? data['date']);
    final rawRepeat = (data['pengulangan'] ?? 'harian').toString().toLowerCase();
    final pengulangan = rawRepeat.contains('hari') ? 'harian' : 'sekali';
    final isActive = data['is_active'] == null && data['isActive'] == null
        ? true
        : (data['is_active'] == true || data['is_active'] == 1 || data['isActive'] == true);
    final status = isActive ? 'aktif' : 'nonaktif';

    await _exec(
      '''
      INSERT INTO reminders (
        id, id_pasien, tipe, judul, subjudul, waktu, tanggal,
        pengulangan, status, is_active, created_at, updated_at
      )
      VALUES (
        @id, @pasienId, @tipe, @judul, @subjudul, @waktu::time, @tanggal::date,
        @pengulangan, @status, @isActive, NOW(), NOW()
      )
      ''',
      parameters: {
        'id': newId,
        'pasienId': resolvedId,
        'tipe': tipe,
        'judul': judul,
        'subjudul': subjudul,
        'waktu': waktu,
        'tanggal': tanggal,
        'pengulangan': pengulangan,
        'status': status,
        'isActive': isActive,
      },
    );

    final nowIso = DateTime.now().toUtc().toIso8601String();
    return {
      'id': newId,
      'id_reminder': newId,
      'id_pasien': resolvedId,
      'tipe': tipe,
      'type': tipe,
      'judul': judul,
      'nama': judul,
      'title': judul,
      'subjudul': subjudul,
      'keterangan': subjudul,
      'dosis': subjudul,
      'subtitle': subjudul,
      'waktu': waktu,
      'tanggal': tanggal,
      'pengulangan': pengulangan,
      'status': status,
      'is_active': isActive,
      'isActive': isActive,
      'created_at': nowIso,
      'updated_at': nowIso,
    };
  }

  /// Memperbarui data pengingat pasien di tabel `reminders` di Supabase
  Future<Map<String, dynamic>?> updatePasienReminder(
    String id,
    Map<String, dynamic> data,
  ) async {
    final trimmedId = id.trim();
    final tipe = (data['tipe'] ?? data['type'] ?? 'obat').toString().trim().toLowerCase();
    final judul = (data['judul'] ?? data['nama'] ?? data['title'] ?? 'Pengingat').toString().trim();
    final subjudul = (data['subjudul'] ?? data['subtitle'] ?? data['keterangan'] ?? data['dosis'] ?? '').toString().trim();
    final waktu = _normalizeTimeForDb(data['waktu'] ?? data['time']);
    final tanggal = _normalizeDateForDb(data['tanggal'] ?? data['date']);
    final rawRepeat = (data['pengulangan'] ?? 'harian').toString().toLowerCase();
    final pengulangan = rawRepeat.contains('hari') ? 'harian' : 'sekali';
    final isActive = data['is_active'] == null && data['isActive'] == null
        ? true
        : (data['is_active'] == true || data['is_active'] == 1 || data['isActive'] == true);
    final status = isActive ? 'aktif' : 'nonaktif';

    await _exec(
      '''
      UPDATE reminders
      SET tipe = @tipe,
          judul = @judul,
          subjudul = @subjudul,
          waktu = @waktu::time,
          tanggal = @tanggal::date,
          pengulangan = @pengulangan,
          status = @status,
          is_active = @isActive,
          updated_at = NOW()
      WHERE TRIM(id) = @id
      ''',
      parameters: {
        'id': trimmedId,
        'tipe': tipe,
        'judul': judul,
        'subjudul': subjudul,
        'waktu': waktu,
        'tanggal': tanggal,
        'pengulangan': pengulangan,
        'status': status,
        'isActive': isActive,
      },
    );

    final nowIso = DateTime.now().toUtc().toIso8601String();
    return {
      'id': trimmedId,
      'id_reminder': trimmedId,
      'tipe': tipe,
      'type': tipe,
      'judul': judul,
      'nama': judul,
      'title': judul,
      'subjudul': subjudul,
      'keterangan': subjudul,
      'dosis': subjudul,
      'subtitle': subjudul,
      'waktu': waktu,
      'tanggal': tanggal,
      'pengulangan': pengulangan,
      'status': status,
      'is_active': isActive,
      'isActive': isActive,
      'updated_at': nowIso,
    };
  }

  /// Mengubah status aktif / nonaktif pengingat pasien di tabel `reminders`
  Future<Map<String, dynamic>?> togglePasienReminder(
    String id, {
    bool? forceValue,
  }) async {
    final trimmedId = id.trim();
    final current = await _exec(
      'SELECT is_active FROM reminders WHERE TRIM(id) = @id LIMIT 1',
      parameters: {'id': trimmedId},
    );
    if (current.isEmpty) return null;

    final currentActive = current.first.toColumnMap()['is_active'] == true;
    final nextActive = forceValue ?? !currentActive;
    final nextStatus = nextActive ? 'aktif' : 'nonaktif';

    await _exec(
      '''
      UPDATE reminders
      SET is_active = @isActive,
          status = @status,
          updated_at = NOW()
      WHERE TRIM(id) = @id
      ''',
      parameters: {
        'id': trimmedId,
        'isActive': nextActive,
        'status': nextStatus,
      },
    );

    return {
      'id': trimmedId,
      'is_active': nextActive,
      'isActive': nextActive,
      'status': nextStatus,
    };
  }

  /// Menghapus pengingat pasien dari tabel `reminders` di Supabase
  Future<bool> deletePasienReminder(String id) async {
    await _exec(
      'DELETE FROM reminders WHERE TRIM(id) = @id',
      parameters: {'id': id.trim()},
    );
    return true;
  }

  /// Mengambil daftar notifikasi pasien real dari tabel `notifikasi` di Supabase
  Future<List<Map<String, dynamic>>> fetchPasienNotifications({
    String? pasienId,
  }) async {
    final resolvedId = await resolveCurrentPasienId(overridePasienId: pasienId);
    if (resolvedId == null) return [];

    final res = await _exec(
      '''
      SELECT
        TRIM(id) AS id,
        TRIM(id_user) AS id_user,
        judul,
        pesan,
        COALESCE(kategori, 'sistem') AS kategori,
        COALESCE(kategori, 'sistem') AS tipe,
        is_read,
        created_at
      FROM notifikasi
      WHERE TRIM(id_user) = @pasienId
      ORDER BY created_at DESC
      LIMIT 50
      ''',
      parameters: {'pasienId': resolvedId},
    );

    return res.map((r) => _normalizeMap(r.toColumnMap())).toList();
  }

  /// Mengambil jumlah notifikasi belum dibaca (`is_read = false`) untuk pasien
  Future<int> fetchPasienUnreadNotificationCount({String? pasienId}) async {
    final resolvedId = await resolveCurrentPasienId(overridePasienId: pasienId);
    if (resolvedId == null) return 0;

    final res = await _exec(
      '''
      SELECT COUNT(*)::int AS cnt
      FROM notifikasi
      WHERE TRIM(id_user) = @pasienId
        AND is_read = false
      ''',
      parameters: {'pasienId': resolvedId},
    );
    if (res.isEmpty) return 0;
    return int.tryParse(res.first.toColumnMap()['cnt']?.toString() ?? '0') ?? 0;
  }

  /// Membuat notifikasi baru untuk pasien di tabel `notifikasi` Supabase
  /// (Digunakan saat waktu Pengingat Saya tiba)
  Future<Map<String, dynamic>?> createPasienNotification({
    String? pasienId,
    required String judul,
    required String pesan,
    String kategori = 'obat',
  }) async {
    final resolvedId = await resolveCurrentPasienId(overridePasienId: pasienId);
    if (resolvedId == null) return null;

    // Cegah duplikasi notifikasi pengingat yang sama pada hari yang sama
    final existing = await _exec(
      '''
      SELECT
        TRIM(id) AS id,
        TRIM(id_user) AS id_user,
        judul,
        pesan,
        COALESCE(kategori, 'obat') AS kategori,
        COALESCE(kategori, 'obat') AS tipe,
        is_read,
        created_at
      FROM notifikasi
      WHERE TRIM(id_user) = @pasienId
        AND judul = @judul
        AND pesan = @pesan
        AND created_at::date = CURRENT_DATE
      LIMIT 1
      ''',
      parameters: {
        'pasienId': resolvedId,
        'judul': judul,
        'pesan': pesan,
      },
    );
    if (existing.isNotEmpty) {
      return _normalizeMap(existing.first.toColumnMap());
    }

    final uuidRes = await _exec('SELECT gen_random_uuid()::text AS id');
    final newId = uuidRes.first.toColumnMap()['id'].toString().trim();

    await _exec(
      '''
      INSERT INTO notifikasi (id, id_user, judul, pesan, kategori, is_read, created_at)
      VALUES (@id, @pasienId, @judul, @pesan, @kategori, false, NOW())
      ''',
      parameters: {
        'id': newId,
        'pasienId': resolvedId,
        'judul': judul,
        'pesan': pesan,
        'kategori': kategori,
      },
    );

    return {
      'id': newId,
      'id_user': resolvedId,
      'judul': judul,
      'pesan': pesan,
      'kategori': kategori,
      'tipe': kategori,
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Menandai semua notifikasi milik pasien sudah dibaca
  Future<void> markPasienNotificationsAllRead({String? pasienId}) async {
    final resolvedId = await resolveCurrentPasienId(overridePasienId: pasienId);
    if (resolvedId == null) return;
    await _exec(
      'UPDATE notifikasi SET is_read = true WHERE TRIM(id_user) = @pasienId',
      parameters: {'pasienId': resolvedId},
    );
  }

  /// Menghapus semua notifikasi milik pasien yang sudah dibaca
  Future<void> clearPasienReadNotifications({String? pasienId}) async {
    final resolvedId = await resolveCurrentPasienId(overridePasienId: pasienId);
    if (resolvedId == null) return;
    await _exec(
      'DELETE FROM notifikasi WHERE TRIM(id_user) = @pasienId AND is_read = true',
      parameters: {'pasienId': resolvedId},
    );
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value == null) {
        result[key] = null;
      } else if (value is DateTime) {
        result[key] = value.toIso8601String();
      } else {
        final strVal = value.toString().trim();
        // Tangani objek Time dari postgres package (misal Time(10:26:16.000) atau Time(10:26:16))
        final timeMatch = RegExp(r'^Time\s*\(\s*(\d{1,2}:\d{2}(?::\d{2})?)').firstMatch(strVal);
        if (timeMatch != null) {
          result[key] = timeMatch.group(1);
        } else if (value is String) {
          result[key] = strVal;
        } else {
          result[key] = value;
        }
      }
    });
    return result;
  }

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'dokter':
        return 'Dokter';
      case 'apotek':
      case 'apoteker':
        return 'Apotek';
      case 'admin':
        return 'Admin';
      default:
        return 'Pasien';
    }
  }

  String _targetLabel(String targetRole) {
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

  String _tipeLabel(String tipe) {
    switch (tipe.toLowerCase()) {
      case 'perbaikan':
        return 'Perbaikan';
      case 'pemeliharaan':
        return 'Pemeliharaan';
      case 'fitur':
      default:
        return 'Fitur Baru';
    }
  }

  // ===========================================================================
  // MODUL DOKTER: DASHBOARD, PESAN TERBARU, JADWAL, DAN RESEP REAL SUPABASE
  // ===========================================================================

  /// Menentukan ID Dokter (`id_dokter` / `user.id`) yang sedang login di Supabase
  Future<String?> resolveCurrentDokterId({String? overrideDokterId, String? doctorName}) async {
    if (overrideDokterId != null && overrideDokterId.trim().length >= 30) {
      return overrideDokterId.trim();
    }

    final user = await StorageService().getUser();
    if (user != null) {
      final rawId = user.id.toString().trim();
      if (rawId.length >= 30) {
        final check = await _exec(
          'SELECT TRIM(id_dokter) AS id FROM dokter WHERE TRIM(id_dokter) = @id LIMIT 1',
          parameters: {'id': rawId},
        );
        if (check.isNotEmpty) {
          return rawId;
        }
      }

      final email = user.email.trim().toLowerCase();
      if (email.isNotEmpty) {
        final byEmail = await _exec(
          '''
          SELECT TRIM(d.id_dokter) AS id
          FROM "user" u
          JOIN dokter d ON TRIM(d.id_dokter) = TRIM(u.id)
          WHERE LOWER(TRIM(u.email)) = @email
          LIMIT 1
          ''',
          parameters: {'email': email},
        );
        if (byEmail.isNotEmpty) {
          final id = byEmail.first.toColumnMap()['id']?.toString().trim();
          if (id != null && id.isNotEmpty) return id;
        }
      }

      final nama = user.nama.trim();
      if (nama.isNotEmpty && !nama.toLowerCase().contains('pasien')) {
        final byNama = await _exec(
          'SELECT TRIM(id_dokter) AS id FROM dokter WHERE LOWER(TRIM(nama)) ILIKE @nama LIMIT 1',
          parameters: {'nama': '%$nama%'},
        );
        if (byNama.isNotEmpty) {
          final id = byNama.first.toColumnMap()['id']?.toString().trim();
          if (id != null && id.isNotEmpty) return id;
        }
      }
    }

    if (doctorName != null && doctorName.trim().isNotEmpty) {
      final byFallbackName = await _exec(
        'SELECT TRIM(id_dokter) AS id FROM dokter WHERE LOWER(TRIM(nama)) ILIKE @nama LIMIT 1',
        parameters: {'nama': '%${doctorName.trim().toLowerCase()}%'},
      );
      if (byFallbackName.isNotEmpty) {
        final id = byFallbackName.first.toColumnMap()['id']?.toString().trim();
        if (id != null && id.isNotEmpty) return id;
      }
    }

    // Default fallback ke dokter pertama di database
    final firstDoc = await _exec('SELECT TRIM(id_dokter) AS id FROM dokter ORDER BY created_at ASC LIMIT 1');
    if (firstDoc.isNotEmpty) {
      return firstDoc.first.toColumnMap()['id']?.toString().trim();
    }
    return null;
  }

  /// Mengambil data dashboard real untuk dokter dari Supabase (profil, pesan terbaru, jadwal, ringkasan aktivitas)
  Future<Map<String, dynamic>> fetchDokterDashboard({String? dokterId, String? doctorName}) async {
    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) {
      throw Exception('Dokter ID tidak ditemukan di database Supabase.');
    }

    // 1. Profil dokter
    final profileRows = await _exec(
      '''
      SELECT 
        TRIM(d.id_dokter) AS id_dokter,
        d.nama,
        d.spesialisasi,
        d.institusi,
        d.no_str,
        d.no_sip,
        d.no_hp,
        d.tarif_konsultasi,
        d.foto_profile,
        d.bio,
        u.email
      FROM dokter d
      LEFT JOIN "user" u ON TRIM(u.id) = TRIM(d.id_dokter)
      WHERE TRIM(d.id_dokter) = @id
      LIMIT 1
      ''',
      parameters: {'id': docId},
    );
    final Map<String, dynamic> doctorMap = profileRows.isNotEmpty
        ? _normalizeMap(profileRows.first.toColumnMap())
        : {'id_dokter': docId, 'nama': doctorName ?? 'Dokter GIAT'};

    // 2. Pesan terbaru (Pesan terakhir dari setiap pasien, unik per pasien)
    final msgRows = await _exec(
      '''
      WITH latest_messages AS (
        SELECT 
          k.id AS id_konsultasi,
          k.id_pasien,
          kp.pesan,
          kp.id_sender,
          kp.created_at,
          ROW_NUMBER() OVER (PARTITION BY k.id_pasien ORDER BY kp.created_at DESC) as rn
        FROM konsultasi_pesan kp
        JOIN konsultasi k ON TRIM(k.id) = TRIM(kp.id_konsultasi)
        WHERE TRIM(k.id_dokter) = @id
      )
      SELECT 
        lm.id_konsultasi,
        lm.id_pasien,
        COALESCE(p.nama, 'Pasien GIAT') AS nama_pasien,
        p.no_hp,
        p.foto_profile,
        p.jenis_kelamin,
        p.alamat,
        p.tanggal_lahir,
        lm.pesan,
        TRIM(lm.id_sender) AS id_sender,
        lm.created_at
      FROM latest_messages lm
      LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(lm.id_pasien)
      WHERE lm.rn = 1
      ORDER BY lm.created_at DESC
      LIMIT 5
      ''',
      parameters: {'id': docId},
    );
    final List<Map<String, dynamic>> recentMessages =
        msgRows.map((r) => _normalizeMap(r.toColumnMap())).toList();

    // 3. Jadwal Hari Ini / Konsultasi Aktif (Unik per pasien, diprioritaskan yang aktif/terdekat)
    final scheduleRows = await _exec(
      '''
      WITH ranked_schedules AS (
        SELECT 
          TRIM(k.id) AS id,
          TRIM(k.id_pasien) AS id_pasien,
          TRIM(k.id_dokter) AS id_dokter,
          k.tanggal_konsultasi,
          k.jam_mulai::text AS jam_mulai,
          k.jam_selesai::text AS jam_selesai,
          k.status,
          k.jenis_layanan,
          k.keluhan_awal,
          COALESCE(p.nama, 'Pasien GIAT') AS nama_pasien,
          p.no_hp,
          p.foto_profile,
          p.jenis_kelamin,
          p.alamat,
          p.tanggal_lahir,
          ROW_NUMBER() OVER (
            PARTITION BY k.id_pasien 
            ORDER BY 
              CASE 
                WHEN DATE(k.tanggal_konsultasi) = CURRENT_DATE THEN 1
                WHEN k.status = 'berlangsung' THEN 2
                WHEN k.status = 'terjadwal' THEN 3
                ELSE 4
              END,
              k.tanggal_konsultasi DESC,
              k.jam_mulai ASC
          ) as rn
        FROM konsultasi k
        LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(k.id_pasien)
        WHERE TRIM(k.id_dokter) = @id
      )
      SELECT * FROM ranked_schedules WHERE rn = 1
      ORDER BY 
        CASE 
          WHEN DATE(tanggal_konsultasi) = CURRENT_DATE THEN 1
          WHEN status = 'berlangsung' THEN 2
          WHEN status = 'terjadwal' THEN 3
          ELSE 4
        END,
        tanggal_konsultasi DESC,
        jam_mulai ASC
      LIMIT 5
      ''',
      parameters: {'id': docId},
    );
    final List<Map<String, dynamic>> todaySchedules =
        scheduleRows.map((r) => _normalizeMap(r.toColumnMap())).toList();

    // 4. Aktivitas Hari Ini - Konsultasi Terbaru
    final activeConsultationRows = await _exec(
      '''
      SELECT 
        TRIM(k.id) AS id,
        TRIM(k.id_pasien) AS id_pasien,
        k.tanggal_konsultasi,
        k.jam_mulai::text AS jam_mulai,
        k.status,
        k.keluhan_awal,
        COALESCE(p.nama, 'Pasien GIAT') AS nama_pasien,
        p.no_hp,
        p.foto_profile,
        p.jenis_kelamin,
        p.alamat,
        p.tanggal_lahir
      FROM konsultasi k
      LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(k.id_pasien)
      WHERE TRIM(k.id_dokter) = @id
      ORDER BY k.created_at DESC
      LIMIT 1
      ''',
      parameters: {'id': docId},
    );
    final Map<String, dynamic>? latestConsultation = activeConsultationRows.isNotEmpty
        ? _normalizeMap(activeConsultationRows.first.toColumnMap())
        : null;

    // 5. Aktivitas Hari Ini - Resep Terbaru & Rincian Obat
    // Lakukan one-time sinkronisasi timestamp created_at jika lebih lama dari updated_at (misal data seed terupdate)
    try {
      await _exec('UPDATE resep SET created_at = updated_at WHERE created_at < updated_at');
    } catch (_) {}

    final resepRows = await _exec(
      '''
      SELECT 
        TRIM(r.id) AS id,
        TRIM(r.id) AS id_resep,
        TRIM(r.id_konsultasi) AS id_konsultasi,
        TRIM(r.id_dokter) AS id_dokter,
        TRIM(r.id_pasien) AS id_pasien,
        r.tanggal_resep::text AS tanggal_resep,
        r.diagnosis,
        r.catatan_dokter,
        r.status,
        COALESCE(r.updated_at, r.created_at) AS created_at,
        r.updated_at,
        COALESCE(p.nama, 'Pasien GIAT') AS nama_pasien,
        p.no_hp,
        p.foto_profile,
        p.jenis_kelamin,
        p.alamat,
        p.tanggal_lahir
      FROM resep r
      LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(r.id_pasien)
      WHERE TRIM(r.id_dokter) = @id
      ORDER BY COALESCE(r.updated_at, r.created_at) DESC
      LIMIT 1
      ''',
      parameters: {'id': docId},
    );

    Map<String, dynamic>? latestPrescription;
    if (resepRows.isNotEmpty) {
      latestPrescription = _normalizeMap(resepRows.first.toColumnMap());
      final rxId = latestPrescription['id_resep']?.toString().trim();
      if (rxId != null && rxId.isNotEmpty) {
        final itemsRows = await _exec(
          '''
          SELECT 
            TRIM(id) AS id,
            TRIM(id_resep) AS id_resep,
            nama_obat,
            dosis,
            aturan_pakai,
            waktu_penggunaan,
            jumlah,
            catatan_khusus
          FROM resep_item
          WHERE TRIM(id_resep) = @rxId
          ORDER BY created_at ASC
          ''',
          parameters: {'rxId': rxId},
        );
        latestPrescription['obat'] =
            itemsRows.map((r) => _normalizeMap(r.toColumnMap())).toList();
      } else {
        latestPrescription['obat'] = <Map<String, dynamic>>[];
      }
    }

    return {
      'dokter': doctorMap,
      'pesan_terbaru': recentMessages,
      'jadwal_hari_ini': todaySchedules,
      'konsultasi_terbaru': latestConsultation,
      'resep_terbaru': latestPrescription != null ? [latestPrescription] : <Map<String, dynamic>>[],
      'ringkasan_aktivitas': {
        'konsultasi': latestConsultation,
        'resep': latestPrescription,
      },
    };
  }

  // ===========================================================================
  // MODUL RESEP DOKTER: PENERBITAN RESEP & AKSES RESEP REAL SUPABASE
  // ===========================================================================

  /// Menyimpan resep obat elektronik baru oleh dokter ke tabel `resep` & `resep_item` Supabase
  Future<Map<String, dynamic>> saveResepDokter({
    required String idPasien,
    String? patientName,
    String? idDokter,
    String? doctorName,
    String? idKonsultasi,
    String? diagnosis,
    String? catatanDokter,
    String status = 'aktif',
    required List<Map<String, dynamic>> items,
  }) async {
    // 1. Resolve Patient ID
    String? targetPasienId;
    if (idPasien.trim().length >= 30) {
      targetPasienId = idPasien.trim();
    } else {
      if (idKonsultasi != null && idKonsultasi.trim().isNotEmpty) {
        final konsRow = await _exec(
          'SELECT TRIM(id_pasien) AS id_pasien FROM konsultasi WHERE TRIM(id) = @id LIMIT 1',
          parameters: {'id': idKonsultasi.trim()},
        );
        if (konsRow.isNotEmpty) {
          targetPasienId = konsRow.first.toColumnMap()['id_pasien']?.toString().trim();
        }
      }
      if (targetPasienId == null && patientName != null && patientName.trim().isNotEmpty) {
        final pasRow = await _exec(
          'SELECT TRIM(id_pasien) AS id_pasien FROM pasien WHERE LOWER(TRIM(nama)) = LOWER(@nama) LIMIT 1',
          parameters: {'nama': patientName.trim()},
        );
        if (pasRow.isNotEmpty) {
          targetPasienId = pasRow.first.toColumnMap()['id_pasien']?.toString().trim();
        }
      }
      targetPasienId ??= await resolveCurrentPasienId();
    }

    if (targetPasienId == null || targetPasienId.isEmpty) {
      throw Exception('ID Pasien tidak dapat diidentifikasi untuk pembuatan resep.');
    }

    // 2. Resolve Doctor ID
    String? targetDokterId;
    if (idDokter != null && idDokter.trim().length >= 30) {
      targetDokterId = idDokter.trim();
    } else {
      if (idKonsultasi != null && idKonsultasi.trim().isNotEmpty) {
        final konsDocRow = await _exec(
          'SELECT TRIM(id_dokter) AS id_dokter FROM konsultasi WHERE TRIM(id) = @id LIMIT 1',
          parameters: {'id': idKonsultasi.trim()},
        );
        if (konsDocRow.isNotEmpty) {
          targetDokterId = konsDocRow.first.toColumnMap()['id_dokter']?.toString().trim();
        }
      }
      targetDokterId ??= await resolveCurrentDokterId(overrideDokterId: idDokter, doctorName: doctorName);
    }

    if (targetDokterId == null || targetDokterId.isEmpty) {
      // Fallback ke dokter pertama jika tidak teridentifikasi
      final firstDoc = await _exec('SELECT TRIM(id_dokter) AS id_dokter FROM dokter ORDER BY created_at ASC LIMIT 1');
      if (firstDoc.isNotEmpty) {
        targetDokterId = firstDoc.first.toColumnMap()['id_dokter']?.toString().trim();
      }
    }

    if (targetDokterId == null || targetDokterId.isEmpty) {
      throw Exception('ID Dokter tidak dapat diidentifikasi.');
    }

    // 3. Resolve Consultation ID if null
    String? resolvedKonsultasiId = idKonsultasi?.trim();
    if (resolvedKonsultasiId == null || resolvedKonsultasiId.isEmpty) {
      final lastKons = await _exec(
        '''
        SELECT TRIM(id) AS id FROM konsultasi
        WHERE TRIM(id_pasien) = @pasId
        ORDER BY created_at DESC
        LIMIT 1
        ''',
        parameters: {'pasId': targetPasienId},
      );
      if (lastKons.isNotEmpty) {
        resolvedKonsultasiId = lastKons.first.toColumnMap()['id']?.toString().trim();
      }
    }

    // 4. Check whether a prescription already exists for this consultation (unique constraint)
    String? existingResepId;
    String? existingNoResep;
    if (resolvedKonsultasiId != null && resolvedKonsultasiId.isNotEmpty) {
      final existingRes = await _exec(
        'SELECT TRIM(id) AS id, no_resep FROM resep WHERE TRIM(id_konsultasi) = @idKonsultasi LIMIT 1',
        parameters: {'idKonsultasi': resolvedKonsultasiId},
      );
      if (existingRes.isNotEmpty) {
        final r = existingRes.first.toColumnMap();
        existingResepId = r['id']?.toString().trim();
        existingNoResep = r['no_resep']?.toString().trim();
      }
    }

    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final seq = (now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
    final generatedNoResep = existingNoResep ?? 'RXP-$y$m$d-$seq';

    final String finalResepId;
    if (existingResepId != null && existingResepId.isNotEmpty) {
      finalResepId = existingResepId;
      await _exec(
        '''
        UPDATE resep
        SET diagnosis = @diagnosis,
            catatan_dokter = @catatanDokter,
            status = @status,
            tanggal_resep = CURRENT_DATE,
            created_at = NOW(),
            updated_at = NOW()
        WHERE TRIM(id) = @id
        ''',
        parameters: {
          'id': finalResepId,
          'diagnosis': diagnosis ?? 'Pemeriksaan Protokol Ginjal',
          'catatanDokter': catatanDokter ?? 'Resep elektronik diterbitkan melalui GIAT Telekonsultasi.',
          'status': status,
        },
      );
      // Hapus item obat lama agar diganti dengan daftar item obat yang baru diterbitkan
      await _exec(
        'DELETE FROM resep_item WHERE TRIM(id_resep) = @id',
        parameters: {'id': finalResepId},
      );
    } else {
      final uuidRes = await _exec('SELECT gen_random_uuid()::text AS id');
      finalResepId = uuidRes.first.toColumnMap()['id'].toString().trim();

      // 5. Insert ke tabel BASE TABLE `resep`
      await _exec(
        '''
        INSERT INTO resep (
          id,
          no_resep,
          id_konsultasi,
          id_dokter,
          id_pasien,
          tanggal_resep,
          diagnosis,
          catatan_dokter,
          status,
          created_at,
          updated_at
        ) VALUES (
          @id,
          @noResep,
          @idKonsultasi,
          @idDokter,
          @idPasien,
          CURRENT_DATE,
          @diagnosis,
          @catatanDokter,
          @status,
          NOW(),
          NOW()
        )
        ''',
        parameters: {
          'id': finalResepId,
          'noResep': generatedNoResep,
          'idKonsultasi': resolvedKonsultasiId,
          'idDokter': targetDokterId,
          'idPasien': targetPasienId,
          'diagnosis': diagnosis ?? 'Pemeriksaan Protokol Ginjal',
          'catatanDokter': catatanDokter ?? 'Resep elektronik diterbitkan melalui GIAT Telekonsultasi.',
          'status': status,
        },
      );
    }

    // 6. Insert items ke tabel `resep_item`
    final List<Map<String, dynamic>> savedItems = [];
    for (var item in items) {
      final namaObat = (item['nama_obat'] ?? item['medicineName'] ?? item['name'] ?? 'Obat Ginjal').toString().trim();
      if (namaObat.isEmpty) continue;

      final dosis = (item['dosis'] ?? item['dose'] ?? '').toString().trim();
      final aturanPakai = (item['aturan_pakai'] ?? item['frequency'] ?? '').toString().trim();
      final waktuPenggunaan = (item['waktu_penggunaan'] ?? item['waktu_minum'] ?? item['usageTime'] ?? '').toString().trim();

      final rawQty = (item['jumlah'] ?? item['quantity'] ?? '30').toString();
      final qtyMatch = RegExp(r'\d+').firstMatch(rawQty);
      final jumlah = qtyMatch != null ? (int.tryParse(qtyMatch.group(0)!) ?? 30) : 30;

      final catatanKhusus = (item['catatan_khusus'] ?? item['specialNotes'] ?? item['catatan'] ?? '').toString().trim();

      final itemIdRes = await _exec('SELECT gen_random_uuid()::text AS id');
      final newItemId = itemIdRes.first.toColumnMap()['id'].toString().trim();

      await _exec(
        '''
        INSERT INTO resep_item (
          id,
          id_resep,
          nama_obat,
          dosis,
          aturan_pakai,
          waktu_penggunaan,
          jumlah,
          catatan_khusus,
          created_at,
          updated_at
        ) VALUES (
          @id,
          @idResep,
          @namaObat,
          @dosis,
          @aturanPakai,
          @waktuPenggunaan,
          @jumlah,
          @catatanKhusus,
          NOW(),
          NOW()
        )
        ''',
        parameters: {
          'id': newItemId,
          'idResep': finalResepId,
          'namaObat': namaObat,
          'dosis': dosis.isNotEmpty ? dosis : null,
          'aturanPakai': aturanPakai.isNotEmpty ? aturanPakai : null,
          'waktuPenggunaan': waktuPenggunaan.isNotEmpty ? waktuPenggunaan : null,
          'jumlah': jumlah,
          'catatanKhusus': catatanKhusus.isNotEmpty ? catatanKhusus : null,
        },
      );

      savedItems.add({
        'id': newItemId,
        'id_resep': finalResepId,
        'nama_obat': namaObat,
        'dosis': dosis,
        'aturan_pakai': aturanPakai,
        'waktu_penggunaan': waktuPenggunaan,
        'jumlah': jumlah,
        'catatan_khusus': catatanKhusus,
      });
    }

    // 7. Notifikasi ke Pasien
    try {
      await createPasienNotification(
        pasienId: targetPasienId,
        judul: 'Resep Obat Baru Diterbitkan',
        pesan: 'Dokter telah menerbitkan resep elektronik untuk Anda. Cek pada menu Obat > Resep Dokter.',
        kategori: 'resep',
      );
    } catch (e) {
      debugPrint('Warning: gagal membuat notifikasi pasien: $e');
    }

    return {
      'id': finalResepId,
      'id_resep': finalResepId,
      'no_resep': generatedNoResep,
      'id_konsultasi': resolvedKonsultasiId,
      'id_dokter': targetDokterId,
      'id_pasien': targetPasienId,
      'tanggal_resep': '$y-$m-$d',
      'diagnosis': diagnosis,
      'catatan_dokter': catatanDokter,
      'status': status,
      'items': savedItems,
    };
  }

  /// Mengambil daftar resep obat pasien beserta rincian item obatnya dari Supabase
  Future<List<Map<String, dynamic>>> fetchResepForPasien({String? pasienId}) async {
    final pid = await resolveCurrentPasienId(overridePasienId: pasienId);
    if (pid == null) return [];

    final rows = await _exec(
      '''
      SELECT 
        TRIM(r.id) AS id,
        TRIM(r.id) AS id_resep,
        r.no_resep,
        TRIM(r.id_konsultasi) AS id_konsultasi,
        TRIM(r.id_dokter) AS id_dokter,
        TRIM(r.id_pasien) AS id_pasien,
        r.tanggal_resep::text AS tanggal_resep,
        r.diagnosis,
        r.catatan_dokter,
        r.status,
        r.created_at,
        r.updated_at,
        COALESCE(d.nama, 'dr. Spesialis GIAT') AS nama_dokter,
        COALESCE(d.spesialisasi, 'Spesialis Ginjal Hipertensi (Sp.PD-KGH)') AS spesialisasi_dokter,
        d.no_sip AS no_sip_dokter,
        d.foto_profile AS foto_dokter,
        d.institusi AS institusi_dokter
      FROM resep r
      LEFT JOIN dokter d ON TRIM(d.id_dokter) = TRIM(r.id_dokter)
      WHERE TRIM(r.id_pasien) = @id
      ORDER BY r.created_at DESC
      ''',
      parameters: {'id': pid},
    );

    final List<Map<String, dynamic>> result = [];
    for (var row in rows) {
      final map = _normalizeMap(row.toColumnMap());
      final rxId = map['id']?.toString().trim() ?? map['id_resep']?.toString().trim();
      if (rxId != null && rxId.isNotEmpty) {
        final itemRows = await _exec(
          '''
          SELECT 
            TRIM(id) AS id,
            TRIM(id_resep) AS id_resep,
            nama_obat,
            dosis,
            aturan_pakai,
            waktu_penggunaan,
            jumlah,
            catatan_khusus
          FROM resep_item
          WHERE TRIM(id_resep) = @rxId
          ORDER BY created_at ASC
          ''',
          parameters: {'rxId': rxId},
        );
        map['items'] = itemRows.map((ir) => _normalizeMap(ir.toColumnMap())).toList();
      } else {
        map['items'] = <Map<String, dynamic>>[];
      }
      result.add(map);
    }
    return result;
  }

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  /// Mengambil data resep obat untuk konsultasi tertentu (beserta rincian item obat)
  Future<Map<String, dynamic>?> fetchResepForKonsultasi(String consultationId, {String? patientId}) async {
    if (_isTest) return null;
    final consId = consultationId.trim();
    if (consId.isEmpty) return null;

    final rows = await _exec(
      '''
      SELECT 
        TRIM(r.id) AS id,
        TRIM(r.id) AS id_resep,
        r.no_resep,
        TRIM(r.id_konsultasi) AS id_konsultasi,
        TRIM(r.id_dokter) AS id_dokter,
        TRIM(r.id_pasien) AS id_pasien,
        r.tanggal_resep::text AS tanggal_resep,
        r.diagnosis,
        r.catatan_dokter,
        r.status,
        COALESCE(r.updated_at, r.created_at) AS created_at,
        r.updated_at,
        COALESCE(d.nama, 'Dokter GIAT') AS nama_dokter
      FROM resep r
      LEFT JOIN dokter d ON TRIM(d.id_dokter) = TRIM(r.id_dokter)
      WHERE TRIM(r.id_konsultasi) = @id
      ORDER BY COALESCE(r.updated_at, r.created_at) DESC
      LIMIT 1
      ''',
      parameters: {'id': consId},
    );

    if (rows.isEmpty && patientId != null && patientId.trim().isNotEmpty) {
      final pasRows = await _exec(
        '''
        SELECT 
          TRIM(r.id) AS id,
          TRIM(r.id) AS id_resep,
          r.no_resep,
          TRIM(r.id_konsultasi) AS id_konsultasi,
          TRIM(r.id_dokter) AS id_dokter,
          TRIM(r.id_pasien) AS id_pasien,
          r.tanggal_resep::text AS tanggal_resep,
          r.diagnosis,
          r.catatan_dokter,
          r.status,
          COALESCE(r.updated_at, r.created_at) AS created_at,
          r.updated_at,
          COALESCE(d.nama, 'Dokter GIAT') AS nama_dokter
        FROM resep r
        LEFT JOIN dokter d ON TRIM(d.id_dokter) = TRIM(r.id_dokter)
        WHERE TRIM(r.id_pasien) = @pid
        ORDER BY COALESCE(r.updated_at, r.created_at) DESC
        LIMIT 1
        ''',
        parameters: {'pid': patientId.trim()},
      );
      if (pasRows.isNotEmpty) {
        rows.addAll(pasRows);
      }
    }

    if (rows.isEmpty) return null;

    final rxMap = _normalizeMap(rows.first.toColumnMap());
    final rxId = rxMap['id']?.toString().trim();
    if (rxId != null && rxId.isNotEmpty) {
      final itemRows = await _exec(
        '''
        SELECT 
          TRIM(id) AS id,
          TRIM(id_resep) AS id_resep,
          nama_obat,
          dosis,
          aturan_pakai,
          waktu_penggunaan,
          jumlah,
          catatan_khusus
        FROM resep_item
        WHERE TRIM(id_resep) = @rxId
        ORDER BY created_at ASC
        ''',
        parameters: {'rxId': rxId},
      );
      rxMap['items'] = itemRows.map((ir) => _normalizeMap(ir.toColumnMap())).toList();
    } else {
      rxMap['items'] = <Map<String, dynamic>>[];
    }
    return rxMap;
  }
}


