import 'package:flutter_test/flutter_test.dart';
import 'package:giat/services/supabase_admin_service.dart';

void main() {
  test('Verify Real Users Auth & Cross-Role Sync against Supabase', () async {
    print('====================================================');
    print('TESTING REAL USERS AUTHENTICATION & CROSS-ROLE SYNC');
    print('====================================================');

    final testUsers = [
      {'email': 'siti.aisyah@gmail.com', 'pass': 'password123', 'expectedRole': 'pasien'},
      {'email': 'dr.budi.santoso@giat.id', 'pass': 'password123', 'expectedRole': 'dokter'},
      {'email': 'apotek.dago@kimiafarma.co.id', 'pass': 'password123', 'expectedRole': 'apotek'},
      {'email': 'admin@gmail.com', 'pass': 'password123', 'expectedRole': 'admin'},
    ];

    final authStopwatch = Stopwatch()..start();
    for (final u in testUsers) {
      final sw = Stopwatch()..start();
      final res = await SupabaseAdminService.instance.authenticateUser(
        email: u['email']!,
        password: u['pass']!,
      );
      sw.stop();

      expect(res, isNotNull, reason: 'Auth failed for ${u['email']}');
      expect(res!['role'], equals(u['expectedRole']));
      print('✅ AUTH SUCCESS (${sw.elapsedMilliseconds} ms): ${u['email']} -> Role: ${res['role']} | Nama: ${res['nama']} (ID: ${res['id']})');
    }
    print('Total Auth Duration: ${authStopwatch.elapsedMilliseconds} ms\n');

    // Test Dokter Dashboard queries
    print('--- Testing Dokter Dashboard Real Data ---');
    final dSw = Stopwatch()..start();
    final dokterData = await SupabaseAdminService.instance.fetchDokterDashboard(
      doctorName: 'dr. Budi Santoso, Sp.PD',
    );
    dSw.stop();
    expect(dokterData, isNotEmpty);
    print('Dokter Dashboard query took ${dSw.elapsedMilliseconds} ms:');
    print('  Ringkasan: ${dokterData['ringkasan']}');
    print('  Jumlah Konsultasi Aktif: ${(dokterData['konsultasi_aktif'] as List?)?.length ?? 0}');
    print('  Jumlah Pasien: ${(dokterData['daftar_pasien'] as List?)?.length ?? 0}');

    // Test Apotek Dashboard queries
    print('\n--- Testing Apotek Dashboard Real Data ---');
    final aSw = Stopwatch()..start();
    final apotekData = await SupabaseAdminService.instance.fetchApotekDashboard(
      apotekName: 'Apotek Kimia Farma Dago',
    );
    aSw.stop();
    expect(apotekData, isNotEmpty);
    print('Apotek Dashboard query took ${aSw.elapsedMilliseconds} ms:');
    print('  Ringkasan: ${apotekData['ringkasan']}');
    print('  Jumlah Pesanan Menunggu: ${(apotekData['pesanan_menunggu'] as List?)?.length ?? 0}');
    print('  Jumlah Obat Stok Rendah: ${(apotekData['obat_stok_rendah'] as List?)?.length ?? 0}');

    // Test Pasien Reminders & Edukasi queries
    print('\n--- Testing Pasien Reminders & Edukasi Real Data ---');
    final pSw = Stopwatch()..start();
    final reminders = await SupabaseAdminService.instance.fetchPasienReminders(onlyToday: true);
    final edukasi = await SupabaseAdminService.instance.fetchEdukasi();
    pSw.stop();
    print('Pasien queries took ${pSw.elapsedMilliseconds} ms:');
    print('  Reminders: ${reminders.length} items');
    print('  Edukasi: ${edukasi.length} items');

    print('\n====================================================');
    print('ALL REAL-DATA FLOW VERIFICATION COMPLETED');
    print('====================================================');
  });
}
