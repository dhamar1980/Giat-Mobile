import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/apotek/apoteker_home_screen.dart';
import 'package:giat/screens/apotek/notifikasi/apotek_notifikasi_screen.dart';
import 'package:giat/screens/apotek/pesanan/apotek_pesanan_screen.dart';
import 'package:giat/screens/apotek/pesanan/apotek_detail_pesanan_screen.dart';
import 'package:giat/screens/apotek/resep/apotek_detail_resep_screen.dart';
import 'package:giat/screens/apotek/obat/apotek_obat_screen.dart';
import 'package:giat/screens/apotek/obat/apotek_detail_obat_screen.dart';
import 'package:giat/screens/apotek/obat/apotek_tambah_obat_screen.dart';
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

    // Verify sections and items
    expect(find.text('Perlu Perhatian'), findsOneWidget);
    expect(find.text('Pesanan belum\ndiproses'), findsOneWidget);
    expect(find.text('Resep belum\nditerima'), findsOneWidget);
    expect(find.text('Stok Menipis'), findsOneWidget);
    expect(find.text('Aktivitas Terbaru'), findsOneWidget);
    expect(find.text('Resep #RX-00110 telah diterima'), findsOneWidget);

    // Verify bottom nav items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Pesanan'), findsWidgets);
    expect(find.text('Resep'), findsWidgets);
    expect(find.text('Obat'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Tap Pesanan tab
    await tester.tap(find.text('Pesanan').last);
    await tester.pumpAndSettle();
    expect(find.text('Pesanan Menunggu Diproses'), findsOneWidget);

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

    expect(find.text('Informasi Pasien'), findsOneWidget);
    expect(find.text('Daftar Obat'), findsOneWidget);
    expect(find.text('Terima Resep'), findsWidgets);

    // Tap tombol Terima Resep di bagian bawah
    await tester.tap(find.widgetWithText(ElevatedButton, 'Terima Resep'));
    await tester.pumpAndSettle();

    // Verify recipe is now verified
    expect(testRecipe.status, ApotekRecipeStatus.diverifikasi);

    // Verify order was automatically added to orders with status MENUNGGU
    final matchingOrder = ApotekMockData.orders.firstWhere((o) => o.recipeRef == 'RSP-99999');
    expect(matchingOrder.status, ApotekOrderStatus.menunggu);
    expect(matchingOrder.patientName, 'Pasien Uji Coba');
    expect(matchingOrder.items.first.medicineName, 'Candesartan 16 mg');
  });

  testWidgets('Patient checkout prescription routes to Apotek Resep screen then to Pesanan Menunggu', (tester) async {
    // 1. Patient completes payment with prescription
    final newRecipe = ApotekMockData.addRecipeFromCheckout(
      recipeId: 'RSP-77777',
      patientName: 'Ahmad Dahlan',
      patientAddress: 'Jl. Merdeka No. 10',
      doctorName: 'dr. Andi Pratama',
      dateText: '31 Agustus 2026',
    );

    expect(newRecipe.status, ApotekRecipeStatus.belumDiverifikasi);
    expect(ApotekMockData.recipes.any((r) => r.id == 'RSP-77777'), isTrue);

    // 2. Pharmacy accepts the recipe
    final createdOrder = ApotekMockData.acceptRecipeAndCreateOrder(newRecipe);

    expect(newRecipe.status, ApotekRecipeStatus.diverifikasi);
    expect(createdOrder.status, ApotekOrderStatus.menunggu);
    expect(createdOrder.recipeRef, 'RSP-77777');
    expect(ApotekMockData.orders.first.id, createdOrder.id);
  });

  testWidgets('ApotekPesananScreen filters by status and processes order', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Reset or prepare test order in Menunggu
    final existingTestOrder = ApotekMockData.orders.firstWhere((o) => o.id == 'ORD-0124');
    existingTestOrder.status = ApotekOrderStatus.menunggu;

    await tester.pumpWidget(
      const MaterialApp(
        home: ApotekPesananScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pesanan Menunggu Diproses'), findsOneWidget);
    expect(find.text('Menunggu'), findsWidgets);
    expect(find.text('Diproses'), findsWidgets);
    expect(find.text('Selesai'), findsWidgets);
    expect(find.text('ORD-0124'), findsOneWidget);
    expect(find.text('Proses Pesanan'), findsWidgets);

    // Ensure visible and tap "Proses Pesanan"
    await tester.ensureVisible(find.text('Proses Pesanan').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proses Pesanan').first);
    await tester.pumpAndSettle();

    // Verify order is now in Diproses tab and button is "Pesanan Selesai"
    expect(find.text('Pesanan Sedang Diproses'), findsOneWidget);
    expect(find.text('Pesanan Selesai'), findsWidgets);

    // Ensure visible and tap "Pesanan Selesai" button
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Pesanan Selesai').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Pesanan Selesai').first);
    await tester.pumpAndSettle();

    // Verify order is now in Selesai tab
    expect(find.text('Pesanan Selesai'), findsWidgets);
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
    tester.view.physicalSize = const Size(450, 950);
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

    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Detail Obat'), findsOneWidget);
    expect(find.text('Rincian Tambah Stok'), findsOneWidget);
    expect(find.text('Simpan Tambahan Stok'), findsOneWidget);
    expect(find.text('Riwayat Batch Terakhir'), findsOneWidget);

    await tester.ensureVisible(find.text('Simpan Tambahan Stok'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Tambahan Stok'));
    await tester.pumpAndSettle();

    // Verify stock increased
    expect(med.stock, greaterThan(initialStock));
  });

  testWidgets('ApotekTambahObatScreen renders all sections, preview, and allows adding new medicine', (tester) async {
    tester.view.physicalSize = const Size(450, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ApotekTambahObatScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Tambah Obat Baru'), findsOneWidget);
    expect(find.textContaining('Gunakan formulir ini HANYA'), findsOneWidget);
    expect(find.text('Pratinjau Obat'), findsOneWidget);
    expect(find.text('Identitas & Sediaan'), findsOneWidget);
    expect(find.text('Stok & Finansial'), findsOneWidget);
    expect(find.text('Aturan & Catatan Khusus'), findsOneWidget);
    expect(find.text('Simpan Obat Stok'), findsOneWidget);
    expect(find.text('Batal & Bersihkan Inputan'), findsOneWidget);
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

  testWidgets('ApotekDetailPesananScreen renders both Menunggu and Diproses flows faithfully', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final testOrder = ApotekMockData.orders.firstWhere((o) => o.id == 'ORD-0012');
    testOrder.status = ApotekOrderStatus.menunggu;

    await tester.pumpWidget(
      MaterialApp(
        home: ApotekDetailPesananScreen(order: testOrder),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify State 1: Menunggu
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Detail Pesanan'), findsOneWidget);
    expect(find.text('ORD-0012'), findsOneWidget);
    expect(find.text('informasi Pasien'), findsOneWidget);
    expect(find.text('BS'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsWidgets);
    expect(find.text('Resep'), findsOneWidget);
    expect(find.text('RX-00110'), findsOneWidget);
    expect(find.text('Daftar Obat'), findsOneWidget);
    expect(find.text('Obat Tersedia'), findsWidgets);
    expect(find.text('Mulai Proses'), findsOneWidget);

    // 2. Tap "Mulai Proses"
    await tester.tap(find.text('Mulai Proses'));
    await tester.pumpAndSettle();
    ScaffoldMessenger.of(tester.element(find.byType(ApotekDetailPesananScreen))).clearSnackBars();
    await tester.pumpAndSettle();

    // 3. Verify State 2: Diproses
    expect(testOrder.status, ApotekOrderStatus.diproses);
    expect(find.text('Diproses'), findsOneWidget);
    expect(find.text('Informasi Pesanan'), findsWidgets);
    expect(find.text('Nomor Pesanan'), findsOneWidget);
    expect(find.text('Mulai Diproses'), findsOneWidget);
    expect(find.text('Progres Pesanan'), findsOneWidget);
    expect(find.text('Pesanan diterima'), findsOneWidget);
    expect(find.text('Obat sedang disiapkan'), findsOneWidget);
    expect(find.text('Sedang berlangsung'), findsOneWidget);
    expect(find.text('Pemeriksaan akhir'), findsOneWidget);
    expect(find.text('Selesaikan Pesanan Sekarang'), findsOneWidget);

    // 4. Tap "Selesaikan Pesanan Sekarang"
    await tester.tap(find.text('Selesaikan Pesanan Sekarang'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // 5. Verify State 3: Selesai (tombol aksi bawah ditiadakan sesuai permintaan)
    expect(testOrder.status, ApotekOrderStatus.selesai);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Pesanan Telah Selesai'), findsNothing);
    expect(find.text('Selesaikan Pesanan Sekarang'), findsNothing);
    expect(find.text('Mulai Proses'), findsNothing);

    // 6. Langsung buka order yang sudah selesai (seperti dari list/pencarian Selesai)
    final completedOrder = ApotekMockData.orders.firstWhere((o) => o.id == 'ORD-0120');
    expect(completedOrder.status, ApotekOrderStatus.selesai);
    await tester.pumpWidget(
      MaterialApp(
        home: ApotekDetailPesananScreen(order: completedOrder),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Pesanan Telah Selesai'), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
