import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/forgot_password_screen.dart';

void main() {
  testWidgets('ForgotPasswordScreen renders without overflow when keyboard is open',
      (WidgetTester tester) async {
    // Standard phone dimensions (e.g. 393 x 851)
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify elements are present
    expect(find.text('GIAT'), findsOneWidget);
    expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
    expect(find.text('Kirim Kode Verifikasi'), findsOneWidget);

    // Now simulate soft keyboard opening (viewInsets.bottom = 300 * 2.75 = 825)
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();

    // Tap email field
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    // Verify NO overflow error was thrown!
    expect(tester.takeException(), isNull);
  });
}
