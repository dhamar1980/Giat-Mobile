import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/dokter/models/dokter_models.dart';
import 'package:giat/screens/dokter/resep/dokter_review_resep_sheet.dart';
import 'package:giat/screens/pasien/obat/detail_resep_screen.dart';
import 'package:giat/screens/pasien/obat/resep_dokter_screen.dart';
import 'package:giat/screens/pasien/obat/daftar_obat_screen.dart';

void main() {
  testWidgets('DokterReviewResepScreen publishes prescription items correctly', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    List<DokterPrescriptionItem>? publishedResult;

    final patient = DokterMockData.patients.first;

    await tester.pumpWidget(
      MaterialApp(
        home: DokterReviewResepScreen(
          patient: patient,
          consultationId: '5fe921df-457e-43d1-bc4f-6dedf761199e',
          onPrescriptionPublished: (items) {
            publishedResult = items;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify screen renders
    expect(find.text('Buat Resep'), findsOneWidget);
    expect(find.text('Terbitkan Resep'), findsOneWidget);

    // Tap Terbitkan Resep
    await tester.tap(find.text('Terbitkan Resep'));
    await tester.pumpAndSettle();

    // Verify callback was called
    expect(publishedResult, isNotNull);
  });

  testWidgets('ResepDokterScreen renders prescriptions correctly', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResepDokterScreen(userName: 'Siti Aisyah'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resep Dokter'), findsWidgets);
    expect(find.text('Lihat Detail Resep'), findsWidgets);
  });

  testWidgets('DaftarObatScreen renders Resep Saya section with active count', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DaftarObatScreen(userName: 'Siti Aisyah'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resep Saya'), findsOneWidget);
    expect(find.text('Lihat Resep Dokter'), findsOneWidget);
  });
}
