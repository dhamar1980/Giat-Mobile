import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/dokter/pasien/dokter_pasien_screen.dart';
import 'package:giat/screens/dokter/pasien/dokter_detail_pasien_screen.dart';
import 'package:giat/screens/dokter/models/dokter_models.dart';

void main() {
  final testPaidPatient = DokterPatient(
    id: 'e70617e7-eed7-4557-9b6f-bdaa65937052',
    name: 'Siti Aisyah',
    initials: 'SA',
    age: 28,
    gender: 'Perempuan',
    address: 'Jl. Dago Asri No. 12, Bandung',
    weightKg: 60.0,
    heightM: 1.60,
    condition: 'Baik',
    complaint: 'Tidak Ada',
    complaintDetail: 'Kondisi stabil, pemeriksaan pasca terapi ginjal',
    currentMedicines: const [
      DokterPrescriptionItem(
        id: 'rx-1',
        medicineName: 'Candesartan 8mg',
        dose: '8mg',
        frequency: '1 x 1 hari',
        quantity: '10 Tablet',
        duration: '10 hari',
        usageTime: 'Sesudah Makan',
      ),
    ],
    consultationId: '5fe921df-457e-43d1-bc4f-6dedf761199e',
    paymentStatus: 'lunas',
  );

  testWidgets('DokterPasienScreen only displays paid patients with Terbayar badge', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: DokterPasienScreen(
          initialPatients: [testPaidPatient],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Search
    expect(find.text('Daftar Pasien'), findsOneWidget);
    expect(find.text('Cari Pasien...'), findsOneWidget);

    // Verify Paid Patient displayed
    expect(find.text('Siti Aisyah'), findsOneWidget);
    expect(find.text('28 Tahun  •  Perempuan'), findsOneWidget);
    expect(find.text('Terbayar'), findsOneWidget);

    // Unpaid/mock patients should NOT appear when initialPatients is provided
    expect(find.text('Siti Wijaya'), findsNothing);
    expect(find.text('Lina Norvita'), findsNothing);

    // Test Search Functionality
    await tester.enterText(find.byType(TextField), 'Siti');
    await tester.pumpAndSettle();
    expect(find.text('Siti Aisyah'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Budi Not Exist');
    await tester.pumpAndSettle();
    expect(find.text('Siti Aisyah'), findsNothing);
    expect(find.textContaining('Tidak ada pasien dengan kata kunci'), findsOneWidget);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Siti Aisyah'), findsOneWidget);

    // Tap patient to open Detail Pasien
    await tester.tap(find.text('Siti Aisyah'));
    await tester.pumpAndSettle();

    expect(find.byType(DokterDetailPasienScreen), findsOneWidget);
    expect(find.text('Detail Pasien'), findsOneWidget);
    expect(find.text('Siti Aisyah'), findsWidgets);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('1.6'), findsOneWidget);
    expect(find.text('Baik'), findsOneWidget);
    expect(find.text('Tidak Ada'), findsOneWidget);
  });

  testWidgets('DokterPasienScreen shows empty state when doctor has no paid patients', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterPasienScreen(
          initialPatients: [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daftar Pasien'), findsOneWidget);
    expect(find.text('Belum ada pasien yang membayar konsultasi.'), findsOneWidget);
    expect(
      find.text('Hanya pasien yang telah menyelesaikan pembayaran konsultasi dokter yang akan muncul di daftar ini.'),
      findsOneWidget,
    );
  });
}

