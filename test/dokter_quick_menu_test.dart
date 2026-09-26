import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/dokter/dokter_home_screen.dart';

void main() {
  testWidgets('DokterHomeScreen renders 3 quick menu buttons and switches tabs', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    int? navigatedTab;

    await tester.pumpWidget(
      MaterialApp(
        home: DokterHomeScreen(
          doctorName: 'Dr. Andi Pratama',
          onNavigateTab: (index) {
            navigatedTab = index;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 3 items exist in quick menu
    expect(find.text('Konsultasi'), findsWidgets);
    expect(find.text('Pasien'), findsWidgets);
    expect(find.text('Jadwal'), findsWidgets);

    // 1. Tap 'Konsultasi' in quick menu (first occurrence)
    await tester.tap(find.text('Konsultasi').first);
    await tester.pumpAndSettle();
    expect(navigatedTab, 1);
    expect(find.text('Daftar Konsultasi'), findsOneWidget);

    // Go back to home tab (tap bottom nav 'Home')
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // 2. Tap 'Pasien' in quick menu (first occurrence)
    await tester.tap(find.text('Pasien').first);
    await tester.pumpAndSettle();
    expect(navigatedTab, 2);
    expect(find.text('Daftar Pasien'), findsOneWidget);

    // Go back to home tab
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    // 3. Tap 'Jadwal' in quick menu (first occurrence)
    await tester.tap(find.text('Jadwal').first);
    await tester.pumpAndSettle();
    expect(navigatedTab, 3);
    expect(find.text('Jadwal Pasien'), findsOneWidget);
  });
}
