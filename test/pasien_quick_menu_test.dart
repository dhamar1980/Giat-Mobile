import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/master_layout.dart';
import 'package:giat/screens/pasien/pasien_home_screen.dart';

void main() {
  testWidgets('PasienHomeScreen renders 4 circular quick menu buttons and fires onNavigateTab', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    int? selectedTab;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasienHomeScreen(
            userName: 'Pasien Test',
            isEmbedded: true,
            onNavigateTab: (idx) {
              selectedTab = idx;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 4 items exist
    expect(find.text('Konsultasi'), findsOneWidget);
    expect(find.text('Skrining Resiko\nPenyakit CKD'), findsOneWidget);
    expect(find.text('Pantau'), findsOneWidget);
    expect(find.text('Obat'), findsOneWidget);

    // Tap Konsultasi
    await tester.tap(find.text('Konsultasi'));
    await tester.pumpAndSettle();
    expect(selectedTab, 1);

    // Tap Skrining Resiko Penyakit CKD
    await tester.tap(find.text('Skrining Resiko\nPenyakit CKD'));
    await tester.pumpAndSettle();
    expect(selectedTab, 2);

    // Tap Pantau
    await tester.tap(find.text('Pantau'));
    await tester.pumpAndSettle();
    expect(selectedTab, 3);

    // Tap Obat
    await tester.tap(find.text('Obat'));
    await tester.pumpAndSettle();
    expect(selectedTab, 4);
  });

  testWidgets('MasterLayout switches tab when quick menu circular button is clicked', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: MasterLayout(
          userName: 'Pasien Test',
          initialIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially at Home (Tab 0)
    expect(find.text('Konsultasi'), findsNWidgets(2)); // in quick menu and bottom navbar
    expect(find.text('Skrining Resiko\nPenyakit CKD'), findsOneWidget);

    // Tap Konsultasi in quick menu
    await tester.tap(find.text('Konsultasi').first);
    await tester.pumpAndSettle();

    // Should switch to tab 1 (Konsultasi Dokter)
    expect(find.text('Konsultasi Saya'), findsOneWidget);
  });
}
