import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import '../constants/api_constants.dart';

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
    final gambarUrl = gambar.startsWith('http')
        ? gambar
        : 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=600&q=80';

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
        'gambar_url': gambar,
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

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> raw) {
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      if (value is DateTime) {
        result[key] = value.toIso8601String();
      } else if (value is String) {
        result[key] = value.trim();
      } else {
        result[key] = value;
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
}

