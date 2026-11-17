import 'package:flutter_test/flutter_test.dart';
import 'package:giat/services/supabase_admin_service.dart';

void main() {
  test('Inspect full dashboard content from Supabase', () async {
    final dokterData = await SupabaseAdminService.instance.fetchDokterDashboard(
      doctorName: 'dr. Budi Santoso, Sp.PD',
    );
    print('--- DOKTER DATA ---');
    print('Dokter Profile: ${dokterData['dokter']}');
    print('Pesan Terbaru: ${(dokterData['pesan_terbaru'] as List).length}');
    print('Jadwal Hari Ini: ${(dokterData['jadwal_hari_ini'] as List).length}');
    for (final j in (dokterData['jadwal_hari_ini'] as List)) {
      print('  Jadwal: ${j['nama_pasien']} - ${j['tanggal_konsultasi']} ${j['jam_mulai']} (${j['status']})');
    }
    print('Resep Terbaru: ${(dokterData['resep_terbaru'] as List).length}');
    for (final r in (dokterData['resep_terbaru'] as List)) {
      print('  Resep: Pasien ${r['nama_pasien']} - Diagnosis: ${r['diagnosis']} - Obat: ${r['obat']}');
    }

    final apotekData = await SupabaseAdminService.instance.fetchApotekDashboard(
      apotekName: 'Apotek Kimia Farma Dago',
    );
    print('\n--- APOTEK DATA ---');
    print('Apotek Keys: ${apotekData.keys.toList()}');
    print('Apotek Profile: ${apotekData['apotek']}');
    print('Pesanan Hari Ini: ${(apotekData['pesanan_hari_ini'] as List?)?.length ?? 0}');
    for (final p in (apotekData['pesanan_hari_ini'] as List? ?? [])) {
      print('  Pesanan: ${p['no_pesanan']} - ${p['nama_pasien']} - Total: ${p['total_bayar']} - Status: ${p['status_pesanan']}');
    }
    print('Obat List / Katalog: ${(apotekData['obat'] as List?)?.length ?? 0}');
  });
}
