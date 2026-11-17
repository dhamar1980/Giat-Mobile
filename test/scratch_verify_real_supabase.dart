import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  print('=== TESTING REAL SUPABASE POSTGRESQL CONNECTION ===');
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
      settings: ConnectionSettings(
        sslMode: SslMode.require,
        connectTimeout: const Duration(seconds: 10),
        queryTimeout: const Duration(seconds: 15),
      ),
    );

    print('Connected successfully in ${stopwatch.elapsedMilliseconds} ms!');
    stopwatch.reset();

    // Check tables & counts
    final tables = [
      'user',
      'pasien',
      'dokter',
      'apotek',
      'obat',
      'konsultasi',
      'resep',
      'resep_item',
      'pesanan_obat',
      'pesanan_obat_items',
      'pesanan_obat_trackings',
      'notifikasi',
      'reminders',
      'pragi_skrining',
      'ulasan_dokter',
    ];

    print('\n--- Table Row Counts & Query Timings ---');
    for (final table in tables) {
      final tWatch = Stopwatch()..start();
      final res = await conn.execute('SELECT COUNT(*) FROM "$table"');
      final count = res.first[0];
      print('Table "$table": $count rows (${tWatch.elapsedMilliseconds} ms)');
    }

    // Check user sync across roles
    print('\n--- Verifying User Synchronization Across Roles ---');
    final usersRes = await conn.execute('SELECT id, email, role, is_active FROM "user" ORDER BY role, email');
    print('Total users in auth "user" table: ${usersRes.length}');
    for (final row in usersRes) {
      final id = row[0].toString();
      final email = row[1].toString();
      final role = row[2].toString();
      final isActive = row[3];

      String detailInfo = 'NO DETAIL FOUND';
      if (role == 'pasien') {
        final pRes = await conn.execute(Sql.named('SELECT nama, no_hp FROM "pasien" WHERE id_pasien = @id'), parameters: {'id': id});
        if (pRes.isNotEmpty) {
          detailInfo = 'Pasien: ${pRes.first[0]} (${pRes.first[1]})';
        }
      } else if (role == 'dokter') {
        final dRes = await conn.execute(Sql.named('SELECT nama, spesialisasi, tarif_konsultasi FROM "dokter" WHERE id_dokter = @id'), parameters: {'id': id});
        if (dRes.isNotEmpty) {
          detailInfo = 'Dokter: ${dRes.first[0]} - ${dRes.first[1]} (Tarif: ${dRes.first[2]})';
        }
      } else if (role == 'apotek') {
        final aRes = await conn.execute(Sql.named('SELECT nama_apotek, penanggung_jawab FROM "apotek" WHERE id_apotek = @id'), parameters: {'id': id});
        if (aRes.isNotEmpty) {
          detailInfo = 'Apotek: ${aRes.first[0]} (PJ: ${aRes.first[1]})';
        }
      } else if (role == 'admin') {
        detailInfo = 'Admin System';
      }

      print('  [$role] $email (Active: $isActive) -> $detailInfo');
    }

    // Check consultations & prescriptions & orders sync
    print('\n--- Verifying Consultation -> Resep -> Pesanan Obat Flow ---');
    final konsRes = await conn.execute('''
      SELECT k.id, k.id_pasien, p.nama as nama_pasien, k.id_dokter, d.nama as nama_dokter, 
             k.status, k.tanggal_konsultasi, k.jam_mulai, k.jam_selesai
      FROM "konsultasi" k
      LEFT JOIN "pasien" p ON k.id_pasien = p.id_pasien
      LEFT JOIN "dokter" d ON k.id_dokter = d.id_dokter
      ORDER BY k.created_at DESC
      LIMIT 5
    ''');
    print('Recent Consultations (${konsRes.length}):');
    for (final row in konsRes) {
      print('  Konsultasi ID: ${row[0]} | Pasien: ${row[2]} | Dokter: ${row[4]} | Status: ${row[5]} | Tgl: ${row[6]} ${row[7]}');
      
      // Check resep linked to this konsultasi
      final resepRes = await conn.execute(Sql.named('SELECT id, no_resep, status, diagnosis FROM "resep" WHERE id_konsultasi = @kId'), parameters: {'kId': row[0]});
      for (final rRow in resepRes) {
        print('    -> Resep: ${rRow[1]} | Status: ${rRow[2]} | Diagnosis: ${rRow[3]}');
        final itemsRes = await conn.execute(Sql.named('SELECT ri.nama_obat, ri.jumlah, ri.aturan_pakai, ri.harga FROM "resep_item" ri WHERE ri.id_resep = @rId'), parameters: {'rId': rRow[0]});
        for (final iRow in itemsRes) {
          print('       Item: ${iRow[0]} x${iRow[1]} (${iRow[2]}) @ Rp ${iRow[3]}');
        }
      }
    }

    // Check Pesanan Obat
    print('\n--- Recent Pesanan Obat ---');
    final pesananRes = await conn.execute('''
      SELECT po.id, po.no_pesanan, p.nama, a.nama_apotek, po.total_bayar, po.status_pesanan, po.status_pembayaran
      FROM "pesanan_obat" po
      LEFT JOIN "pasien" p ON po.id_pasien = p.id_pasien
      LEFT JOIN "apotek" a ON po.id_apotek = a.id_apotek
      ORDER BY po.created_at DESC
      LIMIT 5
    ''');
    for (final row in pesananRes) {
      print('  Pesanan: ${row[1]} | Pasien: ${row[2]} | Apotek: ${row[3]} | Total: Rp ${row[4]} | Status: ${row[5]} | Pembayaran: ${row[6]}');
    }

    await conn.close();
    print('\n=== ALL SUPABASE QUERIES EXECUTED SUCCESSFULLY ===');
  } catch (e, st) {
    print('ERROR connecting to Supabase: $e');
    print(st);
  }
}
