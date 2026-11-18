import 'package:postgres/postgres.dart';

void main() async {
  print('=== MIGRATING & VERIFYING REAL SUPABASE JEMBER ECOSYSTEM ===');
  final stopwatch = Stopwatch()..start();

  try {
    final conn = await Connection.open(
      Endpoint(
        host: 'aws-0-ap-northeast-1.pooler.supabase.com',
        port: 5432,
        database: 'postgres',
        username: 'postgres.auaejgogiyfrefsurahd',
        password: 'KnWPC0g1ajTd2VJ8',
      ),
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
        connectTimeout: Duration(seconds: 10),
        queryTimeout: Duration(seconds: 20),
      ),
    );

    print('Connected to Supabase in ${stopwatch.elapsedMilliseconds} ms!');

    const passHash = r'$2y$12$xdjv21QQAurUCyyQbIAnA.Sikyuk1W8NzKYHnnUQE6cbsOPcVaDFK';

    // 1. Update all user emails to @gmail.com & password to password123
    await conn.execute(
      Sql.named(r'''
      UPDATE "user"
      SET password = @hash,
          email = CASE
            WHEN LOWER(TRIM(email)) = 'apotek.dago@kimiafarma.co.id' THEN 'apotek.kimiafarma.jember@gmail.com'
            WHEN LOWER(TRIM(email)) = 'apotek.buahbatu@k24.co.id' THEN 'apotek.k24.jember@gmail.com'
            WHEN LOWER(TRIM(email)) LIKE '%@giat.id' THEN REPLACE(LOWER(TRIM(email)), '@giat.id', '@gmail.com')
            WHEN LOWER(TRIM(email)) NOT LIKE '%@gmail.com' THEN SPLIT_PART(LOWER(TRIM(email)), '@', 1) || '@gmail.com'
            ELSE LOWER(TRIM(email))
          END,
          is_active = true,
          updated_at = NOW()
      '''),
      parameters: {'hash': passHash},
    );

    // 2. Update Apotek in Jember
    final apotekRows = await conn.execute('''
      SELECT TRIM(a.id_apotek) AS id, u.email
      FROM apotek a
      LEFT JOIN "user" u ON TRIM(u.id) = TRIM(a.id_apotek)
      ORDER BY a.created_at ASC
    ''');

    final jemberApoteks = [
      {
        'nama': 'Apotek Kimia Farma Jember',
        'email': 'apotek.kimiafarma.jember@gmail.com',
        'pj': 'apt. Farhan Ramadhan, S.Farm',
        'sipa': '19910412/SIPA-35.09/2024',
        'noHp': '0331484321',
        'alamat': 'Jl. Gajah Mada No. 175, Kaliwates, Kabupaten Jember, Jawa Timur 68131',
        'latLng': '-8.1747,113.6882',
      },
      {
        'nama': 'Apotek K-24 Sumbersari Jember',
        'email': 'apotek.k24.jember@gmail.com',
        'pj': 'apt. Maya Sartika, S.Farm',
        'sipa': '19930821/SIPA-35.09/2024',
        'noHp': '0331338240',
        'alamat': 'Jl. Kalimantan No. 42, Sumbersari, Kabupaten Jember, Jawa Timur 68121',
        'latLng': '-8.1685,113.7148',
      },
      {
        'nama': 'Apotek Sehat Ginjal Sentosa Jember',
        'email': 'apotek.sentosa@gmail.com',
        'pj': 'apt. Hendra Gunawan, S.Farm',
        'sipa': '19891105/SIPA-35.09/2024',
        'noHp': '0331489112',
        'alamat': 'Jl. Slamet Riyadi No. 68, Patrang, Kabupaten Jember, Jawa Timur 68111',
        'latLng': '-8.1536,113.7126',
      },
    ];

    for (int i = 0; i < apotekRows.length; i++) {
      final aptId = apotekRows[i][0].toString().trim();
      final email = (apotekRows[i][1] ?? '').toString().toLowerCase();

      Map<String, String> targetApt;
      if (email.contains('kimiafarma') || aptId == '5cdfd84d-0124-4abf-a778-e8db2801863f') {
        targetApt = jemberApoteks[0];
      } else if (email.contains('k24') || email.contains('buahbatu')) {
        targetApt = jemberApoteks[1];
      } else if (email.contains('sentosa')) {
        targetApt = jemberApoteks[2];
      } else {
        targetApt = jemberApoteks[i % jemberApoteks.length];
      }

      await conn.execute(
        Sql.named('''
        UPDATE apotek
        SET nama_apotek = @nama,
            penanggung_jawab = @pj,
            no_sipa_sia = @sipa,
            no_hp = @noHp,
            alamat = @alamat,
            lokasi_lat_long = @latLng,
            status_layanan = true,
            updated_at = NOW()
        WHERE TRIM(id_apotek) = @id
        '''),
        parameters: {
          'id': aptId,
          'nama': targetApt['nama'],
          'pj': targetApt['pj'],
          'sipa': targetApt['sipa'],
          'noHp': targetApt['noHp'],
          'alamat': targetApt['alamat'],
          'latLng': targetApt['latLng'],
        },
      );

      await conn.execute(
        Sql.named('''
        UPDATE "user"
        SET email = @email,
            keterangan = @alamat,
            updated_at = NOW()
        WHERE TRIM(id) = @id
        '''),
        parameters: {
          'id': aptId,
          'email': targetApt['email'],
          'alamat': targetApt['alamat'],
        },
      );

      await conn.execute(
        Sql.named('DELETE FROM apotek_area_layanan WHERE TRIM(id_apotek) = @aptId'),
        parameters: {'aptId': aptId},
      );

      final jemberAreas = [
        {'nama': 'Kecamatan Sumbersari, Jember', 'detail': 'Kampus UNEJ, Jl. Kalimantan, Jl. Mastrip, Jl. Jawa & Tegalgede', 'active': true},
        {'nama': 'Kecamatan Kaliwates, Jember', 'detail': 'Jl. Gajah Mada, Jl. Hayam Wuruk, Jl. Sultan Agung & Sempusari', 'active': true},
        {'nama': 'Kecamatan Patrang, Jember', 'detail': 'RSD dr. Soebandi, Jl. Slamet Riyadi, Jl. PB Sudirman & Gebang', 'active': true},
        {'nama': 'Kecamatan Ajung, Jember', 'detail': 'Kawasan Mangli, Wirowongso & Ajung Selatan', 'active': true},
        {'nama': 'Kecamatan Pakusari, Jember', 'detail': 'Koridor Timur Kota Jember & Kertosari', 'active': true},
        {'nama': 'Kecamatan Rambipuji, Jember', 'detail': 'Koridor Barat Jember & Rambigundam', 'active': false},
        {'nama': 'Kecamatan Balung, Jember', 'detail': 'RSD Balung & Kawasan Jember Selatan', 'active': false},
      ];
      for (final ar in jemberAreas) {
        await conn.execute(
          Sql.named('''
          INSERT INTO apotek_area_layanan (id, id_apotek, nama_area, detail, is_active, created_at, updated_at)
          VALUES (gen_random_uuid()::text, @aptId, @nama, @detail, @active, NOW(), NOW())
          '''),
          parameters: {
            'aptId': aptId,
            'nama': ar['nama'],
            'detail': ar['detail'],
            'active': ar['active'],
          },
        );
      }

      // Ensure medicines exist for each Jember pharmacy
      final cntRes = await conn.execute(
        Sql.named('SELECT COUNT(*)::int FROM obat WHERE TRIM(id_apotek) = @aptId'),
        parameters: {'aptId': aptId},
      );
      final medCnt = (cntRes.first[0] as int?) ?? 0;
      if (medCnt == 0) {
        final masterMeds = await conn.execute('''
          SELECT nama_obat, kategori, bentuk_sediaan, dosis, satuan_kemasan, stok_total, harga_beli, harga_jual, aturan_pakai_umum, foto_obat
          FROM obat
          LIMIT 6
        ''');
        for (final mr in masterMeds) {
          final mm = mr.toColumnMap();
          await conn.execute(
            Sql.named('''
            INSERT INTO obat (
              id_obat, id_apotek, nama_obat, kategori, bentuk_sediaan, dosis,
              satuan_kemasan, stok_total, harga_beli, harga_jual, aturan_pakai_umum, foto_obat, created_at, updated_at
            ) VALUES (
              gen_random_uuid()::text, @aptId, @nama, @kat, @bentuk, @dosis,
              @kemasan, @stok, @hb, @hj, @aturan, @foto, NOW(), NOW()
            )
            '''),
            parameters: {
              'aptId': aptId,
              'nama': mm['nama_obat'],
              'kat': mm['kategori'],
              'bentuk': mm['bentuk_sediaan'],
              'dosis': mm['dosis'],
              'kemasan': mm['satuan_kemasan'],
              'stok': mm['stok_total'] ?? 100,
              'hb': mm['harga_beli'] ?? 45000,
              'hj': mm['harga_jual'] ?? 65000,
              'aturan': mm['aturan_pakai_umum'],
              'foto': mm['foto_obat'],
            },
          );
        }
      }
    }

    // 3. Update Dokter to Jember Hospitals
    final docRows = await conn.execute('''
      SELECT TRIM(d.id_dokter) AS id, d.nama, d.spesialisasi, u.email
      FROM dokter d
      LEFT JOIN "user" u ON TRIM(u.id) = TRIM(d.id_dokter)
      ORDER BY d.created_at ASC
    ''');

    final rsList = [
      {
        'namaRs': 'RSD dr. Soebandi Jember',
        'alamat': 'Jl. Dr. Soebandi No. 124, Patrang, Kabupaten Jember, Jawa Timur 68111',
        'lat': -8.1518,
        'lng': 113.7153,
      },
      {
        'namaRs': 'RS Perkebunan Jember Klinik',
        'alamat': 'Jl. Bedadung No. 2, Jemberlor, Patrang, Kabupaten Jember, Jawa Timur 68118',
        'lat': -8.1653,
        'lng': 113.7024,
      },
      {
        'namaRs': 'RS Bina Sehat Jember',
        'alamat': 'Jl. Jayanegara No. 7, Kaliwates, Kabupaten Jember, Jawa Timur 68131',
        'lat': -8.1802,
        'lng': 113.6915,
      },
      {
        'namaRs': 'RS Citra Husada Jember',
        'alamat': 'Jl. Teratai No. 22, Gebang, Patrang, Kabupaten Jember, Jawa Timur 68117',
        'lat': -8.1689,
        'lng': 113.6942,
      },
      {
        'namaRs': 'RS Siloam Jember',
        'alamat': 'Jl. Gajah Mada No. 104, Kaliwates, Kabupaten Jember, Jawa Timur 68131',
        'lat': -8.1731,
        'lng': 113.6938,
      },
      {
        'namaRs': 'RSD Balung Jember',
        'alamat': 'Jl. Rambipuji No. 19, Balung Lor, Balung, Kabupaten Jember, Jawa Timur 68161',
        'lat': -8.2735,
        'lng': 113.5322,
      },
    ];

    for (int i = 0; i < docRows.length; i++) {
      final docId = docRows[i][0].toString().trim();
      final docNama = (docRows[i][1] ?? 'dr. Spesialis GIAT').toString();
      final rawSpec = (docRows[i][2] ?? '').toString();
      final cleanSpec = (rawSpec.contains('Jl.') || rawSpec.contains('Bandung') || rawSpec.isEmpty)
          ? 'Dokter Spesialis Penyakit Dalam'
          : rawSpec;

      Map<String, dynamic> rs = rsList[i % rsList.length];
      final lowerName = docNama.toLowerCase();
      if (lowerName.contains('andi')) {
        rs = rsList[0];
      } else if (lowerName.contains('budi')) {
        rs = rsList[1];
      } else if (lowerName.contains('citra')) {
        rs = rsList[2];
      } else if (lowerName.contains('dedi')) {
        rs = rsList[3];
      } else if (lowerName.contains('eka')) {
        rs = rsList[4];
      } else if (lowerName.contains('rina')) {
        rs = rsList[5];
      }

      final formattedName = docNama.toLowerCase().startsWith('dr.')
          ? docNama
          : 'dr. $docNama, Sp.PD';

      final bioJson =
          '{"alamat_praktik":"${rs['alamat']}","latitude":${rs['lat']},"longitude":${rs['lng']},"jadwal_praktik":"Senin - Jumat, 08:00 - 16:00 WIB","notif_chat":true,"notif_jadwal":true,"notif_update":true}';

      await conn.execute(
        Sql.named('''
        UPDATE dokter
        SET nama = @nama,
            spesialisasi = @spec,
            institusi = @inst,
            bio = @bio,
            updated_at = NOW()
        WHERE TRIM(id_dokter) = @id
        '''),
        parameters: {
          'id': docId,
          'nama': formattedName,
          'spec': cleanSpec,
          'inst': rs['namaRs'],
          'bio': bioJson,
        },
      );

      await conn.execute(
        Sql.named('''
        UPDATE "user"
        SET keterangan = @ket,
            updated_at = NOW()
        WHERE TRIM(id) = @id
        '''),
        parameters: {
          'id': docId,
          'ket': '$cleanSpec • ${rs['namaRs']}',
        },
      );
    }

    // 4. Update Pasien addresses to Jember
    final pasRows = await conn.execute(
      'SELECT TRIM(id_pasien) AS id, nama, alamat FROM pasien ORDER BY created_at ASC',
    );
    final jemberPatientAddresses = [
      'Jl. Kalimantan No. 37, Sumbersari, Kabupaten Jember, Jawa Timur 68121',
      'Jl. Mastrip No. 45, Tegalgede, Sumbersari, Kabupaten Jember, Jawa Timur 68124',
      'Jl. Gajah Mada No. 142, Kaliwates, Kabupaten Jember, Jawa Timur 68131',
      'Jl. Jawa No. 28, Sumbersari, Kabupaten Jember, Jawa Timur 68121',
      'Jl. PB Sudirman No. 42, Patrang, Kabupaten Jember, Jawa Timur 68118',
      'Jl. Hayam Wuruk No. 88, Sempusari, Kaliwates, Kabupaten Jember, Jawa Timur 68135',
      'Jl. Slamet Riyadi No. 54, Patrang, Kabupaten Jember, Jawa Timur 68111',
    ];
    for (int i = 0; i < pasRows.length; i++) {
      final pid = pasRows[i][0].toString().trim();
      final currAddr = (pasRows[i][2] ?? '').toString().trim();
      if (currAddr.isEmpty ||
          currAddr.toLowerCase().contains('bandung') ||
          currAddr.toLowerCase().contains('jakarta') ||
          !currAddr.toLowerCase().contains('jember')) {
        final newAddr = jemberPatientAddresses[i % jemberPatientAddresses.length];
        await conn.execute(
          Sql.named('UPDATE pasien SET alamat = @alamat, updated_at = NOW() WHERE TRIM(id_pasien) = @id'),
          parameters: {'id': pid, 'alamat': newAddr},
        );
        await conn.execute(
          Sql.named('UPDATE "user" SET keterangan = @alamat, updated_at = NOW() WHERE TRIM(id) = @id'),
          parameters: {'id': pid, 'alamat': newAddr},
        );
      }
    }

    // 5. Update pesanan_obat addresses to Jember
    await conn.execute('''
      UPDATE pesanan_obat
      SET alamat_pengiriman = 'Jl. Kalimantan No. 37, Sumbersari, Kabupaten Jember, Jawa Timur 68121',
          updated_at = NOW()
      WHERE alamat_pengiriman IS NULL
         OR LOWER(alamat_pengiriman) LIKE '%bandung%'
    ''');

    // Print verification report
    print('\n--- VERIFIED USERS IN SUPABASE (ALL @gmail.com & password123 & JEMBER) ---');
    final usersRes = await conn.execute(r'''
      SELECT
        u.role,
        u.email,
        (extensions.crypt('password123', replace(u.password, '$2y$', '$2a$')) = replace(u.password, '$2y$', '$2a$')) AS pass_ok,
        COALESCE(d.nama, p.nama, ap.nama_apotek, ad.nama) AS nama,
        COALESCE(d.institusi, ap.alamat, p.alamat, 'Pusat Admin Jember') AS lokasi_jember,
        ap.lokasi_lat_long
      FROM "user" u
      LEFT JOIN dokter d ON TRIM(d.id_dokter) = TRIM(u.id)
      LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(u.id)
      LEFT JOIN apotek ap ON TRIM(ap.id_apotek) = TRIM(u.id)
      LEFT JOIN admin ad ON TRIM(ad.id_admin) = TRIM(u.id)
      ORDER BY u.role, u.email
    ''');

    for (final row in usersRes) {
      print('  [${row[0]}] ${row[1]} (Pass123 Valid: ${row[2]}) -> ${row[3]} | Lokasi: ${row[4]} ${row[5] != null ? "(GPS: ${row[5]})" : ""}');
    }

    await conn.close();
    print('\n=== SUPABASE JEMBER MIGRATION COMPLETED SUCCESSFULLY ===');
  } catch (e, st) {
    print('ERROR: $e\n$st');
  }
}
