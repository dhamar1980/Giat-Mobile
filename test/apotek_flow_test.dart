import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/apotek/apoteker_home_screen.dart';
import 'package:giat/screens/apotek/notifikasi/apotek_notifikasi_screen.dart';
import 'package:giat/screens/apotek/pesanan/apotek_pesanan_screen.dart';
import 'package:giat/screens/apotek/resep/apotek_detail_resep_screen.dart';
import 'package:giat/screens/apotek/obat/apotek_obat_screen.dart';
import 'package:giat/screens/apotek/obat/apotek_detail_obat_screen.dart';
import 'package:giat/screens/apotek/profile/apotek_profile_screen.dart';
import 'package:giat/screens/apotek/profile/apotek_jam_operasional_screen.dart';
import 'package:giat/screens/apotek/profile/apotek_area_layanan_screen.dart';
import 'package:giat/screens/apotek/profile/apotek_pusat_bantuan_screen.dart';
import 'package:giat/screens/apotek/models/apotek_models.dart';

void main() {
  testWidgets('ApotekerHomeScreen renders greeting, activities, attention, and bottom nav', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ApotekerHomeScreen(apotekerName: 'Budi'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify greeting bubbles
    expect(find.textContaining('Selamat Datang Kembali'), findsWidgets);
    expect(find.textContaining('Budi'), findsWidgets);
    expect(find.textContaining('kelancaran ya...'), findsOneWidget);

    // Verify sections
    expect(find.text('Pesanan Perlu Diproses'), findsOneWidget);
    expect(find.text('Aktivitas Hari Ini'), findsOneWidget);
    expect(find.text('Perlu Perhatian'), findsOneWidget);

    // Verify bottom nav items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Pesanan'), findsWidgets);
    expect(find.text('Resep'), findsWidgets);
    expect(find.text('Obat'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Tap Pesanan tab
    await tester.tap(find.text('Pesanan').last);
    await tester.pumpAndSettle();
    expect(find.text('Pesanan Hari Ini'), findsOneWidget);

    // Tap Resep center button
    await tester.tap(find.text('Resep').last);
    await tester.pumpAndSettle();
    expect(find.text('Daftar Resep Masuk'), findsOneWidget);

    // Tap Obat tab
    await tester.tap(find.text('Obat'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Inventaris Obat'), findsOneWidget);

    // Tap Profil tab
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Apotek'), findsOneWidget);
  });

  testWidgets('ApotekNotifikasiScreen renders notifications and marks read', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ApotekNotifikasiScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Pesanan Resep Baru Masuk'), findsOneWidget);
    expect(find.text('Pesanan Siap Diproses'), findsOneWidget);
  });

  testWidgets('Accepting Doctor Recipe creates order in MENUNGGU queue', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Test data
    final testRecipe = ApotekRecipe(
      id: 'RSP-99999',
      patientName: 'Pasien Uji Coba',
      patientInitials: 'PU',
      medRecNo: '#RM-99999',
      doctorName: 'dr. Spesialis Ginjal',
      dateText: '1 September 2026',
      timeText: '5 menit lalu',
      status: ApotekRecipeStatus.belumDiverifikasi,
      items: [
        const ApotekRecipeItem(
          medicineName: 'Candesartan 16 mg',
          formAndPack: 'Tablet • 10 tablet',
          doseRule: '1 x 1 tablet',
          usageNotes: 'Sesudah Makan',
          qtyText: '10 Tablet',
        ),
      ],
    );
    ApotekMockData.recipes.insert(0, testRecipe);

    await tester.pumpWidget(
      MaterialApp(
        home: ApotekDetailResepScreen(recipe: testRecipe),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Resep'), findsOneWidget);
    expect(find.text('Terima Resep'), findsOneWidget);

    // Tap Terima Resep
    await tester.tap(find.text('Terima Resep'));
    await tester.pumpAndSettle();

    // Verify confirmation modal
    expect(find.text('Mulai Proses Resep?'), findsOneWidget);
    expect(find.text('Mulai Proses'), findsOneWidget);

    // Tap Mulai Proses in dialog
    await tester.tap(find.text('Mulai Proses'));
    await tester.pumpAndSettle();

    // Verify recipe is now verified
    expect(testRecipe.status, ApotekRecipeStatus.diverifikasi);

    // Verify order was automatically added to orders with status MENUNGGU
    final matchingOrder = ApotekMockData.orders.firstWhere((o) => o.recipeRef == 'RSP-99999');
    expect(matchingOrder.status, ApotekOrderStatus.menunggu);
    expect(matchingOrder.patientName, 'Pasien Uji Coba');
    expect(matchingOrder.items.first.medicineName, 'Candesartan 16 mg');
  });

  testWidgets('ApotekPesananScreen filters by status and processes order', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ApotekPesananScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pesanan Hari Ini'), findsOneWidget);
    expect(find.text('Menunggu'), findsWidgets);
    expect(find.text('Diproses'), findsWidgets);
    expect(find.text('Selesai'), findsWidgets);

    // Tap Diproses tab
    await tester.tap(find.text('Diproses').first);
    await tester.pumpAndSettle();

    // Tap Selesai tab
    await tester.tap(find.text('Selesai').first);
    await tester.pumpAndSettle();
  });

  testWidgets('ApotekObatScreen searches, filters, and opens detail', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ApotekObatScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daftar Inventaris Obat'), findsOneWidget);
    expect(find.text('Stock Aman'), findsWidgets);
    expect(find.text('Stock Menipis'), findsWidgets);
    expect(find.text('Stock Habis'), findsWidgets);

    // Search for Paracetamol
    await tester.enterText(find.byType(TextField), 'Paracetamol');
    await tester.pumpAndSettle();
    expect(find.text('Paracetamol 500 mg'), findsOneWidget);
  });

  testWidgets('ApotekDetailObatScreen allows adding stock batch', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final med = ApotekMockData.medicines.first;
    final initialStock = med.stock;

    await tester.pumpWidget(
      MaterialApp(
        home: ApotekDetailObatScreen(medicine: med),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Obat'), findsOneWidget);
    expect(find.text('Rincian Tambah Stok'), findsOneWidget);
    expect(find.text('Simpan Tambahan Stok'), findsOneWidget);

    await tester.tap(find.text('Simpan Tambahan Stok'));
    await tester.pumpAndSettle();

    // Verify stock increased
    expect(med.stock, greaterThan(initialStock));
  });

  testWidgets('ApotekProfileScreen and sub-screens render properly', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ApotekProfileScreen(apotekerName: 'Apt. Aminah, S.Farm'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil Apotek'), findsOneWidget);
    expect(find.text('Apt. Aminah, S.Farm'), findsOneWidget);
    expect(find.text('Status Layanan'), findsWidgets);
    expect(find.text('Jam Operasional'), findsWidgets);
    expect(find.text('Area Layanan'), findsWidgets);
    expect(find.text('Riwayat Aktivitas'), findsWidgets);
    expect(find.text('Pusat Bantuan'), findsWidgets);

    // Open Jam Operasional screen directly
    await tester.pumpWidget(
      const MaterialApp(
        home: ApotekJamOperasionalScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ubah Jam Operasional'), findsOneWidget);

    // Open Area Layanan screen directly
    await tester.pumpWidget(
      const MaterialApp(
        home: ApotekAreaLayananScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Area Layanan'), findsOneWidget);
    expect(find.text('Kota Malang'), findsOneWidget);

    // Open Pusat Bantuan directly
    await tester.pumpWidget(
      const MaterialApp(
        home: ApotekPusatBantuanScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pusat Bantuan'), findsOneWidget);
    expect(find.text('Bagaimana cara memverifikasi resep?'), findsOneWidget);
  });
}
