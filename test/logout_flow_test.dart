import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/login_screen.dart';
import 'package:giat/screens/pasien/profile/profile_pasien_screen.dart';

void main() {
  testWidgets('Logout from ProfilePasienScreen successfully redirects to LoginScreen', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilePasienScreen(userName: 'Sarah Amelia'),
      ),
    );
    await tester.pump();

    // Verify on profile screen
    expect(find.text('Ringkasan Kesehatan'), findsOneWidget);

    // Scroll until Keluar card is visible
    final keluarCard = find.text('Keluar');
    await tester.scrollUntilVisible(keluarCard, 200);
    await tester.pumpAndSettle();
    expect(keluarCard, findsOneWidget);

    // Tap Keluar
    await tester.tap(keluarCard);
    await tester.pumpAndSettle();

    // Verify confirmation dialog appears
    expect(find.text('Keluar dari Akun'), findsOneWidget);
    expect(find.text('Apakah Anda yakin ingin keluar dari akun Pasien?'), findsOneWidget);

    // Tap confirm 'Keluar' button in dialog
    final dialogKeluarBtn = find.widgetWithText(ElevatedButton, 'Keluar');
    expect(dialogKeluarBtn, findsOneWidget);
    await tester.tap(dialogKeluarBtn);
    await tester.pumpAndSettle();

    // Verify redirected to LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
