import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/master_layout.dart';
import 'package:giat/screens/dokter/dokter_home_screen.dart';
import 'package:giat/screens/apotek/apoteker_home_screen.dart';

void main() {
  testWidgets('MasterLayout (Pasien) hides top action pill on scroll down, shows when scrolled back to top', (WidgetTester tester) async {
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

    // Initial AnimatedOpacity should be 1.0
    final initialOpacityFinder = find.byWidgetPredicate(
      (widget) => widget is AnimatedOpacity && widget.opacity == 1.0,
    );
    expect(initialOpacityFinder, findsWidgets);

    // Scroll down on the active tab
    final contentToDrag = find.textContaining('Selamat Datang Kembali').first;
    await tester.drag(contentToDrag, const Offset(0, -300));
    await tester.pumpAndSettle();

    // After scrolling down, AnimatedOpacity should transition to 0.0 (hidden)
    final hiddenOpacityFinder = find.byWidgetPredicate(
      (widget) => widget is AnimatedOpacity && widget.opacity == 0.0,
    );
    expect(hiddenOpacityFinder, findsOneWidget);

    // Now scroll back up and reach the top (mentok)
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 500));
    await tester.pumpAndSettle();

    // Top bar should reappear with opacity 1.0
    final restoredOpacityFinder = find.byWidgetPredicate(
      (widget) => widget is AnimatedOpacity && widget.opacity == 1.0,
    );
    expect(restoredOpacityFinder, findsWidgets);
  });

  testWidgets('DokterHomeScreen (Dokter) hides top action pill on scroll down, shows when scrolled back to top', (WidgetTester tester) async {
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

    // Initial AnimatedOpacity for top bar should be 1.0
    final initialOpacityFinder = find.byWidgetPredicate(
      (widget) => widget is AnimatedOpacity && widget.opacity == 1.0,
    );
    expect(initialOpacityFinder, findsWidgets);

    // Scroll down on the active home tab
    final contentToDrag = find.textContaining('Selamat Datang Kembali').first;
    await tester.drag(contentToDrag, const Offset(0, -300));
    await tester.pumpAndSettle();

    // After scrolling down, AnimatedOpacity becomes 0.0 (hidden)
    final hiddenOpacityFinder = find.byWidgetPredicate(
      (widget) => widget is AnimatedOpacity && widget.opacity == 0.0,
    );
    expect(hiddenOpacityFinder, findsOneWidget);

    // Scroll back up to the top (mentok)
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 500));
    await tester.pumpAndSettle();

    // Top bar reappears with opacity 1.0
    final restoredOpacityFinder = find.byWidgetPredicate(
      (widget) => widget is AnimatedOpacity && widget.opacity == 1.0,
    );
    expect(restoredOpacityFinder, findsWidgets);
  });

  testWidgets('ApotekerHomeScreen (Apotek) hides top action pill on scroll down, shows when scrolled back to top', (WidgetTester tester) async {
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

    // Initial AnimatedOpacity for top bar should be 1.0
    final initialOpacityFinder = find.byWidgetPredicate(
      (widget) => widget is AnimatedOpacity && widget.opacity == 1.0,
    );
    expect(initialOpacityFinder, findsWidgets);

    // Scroll down on the active home tab
    final contentToDrag = find.textContaining('Selamat Datang Kembali').first;
    await tester.drag(contentToDrag, const Offset(0, -300));
    await tester.pumpAndSettle();

    // After scrolling down, AnimatedOpacity becomes 0.0 (hidden)
    final hiddenOpacityFinder = find.byWidgetPredicate(
      (widget) => widget is AnimatedOpacity && widget.opacity == 0.0,
    );
    expect(hiddenOpacityFinder, findsOneWidget);

    // Scroll back up to the top (mentok)
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 500));
    await tester.pumpAndSettle();

    // Top bar reappears with opacity 1.0
    final restoredOpacityFinder = find.byWidgetPredicate(
      (widget) => widget is AnimatedOpacity && widget.opacity == 1.0,
    );
    expect(restoredOpacityFinder, findsWidgets);
  });
}
