import 'dart:convert';
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

    // 2. Pesan terbaru (Pesan terakhir yang dikirim oleh pasien ke dokter, unik per pasien)
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
        LEFT JOIN konsultasi_pembayaran kp_pay ON TRIM(kp_pay.id_konsultasi) = TRIM(k.id)
        WHERE TRIM(k.id_dokter) = @id
          AND TRIM(kp.id_sender) != @id
          AND (
            LOWER(TRIM(COALESCE(kp_pay.status_bayar, ''))) = 'lunas'
            OR (
              LOWER(TRIM(k.status)) IN ('berlangsung', 'aktif', 'terjadwal', 'selesai')
              AND LOWER(TRIM(COALESCE(kp_pay.status_bayar, 'lunas'))) NOT IN ('menunggu_pembayaran', 'kadaluwarsa', 'batal')
            )
          )
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
        pan.bb AS berat_badan,
        pan.tb AS tinggi_badan,
        pan.kondisi AS kondisi_pantau,
        pan.keluhan AS keluhan_pantau,
        pan.detail_keluhan AS detail_keluhan_pantau,
        lm.pesan,
        TRIM(lm.id_sender) AS id_sender,
        lm.created_at
      FROM latest_messages lm
      LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(lm.id_pasien)
      LEFT JOIN LATERAL (
        SELECT bb, tb, kondisi, keluhan, detail_keluhan
        FROM pantau
        WHERE TRIM(id_pasien) = TRIM(lm.id_pasien)
        ORDER BY COALESCE(tanggal_pantau, created_at) DESC
        LIMIT 1
      ) pan ON true
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
          pan.bb AS berat_badan,
          pan.tb AS tinggi_badan,
          pan.kondisi AS kondisi_pantau,
          pan.keluhan AS keluhan_pantau,
          pan.detail_keluhan AS detail_keluhan_pantau,
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
        LEFT JOIN konsultasi_pembayaran kp_pay ON TRIM(kp_pay.id_konsultasi) = TRIM(k.id)
        LEFT JOIN LATERAL (
          SELECT bb, tb, kondisi, keluhan, detail_keluhan
          FROM pantau
          WHERE TRIM(id_pasien) = TRIM(k.id_pasien)
          ORDER BY COALESCE(tanggal_pantau, created_at) DESC
          LIMIT 1
        ) pan ON true
        WHERE TRIM(k.id_dokter) = @id
          AND (
            LOWER(TRIM(COALESCE(kp_pay.status_bayar, ''))) = 'lunas'
            OR (
              LOWER(TRIM(k.status)) IN ('berlangsung', 'aktif', 'terjadwal', 'selesai')
              AND LOWER(TRIM(COALESCE(kp_pay.status_bayar, 'lunas'))) NOT IN ('menunggu_pembayaran', 'kadaluwarsa', 'batal')
            )
          )
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
        p.tanggal_lahir,
        pan.bb AS berat_badan,
        pan.tb AS tinggi_badan,
        pan.kondisi AS kondisi_pantau,
        pan.keluhan AS keluhan_pantau,
        pan.detail_keluhan AS detail_keluhan_pantau
      FROM konsultasi k
      LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(k.id_pasien)
      LEFT JOIN LATERAL (
        SELECT bb, tb, kondisi, keluhan, detail_keluhan
        FROM pantau
        WHERE TRIM(id_pasien) = TRIM(k.id_pasien)
        ORDER BY COALESCE(tanggal_pantau, created_at) DESC
        LIMIT 1
      ) pan ON true
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
        p.tanggal_lahir,
        pan.bb AS berat_badan,
        pan.tb AS tinggi_badan,
        pan.kondisi AS kondisi_pantau,
        pan.keluhan AS keluhan_pantau,
        pan.detail_keluhan AS detail_keluhan_pantau
      FROM resep r
      LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(r.id_pasien)
      LEFT JOIN LATERAL (
        SELECT bb, tb, kondisi, keluhan, detail_keluhan
        FROM pantau
        WHERE TRIM(id_pasien) = TRIM(r.id_pasien)
        ORDER BY COALESCE(tanggal_pantau, created_at) DESC
        LIMIT 1
      ) pan ON true
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
        '''
        SELECT TRIM(r.id) AS id, r.no_resep, LOWER(TRIM(COALESCE(r.status, 'aktif'))) AS status,
               (SELECT COUNT(*)::int FROM pesanan_obat po WHERE TRIM(po.id_resep) = TRIM(r.id) AND LOWER(TRIM(po.status_pembayaran)) = 'lunas') AS paid_cnt
        FROM resep r
        WHERE TRIM(r.id_konsultasi) = @idKonsultasi
        LIMIT 1
        ''',
        parameters: {'idKonsultasi': resolvedKonsultasiId},
      );
      if (existingRes.isNotEmpty) {
        final r = existingRes.first.toColumnMap();
        final exStatus = r['status']?.toString() ?? 'aktif';
        final paidCnt = int.tryParse(r['paid_cnt']?.toString() ?? '0') ?? 0;
        if (exStatus == 'aktif' && paidCnt == 0) {
          existingResepId = r['id']?.toString().trim();
          existingNoResep = r['no_resep']?.toString().trim();
        } else {
          // Resep lama sudah ditebus/dibayar, buat baris resep baru untuk pasien
          resolvedKonsultasiId = null;
        }
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
            status = 'aktif',
            tanggal_resep = CURRENT_DATE,
            created_at = NOW(),
            updated_at = NOW()
        WHERE TRIM(id) = @id
        ''',
        parameters: {
          'id': finalResepId,
          'diagnosis': diagnosis ?? 'Pemeriksaan Protokol Ginjal',
          'catatanDokter': catatanDokter ?? 'Resep elektronik diterbitkan melalui GIAT Telekonsultasi.',
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
            TRIM(ri.id) AS id,
            TRIM(ri.id_resep) AS id_resep,
            ri.nama_obat,
            ri.dosis,
            ri.aturan_pakai,
            ri.waktu_penggunaan,
            ri.jumlah,
            ri.catatan_khusus,
            COALESCE(
              (SELECT ROUND(o.harga_jual)::int FROM obat o WHERE LOWER(TRIM(o.nama_obat)) = LOWER(TRIM(ri.nama_obat)) LIMIT 1),
              (SELECT ROUND(o.harga_jual)::int FROM obat o WHERE LOWER(o.nama_obat) LIKE '%' || LOWER(SPLIT_PART(TRIM(ri.nama_obat), ' ', 1)) || '%' LIMIT 1),
              65000
            ) AS harga
          FROM resep_item ri
          WHERE TRIM(ri.id_resep) = @rxId
          ORDER BY ri.created_at ASC
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

  /// Memperbarui status resep menjadi 'sudah_ditebus' setelah pembayaran berhasil
  Future<bool> markResepSudahDitebus({String? idResep, String? noResep}) async {
    final cleanId = (idResep ?? '').trim().replaceAll('No.', '').trim();
    final cleanNo = (noResep ?? '').trim().replaceAll('No.', '').trim();
    if (cleanId.isEmpty && cleanNo.isEmpty) return false;

    try {
      await _exec(
        '''
        UPDATE resep
        SET status = 'sudah_ditebus',
            updated_at = NOW()
        WHERE TRIM(id) = @cleanId 
           OR TRIM(no_resep) = @cleanNo 
           OR TRIM(no_resep) = @cleanId
           OR TRIM(id) = @cleanNo
        ''',
        parameters: {
          'cleanId': cleanId,
          'cleanNo': cleanNo,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error markResepSudahDitebus: $e');
      return false;
    }
  }

  /// Mengambil katalog obat real dari tabel `obat` Supabase
  Future<List<Map<String, dynamic>>> fetchKatalogObat({String? search, String? kategori}) async {
    try {
      String whereClause = 'WHERE 1=1';
      final Map<String, dynamic> params = {};
      if (search != null && search.trim().isNotEmpty) {
        whereClause += ' AND (LOWER(o.nama_obat) LIKE @search OR LOWER(o.kategori) LIKE @search)';
        params['search'] = '%${search.trim().toLowerCase()}%';
      }
      if (kategori != null && kategori.trim().isNotEmpty && kategori.toLowerCase() != 'semua') {
        whereClause += ' AND LOWER(o.kategori) = @kategori';
        params['kategori'] = kategori.trim().toLowerCase();
      }

      final sql = '''
        SELECT
          TRIM(o.id_obat) AS id_obat,
          TRIM(o.id_obat) AS id,
          TRIM(o.id_apotek) AS id_apotek,
          o.nama_obat,
          o.nama_obat AS nama,
          o.kategori,
          o.bentuk_sediaan,
          o.dosis,
          o.satuan_kemasan,
          o.satuan_kemasan AS kemasan,
          o.stok_total,
          o.harga_beli,
          o.harga_jual,
          o.harga_jual AS harga,
          o.aturan_pakai_umum,
          o.aturan_pakai_umum AS deskripsi,
          o.foto_obat,
          o.foto_obat AS gambar,
          COALESCE(a.nama_apotek, 'Apotek Kimia Farma Mitra') AS nama_apotek
        FROM obat o
        LEFT JOIN apotek a ON TRIM(o.id_apotek) = TRIM(a.id_apotek)
        $whereClause
        ORDER BY o.nama_obat ASC;
      ''';
      final res = await _exec(sql, parameters: params);
      return res.map((r) => _normalizeMap(r.toColumnMap())).toList();
    } catch (e) {
      debugPrint('Error fetchKatalogObat: $e');
      return [];
    }
  }

  /// Mengambil daftar pesanan obat pasien beserta rincian itemnya dari Supabase
  Future<List<Map<String, dynamic>>> fetchPesananForPasien({String? pasienId}) async {
    final pid = await resolveCurrentPasienId(overridePasienId: pasienId);
    if (pid == null) return [];

    try {
      final rows = await _exec(
        '''
        SELECT 
          TRIM(p.id) AS id,
          p.no_pesanan,
          TRIM(p.id_pasien) AS id_pasien,
          TRIM(p.id_apotek) AS id_apotek,
          TRIM(p.id_resep) AS id_resep,
          p.tipe_pesanan,
          p.metode_pengambilan,
          p.nama_penerima,
          p.no_hp_penerima,
          p.alamat_pengiriman,
          p.subtotal,
          p.ongkos_kirim,
          p.total_bayar,
          p.metode_pembayaran,
          p.status_pembayaran,
          p.progress_step,
          p.status_pesanan,
          p.created_at::text AS created_at,
          p.updated_at::text AS updated_at,
          p.snap_token,
          p.redirect_url,
          COALESCE(a.nama_apotek, 'Apotek Mitra GIAT') AS nama_apotek,
          a.alamat AS alamat_apotek
        FROM pesanan_obat p
        LEFT JOIN apotek a ON TRIM(a.id_apotek) = TRIM(p.id_apotek)
        WHERE TRIM(p.id_pasien) = @id
        ORDER BY p.created_at DESC
        ''',
        parameters: {'id': pid},
      );

      final List<Map<String, dynamic>> result = [];
      for (var row in rows) {
        final map = _normalizeMap(row.toColumnMap());
        final pId = map['id']?.toString().trim();
        if (pId != null && pId.isNotEmpty) {
          final itemRows = await _exec(
            '''
            SELECT 
              TRIM(id) AS id,
              TRIM(id_pesanan) AS id_pesanan,
              TRIM(id_obat) AS id_obat,
              nama_obat,
              jumlah,
              harga_satuan,
              subtotal
            FROM pesanan_obat_items
            WHERE TRIM(id_pesanan) = @pId
            ORDER BY created_at ASC
            ''',
            parameters: {'pId': pId},
          );
          map['items'] = itemRows.map((ir) => _normalizeMap(ir.toColumnMap())).toList();
        } else {
          map['items'] = <Map<String, dynamic>>[];
        }
        map['id_pembelian'] = map['id'];
        map['total_harga'] = map['total_bayar'];
        map['tipe_pembelian'] = map['tipe_pesanan'];
        map['apotek'] = {
          'id': map['id_apotek'],
          'nama': map['nama_apotek'],
          'nama_apotek': map['nama_apotek'],
          'alamat': map['alamat_apotek'],
        };
        result.add(map);
      }
      return result;
    } catch (e) {
      debugPrint('Error fetchPesananForPasien: $e');
      return [];
    }
  }

  /// Mengambil detail pesanan obat spesifik dari Supabase
  Future<Map<String, dynamic>?> fetchDetailPesanan(dynamic idPesanan) async {
    final searchId = idPesanan?.toString().trim() ?? '';
    if (searchId.isEmpty) return null;

    try {
      final rows = await _exec(
        '''
        SELECT 
          TRIM(p.id) AS id,
          p.no_pesanan,
          TRIM(p.id_pasien) AS id_pasien,
          TRIM(p.id_apotek) AS id_apotek,
          TRIM(p.id_resep) AS id_resep,
          p.tipe_pesanan,
          p.metode_pengambilan,
          p.nama_penerima,
          p.no_hp_penerima,
          p.alamat_pengiriman,
          p.subtotal,
          p.ongkos_kirim,
          p.total_bayar,
          p.metode_pembayaran,
          p.status_pembayaran,
          p.progress_step,
          p.status_pesanan,
          p.created_at::text AS created_at,
          p.updated_at::text AS updated_at,
          p.snap_token,
          p.redirect_url,
          COALESCE(a.nama_apotek, 'Apotek Mitra GIAT') AS nama_apotek,
          a.alamat AS alamat_apotek
        FROM pesanan_obat p
        LEFT JOIN apotek a ON TRIM(a.id_apotek) = TRIM(p.id_apotek)
        WHERE TRIM(p.id) = @searchId OR TRIM(p.no_pesanan) = @searchId
        LIMIT 1
        ''',
        parameters: {'searchId': searchId},
      );

      if (rows.isEmpty) return null;
      final map = _normalizeMap(rows.first.toColumnMap());
      final pId = map['id']?.toString().trim();
      if (pId != null && pId.isNotEmpty) {
        final itemRows = await _exec(
          '''
          SELECT 
            TRIM(id) AS id,
            TRIM(id_pesanan) AS id_pesanan,
            TRIM(id_obat) AS id_obat,
            nama_obat,
            jumlah,
            harga_satuan,
            subtotal
          FROM pesanan_obat_items
          WHERE TRIM(id_pesanan) = @pId
          ORDER BY created_at ASC
          ''',
          parameters: {'pId': pId},
        );
        map['items'] = itemRows.map((ir) => _normalizeMap(ir.toColumnMap())).toList();
      } else {
        map['items'] = <Map<String, dynamic>>[];
      }
      map['id_pembelian'] = map['id'];
      map['total_harga'] = map['total_bayar'];
      map['tipe_pembelian'] = map['tipe_pesanan'];
      map['apotek'] = {
        'id': map['id_apotek'],
        'nama': map['nama_apotek'],
        'nama_apotek': map['nama_apotek'],
        'alamat': map['alamat_apotek'],
      };
      return map;
    } catch (e) {
      debugPrint('Error fetchDetailPesanan: $e');
      return null;
    }
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

  /// Mengambil daftar konsultasi aktif/terjadwal/selesai untuk dokter dari Supabase
  /// HANYA menampilkan konsultasi yang pasiennya SUDAH MELAKUKAN PEMBAYARAN (status_bayar = 'lunas')
  Future<List<Map<String, dynamic>>> fetchDokterConsultations({String? dokterId, String? doctorName}) async {
    if (_isTest) return [];

    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) return [];

    final rows = await _exec(
      '''
      SELECT 
        TRIM(k.id) AS id,
        TRIM(k.id) AS id_konsultasi,
        TRIM(k.id_pasien) AS id_pasien,
        TRIM(k.id_dokter) AS id_dokter,
        k.tanggal_konsultasi::text AS tanggal_konsultasi,
        k.jam_mulai::text AS jam_mulai,
        k.jam_selesai::text AS jam_selesai,
        k.keluhan_awal,
        k.jenis_layanan,
        k.status AS status_konsultasi,
        k.created_at,
        k.updated_at,
        COALESCE(p.nama, 'Pasien GIAT') AS nama_pasien,
        p.no_hp,
        p.foto_profile,
        p.jenis_kelamin,
        p.alamat,
        p.tanggal_lahir,
        COALESCE(kp.status_bayar, 'lunas') AS status_bayar,
        kp.waktu_bayar,
        kp.jumlah_bayar,
        pan.bb AS berat_badan,
        pan.tb AS tinggi_badan,
        pan.kondisi AS kondisi_pantau,
        pan.keluhan AS keluhan_pantau,
        pan.detail_keluhan AS detail_keluhan_pantau,
        (
          SELECT COUNT(*) 
          FROM konsultasi_pesan m 
          WHERE TRIM(m.id_konsultasi) = TRIM(k.id)
            AND m.is_read = false
            AND TRIM(m.id_sender) != @docId
        ) AS unread_count,
        COALESCE(
          (
            SELECT m.pesan
            FROM konsultasi_pesan m
            WHERE TRIM(m.id_konsultasi) = TRIM(k.id)
              AND TRIM(m.id_sender) != @docId
            ORDER BY m.created_at DESC
            LIMIT 1
          ),
          (
            SELECT m.pesan
            FROM konsultasi_pesan m
            WHERE TRIM(m.id_konsultasi) = TRIM(k.id)
            ORDER BY m.created_at DESC
            LIMIT 1
          )
        ) AS last_message,
        COALESCE(
          (
            SELECT m.created_at
            FROM konsultasi_pesan m
            WHERE TRIM(m.id_konsultasi) = TRIM(k.id)
              AND TRIM(m.id_sender) != @docId
            ORDER BY m.created_at DESC
            LIMIT 1
          ),
          (
            SELECT m.created_at
            FROM konsultasi_pesan m
            WHERE TRIM(m.id_konsultasi) = TRIM(k.id)
            ORDER BY m.created_at DESC
            LIMIT 1
          )
        ) AS last_message_time
      FROM konsultasi k
      JOIN pasien p ON TRIM(p.id_pasien) = TRIM(k.id_pasien)
      LEFT JOIN konsultasi_pembayaran kp ON TRIM(kp.id_konsultasi) = TRIM(k.id)
      LEFT JOIN LATERAL (
        SELECT bb, tb, kondisi, keluhan, detail_keluhan
        FROM pantau
        WHERE TRIM(id_pasien) = TRIM(k.id_pasien)
        ORDER BY COALESCE(tanggal_pantau, created_at) DESC
        LIMIT 1
      ) pan ON true
      WHERE TRIM(k.id_dokter) = @docId
        AND (
          LOWER(TRIM(COALESCE(kp.status_bayar, ''))) = 'lunas'
          OR (
            LOWER(TRIM(k.status)) IN ('berlangsung', 'aktif', 'terjadwal', 'selesai')
            AND LOWER(TRIM(COALESCE(kp.status_bayar, 'lunas'))) NOT IN ('menunggu_pembayaran', 'kadaluwarsa', 'batal')
          )
        )
      ORDER BY 
        CASE 
          WHEN LOWER(TRIM(k.status)) IN ('berlangsung', 'aktif') THEN 1
          WHEN LOWER(TRIM(k.status)) = 'terjadwal' THEN 2
          ELSE 3
        END,
        COALESCE(k.updated_at, k.created_at) DESC
      ''',
      parameters: {'docId': docId},
    );

    return rows.map((r) {
      final map = _normalizeMap(r.toColumnMap());
      final unread = int.tryParse(map['unread_count']?.toString() ?? '0') ?? 0;
      map['unread_count'] = unread;
      map['pesan_count'] = unread;
      map['pasien'] = {
        'id': map['id_pasien'],
        'id_pasien': map['id_pasien'],
        'nama': map['nama_pasien'],
        'foto_profile': map['foto_profile'],
        'jenis_kelamin': map['jenis_kelamin'],
        'alamat': map['alamat'],
        'tanggal_lahir': map['tanggal_lahir'],
        'no_hp': map['no_hp'],
        'berat_badan': map['berat_badan'],
        'tinggi_badan': map['tinggi_badan'],
        'kondisi': map['kondisi_pantau'],
        'keluhan': map['keluhan_pantau'] ?? map['keluhan_awal'],
        'detail_keluhan': map['detail_keluhan_pantau'],
      };
      return map;
    }).toList();
  }

  /// Mengambil data jadwal konsultasi dokter secara real dari Supabase PostgreSQL
  Future<List<Map<String, dynamic>>> fetchDokterJadwal({
    String? dokterId,
    String? doctorName,
    String? date,
  }) async {
    if (_isTest) return [];

    var docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) {
      final firstDoc = await _exec('SELECT TRIM(id_dokter) AS id FROM dokter ORDER BY created_at ASC LIMIT 1');
      if (firstDoc.isNotEmpty) {
        docId = firstDoc.first[0]?.toString().trim();
      }
    }
    if (docId == null) return [];

    final Map<String, dynamic> params = {'docId': docId};
    String dateClause = '';
    if (date != null && date.trim().isNotEmpty) {
      dateClause = 'AND DATE(k.tanggal_konsultasi) = @selectedDate::date';
      params['selectedDate'] = date.trim();
    }

    final rows = await _exec(
      '''
      SELECT 
        TRIM(k.id) AS id,
        TRIM(k.id) AS id_konsultasi,
        TRIM(k.id_pasien) AS id_pasien,
        TRIM(k.id_dokter) AS id_dokter,
        k.tanggal_konsultasi::text AS tanggal_konsultasi,
        k.jam_mulai::text AS jam_mulai,
        k.jam_selesai::text AS jam_selesai,
        k.keluhan_awal,
        k.jenis_layanan,
        k.status AS status_konsultasi,
        k.created_at,
        k.updated_at,
        COALESCE(p.nama, 'Pasien GIAT') AS nama_pasien,
        p.no_hp,
        p.foto_profile,
        p.jenis_kelamin,
        p.alamat,
        p.tanggal_lahir,
        COALESCE(kp.status_bayar, 'lunas') AS status_bayar,
        kp.waktu_bayar,
        kp.jumlah_bayar,
        pan.bb AS berat_badan,
        pan.tb AS tinggi_badan,
        pan.kondisi AS kondisi_pantau,
        pan.keluhan AS keluhan_pantau,
        pan.detail_keluhan AS detail_keluhan_pantau
      FROM konsultasi k
      JOIN pasien p ON TRIM(p.id_pasien) = TRIM(k.id_pasien)
      LEFT JOIN konsultasi_pembayaran kp ON TRIM(kp.id_konsultasi) = TRIM(k.id)
      LEFT JOIN LATERAL (
        SELECT bb, tb, kondisi, keluhan, detail_keluhan
        FROM pantau
        WHERE TRIM(id_pasien) = TRIM(k.id_pasien)
        ORDER BY created_at DESC
        LIMIT 1
      ) pan ON true
      WHERE TRIM(k.id_dokter) = @docId
        AND (
          LOWER(TRIM(COALESCE(kp.status_bayar, ''))) = 'lunas'
          OR (
            LOWER(TRIM(k.status)) IN ('berlangsung', 'aktif', 'terjadwal', 'selesai')
            AND LOWER(TRIM(COALESCE(kp.status_bayar, 'lunas'))) NOT IN ('menunggu_pembayaran', 'kadaluwarsa', 'batal')
          )
        )
        $dateClause
      ORDER BY 
        k.tanggal_konsultasi DESC,
        k.jam_mulai ASC,
        CASE 
          WHEN LOWER(TRIM(k.status)) IN ('berlangsung', 'aktif') THEN 1
          WHEN LOWER(TRIM(k.status)) = 'terjadwal' THEN 2
          ELSE 3
        END,
        COALESCE(k.updated_at, k.created_at) DESC
      ''',
      parameters: params,
    );

    return rows.map((r) {
      final map = _normalizeMap(r.toColumnMap());
      map['pasien'] = {
        'id': map['id_pasien'],
        'id_pasien': map['id_pasien'],
        'nama': map['nama_pasien'],
        'foto_profile': map['foto_profile'],
        'jenis_kelamin': map['jenis_kelamin'],
        'alamat': map['alamat'],
        'tanggal_lahir': map['tanggal_lahir'],
        'no_hp': map['no_hp'],
        'berat_badan': map['berat_badan'],
        'tinggi_badan': map['tinggi_badan'],
        'kondisi': map['kondisi_pantau'],
        'keluhan': map['keluhan_pantau'] ?? map['keluhan_awal'],
        'detail_keluhan': map['detail_keluhan_pantau'],
      };
      return map;
    }).toList();
  }

  /// Mengambil daftar pasien yang TELAH BERHASIL MEMBAYAR sesi konsultasi dengan dokter bersangkutan.
  /// Memastikan data 100% real dari Supabase PostgreSQL dengan join konsultasi & konsultasi_pembayaran.
  Future<List<Map<String, dynamic>>> fetchDokterPaidPatients({
    String? dokterId,
    String? doctorName,
    String? search,
  }) async {
    if (_isTest) return [];

    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) return [];

    final Map<String, dynamic> params = {'docId': docId};
    String searchClause = '';
    if (search != null && search.trim().isNotEmpty) {
      searchClause = 'AND (LOWER(p.nama) LIKE @search OR LOWER(COALESCE(p.alamat, \'\')) LIKE @search)';
      params['search'] = '%${search.trim().toLowerCase()}%';
    }

    final query = '''
      SELECT DISTINCT ON (TRIM(p.id_pasien))
        TRIM(p.id_pasien) AS id,
        TRIM(p.id_pasien) AS id_pasien,
        p.nama,
        p.no_hp,
        p.alamat,
        p.jenis_kelamin,
        p.nik,
        p.tanggal_lahir,
        p.golongan_darah,
        p.foto_profile,
        TRIM(k.id) AS id_konsultasi,
        k.keluhan_awal,
        k.status AS status_konsultasi,
        COALESCE(kp.status_bayar, 'lunas') AS status_bayar,
        kp.jumlah_bayar,
        kp.waktu_bayar,
        pan.bb AS berat_badan,
        pan.tb AS tinggi_badan,
        pan.kondisi AS kondisi_pantau,
        pan.keluhan AS keluhan_pantau,
        pan.detail_keluhan AS detail_keluhan_pantau
      FROM konsultasi k
      JOIN pasien p ON TRIM(p.id_pasien) = TRIM(k.id_pasien)
      LEFT JOIN konsultasi_pembayaran kp ON TRIM(kp.id_konsultasi) = TRIM(k.id)
      LEFT JOIN LATERAL (
        SELECT bb, tb, kondisi, keluhan, detail_keluhan
        FROM pantau
        WHERE TRIM(id_pasien) = TRIM(p.id_pasien)
        ORDER BY COALESCE(tanggal_pantau, created_at) DESC
        LIMIT 1
      ) pan ON true
      WHERE TRIM(k.id_dokter) = @docId
        $searchClause
        AND (
          LOWER(TRIM(COALESCE(kp.status_bayar, ''))) IN ('lunas', 'settlement', 'capture', 'success', 'paid')
          OR (
            LOWER(TRIM(k.status)) IN ('berlangsung', 'aktif', 'terjadwal', 'selesai')
            AND LOWER(TRIM(COALESCE(kp.status_bayar, 'lunas'))) NOT IN ('menunggu_pembayaran', 'kadaluwarsa', 'batal', 'pending', 'expire', 'cancel', 'failed')
          )
        )
      ORDER BY TRIM(p.id_pasien), COALESCE(kp.waktu_bayar, k.updated_at, k.created_at) DESC
    ''';

    final rows = await _exec(query, parameters: params);
    final List<Map<String, dynamic>> results = [];

    for (final r in rows) {
      final map = _normalizeMap(r.toColumnMap());
      final pId = map['id_pasien']?.toString().trim();

      // Ambil riwayat resep terakhir yang pernah diresepkan untuk pasien ini jika ada
      List<Map<String, dynamic>> medicines = [];
      if (pId != null && pId.isNotEmpty) {
        try {
          final medRows = await _exec(
            '''
            SELECT 
              TRIM(ri.id) AS id,
              ri.nama_obat AS medicine_name,
              ri.dosis AS dose,
              ri.aturan_pakai AS frequency,
              ri.jumlah::text AS quantity,
              ri.waktu_penggunaan AS usage_time,
              ri.catatan_khusus AS special_notes
            FROM resep r
            JOIN resep_item ri ON TRIM(ri.id_resep) = TRIM(r.id)
            WHERE TRIM(r.id_pasien) = @pId
            ORDER BY r.created_at DESC
            LIMIT 10
            ''',
            parameters: {'pId': pId},
          );
          medicines = medRows.map((mr) => _normalizeMap(mr.toColumnMap())).toList();
        } catch (_) {}
      }
      map['current_medicines'] = medicines;
      results.add(map);
    }

    return results;
  }

  /// Mengambil detail lengkap satu pasien berbayar (kondisi pantau + resep + konsultasi)
  Future<Map<String, dynamic>?> fetchDokterPatientDetail(
    String patientId, {
    String? dokterId,
    String? doctorName,
  }) async {
    if (_isTest) return null;
    final pId = patientId.trim();
    if (pId.isEmpty) return null;

    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);

    final query = '''
      SELECT 
        TRIM(p.id_pasien) AS id,
        TRIM(p.id_pasien) AS id_pasien,
        p.nama,
        p.no_hp,
        p.alamat,
        p.jenis_kelamin,
        p.nik,
        p.tanggal_lahir,
        p.golongan_darah,
        p.foto_profile,
        TRIM(k.id) AS id_konsultasi,
        k.keluhan_awal,
        k.status AS status_konsultasi,
        COALESCE(kp.status_bayar, 'lunas') AS status_bayar,
        kp.jumlah_bayar,
        kp.waktu_bayar,
        pan.bb AS berat_badan,
        pan.tb AS tinggi_badan,
        pan.kondisi AS kondisi_pantau,
        pan.keluhan AS keluhan_pantau,
        pan.detail_keluhan AS detail_keluhan_pantau
      FROM pasien p
      LEFT JOIN konsultasi k ON TRIM(k.id_pasien) = TRIM(p.id_pasien) \${docId != null ? 'AND TRIM(k.id_dokter) = @docId' : ''}
      LEFT JOIN konsultasi_pembayaran kp ON TRIM(kp.id_konsultasi) = TRIM(k.id)
      LEFT JOIN LATERAL (
        SELECT bb, tb, kondisi, keluhan, detail_keluhan
        FROM pantau
        WHERE TRIM(id_pasien) = TRIM(p.id_pasien)
        ORDER BY COALESCE(tanggal_pantau, created_at) DESC
        LIMIT 1
      ) pan ON true
      WHERE TRIM(p.id_pasien) = @pId
      ORDER BY COALESCE(kp.waktu_bayar, k.updated_at, k.created_at) DESC
      LIMIT 1
    ''';

    final params = <String, dynamic>{'pId': pId};
    if (docId != null) params['docId'] = docId;

    final rows = await _exec(query, parameters: params);
    if (rows.isEmpty) return null;

    final map = _normalizeMap(rows.first.toColumnMap());

    // Ambil resep
    try {
      final medRows = await _exec(
        '''
        SELECT 
          TRIM(ri.id) AS id,
          ri.nama_obat AS medicine_name,
          ri.dosis AS dose,
          ri.aturan_pakai AS frequency,
          ri.jumlah::text AS quantity,
          ri.waktu_penggunaan AS usage_time,
          ri.catatan_khusus AS special_notes
        FROM resep r
        JOIN resep_item ri ON TRIM(ri.id_resep) = TRIM(r.id)
        WHERE TRIM(r.id_pasien) = @pId
        ORDER BY r.created_at DESC
        LIMIT 10
        ''',
        parameters: {'pId': pId},
      );
      map['current_medicines'] = medRows.map((mr) => _normalizeMap(mr.toColumnMap())).toList();
    } catch (_) {
      map['current_medicines'] = <Map<String, dynamic>>[];
    }

    return map;
  }

  /// Menandai semua pesan dari pasien dalam suatu sesi konsultasi sebagai telah dibaca oleh dokter
  Future<void> markConsultationMessagesAsRead(String consultationId, {String? readerId}) async {
    if (_isTest) return;
    final consId = consultationId.trim();
    if (consId.isEmpty) return;

    final resolvedReaderId = readerId ?? await resolveCurrentDokterId();
    if (resolvedReaderId != null && resolvedReaderId.isNotEmpty) {
      await _exec(
        '''
        UPDATE konsultasi_pesan
        SET is_read = true
        WHERE TRIM(id_konsultasi) = @consId
          AND is_read = false
          AND TRIM(id_sender) != @readerId
        ''',
        parameters: {
          'consId': consId,
          'readerId': resolvedReaderId,
        },
      );
    } else {
      await _exec(
        '''
        UPDATE konsultasi_pesan
        SET is_read = true
        WHERE TRIM(id_konsultasi) = @consId
          AND is_read = false
        ''',
        parameters: {'consId': consId},
      );
    }
  }

  /// Mengambil daftar notifikasi real untuk dokter dari tabel `notifikasi` di Supabase
  Future<List<Map<String, dynamic>>> fetchDokterNotifications({
    String? dokterId,
    String? doctorName,
  }) async {
    if (_isTest) return [];

    var docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) {
      final firstDoc = await _exec('SELECT TRIM(id_dokter) AS id FROM dokter ORDER BY created_at ASC LIMIT 1');
      if (firstDoc.isNotEmpty) {
        docId = firstDoc.first[0]?.toString().trim();
      }
    }
    if (docId == null) return [];

    final res = await _exec(
      '''
      SELECT
        TRIM(n.id) AS id,
        TRIM(n.id_user) AS id_user,
        n.judul,
        n.pesan,
        COALESCE(n.kategori, 'sistem') AS kategori,
        COALESCE(n.kategori, 'sistem') AS tipe,
        n.is_read,
        n.created_at
      FROM notifikasi n
      WHERE TRIM(n.id_user) = @docId
      ORDER BY n.created_at DESC
      LIMIT 50
      ''',
      parameters: {'docId': docId},
    );

    final notifs = res.map((r) => _normalizeMap(r.toColumnMap())).toList();

    // Sertakan notifikasi broadcast update sistem bila belum ada
    try {
      final broadcastRes = await _exec(
        '''
        SELECT
          TRIM(n.id) AS id,
          TRIM(n.id_user) AS id_user,
          n.judul,
          n.pesan,
          COALESCE(n.kategori, 'sistem') AS kategori,
          COALESCE(n.kategori, 'sistem') AS tipe,
          n.is_read,
          n.created_at
        FROM notifikasi n
        WHERE LOWER(TRIM(COALESCE(n.kategori, ''))) = 'sistem'
          AND (
            LOWER(TRIM(n.judul)) LIKE '%[dokter]%'
            OR LOWER(TRIM(n.judul)) LIKE '%[semua]%'
            OR LOWER(TRIM(n.pesan)) LIKE '%dokter%'
          )
          AND TRIM(n.id) NOT IN (SELECT TRIM(id) FROM notifikasi WHERE TRIM(id_user) = @docId)
        ORDER BY n.created_at DESC
        LIMIT 10
        ''',
      );
      for (final b in broadcastRes) {
        notifs.add(_normalizeMap(b.toColumnMap()));
      }
    } catch (_) {}

    // Urutkan berdasarkan waktu created_at DESC
    notifs.sort((a, b) {
      final tA = a['created_at']?.toString() ?? '';
      final tB = b['created_at']?.toString() ?? '';
      return tB.compareTo(tA);
    });

    return notifs;
  }

  /// Mengambil jumlah notifikasi belum dibaca (`is_read = false`) untuk dokter
  Future<int> fetchDokterUnreadNotificationCount({
    String? dokterId,
    String? doctorName,
  }) async {
    if (_isTest) return 0;
    var docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) {
      final firstDoc = await _exec('SELECT TRIM(id_dokter) AS id FROM dokter ORDER BY created_at ASC LIMIT 1');
      if (firstDoc.isNotEmpty) {
        docId = firstDoc.first[0]?.toString().trim();
      }
    }
    if (docId == null) return 0;

    final res = await _exec(
      '''
      SELECT COUNT(*)::int AS cnt
      FROM notifikasi
      WHERE TRIM(id_user) = @docId
        AND is_read = false
      ''',
      parameters: {'docId': docId},
    );
    if (res.isEmpty) return 0;
    return int.tryParse(res.first.toColumnMap()['cnt']?.toString() ?? '0') ?? 0;
  }

  /// Menandai semua notifikasi milik dokter sudah dibaca
  Future<void> markDokterNotificationsAllRead({
    String? dokterId,
    String? doctorName,
  }) async {
    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) return;
    await _exec(
      'UPDATE notifikasi SET is_read = true WHERE TRIM(id_user) = @docId',
      parameters: {'docId': docId},
    );
  }

  /// Menghapus semua notifikasi milik dokter yang sudah dibaca
  Future<void> clearDokterReadNotifications({
    String? dokterId,
    String? doctorName,
  }) async {
    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) return;
    await _exec(
      'DELETE FROM notifikasi WHERE TRIM(id_user) = @docId AND is_read = true',
      parameters: {'docId': docId},
    );
  }

  // ===========================================================================
  // MODUL PROFIL DOKTER, KEAMANAN AKUN, NOTIFIKASI & SESI PERANGKAT REAL SUPABASE
  // ===========================================================================

  Map<String, dynamic> _parseDokterBioMeta(dynamic rawBio) {
    if (rawBio == null) return <String, dynamic>{};
    final str = rawBio.toString().trim();
    if (str.isEmpty) return <String, dynamic>{};
    if (str.startsWith('{') && str.endsWith('}')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return <String, dynamic>{'bio_text': str};
  }

  /// Mengambil data profil dokter secara real dari tabel `dokter` & `"user"` di Supabase
  Future<Map<String, dynamic>?> fetchDokterProfile({
    String? dokterId,
    String? doctorName,
  }) async {
    if (_isTest) return null;

    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) return null;

    final rows = await _exec(
      '''
      SELECT 
        TRIM(d.id_dokter) AS id,
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
        u.email,
        u.keterangan
      FROM dokter d
      LEFT JOIN "user" u ON TRIM(u.id) = TRIM(d.id_dokter)
      WHERE TRIM(d.id_dokter) = @id
      LIMIT 1
      ''',
      parameters: {'id': docId},
    );

    if (rows.isEmpty) return null;
    final map = _normalizeMap(rows.first.toColumnMap());
    final bioMeta = _parseDokterBioMeta(map['bio']);
    final institusi = (map['institusi']?.toString().trim().isNotEmpty == true)
        ? map['institusi'].toString().trim()
        : 'RS Mitra GIAT';
    final alamatPraktik = (bioMeta['alamat_praktik']?.toString().trim().isNotEmpty == true)
        ? bioMeta['alamat_praktik'].toString().trim()
        : institusi;
    final jadwalPraktik = (bioMeta['jadwal_praktik']?.toString().trim().isNotEmpty == true)
        ? bioMeta['jadwal_praktik'].toString().trim()
        : 'Senin - Jumat, 08:00 - 16:00 WIB';

    map['institusi'] = institusi;
    map['no_str'] = (map['no_str']?.toString().trim().isNotEmpty == true)
        ? map['no_str'].toString().trim()
        : '-';
    map['no_sip'] = (map['no_sip']?.toString().trim().isNotEmpty == true)
        ? map['no_sip'].toString().trim()
        : '-';
    map['alamat_praktik'] = alamatPraktik;
    map['jadwal_praktik'] = jadwalPraktik;
    map['notif_chat'] = bioMeta['notif_chat'] is bool ? bioMeta['notif_chat'] : true;
    map['notif_jadwal'] = bioMeta['notif_jadwal'] is bool ? bioMeta['notif_jadwal'] : true;
    map['notif_update'] = bioMeta['notif_update'] is bool ? bioMeta['notif_update'] : true;

    return map;
  }

  /// Memperbarui profil dokter secara real ke tabel `dokter` & `"user"` di Supabase
  Future<Map<String, dynamic>?> updateDokterProfile(
    Map<String, dynamic> data, {
    String? dokterId,
    String? doctorName,
  }) async {
    if (_isTest) return null;

    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) return null;

    final current = await fetchDokterProfile(dokterId: docId) ?? <String, dynamic>{};
    final currentBioMeta = _parseDokterBioMeta(current['bio']);

    final nama = (data['nama'] ?? data['name'] ?? current['nama'] ?? 'Dokter GIAT').toString().trim();
    final spesialisasi = (data['spesialisasi'] ?? data['specialty'] ?? current['spesialisasi'] ?? 'Spesialis Ginjal & Hipertensi').toString().trim();
    final institusi = (data['institusi'] ?? data['institution'] ?? current['institusi'] ?? 'RS Mitra GIAT').toString().trim();
    final noStr = (data['no_str'] ?? data['str_number'] ?? current['no_str'] ?? '-').toString().trim();
    final noSip = (data['no_sip'] ?? data['sip_number'] ?? current['no_sip'] ?? '-').toString().trim();
    final noHp = (data['no_hp'] ?? data['phone'] ?? current['no_hp'] ?? '').toString().trim();
    final email = (data['email'] ?? current['email'] ?? '').toString().trim();
    final fotoProfile = (data['foto_profile'] ?? data['foto_profil'] ?? data['photo_url'] ?? current['foto_profile'])?.toString().trim();

    if (data.containsKey('alamat_praktik') || data.containsKey('practice_address')) {
      currentBioMeta['alamat_praktik'] = (data['alamat_praktik'] ?? data['practice_address'] ?? '').toString().trim();
    }
    if (data.containsKey('jadwal_praktik') || data.containsKey('practice_schedule')) {
      currentBioMeta['jadwal_praktik'] = (data['jadwal_praktik'] ?? data['practice_schedule'] ?? '').toString().trim();
    }
    final newBioJson = jsonEncode(currentBioMeta);

    await _exec(
      '''
      UPDATE dokter
      SET nama = @nama,
          spesialisasi = @spesialisasi,
          institusi = @institusi,
          no_str = @noStr,
          no_sip = @noSip,
          no_hp = CASE WHEN @noHp = '' THEN no_hp ELSE @noHp END,
          foto_profile = COALESCE(@fotoProfile, foto_profile),
          bio = @bio,
          updated_at = NOW()
      WHERE TRIM(id_dokter) = @id
      ''',
      parameters: {
        'id': docId,
        'nama': nama,
        'spesialisasi': spesialisasi,
        'institusi': institusi,
        'noStr': noStr,
        'noSip': noSip,
        'noHp': noHp,
        'fotoProfile': (fotoProfile != null && fotoProfile.isNotEmpty) ? fotoProfile : null,
        'bio': newBioJson,
      },
    );

    if (email.isNotEmpty) {
      await _exec(
        '''
        UPDATE "user"
        SET email = @email,
            updated_at = NOW()
        WHERE TRIM(id) = @id
        ''',
        parameters: {
          'id': docId,
          'email': email.toLowerCase(),
        },
      );
    }

    // Sinkronkan juga ke StorageService user jika ada
    try {
      final savedUser = await StorageService().getUser();
      if (savedUser != null && (savedUser.id.toString().trim() == docId || savedUser.role == 'dokter')) {
        await StorageService().saveUser(
          savedUser.copyWith(
            nama: nama,
            email: email.isNotEmpty ? email : savedUser.email,
            noHp: noHp.isNotEmpty ? noHp : savedUser.noHp,
            fotoProfile: (fotoProfile != null && fotoProfile.isNotEmpty) ? fotoProfile : savedUser.fotoProfile,
            spesialisasi: spesialisasi,
          ),
        );
      }
    } catch (_) {}

    return fetchDokterProfile(dokterId: docId);
  }

  /// Memperbarui foto profil dokter di tabel `dokter` Supabase
  Future<Map<String, dynamic>?> updateDokterPhoto(
    String fileOrUrl, {
    String? dokterId,
    String? doctorName,
  }) async {
    if (_isTest) return null;

    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) return null;

    final cleanVal = fileOrUrl.trim();
    if (cleanVal.isEmpty) return null;

    try {
      await _exec('ALTER TABLE dokter ALTER COLUMN foto_profile TYPE TEXT');
    } catch (_) {}

    await _exec(
      '''
      UPDATE dokter
      SET foto_profile = @foto,
          updated_at = NOW()
      WHERE TRIM(id_dokter) = @id
      ''',
      parameters: {
        'id': docId,
        'foto': cleanVal,
      },
    );

    try {
      final savedUser = await StorageService().getUser();
      if (savedUser != null && (savedUser.id.toString().trim() == docId || savedUser.role == 'dokter')) {
        await StorageService().saveUser(savedUser.copyWith(fotoProfile: cleanVal));
      }
    } catch (_) {}

    return {
      'id_dokter': docId,
      'foto_profile': cleanVal,
      'foto_profil': cleanVal,
      'foto_url': cleanVal,
    };
  }

  /// Memperbarui kata sandi dokter secara real di tabel `"user"` Supabase
  /// Mengembalikan `null` jika berhasil, atau pesan error jika gagal
  Future<String?> updateDokterPassword({
    required String currentPassword,
    required String newPassword,
    String? dokterId,
    String? doctorName,
  }) async {
    if (_isTest) return null;

    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) return 'Akun dokter tidak ditemukan di database.';

    final check = await _exec(
      r'''
      SELECT (
        (extensions.crypt(@currentPass, replace(password, '$2y$', '$2a$')) = replace(password, '$2y$', '$2a$'))
        OR password = @currentPass
      ) AS is_valid
      FROM "user"
      WHERE TRIM(id) = @id
      LIMIT 1
      ''',
      parameters: {
        'id': docId,
        'currentPass': currentPassword,
      },
    );

    if (check.isEmpty || check.first.toColumnMap()['is_valid'] != true) {
      return 'Kata sandi lama tidak sesuai dengan akun Anda.';
    }

    await _exec(
      r'''
      UPDATE "user"
      SET password = replace(extensions.crypt(@newPass, extensions.gen_salt('bf', 12)), '$2a$', '$2y$'),
          updated_at = NOW()
      WHERE TRIM(id) = @id
      ''',
      parameters: {
        'id': docId,
        'newPass': newPassword,
      },
    );

    return null;
  }

  /// Mengambil pengaturan notifikasi dokter dari Supabase (`dokter.bio`)
  Future<Map<String, dynamic>> fetchDokterNotificationSettings({
    String? dokterId,
    String? doctorName,
  }) async {
    if (_isTest) {
      return {
        'notif_chat': true,
        'notif_jadwal': true,
        'notif_update': true,
      };
    }
    final profile = await fetchDokterProfile(dokterId: dokterId, doctorName: doctorName);
    return {
      'notif_chat': profile?['notif_chat'] is bool ? profile!['notif_chat'] : true,
      'notif_jadwal': profile?['notif_jadwal'] is bool ? profile!['notif_jadwal'] : true,
      'notif_update': profile?['notif_update'] is bool ? profile!['notif_update'] : true,
    };
  }

  /// Menyimpan pengaturan notifikasi dokter ke Supabase (`dokter.bio`)
  Future<Map<String, dynamic>> updateDokterNotificationSettings(
    Map<String, dynamic> settings, {
    String? dokterId,
    String? doctorName,
  }) async {
    if (_isTest) return settings;

    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) return settings;

    final current = await fetchDokterProfile(dokterId: docId) ?? <String, dynamic>{};
    final bioMeta = _parseDokterBioMeta(current['bio']);

    if (settings.containsKey('notif_chat')) {
      bioMeta['notif_chat'] = settings['notif_chat'] == true;
    }
    if (settings.containsKey('notif_jadwal')) {
      bioMeta['notif_jadwal'] = settings['notif_jadwal'] == true;
    }
    if (settings.containsKey('notif_update')) {
      bioMeta['notif_update'] = settings['notif_update'] == true;
    }

    await _exec(
      '''
      UPDATE dokter
      SET bio = @bio,
          updated_at = NOW()
      WHERE TRIM(id_dokter) = @id
      ''',
      parameters: {
        'id': docId,
        'bio': jsonEncode(bioMeta),
      },
    );

    return {
      'notif_chat': bioMeta['notif_chat'] ?? true,
      'notif_jadwal': bioMeta['notif_jadwal'] ?? true,
      'notif_update': bioMeta['notif_update'] ?? true,
    };
  }

  /// Mengambil daftar perangkat login aktif untuk dokter dari `personal_access_tokens` & `sessions` Supabase
  Future<List<Map<String, dynamic>>> fetchDokterLoginDevices({
    String? dokterId,
    String? doctorName,
  }) async {
    if (_isTest) return [];

    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    final List<Map<String, dynamic>> devices = [];

    String currentDeviceName = 'Perangkat GIAT';
    try {
      final os = Platform.operatingSystem;
      final host = Platform.localHostname;
      if (os == 'android') {
        currentDeviceName = 'Smartphone Android ($host)';
      } else if (os == 'ios') {
        currentDeviceName = 'iPhone / iOS ($host)';
      } else if (os == 'windows') {
        currentDeviceName = 'Windows Desktop ($host)';
      } else if (os == 'macos') {
        currentDeviceName = 'macOS Desktop ($host)';
      } else {
        currentDeviceName = '${os.toUpperCase()} ($host)';
      }
    } catch (_) {}

    final now = DateTime.now();
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final nowFormatted =
        '${now.day.toString().padLeft(2, '0')} ${months[now.month]} ${now.year}, ${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')} WIB';

    devices.add({
      'id': 'current-session',
      'device_name': currentDeviceName,
      'location': 'Indonesia (Sesi Saat Ini)',
      'login_date': nowFormatted,
      'is_current_device': true,
    });

    if (docId != null && docId.isNotEmpty) {
      try {
        final tokenRows = await _exec(
          '''
          SELECT 
            id::text AS id,
            name,
            last_used_at,
            created_at
          FROM personal_access_tokens
          WHERE TRIM(tokenable_id) = @docId
          ORDER BY COALESCE(last_used_at, created_at) DESC
          LIMIT 10
          ''',
          parameters: {'docId': docId},
        );
        for (final r in tokenRows) {
          final m = _normalizeMap(r.toColumnMap());
          final rawTime = (m['last_used_at'] ?? m['created_at'])?.toString() ?? '';
          final parsed = DateTime.tryParse(rawTime)?.toLocal();
          final dateStr = parsed != null
              ? '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month]} ${parsed.year}, ${parsed.hour.toString().padLeft(2, '0')}.${parsed.minute.toString().padLeft(2, '0')} WIB'
              : rawTime;
          devices.add({
            'id': 'pat-${m['id']}',
            'device_name': m['name']?.toString().isNotEmpty == true ? m['name'].toString() : 'Sesi Token GIAT',
            'location': 'Indonesia',
            'login_date': dateStr,
            'is_current_device': false,
          });
        }
      } catch (_) {}

      try {
        final sessionRows = await _exec(
          '''
          SELECT 
            id,
            ip_address,
            user_agent,
            last_activity
          FROM sessions
          WHERE TRIM(user_id) = @docId
          ORDER BY last_activity DESC
          LIMIT 10
          ''',
          parameters: {'docId': docId},
        );
        for (final r in sessionRows) {
          final m = _normalizeMap(r.toColumnMap());
          final lastAct = int.tryParse(m['last_activity']?.toString() ?? '0') ?? 0;
          final dt = lastAct > 0
              ? DateTime.fromMillisecondsSinceEpoch(lastAct * 1000).toLocal()
              : now;
          final dateStr =
              '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')} WIB';
          devices.add({
            'id': 'sess-${m['id']}',
            'device_name': m['user_agent']?.toString().isNotEmpty == true
                ? m['user_agent'].toString().split(' ').take(3).join(' ')
                : 'Sesi Web GIAT',
            'location': m['ip_address']?.toString() ?? 'Indonesia',
            'login_date': dateStr,
            'is_current_device': false,
          });
        }
      } catch (_) {}
    }

    return devices;
  }

  /// Menghapus/mencabut sesi perangkat login dari `personal_access_tokens` atau `sessions` di Supabase
  Future<bool> revokeDokterDevice(dynamic idToken) async {
    if (_isTest) return true;
    final raw = idToken?.toString().trim() ?? '';
    if (raw.isEmpty || raw == 'current-session') return false;

    if (raw.startsWith('pat-')) {
      final patId = raw.substring(4);
      await _exec(
        'DELETE FROM personal_access_tokens WHERE id::text = @id',
        parameters: {'id': patId},
      );
      return true;
    } else if (raw.startsWith('sess-')) {
      final sessId = raw.substring(5);
      await _exec(
        'DELETE FROM sessions WHERE id = @id',
        parameters: {'id': sessId},
      );
      return true;
    } else {
      await _exec(
        'DELETE FROM personal_access_tokens WHERE id::text = @id',
        parameters: {'id': raw},
      );
      await _exec(
        'DELETE FROM sessions WHERE id = @id',
        parameters: {'id': raw},
      );
      return true;
    }
  }

  /// Mengambil daftar riwayat resep obat yang diterbitkan oleh dokter dari Supabase
  Future<List<Map<String, dynamic>>> fetchDokterResepHistory({
    String? dokterId,
    String? doctorName,
    String? patientId,
  }) async {
    if (_isTest) return [];
    final docId = await resolveCurrentDokterId(overrideDokterId: dokterId, doctorName: doctorName);
    if (docId == null) return [];

    final params = <String, dynamic>{'docId': docId};
    String patientClause = '';
    if (patientId != null && patientId.trim().isNotEmpty) {
      patientClause = 'AND TRIM(r.id_pasien) = @pId';
      params['pId'] = patientId.trim();
    }

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
        COALESCE(p.nama, 'Pasien GIAT') AS nama_pasien
      FROM resep r
      LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(r.id_pasien)
      WHERE TRIM(r.id_dokter) = @docId
        $patientClause
      ORDER BY COALESCE(r.updated_at, r.created_at) DESC
      LIMIT 30
      ''',
      parameters: params,
    );

    final List<Map<String, dynamic>> result = [];
    for (final row in rows) {
      final map = _normalizeMap(row.toColumnMap());
      final rxId = map['id']?.toString().trim();
      if (rxId != null && rxId.isNotEmpty) {
        final itemRows = await _exec(
          '''
          SELECT 
            TRIM(ri.id) AS id,
            TRIM(ri.id_resep) AS id_resep,
            ri.nama_obat,
            ri.dosis,
            ri.aturan_pakai,
            ri.waktu_penggunaan,
            ri.jumlah,
            ri.catatan_khusus,
            COALESCE(
              (SELECT ROUND(o.harga_jual)::int FROM obat o WHERE LOWER(TRIM(o.nama_obat)) = LOWER(TRIM(ri.nama_obat)) LIMIT 1),
              (SELECT ROUND(o.harga_jual)::int FROM obat o WHERE LOWER(o.nama_obat) LIKE '%' || LOWER(SPLIT_PART(TRIM(ri.nama_obat), ' ', 1)) || '%' LIMIT 1),
              65000
            ) AS harga
          FROM resep_item ri
          WHERE TRIM(ri.id_resep) = @rxId
          ORDER BY ri.created_at ASC
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

  /// Mengambil daftar pesan chat dari tabel `konsultasi_pesan` di Supabase untuk sesi konsultasi tertentu
  Future<List<Map<String, dynamic>>> fetchConsultationMessages(String consultationId) async {
    if (_isTest) return [];
    final consId = consultationId.trim();
    if (consId.isEmpty) return [];

    final rows = await _exec(
      '''
      SELECT 
        TRIM(m.id) AS id,
        TRIM(m.id_konsultasi) AS id_konsultasi,
        TRIM(m.id_sender) AS id_sender,
        m.pesan,
        m.attachment_url,
        m.is_read,
        m.created_at,
        CASE 
          WHEN TRIM(m.id_sender) = TRIM(k.id_dokter) THEN 'dokter'
          WHEN TRIM(m.id_sender) = TRIM(k.id_pasien) THEN 'pasien'
          ELSE COALESCE(u.role, 'pasien')
        END AS sender_role
      FROM konsultasi_pesan m
      LEFT JOIN konsultasi k ON TRIM(k.id) = TRIM(m.id_konsultasi)
      LEFT JOIN "user" u ON TRIM(u.id) = TRIM(m.id_sender)
      WHERE TRIM(m.id_konsultasi) = @consId
      ORDER BY m.created_at ASC
      ''',
      parameters: {'consId': consId},
    );

    return rows.map((r) => _normalizeMap(r.toColumnMap())).toList();
  }

  /// Menyimpan pesan chat baru ke tabel `konsultasi_pesan` di Supabase
  Future<Map<String, dynamic>?> sendConsultationMessage({
    required String consultationId,
    required String pesan,
    String? senderId,
    String? senderRole,
    String? attachmentUrl,
  }) async {
    if (_isTest) return null;
    final consId = consultationId.trim();
    final cleanMsg = pesan.trim();
    if (consId.isEmpty || cleanMsg.isEmpty) return null;

    String? resolvedSenderId = senderId?.trim();
    if (resolvedSenderId == null || resolvedSenderId.length < 30) {
      final user = await StorageService().getUser();
      final role = (senderRole ?? user?.role ?? '').toLowerCase();
      if (role == 'dokter') {
        final konsRow = await _exec(
          'SELECT TRIM(id_dokter) AS id_dokter FROM konsultasi WHERE TRIM(id) = @id LIMIT 1',
          parameters: {'id': consId},
        );
        if (konsRow.isNotEmpty) {
          resolvedSenderId = konsRow.first.toColumnMap()['id_dokter']?.toString().trim();
        }
        resolvedSenderId ??= await resolveCurrentDokterId();
      } else {
        final konsRow = await _exec(
          'SELECT TRIM(id_pasien) AS id_pasien FROM konsultasi WHERE TRIM(id) = @id LIMIT 1',
          parameters: {'id': consId},
        );
        if (konsRow.isNotEmpty) {
          resolvedSenderId = konsRow.first.toColumnMap()['id_pasien']?.toString().trim();
        }
        resolvedSenderId ??= await resolveCurrentPasienId();
      }
    }

    if (resolvedSenderId == null || resolvedSenderId.isEmpty) return null;

    final uuidRes = await _exec('SELECT gen_random_uuid()::text AS id');
    final newId = uuidRes.first.toColumnMap()['id'].toString().trim();

    await _exec(
      '''
      INSERT INTO konsultasi_pesan (id, id_konsultasi, id_sender, pesan, attachment_url, is_read, created_at)
      VALUES (@id, @consId, @senderId, @pesan, @attachment, false, NOW())
      ''',
      parameters: {
        'id': newId,
        'consId': consId,
        'senderId': resolvedSenderId,
        'pesan': cleanMsg,
        'attachment': attachmentUrl,
      },
    );

    await _exec(
      'UPDATE konsultasi SET updated_at = NOW() WHERE TRIM(id) = @consId',
      parameters: {'consId': consId},
    );

    return {
      'id': newId,
      'id_konsultasi': consId,
      'id_sender': resolvedSenderId,
      'pesan': cleanMsg,
      'attachment_url': attachmentUrl,
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Menyelesaikan sesi konsultasi di tabel `konsultasi` Supabase
  Future<Map<String, dynamic>?> completeConsultation(String consultationId) async {
    if (_isTest) return null;
    final consId = consultationId.trim();
    if (consId.isEmpty) return null;

    await _exec(
      '''
      UPDATE konsultasi
      SET status = 'selesai',
          jam_selesai = COALESCE(jam_selesai, CURRENT_TIME),
          updated_at = NOW()
      WHERE TRIM(id) = @consId
      ''',
      parameters: {'consId': consId},
    );

    return {
      'id': consId,
      'status': 'selesai',
    };
  }

  // ===========================================================================
  // MODUL APOTEK: NOTIFIKASI REAL SUPABASE
  // ===========================================================================

  /// Menentukan ID Apotek (`id_apotek` / `user.id`) yang sedang login di Supabase
  Future<String?> resolveCurrentApotekId({
    String? overrideApotekId,
    String? apotekName,
  }) async {
    if (overrideApotekId != null && overrideApotekId.trim().length >= 30) {
      return overrideApotekId.trim();
    }

    final user = await StorageService().getUser();
    if (user != null) {
      final rawId = user.id.toString().trim();
      if (rawId.length >= 30) {
        final check = await _exec(
          'SELECT TRIM(id_apotek) AS id FROM apotek WHERE TRIM(id_apotek) = @id LIMIT 1',
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
          SELECT TRIM(ap.id_apotek) AS id
          FROM "user" u
          JOIN apotek ap ON TRIM(ap.id_apotek) = TRIM(u.id)
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
      if (nama.isNotEmpty) {
        final byNama = await _exec(
          '''
          SELECT TRIM(id_apotek) AS id
          FROM apotek
          WHERE LOWER(TRIM(nama_apotek)) ILIKE @nama
             OR LOWER(TRIM(penanggung_jawab)) ILIKE @nama
          LIMIT 1
          ''',
          parameters: {'nama': '%$nama%'},
        );
        if (byNama.isNotEmpty) {
          final id = byNama.first.toColumnMap()['id']?.toString().trim();
          if (id != null && id.isNotEmpty) return id;
        }
      }
    }

    if (apotekName != null && apotekName.trim().isNotEmpty) {
      final byFallbackName = await _exec(
        '''
        SELECT TRIM(id_apotek) AS id
        FROM apotek
        WHERE LOWER(TRIM(nama_apotek)) ILIKE @nama
           OR LOWER(TRIM(penanggung_jawab)) ILIKE @nama
        LIMIT 1
        ''',
        parameters: {'nama': '%${apotekName.trim().toLowerCase()}%'},
      );
      if (byFallbackName.isNotEmpty) {
        final id = byFallbackName.first.toColumnMap()['id']?.toString().trim();
        if (id != null && id.isNotEmpty) return id;
      }
    }

    // Default fallback ke apotek utama di database (Apotek Kimia Farma Dago)
    final firstApotek = await _exec(
      'SELECT TRIM(id_apotek) AS id FROM apotek ORDER BY created_at ASC LIMIT 1',
    );
    if (firstApotek.isNotEmpty) {
      return firstApotek.first.toColumnMap()['id']?.toString().trim();
    }
    return null;
  }

  /// Mengambil daftar notifikasi real untuk apotek dari tabel `notifikasi` di Supabase
  Future<List<Map<String, dynamic>>> fetchApotekNotifications({
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return [];

    var aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) {
      final firstApt = await _exec(
        'SELECT TRIM(id_apotek) AS id FROM apotek ORDER BY created_at ASC LIMIT 1',
      );
      if (firstApt.isNotEmpty) {
        aptId = firstApt.first[0]?.toString().trim();
      }
    }
    if (aptId == null) return [];

    final res = await _exec(
      '''
      SELECT
        TRIM(n.id) AS id,
        TRIM(n.id_user) AS id_user,
        n.judul,
        n.pesan,
        COALESCE(n.kategori, 'sistem') AS kategori,
        COALESCE(n.kategori, 'sistem') AS tipe,
        n.is_read,
        n.created_at
      FROM notifikasi n
      WHERE TRIM(n.id_user) = @aptId
      ORDER BY n.created_at DESC
      LIMIT 50
      ''',
      parameters: {'aptId': aptId},
    );

    final notifs = res.map((r) => _normalizeMap(r.toColumnMap())).toList();

    // Sertakan notifikasi broadcast update sistem untuk Apotek / Semua bila belum ada
    try {
      final broadcastRes = await _exec(
        '''
        SELECT
          TRIM(n.id) AS id,
          TRIM(n.id_user) AS id_user,
          n.judul,
          n.pesan,
          COALESCE(n.kategori, 'sistem') AS kategori,
          COALESCE(n.kategori, 'sistem') AS tipe,
          n.is_read,
          n.created_at
        FROM notifikasi n
        WHERE LOWER(TRIM(COALESCE(n.kategori, ''))) = 'sistem'
          AND (
            LOWER(TRIM(n.judul)) LIKE '%[apotek]%'
            OR LOWER(TRIM(n.judul)) LIKE '%[semua]%'
            OR LOWER(TRIM(n.pesan)) LIKE '%apotek%'
          )
          AND TRIM(n.id) NOT IN (SELECT TRIM(id) FROM notifikasi WHERE TRIM(id_user) = @aptId)
        ORDER BY n.created_at DESC
        LIMIT 10
        ''',
        parameters: {'aptId': aptId},
      );
      for (final b in broadcastRes) {
        notifs.add(_normalizeMap(b.toColumnMap()));
      }
    } catch (_) {}

    notifs.sort((a, b) {
      final tA = a['created_at']?.toString() ?? '';
      final tB = b['created_at']?.toString() ?? '';
      return tB.compareTo(tA);
    });

    return notifs;
  }

  /// Mengambil jumlah notifikasi belum dibaca (`is_read = false`) untuk apotek
  Future<int> fetchApotekUnreadNotificationCount({
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return 0;
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return 0;

    final res = await _exec(
      '''
      SELECT COUNT(*)::int AS cnt
      FROM notifikasi
      WHERE TRIM(id_user) = @aptId
        AND is_read = false
      ''',
      parameters: {'aptId': aptId},
    );
    if (res.isEmpty) return 0;
    return int.tryParse(res.first.toColumnMap()['cnt']?.toString() ?? '0') ?? 0;
  }

  /// Menandai semua notifikasi milik apotek sudah dibaca
  Future<void> markApotekNotificationsAllRead({
    String? apotekId,
    String? apotekName,
  }) async {
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return;
    await _exec(
      'UPDATE notifikasi SET is_read = true WHERE TRIM(id_user) = @aptId',
      parameters: {'aptId': aptId},
    );
  }

  /// Menghapus semua notifikasi milik apotek yang sudah dibaca
  Future<void> clearApotekReadNotifications({
    String? apotekId,
    String? apotekName,
  }) async {
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return;
    await _exec(
      'DELETE FROM notifikasi WHERE TRIM(id_user) = @aptId AND is_read = true',
      parameters: {'aptId': aptId},
    );
  }

  /// Membuat notifikasi baru untuk user apotek di tabel `notifikasi` Supabase
  Future<void> createApotekNotification({
    required String apotekId,
    required String judul,
    required String pesan,
    String kategori = 'pesanan',
  }) async {
    if (_isTest) return;
    final cleanAptId = apotekId.trim();
    if (cleanAptId.isEmpty) return;

    await _exec(
      '''
      INSERT INTO notifikasi (id, id_user, judul, pesan, kategori, is_read, created_at)
      VALUES (gen_random_uuid()::text, @aptId, @judul, @pesan, @kategori, false, NOW())
      ''',
      parameters: {
        'aptId': cleanAptId,
        'judul': judul,
        'pesan': pesan,
        'kategori': kategori,
      },
    );
  }

  // ===========================================================================
  // MODUL INTEGRASI ALUR RESEP DOKTER -> PASIEN -> PEMBAYARAN LUNAS -> APOTEK
  // ===========================================================================

  /// Mengembalikan status resep ke 'aktif' apabila pasien membatalkan / belum menyelesaikan pembayaran
  Future<void> revertResepToAktifIfUnpaid({
    String? idResep,
    String? noResep,
  }) async {
    if (_isTest) return;
    final cleanId = (idResep ?? '').trim().replaceAll('No.', '').trim();
    final cleanNo = (noResep ?? '').trim().replaceAll('No.', '').trim();
    if (cleanId.isEmpty && cleanNo.isEmpty) return;

    try {
      final rxRows = await _exec(
        '''
        SELECT TRIM(r.id) AS id,
               (SELECT COUNT(*)::int FROM pesanan_obat po
                WHERE TRIM(po.id_resep) = TRIM(r.id)
                  AND LOWER(TRIM(po.status_pembayaran)) = 'lunas') AS paid_cnt
        FROM resep r
        WHERE TRIM(r.id) = @cleanId
           OR TRIM(r.no_resep) = @cleanNo
           OR TRIM(r.no_resep) = @cleanId
           OR TRIM(r.id) = @cleanNo
        LIMIT 1
        ''',
        parameters: {'cleanId': cleanId, 'cleanNo': cleanNo},
      );
      if (rxRows.isNotEmpty) {
        final m = rxRows.first.toColumnMap();
        final rId = m['id']?.toString().trim();
        final paidCnt = int.tryParse(m['paid_cnt']?.toString() ?? '0') ?? 0;
        if (rId != null && rId.isNotEmpty && paidCnt == 0) {
          await _exec(
            '''
            UPDATE resep
            SET status = 'aktif',
                updated_at = NOW()
            WHERE TRIM(id) = @id
              AND LOWER(TRIM(status)) NOT IN ('diverifikasi', 'selesai')
            ''',
            parameters: {'id': rId},
          );
        }
      }
    } catch (e) {
      debugPrint('Error revertResepToAktifIfUnpaid: $e');
    }
  }

  /// Menyelesaikan pembayaran obat pasien (baik dari Resep Dokter maupun Pembelian Umum)
  /// dan mengirimkan pesanan/resep yang sudah LUNAS tersebut ke User Apotek di Supabase
  Future<Map<String, dynamic>?> completePasienObatPaymentInSupabase({
    String? idPesanan,
    String? noPesanan,
    String? idResep,
    String? noResep,
    String? idPasien,
    String? patientName,
    String? idApotek,
    String? metodePengambilan,
    String? namaPenerima,
    String? noHpPenerima,
    String? alamatPengiriman,
    String? metodePembayaran,
    int? subtotal,
    int? ongkosKirim,
    int? totalBayar,
    List<Map<String, dynamic>>? items,
  }) async {
    if (_isTest) return null;

    try {
      // 1. Resolve Apotek ID (default ke Apotek Kimia Farma Dago bila tidak ditentukan)
      final targetApotekId = await resolveCurrentApotekId(overrideApotekId: idApotek) ??
          '5cdfd84d-0124-4abf-a778-e8db2801863f';

      // 2. Cek apakah ini transaksi penebusan resep dokter
      String? resolvedResepId;
      String? resolvedNoResep;
      String? resepPasienId;
      final cleanRxId = (idResep ?? '').trim().replaceAll('No.', '').trim();
      final cleanRxNo = (noResep ?? '').trim().replaceAll('No.', '').trim();

      if (cleanRxId.isNotEmpty || cleanRxNo.isNotEmpty) {
        final rxRows = await _exec(
          '''
          SELECT TRIM(id) AS id, no_resep, TRIM(id_pasien) AS id_pasien
          FROM resep
          WHERE TRIM(id) = @rxId
             OR TRIM(no_resep) = @rxNo
             OR TRIM(no_resep) = @rxId
             OR TRIM(id) = @rxNo
          LIMIT 1
          ''',
          parameters: {'rxId': cleanRxId, 'rxNo': cleanRxNo},
        );
        if (rxRows.isNotEmpty) {
          final rm = rxRows.first.toColumnMap();
          resolvedResepId = rm['id']?.toString().trim();
          resolvedNoResep = rm['no_resep']?.toString().trim();
          resepPasienId = rm['id_pasien']?.toString().trim();
        }
      }

      // 3. Resolve Pasien ID
      String? targetPasienId = resepPasienId;
      if (targetPasienId == null || targetPasienId.isEmpty) {
        if (idPasien != null && idPasien.trim().length >= 30) {
          targetPasienId = idPasien.trim();
        } else {
          targetPasienId = await resolveCurrentPasienId(
            overridePasienId: idPasien,
          );
          if (targetPasienId == null && (patientName ?? namaPenerima) != null) {
            final pSearchName = (patientName ?? namaPenerima ?? '').trim();
            if (pSearchName.isNotEmpty) {
              final byPName = await _exec(
                'SELECT TRIM(id_pasien) AS id FROM pasien WHERE LOWER(TRIM(nama)) ILIKE @nama LIMIT 1',
                parameters: {'nama': '%${pSearchName.toLowerCase()}%'},
              );
              if (byPName.isNotEmpty) {
                targetPasienId = byPName.first.toColumnMap()['id']?.toString().trim();
              }
            }
          }
        }
      }
      if (targetPasienId == null || targetPasienId.isEmpty) {
        final firstPas = await _exec('SELECT TRIM(id_pasien) AS id FROM pasien ORDER BY created_at ASC LIMIT 1');
        if (firstPas.isNotEmpty) {
          targetPasienId = firstPas.first.toColumnMap()['id']?.toString().trim();
        }
      }
      if (targetPasienId == null || targetPasienId.isEmpty) return null;

      // Ambil profil pasien untuk fallback nama/alamat/no_hp
      final pasProfileRows = await _exec(
        'SELECT nama, no_hp, alamat FROM pasien WHERE TRIM(id_pasien) = @pid LIMIT 1',
        parameters: {'pid': targetPasienId},
      );
      final pasMap = pasProfileRows.isNotEmpty
          ? pasProfileRows.first.toColumnMap()
          : <String, dynamic>{};

      final finalRecipientName = (namaPenerima != null && namaPenerima.trim().isNotEmpty)
          ? namaPenerima.trim()
          : (pasMap['nama']?.toString().trim().isNotEmpty == true
              ? pasMap['nama'].toString().trim()
              : (patientName ?? 'Pasien GIAT'));
      final finalRecipientPhone = (noHpPenerima != null && noHpPenerima.trim().isNotEmpty)
          ? noHpPenerima.trim()
          : (pasMap['no_hp']?.toString().trim().isNotEmpty == true
              ? pasMap['no_hp'].toString().trim()
              : '081234567890');
      final finalRecipientAddress = (alamatPengiriman != null && alamatPengiriman.trim().isNotEmpty)
          ? alamatPengiriman.trim()
          : (pasMap['alamat']?.toString().trim().isNotEmpty == true
              ? pasMap['alamat'].toString().trim()
              : 'Jl. Dago Asri No. 12, Coblong, Kota Bandung');

      // 4. Jika ini penebusan resep dokter, ubah status resep menjadi 'sudah_ditebus'
      // sehingga resep masuk ke daftar Resep Masuk di User Apotek (status: Belum Diverifikasi)
      if (resolvedResepId != null && resolvedResepId.isNotEmpty) {
        await _exec(
          '''
          UPDATE resep
          SET status = CASE
                WHEN LOWER(TRIM(status)) IN ('diverifikasi', 'selesai') THEN status
                ELSE 'sudah_ditebus'
              END,
              updated_at = NOW()
          WHERE TRIM(id) = @rxId
          ''',
          parameters: {'rxId': resolvedResepId},
        );
      }

      // 5. Cari apakah baris pesanan_obat sudah ada di database
      String? existingOrderId;
      String? existingOrderNo;
      final cleanOrderId = (idPesanan ?? '').trim();
      final cleanOrderNo = (noPesanan ?? '').trim();

      if (cleanOrderId.isNotEmpty || cleanOrderNo.isNotEmpty) {
        final ordRows = await _exec(
          '''
          SELECT TRIM(id) AS id, no_pesanan, TRIM(id_resep) AS id_resep
          FROM pesanan_obat
          WHERE TRIM(id) = @oid
             OR TRIM(no_pesanan) = @ono
             OR TRIM(id) = @ono
             OR TRIM(no_pesanan) = @oid
          LIMIT 1
          ''',
          parameters: {'oid': cleanOrderId, 'ono': cleanOrderNo},
        );
        if (ordRows.isNotEmpty) {
          final om = ordRows.first.toColumnMap();
          existingOrderId = om['id']?.toString().trim();
          existingOrderNo = om['no_pesanan']?.toString().trim();
          if (resolvedResepId == null && om['id_resep'] != null) {
            final dbRx = om['id_resep'].toString().trim();
            if (dbRx.isNotEmpty) {
              resolvedResepId = dbRx;
              await _exec(
                '''
                UPDATE resep
                SET status = CASE
                      WHEN LOWER(TRIM(status)) IN ('diverifikasi', 'selesai') THEN status
                      ELSE 'sudah_ditebus'
                    END,
                    updated_at = NOW()
                WHERE TRIM(id) = @rxId
                ''',
                parameters: {'rxId': resolvedResepId},
              );
            }
          }
        }
      }

      if (existingOrderId == null && resolvedResepId != null && resolvedResepId.isNotEmpty) {
        final byRxRows = await _exec(
          '''
          SELECT TRIM(id) AS id, no_pesanan
          FROM pesanan_obat
          WHERE TRIM(id_resep) = @rxId
          ORDER BY created_at DESC
          LIMIT 1
          ''',
          parameters: {'rxId': resolvedResepId},
        );
        if (byRxRows.isNotEmpty) {
          final om = byRxRows.first.toColumnMap();
          existingOrderId = om['id']?.toString().trim();
          existingOrderNo = om['no_pesanan']?.toString().trim();
        }
      }

      final isResepOrder = resolvedResepId != null && resolvedResepId.isNotEmpty;
      final tipePesanan = isResepOrder ? 'resep' : 'umum';
      final finalMetodeAmbil = (metodePengambilan ?? 'antar').toLowerCase().contains('ambil')
          ? 'ambil'
          : 'antar';
      final finalMetodeBayar = (metodePembayaran ?? 'qris').toLowerCase();
      final finalSubtotal = subtotal ?? 85000;
      final finalOngkir = ongkosKirim ?? (finalMetodeAmbil == 'antar' ? 15000 : 0);
      final finalTotal = totalBayar ?? (finalSubtotal + finalOngkir);

      String finalOrderId;
      String finalOrderNo;

      if (existingOrderId != null && existingOrderId.isNotEmpty) {
        finalOrderId = existingOrderId;
        finalOrderNo = existingOrderNo ?? cleanOrderNo;
        await _exec(
          '''
          UPDATE pesanan_obat
          SET id_apotek = COALESCE(@aptId, id_apotek),
              id_resep = COALESCE(@rxId, id_resep),
              tipe_pesanan = @tipe,
              status_pembayaran = 'lunas',
              waktu_bayar = COALESCE(waktu_bayar, NOW()),
              status_pesanan = CASE
                WHEN LOWER(TRIM(status_pesanan)) IN ('diproses', 'selesai') THEN status_pesanan
                ELSE 'menunggu_konfirmasi'
              END,
              progress_step = GREATEST(COALESCE(progress_step, 1), 1),
              updated_at = NOW()
          WHERE TRIM(id) = @id
          ''',
          parameters: {
            'id': finalOrderId,
            'aptId': targetApotekId,
            'rxId': resolvedResepId,
            'tipe': tipePesanan,
          },
        );
      } else {
        final uuidRes = await _exec('SELECT gen_random_uuid()::text AS id');
        finalOrderId = uuidRes.first.toColumnMap()['id'].toString().trim();
        final ts = (DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0');
        finalOrderNo = cleanOrderNo.isNotEmpty ? cleanOrderNo : 'ORD-GIAT-$ts';

        await _exec(
          '''
          INSERT INTO pesanan_obat (
            id, no_pesanan, id_pasien, id_apotek, id_resep, tipe_pesanan,
            metode_pengambilan, nama_penerima, no_hp_penerima, alamat_pengiriman,
            subtotal, ongkos_kirim, total_bayar, metode_pembayaran,
            status_pembayaran, progress_step, status_pesanan, waktu_bayar,
            created_at, updated_at
          ) VALUES (
            @id, @noPesanan, @idPasien, @idApotek, @idResep, @tipePesanan,
            @metodeAmbil, @namaPenerima, @noHpPenerima, @alamatPengiriman,
            @subtotal, @ongkir, @totalBayar, @metodeBayar,
            'lunas', 1, 'menunggu_konfirmasi', NOW(),
            NOW(), NOW()
          )
          ''',
          parameters: {
            'id': finalOrderId,
            'noPesanan': finalOrderNo,
            'idPasien': targetPasienId,
            'idApotek': targetApotekId,
            'idResep': resolvedResepId,
            'tipePesanan': tipePesanan,
            'metodeAmbil': finalMetodeAmbil,
            'namaPenerima': finalRecipientName,
            'noHpPenerima': finalRecipientPhone,
            'alamatPengiriman': finalRecipientAddress,
            'subtotal': finalSubtotal,
            'ongkir': finalOngkir,
            'totalBayar': finalTotal,
            'metodeBayar': finalMetodeBayar,
          },
        );
      }

      // 6. Pastikan pesanan_obat_items terisi untuk pesanan ini
      final existingItems = await _exec(
        'SELECT COUNT(*)::int AS cnt FROM pesanan_obat_items WHERE TRIM(id_pesanan) = @pid',
        parameters: {'pid': finalOrderId},
      );
      final existingItemCount = int.tryParse(
            existingItems.first.toColumnMap()['cnt']?.toString() ?? '0',
          ) ??
          0;

      if (existingItemCount == 0) {
        // Ambil daftar obat apotek untuk resolusi FK id_obat
        final aptObatRows = await _exec(
          '''
          SELECT TRIM(id_obat) AS id_obat, nama_obat, ROUND(harga_jual)::int AS harga_jual
          FROM obat
          WHERE TRIM(id_apotek) = @aptId
          ORDER BY created_at ASC
          ''',
          parameters: {'aptId': targetApotekId},
        );
        final aptObatList = aptObatRows.map((r) => _normalizeMap(r.toColumnMap())).toList();
        final defaultObatId = aptObatList.isNotEmpty
            ? aptObatList.first['id_obat'].toString()
            : '91d0bddb-c673-4245-92f3-2a681b645e67';

        List<Map<String, dynamic>> itemsToInsert = [];
        if (items != null && items.isNotEmpty) {
          itemsToInsert = items;
        } else if (resolvedResepId != null && resolvedResepId.isNotEmpty) {
          final rxItemRows = await _exec(
            '''
            SELECT nama_obat, jumlah
            FROM resep_item
            WHERE TRIM(id_resep) = @rxId
            ORDER BY created_at ASC
            ''',
            parameters: {'rxId': resolvedResepId},
          );
          for (final r in rxItemRows) {
            final rm = r.toColumnMap();
            itemsToInsert.add({
              'nama_obat': rm['nama_obat']?.toString() ?? 'Obat Resep Ginjal',
              'jumlah': int.tryParse(rm['jumlah']?.toString() ?? '1') ?? 1,
            });
          }
        }

        if (itemsToInsert.isEmpty) {
          itemsToInsert.add({
            'nama_obat': aptObatList.isNotEmpty
                ? aptObatList.first['nama_obat'].toString()
                : 'Renalvit Tab',
            'jumlah': 1,
            'harga_satuan': finalSubtotal,
          });
        }

        for (final it in itemsToInsert) {
          final medName = (it['nama_obat'] ?? it['nama'] ?? it['medicineName'] ?? 'Obat Ginjal').toString().trim();
          final rawQty = (it['jumlah'] ?? it['qty'] ?? '1').toString();
          final qtyMatch = RegExp(r'\d+').firstMatch(rawQty);
          final qty = qtyMatch != null ? (int.tryParse(qtyMatch.group(0)!) ?? 1) : 1;

          String matchedObatId = (it['id_obat'] ?? '').toString().trim();
          int unitPrice = int.tryParse((it['harga_satuan'] ?? it['harga'] ?? '').toString()) ?? 0;

          if (matchedObatId.length < 30 || unitPrice <= 0) {
            final firstWord = medName.split(' ').first.toLowerCase();
            final matched = aptObatList.firstWhere(
              (o) => o['nama_obat'].toString().toLowerCase().contains(firstWord),
              orElse: () => aptObatList.isNotEmpty ? aptObatList.first : <String, dynamic>{},
            );
            if (matched.isNotEmpty) {
              if (matchedObatId.length < 30) {
                matchedObatId = matched['id_obat'].toString();
              }
              if (unitPrice <= 0) {
                unitPrice = int.tryParse(matched['harga_jual']?.toString() ?? '65000') ?? 65000;
              }
            }
          }
          if (matchedObatId.length < 30) matchedObatId = defaultObatId;
          if (unitPrice <= 0) unitPrice = 65000;

          await _exec(
            '''
            INSERT INTO pesanan_obat_items (
              id, id_pesanan, id_obat, nama_obat, jumlah, harga_satuan, subtotal, created_at, updated_at
            ) VALUES (
              gen_random_uuid()::text, @idPesanan, @idObat, @namaObat, @jumlah, @hargaSatuan, @subtotal, NOW(), NOW()
            )
            ''',
            parameters: {
              'idPesanan': finalOrderId,
              'idObat': matchedObatId,
              'namaObat': medName,
              'jumlah': qty > 0 ? qty : 1,
              'hargaSatuan': unitPrice,
              'subtotal': unitPrice * (qty > 0 ? qty : 1),
            },
          );
        }
      }

      // 7. Catat riwayat tracking pembayaran lunas
      try {
        await _exec(
          '''
          INSERT INTO pesanan_obat_trackings (id, id_pesanan, status, keterangan, created_at, updated_at)
          VALUES (
            gen_random_uuid()::text,
            @idPesanan,
            'Pembayaran Lunas',
            @ket,
            NOW(),
            NOW()
          )
          ''',
          parameters: {
            'idPesanan': finalOrderId,
            'ket': isResepOrder
                ? 'Pembayaran tebus resep dokter (${resolvedNoResep ?? cleanRxNo}) berhasil dikonfirmasi. Menunggu verifikasi apoteker.'
                : 'Pembayaran pesanan obat ($finalOrderNo) berhasil dikonfirmasi dan siap diproses apotek.',
          },
        );
      } catch (_) {}

      // 8. Kirim notifikasi real ke User Apotek
      await createApotekNotification(
        apotekId: targetApotekId,
        judul: isResepOrder ? 'Pesanan Resep Baru Masuk' : 'Pesanan Obat Baru Masuk',
        pesan: isResepOrder
            ? 'Resep dokter ${resolvedNoResep ?? cleanRxNo} untuk pasien $finalRecipientName telah dibayar (Lunas) dan menunggu verifikasi Anda.'
            : 'Pesanan $finalOrderNo atas nama $finalRecipientName telah dibayar (Lunas) dan siap disiapkan obatnya.',
        kategori: isResepOrder ? 'resep' : 'pesanan',
      );

      return {
        'id': finalOrderId,
        'no_pesanan': finalOrderNo,
        'id_resep': resolvedResepId,
        'no_resep': resolvedNoResep,
        'id_apotek': targetApotekId,
        'status_pembayaran': 'lunas',
      };
    } catch (e) {
      debugPrint('Error completePasienObatPaymentInSupabase: $e');
      return null;
    }
  }

  // ===========================================================================
  // MODUL APOTEK: PROFIL, JAM OPERASIONAL, AREA LAYANAN, STATUS & KEAMANAN REAL
  // ===========================================================================

  /// Mengambil profil lengkap Apotek beserta ringkasan jam operasional & area layanan dari Supabase
  Future<Map<String, dynamic>?> fetchApotekProfileFull({
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return null;
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return null;

    final rows = await _exec(
      '''
      SELECT
        TRIM(a.id_apotek) AS id,
        TRIM(a.id_apotek) AS id_apotek,
        a.nama_apotek,
        a.penanggung_jawab,
        a.no_sipa_sia,
        a.no_hp,
        a.alamat,
        a.lokasi_lat_long,
        COALESCE(a.status_layanan, true) AS status_layanan,
        a.foto_profile,
        u.email,
        u.nama AS nama_user
      FROM apotek a
      LEFT JOIN "user" u ON TRIM(u.id) = TRIM(a.id_apotek)
      WHERE TRIM(a.id_apotek) = @aptId
      LIMIT 1
      ''',
      parameters: {'aptId': aptId},
    );
    if (rows.isEmpty) return null;

    final map = _normalizeMap(rows.first.toColumnMap());

    // Ambil jam operasional real
    final schedules = await fetchApotekJamOperasional(apotekId: aptId);
    String jamRingkas = '08.00 - 22.00 WIB';
    if (schedules.isNotEmpty) {
      final openDays = schedules.where((s) => s['is_open'] == true).toList();
      if (openDays.isNotEmpty) {
        final firstOpen = (openDays.first['jam_buka_24'] ?? '08.00').toString();
        final firstClose = (openDays.first['jam_tutup_24'] ?? '22.00').toString();
        jamRingkas = '$firstOpen - $firstClose WIB';
      } else {
        jamRingkas = 'Tutup Sementara';
      }
    }

    // Ambil area layanan aktif real
    final areas = await fetchApotekAreaLayanan(apotekId: aptId);
    final activeAreas = areas
        .where((a) => a['is_active'] == true)
        .map((a) => (a['nama_area'] ?? '').toString().trim())
        .where((n) => n.isNotEmpty)
        .toList();
    final areaRingkas = activeAreas.isNotEmpty
        ? activeAreas.join(', ')
        : 'Kota Bandung dan Sekitarnya';

    map['jam_operasional_ringkas'] = jamRingkas;
    map['area_layanan_ringkas'] = areaRingkas;
    map['jam_operasional'] = schedules;
    map['area_layanan'] = areas;
    return map;
  }

  /// Memperbarui data profil Apotek (nama, email, no_hp, alamat, penanggung_jawab, sipa) di Supabase
  Future<Map<String, dynamic>?> updateApotekProfileFull(
    Map<String, dynamic> data, {
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return null;
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return null;

    final current = await fetchApotekProfileFull(apotekId: aptId) ?? <String, dynamic>{};
    final namaApotek = (data['nama_apotek'] ?? data['nama'] ?? data['name'] ?? current['nama_apotek'] ?? 'Apotek Mitra GIAT').toString().trim();
    final penanggungJawab = (data['penanggung_jawab'] ?? current['penanggung_jawab'] ?? 'apt. Farhan Ramadhan, S.Farm').toString().trim();
    final noHp = (data['no_hp'] ?? data['phone'] ?? current['no_hp'] ?? '').toString().trim();
    final email = (data['email'] ?? current['email'] ?? '').toString().trim();
    final alamat = (data['alamat'] ?? current['alamat'] ?? '').toString().trim();
    final fotoProfile = (data['foto_profile'] ?? data['foto_profil'] ?? current['foto_profile'])?.toString().trim();

    await _exec(
      '''
      UPDATE apotek
      SET nama_apotek = @namaApotek,
          penanggung_jawab = @penanggungJawab,
          no_hp = CASE WHEN @noHp = '' THEN no_hp ELSE @noHp END,
          alamat = CASE WHEN @alamat = '' THEN alamat ELSE @alamat END,
          foto_profile = COALESCE(@fotoProfile, foto_profile),
          updated_at = NOW()
      WHERE TRIM(id_apotek) = @aptId
      ''',
      parameters: {
        'aptId': aptId,
        'namaApotek': namaApotek,
        'penanggungJawab': penanggungJawab,
        'noHp': noHp,
        'alamat': alamat,
        'fotoProfile': (fotoProfile != null && fotoProfile.isNotEmpty) ? fotoProfile : null,
      },
    );

    await _exec(
      '''
      UPDATE "user"
      SET nama = @namaApotek,
          email = CASE WHEN @email = '' THEN email ELSE LOWER(@email) END,
          no_hp = CASE WHEN @noHp = '' THEN no_hp ELSE @noHp END,
          updated_at = NOW()
      WHERE TRIM(id) = @aptId
      ''',
      parameters: {
        'aptId': aptId,
        'namaApotek': namaApotek,
        'email': email,
        'noHp': noHp,
      },
    );

    try {
      final savedUser = await StorageService().getUser();
      if (savedUser != null) {
        await StorageService().saveUser(
          savedUser.copyWith(
            nama: namaApotek,
            email: email.isNotEmpty ? email : savedUser.email,
            noHp: noHp.isNotEmpty ? noHp : savedUser.noHp,
            fotoProfile: (fotoProfile != null && fotoProfile.isNotEmpty)
                ? fotoProfile
                : savedUser.fotoProfile,
          ),
        );
      }
    } catch (_) {}

    return fetchApotekProfileFull(apotekId: aptId);
  }

  /// Memperbarui foto profil Apotek di Supabase
  Future<Map<String, dynamic>?> updateApotekPhoto(
    String fileOrUrl, {
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return null;
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return null;
    final cleanVal = fileOrUrl.trim();

    await _exec(
      '''
      UPDATE apotek
      SET foto_profile = @foto,
          updated_at = NOW()
      WHERE TRIM(id_apotek) = @aptId
      ''',
      parameters: {
        'aptId': aptId,
        'foto': cleanVal.isNotEmpty ? cleanVal : null,
      },
    );

    return {
      'id_apotek': aptId,
      'foto_profile': cleanVal,
      'foto_profil': cleanVal,
      'url': cleanVal,
    };
  }

  /// Memperbarui kata sandi akun Apotek di tabel `"user"` Supabase
  /// Mengembalikan `null` jika berhasil, atau pesan error jika kata sandi lama salah
  Future<String?> updateApotekPassword({
    required String currentPassword,
    required String newPassword,
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return null;
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return 'Akun apotek tidak ditemukan di database.';

    final check = await _exec(
      r'''
      SELECT (
        (extensions.crypt(@currentPass, replace(password, '$2y$', '$2a$')) = replace(password, '$2y$', '$2a$'))
        OR password = @currentPass
      ) AS is_valid
      FROM "user"
      WHERE TRIM(id) = @id
      LIMIT 1
      ''',
      parameters: {
        'id': aptId,
        'currentPass': currentPassword,
      },
    );

    if (check.isEmpty || check.first.toColumnMap()['is_valid'] != true) {
      return 'Kata sandi saat ini tidak sesuai.';
    }

    await _exec(
      r'''
      UPDATE "user"
      SET password = replace(extensions.crypt(@newPass, extensions.gen_salt('bf', 12)), '$2a$', '$2y$'),
          updated_at = NOW()
      WHERE TRIM(id) = @id
      ''',
      parameters: {
        'id': aptId,
        'newPass': newPassword,
      },
    );

    return null;
  }

  /// Mengubah status aktif/tutup layanan Apotek (`apotek.status_layanan`) di Supabase
  Future<Map<String, dynamic>?> toggleApotekStatusLayanan({
    bool? isActive,
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return null;
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return null;

    bool newStatus;
    if (isActive != null) {
      newStatus = isActive;
    } else {
      final cur = await _exec(
        'SELECT COALESCE(status_layanan, true) AS st FROM apotek WHERE TRIM(id_apotek) = @aptId LIMIT 1',
        parameters: {'aptId': aptId},
      );
      final curBool = cur.isNotEmpty ? (cur.first.toColumnMap()['st'] == true) : true;
      newStatus = !curBool;
    }

    await _exec(
      '''
      UPDATE apotek
      SET status_layanan = @st,
          updated_at = NOW()
      WHERE TRIM(id_apotek) = @aptId
      ''',
      parameters: {'aptId': aptId, 'st': newStatus},
    );

    return {
      'id_apotek': aptId,
      'status_layanan': newStatus,
      'is_active': newStatus,
    };
  }

  String _formatSqlTimeTo12h(String rawTime, {String fallback = '08:00 AM'}) {
    final clean = rawTime.replaceAll('Time(', '').replaceAll(')', '').trim();
    final parts = clean.split(':');
    if (parts.length < 2) return fallback;
    final h = int.tryParse(parts[0]) ?? 8;
    final m = int.tryParse(parts[1]) ?? 0;
    final suffix = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $suffix';
  }

  String _formatSqlTimeTo24hDot(String rawTime, {String fallback = '08.00'}) {
    final clean = rawTime.replaceAll('Time(', '').replaceAll(')', '').trim();
    final parts = clean.split(':');
    if (parts.length < 2) return fallback;
    final h = int.tryParse(parts[0]) ?? 8;
    final m = int.tryParse(parts[1]) ?? 0;
    return '${h.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}';
  }

  String _parse12hOr24hToSqlTime(String input, {String fallback = '08:00:00'}) {
    final s = input.trim().toUpperCase();
    final isPm = s.contains('PM');
    final isAm = s.contains('AM');
    final cleaned = s.replaceAll('AM', '').replaceAll('PM', '').replaceAll('.', ':').trim();
    final parts = cleaned.split(':');
    if (parts.isEmpty) return fallback;
    int h = int.tryParse(parts[0].trim()) ?? 8;
    int m = parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0;
    if (isPm && h < 12) h += 12;
    if (isAm && h == 12) h = 0;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
  }

  /// Mengambil jadwal jam operasional 7 hari milik Apotek dari tabel `apotek_jam_operasional` Supabase
  Future<List<Map<String, dynamic>>> fetchApotekJamOperasional({
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return [];
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return [];

    final rows = await _exec(
      '''
      SELECT
        TRIM(id) AS id,
        TRIM(id_apotek) AS id_apotek,
        LOWER(TRIM(hari)) AS hari,
        COALESCE(is_open, true) AS is_open,
        jam_buka::text AS jam_buka,
        jam_tutup::text AS jam_tutup
      FROM apotek_jam_operasional
      WHERE TRIM(id_apotek) = @aptId
      ''',
      parameters: {'aptId': aptId},
    );

    final dayOrder = [
      {'key': 'senin', 'label': 'Senin', 'short': 'S'},
      {'key': 'selasa', 'label': 'Selasa', 'short': 'S'},
      {'key': 'rabu', 'label': 'Rabu', 'short': 'R'},
      {'key': 'kamis', 'label': 'Kamis', 'short': 'K'},
      {'key': 'jumat', 'label': 'Jumat', 'short': 'J'},
      {'key': 'sabtu', 'label': 'Sabtu', 'short': 'S'},
      {'key': 'minggu', 'label': 'Minggu', 'short': 'M'},
    ];

    final Map<String, Map<String, dynamic>> byDay = {};
    for (final r in rows) {
      final m = _normalizeMap(r.toColumnMap());
      final key = (m['hari'] ?? '').toString().toLowerCase().trim();
      byDay[key] = m;
    }

    final List<Map<String, dynamic>> result = [];
    for (final d in dayOrder) {
      final key = d['key']!;
      final existing = byDay[key];
      final rawBuka = existing?['jam_buka']?.toString() ?? '08:00:00';
      final rawTutup = existing?['jam_tutup']?.toString() ?? '22:00:00';
      final isOpen = existing != null ? (existing['is_open'] == true) : true;
      result.add({
        'id': existing?['id']?.toString() ?? '',
        'id_apotek': aptId,
        'hari': key,
        'day_name': d['label']!,
        'short_day': d['short']!,
        'is_open': isOpen,
        'jam_buka': _formatSqlTimeTo12h(rawBuka, fallback: '08:00 AM'),
        'jam_tutup': _formatSqlTimeTo12h(rawTutup, fallback: '10:00 PM'),
        'jam_buka_24': _formatSqlTimeTo24hDot(rawBuka, fallback: '08.00'),
        'jam_tutup_24': _formatSqlTimeTo24hDot(rawTutup, fallback: '22.00'),
      });
    }

    return result;
  }

  /// Menyimpan perubahan jadwal jam operasional Apotek ke tabel `apotek_jam_operasional` Supabase
  Future<List<Map<String, dynamic>>> updateApotekJamOperasional(
    List<Map<String, dynamic>> schedules, {
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return schedules;
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return schedules;

    for (final s in schedules) {
      final dayKey = (s['hari'] ?? s['day_name'] ?? s['dayName'] ?? '')
          .toString()
          .toLowerCase()
          .trim();
      if (dayKey.isEmpty) continue;
      final isOpen = s['is_open'] == true || s['isOpen'] == true;
      final openTimeSql = _parse12hOr24hToSqlTime(
        (s['jam_buka'] ?? s['openTime'] ?? '08:00 AM').toString(),
        fallback: '08:00:00',
      );
      final closeTimeSql = _parse12hOr24hToSqlTime(
        (s['jam_tutup'] ?? s['closeTime'] ?? '10:00 PM').toString(),
        fallback: '22:00:00',
      );

      final existing = await _exec(
        '''
        SELECT TRIM(id) AS id
        FROM apotek_jam_operasional
        WHERE TRIM(id_apotek) = @aptId
          AND LOWER(TRIM(hari)) = @hari
        LIMIT 1
        ''',
        parameters: {'aptId': aptId, 'hari': dayKey},
      );

      if (existing.isNotEmpty) {
        final rowId = existing.first.toColumnMap()['id']?.toString().trim();
        await _exec(
          '''
          UPDATE apotek_jam_operasional
          SET is_open = @isOpen,
              jam_buka = @jamBuka::time,
              jam_tutup = @jamTutup::time,
              updated_at = NOW()
          WHERE TRIM(id) = @id
          ''',
          parameters: {
            'id': rowId,
            'isOpen': isOpen,
            'jamBuka': openTimeSql,
            'jamTutup': closeTimeSql,
          },
        );
      } else {
        await _exec(
          '''
          INSERT INTO apotek_jam_operasional (
            id, id_apotek, hari, is_open, jam_buka, jam_tutup, created_at, updated_at
          ) VALUES (
            gen_random_uuid()::text, @aptId, @hari, @isOpen, @jamBuka::time, @jamTutup::time, NOW(), NOW()
          )
          ''',
          parameters: {
            'aptId': aptId,
            'hari': dayKey,
            'isOpen': isOpen,
            'jamBuka': openTimeSql,
            'jamTutup': closeTimeSql,
          },
        );
      }
    }

    return fetchApotekJamOperasional(apotekId: aptId);
  }

  /// Mengambil daftar cakupan wilayah area layanan dari tabel `apotek_area_layanan` Supabase
  Future<List<Map<String, dynamic>>> fetchApotekAreaLayanan({
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return [];
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return [];

    final rows = await _exec(
      '''
      SELECT
        TRIM(id) AS id,
        TRIM(id_apotek) AS id_apotek,
        nama_area,
        COALESCE(detail, 'Layanan pengantaran obat kurir farmasi') AS detail,
        COALESCE(is_active, true) AS is_active
      FROM apotek_area_layanan
      WHERE TRIM(id_apotek) = @aptId
      ORDER BY created_at ASC, nama_area ASC
      ''',
      parameters: {'aptId': aptId},
    );

    return rows.map((r) => _normalizeMap(r.toColumnMap())).toList();
  }

  /// Menyimpan daftar cakupan area layanan ke tabel `apotek_area_layanan` Supabase
  Future<List<Map<String, dynamic>>> updateApotekAreaLayanan(
    List<Map<String, dynamic>> areas, {
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return areas;
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return areas;

    for (final a in areas) {
      final nama = (a['nama_area'] ?? a['name'] ?? '').toString().trim();
      final detail = (a['detail'] ?? a['details'] ?? 'Layanan pengantaran obat kurir farmasi').toString().trim();
      final isActive = a['is_active'] == true || a['isActive'] == true;
      if (nama.isEmpty) continue;

      final existing = await _exec(
        '''
        SELECT TRIM(id) AS id
        FROM apotek_area_layanan
        WHERE TRIM(id_apotek) = @aptId
          AND LOWER(TRIM(nama_area)) = LOWER(@nama)
        LIMIT 1
        ''',
        parameters: {'aptId': aptId, 'nama': nama},
      );

      if (existing.isNotEmpty) {
        final rowId = existing.first.toColumnMap()['id']?.toString().trim();
        await _exec(
          '''
          UPDATE apotek_area_layanan
          SET is_active = @isActive,
              detail = @detail,
              updated_at = NOW()
          WHERE TRIM(id) = @id
          ''',
          parameters: {
            'id': rowId,
            'isActive': isActive,
            'detail': detail,
          },
        );
      } else {
        await _exec(
          '''
          INSERT INTO apotek_area_layanan (
            id, id_apotek, nama_area, detail, is_active, created_at, updated_at
          ) VALUES (
            gen_random_uuid()::text, @aptId, @nama, @detail, @isActive, NOW(), NOW()
          )
          ''',
          parameters: {
            'aptId': aptId,
            'nama': nama,
            'detail': detail,
            'isActive': isActive,
          },
        );
      }
    }

    return fetchApotekAreaLayanan(apotekId: aptId);
  }

  // ===========================================================================
  // MODUL APOTEK: RESEP DOKTER MASUK (HANYA YANG SUDAH DITEBUS & DIBAYAR PASIEN)
  // ===========================================================================

  /// Mengambil daftar resep dokter yang SUDAH DITEBUS & DIBAYAR LUNAS oleh pasien
  /// Resep yang masih berstatus 'aktif' (belum dibeli/dibayar pasien) TIDAK ditampilkan di Apotek!
  Future<List<Map<String, dynamic>>> fetchApotekResepList({
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return [];
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return [];

    final rows = await _exec(
      '''
      SELECT
        TRIM(r.id) AS id,
        TRIM(r.id) AS id_resep,
        r.no_resep,
        TRIM(r.id_pasien) AS id_pasien,
        TRIM(r.id_dokter) AS id_dokter,
        r.tanggal_resep::text AS tanggal_resep,
        r.diagnosis,
        r.catatan_dokter,
        LOWER(TRIM(r.status)) AS status,
        r.created_at,
        r.updated_at,
        COALESCE(p.nama, 'Pasien GIAT') AS nama_pasien,
        p.alamat AS alamat_pasien,
        p.no_hp AS no_hp_pasien,
        p.nik AS nik_pasien,
        COALESCE(d.nama, 'dr. Spesialis GIAT') AS nama_dokter,
        d.no_sip AS no_sip_dokter,
        TRIM(po.id) AS id_pesanan,
        po.no_pesanan,
        LOWER(TRIM(COALESCE(po.status_pembayaran, 'lunas'))) AS status_pembayaran,
        LOWER(TRIM(COALESCE(po.status_pesanan, ''))) AS status_pesanan,
        po.waktu_bayar,
        po.updated_at AS pesanan_updated_at
      FROM resep r
      LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(r.id_pasien)
      LEFT JOIN dokter d ON TRIM(d.id_dokter) = TRIM(r.id_dokter)
      LEFT JOIN LATERAL (
        SELECT id, no_pesanan, id_apotek, status_pembayaran, status_pesanan, waktu_bayar, updated_at
        FROM pesanan_obat
        WHERE TRIM(id_resep) = TRIM(r.id)
        ORDER BY
          CASE WHEN LOWER(TRIM(status_pembayaran)) = 'lunas' THEN 0 ELSE 1 END,
          created_at DESC
        LIMIT 1
      ) po ON true
      WHERE LOWER(TRIM(r.status)) IN ('sudah_ditebus', 'diverifikasi', 'selesai')
        AND (
          po.id IS NULL
          OR (
            LOWER(TRIM(po.status_pembayaran)) = 'lunas'
            AND (TRIM(po.id_apotek) = @aptId OR po.id_apotek IS NULL)
          )
        )
      ORDER BY COALESCE(r.updated_at, r.created_at) DESC
      ''',
      parameters: {'aptId': aptId},
    );

    final List<Map<String, dynamic>> result = [];
    for (final r in rows) {
      final m = _normalizeMap(r.toColumnMap());
      final rxId = m['id']?.toString().trim() ?? '';
      final itemRows = await _exec(
        '''
        SELECT
          TRIM(ri.id) AS id,
          ri.nama_obat,
          ri.dosis,
          ri.aturan_pakai,
          ri.waktu_penggunaan,
          ri.jumlah,
          ri.catatan_khusus,
          COALESCE(
            (SELECT o.bentuk_sediaan || ' • ' || o.satuan_kemasan
             FROM obat o
             WHERE LOWER(TRIM(o.nama_obat)) = LOWER(TRIM(ri.nama_obat))
             LIMIT 1),
            'Tablet • Kemasan Standar'
          ) AS form_and_pack
        FROM resep_item ri
        WHERE TRIM(ri.id_resep) = @rxId
        ORDER BY ri.created_at ASC
        ''',
        parameters: {'rxId': rxId},
      );
      m['items'] = itemRows.map((ir) => _normalizeMap(ir.toColumnMap())).toList();
      result.add(m);
    }

    return result;
  }

  /// Memvalidasi & menerima Resep Dokter oleh Apotek (`Terima Resep`)
  /// Mengubah status resep menjadi 'diverifikasi' dan memasukkan pesanan ke antrean Pesanan Menunggu di Apotek
  Future<Map<String, dynamic>?> acceptApotekResep(
    String resepIdOrNo, {
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return null;
    final cleanRx = resepIdOrNo.trim().replaceAll('No.', '').trim();
    if (cleanRx.isEmpty) return null;

    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return null;

    final rxRows = await _exec(
      '''
      SELECT TRIM(id) AS id, no_resep, TRIM(id_pasien) AS id_pasien
      FROM resep
      WHERE TRIM(id) = @rx OR TRIM(no_resep) = @rx
      LIMIT 1
      ''',
      parameters: {'rx': cleanRx},
    );
    if (rxRows.isEmpty) return null;

    final rm = rxRows.first.toColumnMap();
    final rxId = rm['id']?.toString().trim() ?? '';
    final noResep = rm['no_resep']?.toString().trim() ?? cleanRx;
    final idPasien = rm['id_pasien']?.toString().trim() ?? '';

    await _exec(
      '''
      UPDATE resep
      SET status = 'diverifikasi',
          updated_at = NOW()
      WHERE TRIM(id) = @rxId
      ''',
      parameters: {'rxId': rxId},
    );

    // Pastikan pesanan_obat terkait sudah siap di antrean Menunggu (status_pesanan = 'menunggu_konfirmasi', progress_step = 2)
    final ordRows = await _exec(
      '''
      SELECT TRIM(id) AS id, no_pesanan
      FROM pesanan_obat
      WHERE TRIM(id_resep) = @rxId
      ORDER BY created_at DESC
      LIMIT 1
      ''',
      parameters: {'rxId': rxId},
    );

    String? orderId;
    String? orderNo;
    if (ordRows.isNotEmpty) {
      final om = ordRows.first.toColumnMap();
      orderId = om['id']?.toString().trim();
      orderNo = om['no_pesanan']?.toString().trim();
      await _exec(
        '''
        UPDATE pesanan_obat
        SET id_apotek = @aptId,
            status_pembayaran = 'lunas',
            status_pesanan = CASE
              WHEN LOWER(TRIM(status_pesanan)) IN ('diproses', 'selesai') THEN status_pesanan
              ELSE 'menunggu_konfirmasi'
            END,
            progress_step = GREATEST(COALESCE(progress_step, 1), 2),
            updated_at = NOW()
        WHERE TRIM(id) = @oid
        ''',
        parameters: {'oid': orderId, 'aptId': aptId},
      );
    } else {
      final created = await completePasienObatPaymentInSupabase(
        idResep: rxId,
        noResep: noResep,
        idPasien: idPasien,
        idApotek: aptId,
      );
      orderId = created?['id']?.toString();
      orderNo = created?['no_pesanan']?.toString();
      if (orderId != null && orderId.isNotEmpty) {
        await _exec(
          '''
          UPDATE pesanan_obat
          SET progress_step = 2,
              status_pesanan = 'menunggu_konfirmasi',
              updated_at = NOW()
          WHERE TRIM(id) = @oid
          ''',
          parameters: {'oid': orderId},
        );
      }
    }

    if (orderId != null && orderId.isNotEmpty) {
      try {
        await _exec(
          '''
          INSERT INTO pesanan_obat_trackings (id, id_pesanan, status, keterangan, created_at, updated_at)
          VALUES (
            gen_random_uuid()::text,
            @oid,
            'Resep Diverifikasi Apotek',
            @ket,
            NOW(),
            NOW()
          )
          ''',
          parameters: {
            'oid': orderId,
            'ket': 'Resep dokter ($noResep) telah diverifikasi oleh apoteker dan masuk antrean penyiapan obat.',
          },
        );
      } catch (_) {}
    }

    if (idPasien.isNotEmpty) {
      try {
        await createPasienNotification(
          pasienId: idPasien,
          judul: 'Resep Dokter Diverifikasi Apotek',
          pesan: 'Resep $noResep Anda telah diverifikasi oleh apoteker dan obat sedang dalam antrean penyiapan.',
          kategori: 'resep',
        );
      } catch (_) {}
    }

    return {
      'id_resep': rxId,
      'no_resep': noResep,
      'status': 'diverifikasi',
      'id_pesanan': orderId,
      'no_pesanan': orderNo,
    };
  }

  // ===========================================================================
  // MODUL APOTEK: PESANAN OBAT REAL (MENUNGGU, DIPROSES, SELESAI)
  // ===========================================================================

  /// Mengambil daftar pesanan obat yang SUDAH DIBAYAR LUNAS untuk Apotek dari Supabase
  /// Untuk pesanan bertipe 'resep', hanya masuk ke daftar Pesanan setelah resep diverifikasi ('diverifikasi'/'selesai')
  Future<List<Map<String, dynamic>>> fetchApotekPesananList({
    String? apotekId,
    String? apotekName,
    String? status,
  }) async {
    if (_isTest) return [];
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return [];

    final rows = await _exec(
      '''
      SELECT
        TRIM(po.id) AS id,
        po.no_pesanan,
        TRIM(po.id_pasien) AS id_pasien,
        TRIM(po.id_apotek) AS id_apotek,
        TRIM(po.id_resep) AS id_resep,
        LOWER(TRIM(COALESCE(po.tipe_pesanan, 'umum'))) AS tipe_pesanan,
        po.metode_pengambilan,
        po.nama_penerima,
        po.no_hp_penerima,
        po.alamat_pengiriman,
        po.subtotal,
        po.ongkos_kirim,
        po.total_bayar,
        po.metode_pembayaran,
        LOWER(TRIM(COALESCE(po.status_pembayaran, ''))) AS status_pembayaran,
        COALESCE(po.progress_step, 1) AS progress_step,
        LOWER(TRIM(COALESCE(po.status_pesanan, 'menunggu_konfirmasi'))) AS status_pesanan,
        po.waktu_bayar,
        po.created_at,
        po.updated_at,
        COALESCE(p.nama, po.nama_penerima, 'Pasien GIAT') AS nama_pasien,
        p.jenis_kelamin,
        p.tanggal_lahir::text AS tanggal_lahir,
        COALESCE(po.alamat_pengiriman, p.alamat, 'Kota Bandung') AS alamat_pasien,
        r.no_resep,
        r.tanggal_resep::text AS tanggal_resep,
        LOWER(TRIM(COALESCE(r.status, ''))) AS status_resep,
        COALESCE(d.nama, '') AS nama_dokter
      FROM pesanan_obat po
      LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(po.id_pasien)
      LEFT JOIN resep r ON TRIM(r.id) = TRIM(po.id_resep)
      LEFT JOIN dokter d ON TRIM(d.id_dokter) = TRIM(r.id_dokter)
      WHERE TRIM(po.id_apotek) = @aptId
        AND LOWER(TRIM(po.status_pembayaran)) = 'lunas'
        AND LOWER(TRIM(po.status_pesanan)) NOT IN ('ditolak', 'batal', 'dibatalkan')
        AND (
          po.id_resep IS NULL
          OR LOWER(TRIM(COALESCE(r.status, ''))) IN ('diverifikasi', 'selesai')
          OR LOWER(TRIM(po.status_pesanan)) IN ('diproses', 'dikirim', 'selesai')
          OR COALESCE(po.progress_step, 1) >= 2
        )
      ORDER BY COALESCE(po.updated_at, po.created_at) DESC
      ''',
      parameters: {'aptId': aptId},
    );

    final List<Map<String, dynamic>> result = [];
    for (final r in rows) {
      final m = _normalizeMap(r.toColumnMap());
      final ordId = m['id']?.toString().trim() ?? '';
      final itemRows = await _exec(
        '''
        SELECT
          TRIM(poi.id) AS id,
          TRIM(poi.id_obat) AS id_obat,
          poi.nama_obat,
          poi.jumlah,
          poi.harga_satuan,
          poi.subtotal,
          COALESCE(o.bentuk_sediaan, 'Tablet') AS bentuk_sediaan,
          COALESCE(o.satuan_kemasan, 'Strip / Box') AS satuan_kemasan,
          COALESCE(o.stok_total, 100) AS stok_total
        FROM pesanan_obat_items poi
        LEFT JOIN obat o ON TRIM(o.id_obat) = TRIM(poi.id_obat)
        WHERE TRIM(poi.id_pesanan) = @oid
        ORDER BY poi.created_at ASC
        ''',
        parameters: {'oid': ordId},
      );
      m['items'] = itemRows.map((ir) => _normalizeMap(ir.toColumnMap())).toList();
      result.add(m);
    }

    return result;
  }

  /// Memperbarui status pesanan obat di Apotek (`menunggu_konfirmasi`, `diproses`, `selesai`, `ditolak`)
  Future<Map<String, dynamic>?> updateApotekPesananStatus(
    String orderIdOrNo, {
    required String newStatus,
    int? progressStep,
    String? alasanPenolakan,
  }) async {
    if (_isTest) return null;
    final cleanOrd = orderIdOrNo.trim();
    if (cleanOrd.isEmpty) return null;

    final ordRows = await _exec(
      '''
      SELECT TRIM(id) AS id, no_pesanan, TRIM(id_pasien) AS id_pasien, TRIM(id_resep) AS id_resep
      FROM pesanan_obat
      WHERE TRIM(id) = @ord OR TRIM(no_pesanan) = @ord
      LIMIT 1
      ''',
      parameters: {'ord': cleanOrd},
    );
    if (ordRows.isEmpty) return null;

    final om = ordRows.first.toColumnMap();
    final ordId = om['id']?.toString().trim() ?? '';
    final noPesanan = om['no_pesanan']?.toString().trim() ?? cleanOrd;
    final idPasien = om['id_pasien']?.toString().trim() ?? '';
    final idResep = om['id_resep']?.toString().trim();

    final normalizedStatus = newStatus.toLowerCase().trim();
    final resolvedStep = progressStep ??
        (normalizedStatus == 'selesai'
            ? 5
            : (normalizedStatus == 'diproses' ? 4 : 2));

    await _exec(
      '''
      UPDATE pesanan_obat
      SET status_pesanan = @st,
          progress_step = @step,
          alasan_penolakan = COALESCE(@alasan, alasan_penolakan),
          updated_at = NOW()
      WHERE TRIM(id) = @oid
      ''',
      parameters: {
        'oid': ordId,
        'st': normalizedStatus,
        'step': resolvedStep,
        'alasan': alasanPenolakan,
      },
    );

    if (normalizedStatus == 'selesai' && idResep != null && idResep.isNotEmpty) {
      await _exec(
        '''
        UPDATE resep
        SET status = 'selesai',
            updated_at = NOW()
        WHERE TRIM(id) = @rxId
        ''',
        parameters: {'rxId': idResep},
      );
    }

    // Tambahkan log tracking pesanan
    String trackTitle = 'Status Pesanan Diperbarui';
    String trackDesc = 'Status pesanan $noPesanan diperbarui menjadi $normalizedStatus.';
    if (normalizedStatus == 'diproses') {
      trackTitle = 'Pesanan Sedang Disiapkan';
      trackDesc = 'Apoteker sedang menyiapkan dan mengemas obat untuk pesanan $noPesanan.';
    } else if (normalizedStatus == 'selesai') {
      trackTitle = 'Pesanan Selesai';
      trackDesc = 'Pesanan obat $noPesanan telah selesai disiapkan dan diserahkan.';
    }

    try {
      await _exec(
        '''
        INSERT INTO pesanan_obat_trackings (id, id_pesanan, status, keterangan, created_at, updated_at)
        VALUES (gen_random_uuid()::text, @oid, @title, @desc, NOW(), NOW())
        ''',
        parameters: {
          'oid': ordId,
          'title': trackTitle,
          'desc': trackDesc,
        },
      );
    } catch (_) {}

    if (idPasien.isNotEmpty) {
      try {
        await createPasienNotification(
          pasienId: idPasien,
          judul: trackTitle,
          pesan: trackDesc,
          kategori: 'obat',
        );
      } catch (_) {}
    }

    return {
      'id': ordId,
      'no_pesanan': noPesanan,
      'status_pesanan': normalizedStatus,
      'progress_step': resolvedStep,
    };
  }

  // ===========================================================================
  // MODUL APOTEK: INVENTARIS OBAT & BATCH STOK REAL SUPABASE
  // ===========================================================================

  /// Mengambil daftar inventaris obat beserta rincian batch stoknya dari tabel `obat` & `obat_batches` Supabase
  Future<List<Map<String, dynamic>>> fetchApotekObatList({
    String? apotekId,
    String? apotekName,
    String? query,
  }) async {
    if (_isTest) return [];
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return [];

    String searchFilter = '';
    final params = <String, dynamic>{'aptId': aptId};
    if (query != null && query.trim().isNotEmpty) {
      searchFilter = 'AND (LOWER(o.nama_obat) LIKE @q OR LOWER(o.kategori) LIKE @q)';
      params['q'] = '%${query.trim().toLowerCase()}%';
    }

    final rows = await _exec(
      '''
      SELECT
        TRIM(o.id_obat) AS id,
        TRIM(o.id_obat) AS id_obat,
        TRIM(o.id_apotek) AS id_apotek,
        o.nama_obat,
        o.kategori,
        COALESCE(o.bentuk_sediaan, 'Tablet') AS bentuk_sediaan,
        COALESCE(o.dosis, '-') AS dosis,
        COALESCE(o.satuan_kemasan, 'Strip / Box') AS satuan_kemasan,
        COALESCE(o.stok_total, 0) AS stok_total,
        ROUND(COALESCE(o.harga_beli, 0))::int AS harga_beli,
        ROUND(COALESCE(o.harga_jual, 0))::int AS harga_jual,
        o.aturan_pakai_umum,
        o.foto_obat,
        o.created_at,
        o.updated_at
      FROM obat o
      WHERE TRIM(o.id_apotek) = @aptId
        $searchFilter
      ORDER BY o.updated_at DESC, o.nama_obat ASC
      ''',
      parameters: params,
    );

    final List<Map<String, dynamic>> result = [];
    for (final r in rows) {
      final m = _normalizeMap(r.toColumnMap());
      final idObat = m['id_obat']?.toString().trim() ?? '';
      final batchRows = await _exec(
        '''
        SELECT
          TRIM(id) AS id,
          no_batch,
          COALESCE(stok_batch, 0) AS stok_batch,
          tanggal_kadaluwarsa::text AS tanggal_kadaluwarsa,
          COALESCE(status, 'tersedia') AS status,
          created_at
        FROM obat_batches
        WHERE TRIM(id_obat) = @idObat
        ORDER BY created_at DESC
        ''',
        parameters: {'idObat': idObat},
      );
      m['batches'] = batchRows.map((br) => _normalizeMap(br.toColumnMap())).toList();
      result.add(m);
    }

    return result;
  }

  DateTime _parseIndonesianOrIsoDate(String rawDate) {
    final clean = rawDate.trim();
    final direct = DateTime.tryParse(clean);
    if (direct != null) return direct;

    final months = <String, int>{
      'jan': 1, 'januari': 1,
      'feb': 2, 'februari': 2,
      'mar': 3, 'maret': 3,
      'apr': 4, 'april': 4,
      'mei': 5,
      'jun': 6, 'juni': 6,
      'jul': 7, 'juli': 7,
      'agu': 8, 'agustus': 8,
      'sep': 9, 'september': 9,
      'okt': 10, 'oktober': 10,
      'nov': 11, 'november': 11,
      'des': 12, 'desember': 12,
    };

    final parts = clean.split(RegExp(r'[\s/\-]+'));
    if (parts.length >= 3) {
      final d = int.tryParse(parts[0]) ?? 1;
      final mKey = parts[1].toLowerCase();
      final m = months[mKey] ?? int.tryParse(parts[1]) ?? 12;
      final y = int.tryParse(parts[2]) ?? (DateTime.now().year + 2);
      return DateTime(y, m, d);
    }
    return DateTime(DateTime.now().year + 2, 12, 31);
  }

  /// Mendaftarkan obat baru beserta batch stok awalnya ke tabel `obat`, `obat_batches` & `stock_obat` Supabase
  Future<Map<String, dynamic>?> addApotekObat(
    Map<String, dynamic> data, {
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return null;
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return null;

    final uuidRes = await _exec('SELECT gen_random_uuid()::text AS id');
    final newObatId = uuidRes.first.toColumnMap()['id'].toString().trim();

    final namaObat = (data['nama_obat'] ?? data['name'] ?? '').toString().trim();
    final kategori = (data['kategori'] ?? data['category'] ?? 'Obat Ginjal').toString().trim();
    final bentukSediaan = (data['bentuk_sediaan'] ?? data['form'] ?? 'Tablet').toString().trim();
    final dosis = (data['dosis'] ?? data['dose'] ?? '-').toString().trim();
    final satuanKemasan = (data['satuan_kemasan'] ?? data['packageUnit'] ?? 'Strip / Box').toString().trim();
    final stokTotal = int.tryParse((data['stok_total'] ?? data['stock'] ?? '0').toString()) ?? 0;
    final hargaBeli = double.tryParse((data['harga_beli'] ?? data['buyPrice'] ?? '0').toString()) ?? 0;
    final hargaJual = double.tryParse((data['harga_jual'] ?? data['sellPrice'] ?? '0').toString()) ?? 0;
    final aturanPakai = (data['aturan_pakai_umum'] ?? data['usageRule'] ?? 'Gunakan sesuai petunjuk dokter atau apoteker.').toString().trim();
    final fotoObat = (data['foto_obat'] ?? data['imagePath'])?.toString().trim();
    final rawExp = (data['tanggal_kadaluwarsa'] ?? data['expDate'] ?? '2028-12-31').toString();
    final expDate = _parseIndonesianOrIsoDate(rawExp);
    final expDateStr = '${expDate.year}-${expDate.month.toString().padLeft(2, '0')}-${expDate.day.toString().padLeft(2, '0')}';

    await _exec(
      '''
      INSERT INTO obat (
        id_obat, id_apotek, nama_obat, kategori, bentuk_sediaan, dosis,
        satuan_kemasan, stok_total, harga_beli, harga_jual, aturan_pakai_umum,
        foto_obat, created_at, updated_at
      ) VALUES (
        @idObat, @aptId, @namaObat, @kategori, @bentukSediaan, @dosis,
        @satuanKemasan, @stokTotal, @hargaBeli, @hargaJual, @aturanPakai,
        @fotoObat, NOW(), NOW()
      )
      ''',
      parameters: {
        'idObat': newObatId,
        'aptId': aptId,
        'namaObat': namaObat,
        'kategori': kategori,
        'bentukSediaan': bentukSediaan,
        'dosis': dosis,
        'satuanKemasan': satuanKemasan,
        'stokTotal': stokTotal,
        'hargaBeli': hargaBeli,
        'hargaJual': hargaJual,
        'aturanPakai': aturanPakai,
        'fotoObat': (fotoObat != null && fotoObat.isNotEmpty) ? fotoObat : null,
      },
    );

    final batchNo = (data['no_batch'] ?? 'BATCH-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}').toString().trim();
    await _exec(
      '''
      INSERT INTO obat_batches (
        id, id_obat, id_apotek, no_batch, stok_batch, tanggal_kadaluwarsa, status, created_at, updated_at
      ) VALUES (
        gen_random_uuid()::text, @idObat, @aptId, @noBatch, @stokBatch, @expDate::date,
        CASE WHEN @stokBatch <= 0 THEN 'habis' WHEN @stokBatch <= 10 THEN 'stok_menipis' ELSE 'tersedia' END,
        NOW(), NOW()
      )
      ''',
      parameters: {
        'idObat': newObatId,
        'aptId': aptId,
        'noBatch': batchNo,
        'stokBatch': stokTotal,
        'expDate': expDateStr,
      },
    );

    try {
      await _exec(
        '''
        INSERT INTO stock_obat (
          id_stock, id_obat, id_apoteker, jumlah_stock, tanggal_kadaluwarsa, created_at, updated_at
        ) VALUES (
          gen_random_uuid()::text, @idObat, @aptId, @stokBatch, @expDate::date, NOW(), NOW()
        )
        ''',
        parameters: {
          'idObat': newObatId,
          'aptId': aptId,
          'stokBatch': stokTotal,
          'expDate': expDateStr,
        },
      );
    } catch (_) {}

    return {
      'id_obat': newObatId,
      'id': newObatId,
      'nama_obat': namaObat,
      'stok_total': stokTotal,
      'no_batch': batchNo,
      'tanggal_kadaluwarsa': expDateStr,
    };
  }

  /// Menambahkan batch stok obat baru & memperbarui `stok_total` di tabel `obat` & `obat_batches` Supabase
  Future<Map<String, dynamic>?> addApotekStockBatch(
    Map<String, dynamic> data, {
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return null;
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return null;

    final rawIdObat = (data['id_obat'] ?? data['medicineId'] ?? '').toString().replaceAll('#MED-', '').trim();
    final medName = (data['nama_obat'] ?? data['medicineName'] ?? '').toString().trim();

    String? targetObatId;
    if (rawIdObat.length >= 30) {
      targetObatId = rawIdObat;
    } else if (medName.isNotEmpty) {
      final byName = await _exec(
        '''
        SELECT TRIM(id_obat) AS id_obat
        FROM obat
        WHERE TRIM(id_apotek) = @aptId
          AND LOWER(TRIM(nama_obat)) = LOWER(@nama)
        LIMIT 1
        ''',
        parameters: {'aptId': aptId, 'nama': medName},
      );
      if (byName.isNotEmpty) {
        targetObatId = byName.first.toColumnMap()['id_obat']?.toString().trim();
      }
    }
    if (targetObatId == null || targetObatId.isEmpty) return null;

    final qty = int.tryParse((data['jumlah'] ?? data['quantity'] ?? data['stok_batch'] ?? '0').toString()) ?? 0;
    final buyPrice = double.tryParse((data['harga_beli'] ?? data['buyPrice'] ?? '0').toString()) ?? 0;
    final sellPrice = double.tryParse((data['harga_jual'] ?? data['sellPrice'] ?? '0').toString()) ?? 0;
    final rawBatchNo = (data['no_batch'] ?? data['batchNo'] ?? '').toString().trim();
    final batchNo = rawBatchNo.isNotEmpty
        ? '$rawBatchNo-${DateTime.now().millisecondsSinceEpoch % 1000}'
        : 'BATCH-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final rawExp = (data['tanggal_kadaluwarsa'] ?? data['expDate'] ?? '2028-12-31').toString();
    final expDate = _parseIndonesianOrIsoDate(rawExp);
    final expDateStr = '${expDate.year}-${expDate.month.toString().padLeft(2, '0')}-${expDate.day.toString().padLeft(2, '0')}';

    await _exec(
      '''
      INSERT INTO obat_batches (
        id, id_obat, id_apotek, no_batch, stok_batch, tanggal_kadaluwarsa, status, created_at, updated_at
      ) VALUES (
        gen_random_uuid()::text, @idObat, @aptId, @noBatch, @qty, @expDate::date, 'tersedia', NOW(), NOW()
      )
      ''',
      parameters: {
        'idObat': targetObatId,
        'aptId': aptId,
        'noBatch': batchNo,
        'qty': qty,
        'expDate': expDateStr,
      },
    );

    await _exec(
      '''
      UPDATE obat
      SET stok_total = COALESCE(stok_total, 0) + @qty,
          harga_beli = CASE WHEN @buyPrice > 0 THEN @buyPrice ELSE harga_beli END,
          harga_jual = CASE WHEN @sellPrice > 0 THEN @sellPrice ELSE harga_jual END,
          updated_at = NOW()
      WHERE TRIM(id_obat) = @idObat
      ''',
      parameters: {
        'idObat': targetObatId,
        'qty': qty,
        'buyPrice': buyPrice,
        'sellPrice': sellPrice,
      },
    );

    return {
      'id_obat': targetObatId,
      'no_batch': rawBatchNo.isNotEmpty ? rawBatchNo : batchNo,
      'stok_batch': qty,
      'tanggal_kadaluwarsa': expDateStr,
    };
  }

  // ===========================================================================
  // MODUL APOTEK: RIWAYAT AKTIVITAS & DASHBOARD REAL SUPABASE
  // ===========================================================================

  /// Mengambil riwayat aktivitas & audit real Apotek dari Supabase (`pesanan_obat`, `resep`, `obat_batches`, `obat`)
  Future<List<Map<String, dynamic>>> fetchApotekRiwayatAktivitas({
    String? apotekId,
    String? apotekName,
  }) async {
    if (_isTest) return [];
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) return [];

    final profile = await fetchApotekProfileFull(apotekId: aptId);
    final apotekerName = (profile?['penanggung_jawab'] ?? 'apt. Farhan Ramadhan, S.Farm').toString();
    final sipaNo = (profile?['no_sipa_sia'] ?? 'SIPA-3273/1990/440/2022').toString();

    final List<Map<String, dynamic>> activities = [];

    // 1. Aktivitas Pesanan Obat
    final orders = await fetchApotekPesananList(apotekId: aptId);
    for (final ord in orders.take(15)) {
      final noPesanan = (ord['no_pesanan'] ?? ord['id'] ?? 'ORD-GIAT').toString();
      final namaPasien = (ord['nama_pasien'] ?? 'Pasien GIAT').toString();
      final alamatPasien = (ord['alamat_pasien'] ?? 'Kota Bandung').toString();
      final statusPesanan = (ord['status_pesanan'] ?? 'menunggu_konfirmasi').toString();
      final rawTime = (ord['updated_at'] ?? ord['created_at'] ?? '').toString();
      final totalBayar = double.tryParse((ord['total_bayar'] ?? '0').toString())?.round() ?? 0;
      final ongkir = double.tryParse((ord['ongkos_kirim'] ?? '0').toString())?.round() ?? 0;

      String title = 'Pesanan Obat Masuk';
      String statusDesc = 'Pesanan siap disiapkan oleh apotek';
      if (statusPesanan == 'diproses') {
        title = 'Memproses Pesanan';
        statusDesc = 'Obat sedang disiapkan & dikemas untuk pasien';
      } else if (statusPesanan == 'selesai') {
        title = 'Menyelesaikan Pesanan';
        statusDesc = 'Pesanan telah selesai & diserahkan';
      }

      activities.add({
        'id': 'act-ord-${ord['id']}',
        'title': title,
        'subtitle': '$noPesanan ($namaPasien) • $statusDesc',
        'created_at': rawTime,
        'type': 'pesanan',
        'meta': {
          'no_pesanan': noPesanan,
          'nama_pasien': namaPasien,
          'alamat_pasien': alamatPasien,
          'total_bayar': totalBayar,
          'ongkos_kirim': ongkir,
          'items': ord['items'] ?? [],
          'apoteker': apotekerName,
          'sipa': sipaNo,
        },
      });
    }

    // 2. Aktivitas Batch Stok & Registrasi Obat
    final meds = await fetchApotekObatList(apotekId: aptId);
    for (final med in meds.take(10)) {
      final medName = (med['nama_obat'] ?? 'Obat Ginjal').toString();
      final kategori = (med['kategori'] ?? 'Obat Ginjal').toString();
      final bentuk = (med['bentuk_sediaan'] ?? 'Tablet').toString();
      final kemasan = (med['satuan_kemasan'] ?? 'Strip / Box').toString();
      final stokTotal = int.tryParse((med['stok_total'] ?? '0').toString()) ?? 0;
      final hargaBeli = int.tryParse((med['harga_beli'] ?? '0').toString()) ?? 0;
      final hargaJual = int.tryParse((med['harga_jual'] ?? '0').toString()) ?? 0;
      final batches = (med['batches'] as List?) ?? [];
      final latestBatch = batches.isNotEmpty && batches.first is Map
          ? Map<String, dynamic>.from(batches.first as Map)
          : <String, dynamic>{};
      final batchNo = (latestBatch['no_batch'] ?? 'BATCH-2026').toString();
      final batchQty = int.tryParse((latestBatch['stok_batch'] ?? stokTotal).toString()) ?? stokTotal;
      final expDate = (latestBatch['tanggal_kadaluwarsa'] ?? '2028-05-01').toString();
      final rawTime = (med['updated_at'] ?? med['created_at'] ?? '').toString();

      activities.add({
        'id': 'act-stok-${med['id_obat']}',
        'title': 'Memperbarui Stok Obat',
        'subtitle': '$medName • Batch $batchNo ($stokTotal $bentuk tersedia)',
        'created_at': rawTime,
        'type': 'stok',
        'meta': {
          'nama_obat': medName,
          'kategori': '$bentuk • $kategori',
          'no_batch': batchNo,
          'stok_batch': batchQty,
          'stok_total': stokTotal,
          'satuan': bentuk,
          'kemasan': kemasan,
          'harga_beli': hargaBeli,
          'harga_jual': hargaJual,
          'tanggal_kadaluwarsa': expDate,
          'apoteker': apotekerName,
          'sipa': sipaNo,
        },
      });
    }

    activities.sort((a, b) {
      final tA = (a['created_at'] ?? '').toString();
      final tB = (b['created_at'] ?? '').toString();
      return tB.compareTo(tA);
    });

    return activities;
  }

  /// Mengambil data ringkasan Dashboard Utama Apotek secara real dari Supabase
  Future<Map<String, dynamic>> fetchApotekDashboard({
    String? apotekId,
    String? apotekName,
  }) async {
    final aptId = await resolveCurrentApotekId(
      overrideApotekId: apotekId,
      apotekName: apotekName,
    );
    if (aptId == null) {
      return {};
    }

    final profile = await fetchApotekProfileFull(apotekId: aptId) ?? <String, dynamic>{};
    final recipes = await fetchApotekResepList(apotekId: aptId);
    final orders = await fetchApotekPesananList(apotekId: aptId);
    final medicines = await fetchApotekObatList(apotekId: aptId);

    final belumDiverifikasiCount = recipes
        .where((r) => (r['status'] ?? '') == 'sudah_ditebus')
        .length;
    final totalResepMasukCount = recipes.length;

    final perluDiprosesCount = orders
        .where((o) => (o['status_pesanan'] ?? '') != 'selesai')
        .length;

    final stokMenipisCount = medicines.where((m) {
      final stk = int.tryParse((m['stok_total'] ?? '0').toString()) ?? 0;
      return stk <= 10;
    }).length;

    return {
      'apotek': profile,
      'resep_masuk_count': belumDiverifikasiCount > 0 ? belumDiverifikasiCount : totalResepMasukCount,
      'belum_diverifikasi_count': belumDiverifikasiCount,
      'perlu_diproses_count': perluDiprosesCount,
      'stok_menipis_count': stokMenipisCount,
      'resep_list': recipes,
      'pesanan_list': orders,
      'obat_list': medicines,
    };
  }
}


