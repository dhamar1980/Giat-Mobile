import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/master_layout.dart';
import 'package:giat/screens/pasien/pragi/pragi_result_screen.dart';
import 'package:giat/screens/pasien/pragi/pragi_state_service.dart';
import 'package:giat/screens/pasien/pantau/pantau_dashboard_screen.dart';
import 'package:giat/screens/pasien/obat/daftar_obat_screen.dart';
import 'package:giat/screens/pasien/widgets/pasien_bottom_navbar.dart';

void main() {
  testWidgets('PantauDashboardScreen standalone has PasienBottomNavbar visible', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: PantauDashboardScreen(
          userName: 'Pasien',
          isEmbedded: false,
        ),
      ),
    );
    await tester.pump();

    // Verify Pantau content exists
    expect(find.text('Kondisi Tubuh Saat Ini'), findsOneWidget);

    // Verify PasienBottomNavbar is ALWAYS present
    expect(find.byType(PasienBottomNavbar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Konsultasi'), findsOneWidget);
    expect(find.text('PRAGI'), findsOneWidget);
    expect(find.text('Pantau'), findsOneWidget);
    expect(find.text('Obat'), findsOneWidget);
  });

  testWidgets('DaftarObatScreen standalone has PasienBottomNavbar visible', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DaftarObatScreen(
          userName: 'Pasien',
          isEmbedded: false,
        ),
      ),
    );
    await tester.pump();

    // Verify PasienBottomNavbar is present
    expect(find.byType(PasienBottomNavbar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Konsultasi'), findsOneWidget);
    expect(find.text('PRAGI'), findsOneWidget);
    expect(find.text('Pantau'), findsOneWidget);
    expect(find.text('Obat'), findsOneWidget);
  });

  testWidgets('Flow from PragiResultScreen to Konsultasi to Pantau keeps bottom navbar present', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockResult = PragiService().historyNotifier.value.first;

    await tester.pumpWidget(
      MaterialApp(
        home: PragiResultScreen(result: mockResult),
      ),
    );
    await tester.pump();

    // Find Konsultasi button in PragiResultScreen and ensure it's visible
    final konsultasiBtn = find.text('Konsultasi Dokter Sekarang');
    expect(konsultasiBtn, findsOneWidget);
    await tester.ensureVisible(konsultasiBtn);
    await tester.pumpAndSettle();

    // Tap Konsultasi button -> routes to MasterLayout(initialIndex: 1)
    await tester.tap(konsultasiBtn);
    await tester.pumpAndSettle();

    // Now on MasterLayout, Konsultasi tab
    expect(find.byType(MasterLayout), findsOneWidget);
    expect(find.byType(PasienBottomNavbar), findsOneWidget);

    // Tap Pantau in the navbar
    await tester.tap(find.text('Pantau'));
    await tester.pumpAndSettle();

    // Now on Pantau tab inside MasterLayout
    expect(find.text('Kondisi Tubuh Saat Ini'), findsOneWidget);

    // Navbar MUST still be present and visible
    expect(find.byType(PasienBottomNavbar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Konsultasi'), findsOneWidget);
    expect(find.text('PRAGI'), findsOneWidget);
    expect(find.text('Pantau'), findsOneWidget);
    expect(find.text('Obat'), findsOneWidget);
  });
}
