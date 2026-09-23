import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/dokter/pasien/dokter_pasien_screen.dart';
import 'package:giat/screens/dokter/pasien/dokter_detail_pasien_screen.dart';
import 'package:giat/screens/dokter/resep/dokter_review_resep_sheet.dart';
import 'package:giat/screens/dokter/resep/dokter_tambah_obat_dialog.dart';
import 'package:giat/screens/dokter/konsultasi/dokter_room_chat_screen.dart';
import 'package:giat/screens/dokter/models/dokter_models.dart';

void main() {
  testWidgets('Dokter Pasien Flow: Daftar Pasien -> Detail Pasien -> Buat Resep -> Tambah Obat', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // 1. Build DokterPasienScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: DokterPasienScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and elements in Daftar Pasien (Image 1)
    expect(find.text('Daftar Pasien'), findsOneWidget);
    expect(find.text('Cari Pasien...'), findsOneWidget);
    expect(find.text('Siti Wijaya'), findsOneWidget);
    expect(find.text('42 Tahun  •  Perempuan'), findsOneWidget);
    expect(find.text('Lina Norvita'), findsOneWidget);
    expect(find.text('38 Tahun  •  Perempuan'), findsOneWidget);

    // 2. Tap on Siti Wijaya card to open Detail Pasien (Image 2 & 3)
    await tester.tap(find.text('Siti Wijaya'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Pasien'), findsOneWidget);
    expect(find.text('Siti Wijaya'), findsWidgets);
    expect(find.text('Usia: 42 Tahun'), findsOneWidget);
    expect(find.text('Kelamin: Perempuan'), findsOneWidget);
    expect(find.text('Alamat :Jalan Merpati 45 Madiun'), findsOneWidget);

    // Verify 4 Pantau metrics
    expect(find.text('Pantau Kondisi Pasien Terakhir'), findsOneWidget);
    expect(find.text('Berat Badan'), findsOneWidget);
    expect(find.text('48'), findsOneWidget);
    expect(find.text('Tinggi Badan'), findsOneWidget);
    expect(find.text('1.6'), findsOneWidget);
    expect(find.text('Kondisi'), findsOneWidget);
    expect(find.text('Kurang Baik'), findsOneWidget);
    expect(find.text('Keluhan'), findsOneWidget);
    expect(find.text('Mudah Lelah'), findsOneWidget);

    // Verify Detail Keluhan
    expect(find.text('Detail Keluhan'), findsOneWidget);
    expect(find.text('Keluhan Pasien kepada dokter....'), findsOneWidget);

    // Verify Obat Saat Ini
    expect(find.text('Obat Saat Ini'), findsOneWidget);
    expect(find.text('Candesartan 8mg'), findsOneWidget);
    expect(find.text('Furosemide 40mg'), findsOneWidget);

    // Verify Sticky Bottom Action Bar (Image 3)
    expect(find.text('Buat Resep'), findsOneWidget);
    expect(find.text('Mulai Konsultasi'), findsOneWidget);

    // 3. Tap "Buat Resep" to open Buat Resep screen (Image 4)
    await tester.tap(find.text('Buat Resep'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Resep'), findsOneWidget);
    expect(find.text('Daftar Obat'), findsOneWidget);
    expect(find.text('Candesartan 8mg'), findsOneWidget);
    expect(find.text('Furosemide 40mg'), findsOneWidget);
    expect(find.text('Tambah Obat'), findsOneWidget);
    expect(find.text('Terbitkan Resep'), findsOneWidget);

    // 4. Tap "Tambah Obat" to open form Tambah Obat (Image 5)
    await tester.tap(find.text('Tambah Obat'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Obat'), findsNWidgets(2));
    expect(find.text('Detail Obat'), findsOneWidget);
    expect(find.text('Cari Obat....'), findsOneWidget);
    expect(find.text('Dosis'), findsOneWidget);
    expect(find.text('Jumlah'), findsOneWidget);
    expect(find.text('Frekuensi'), findsOneWidget);
    expect(find.text('Durasi'), findsOneWidget);
    expect(find.text('Cara Penggunaan'), findsOneWidget);
    expect(find.text('Instruksi Khusus (Opsional)'), findsOneWidget);

    // 5. Go back to Buat Resep screen
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Resep'), findsOneWidget);

    // 6. Tap "Terbitkan Resep"
    await tester.ensureVisible(find.text('Terbitkan Resep'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terbitkan Resep'));
    await tester.pumpAndSettle();

    // Verify back to Detail Pasien screen
    expect(find.text('Detail Pasien'), findsOneWidget);
  });
}
