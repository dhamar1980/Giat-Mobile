import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/master_layout.dart';
import 'package:giat/screens/dokter/dokter_home_screen.dart';
import 'package:giat/screens/apotek/apoteker_home_screen.dart';

void main() {
  testWidgets('MasterLayout (Pasien) keeps top action pill persistent (netap) on scroll', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: MasterLayout(userName: 'Pasien Test'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial visibility: notification and person icons are present
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);

    // Scroll down on the active tab
    final contentToDrag = find.textContaining('Selamat Datang Kembali').first;
    await tester.drag(contentToDrag, const Offset(0, -300));
    await tester.pumpAndSettle();

    // After scrolling down, notification and profile icons remain persistent (netap)
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('DokterHomeScreen (Dokter) keeps top action pill persistent (netap) on scroll', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterHomeScreen(doctorName: 'dr. Budi Santoso, Sp.PD'),
      ),
    );
    await tester.pumpAndSettle();

    // Initially top action pill with bell and profile is visible
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);

    // Scroll down on the active home tab
    final contentToDrag = find.textContaining('Selamat Datang Kembali').first;
    await tester.drag(contentToDrag, const Offset(0, -300));
    await tester.pumpAndSettle();

    // Top action pill remains persistent (netap)
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('ApotekerHomeScreen (Apotek) keeps top action pill persistent (netap) on scroll', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ApotekerHomeScreen(apotekerName: 'apt. Sarah Amelia, S.Farm'),
      ),
    );
    await tester.pumpAndSettle();

    // Initially top action pill with bell and profile is visible
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);

    // Scroll down on the active home tab
    final contentToDrag = find.textContaining('Selamat Datang Kembali').first;
    await tester.drag(contentToDrag, const Offset(0, -300));
    await tester.pumpAndSettle();

    // Top action pill remains persistent (netap)
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });
}
