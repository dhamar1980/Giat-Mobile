import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/forgot_password_screen.dart';
import 'package:giat/login_screen.dart';
import 'package:giat/reset_password_screen.dart';
import 'package:giat/verification_code_screen.dart';

void main() {
  testWidgets('Complete Forgot Password -> Verification Code -> Reset Password flow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. ForgotPasswordScreen
    expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'pasien@giat.id');
    await tester.tap(find.text('Kirim Kode Verifikasi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // 2. VerificationCodeScreen should now be open
    expect(find.byType(VerificationCodeScreen), findsOneWidget);
    expect(find.text('Masukan Kode Verifikasi'), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) =>
          w is RichText &&
          w.text.toPlainText().contains('Kode dikirimkan ke email:') &&
          w.text.toPlainText().contains('pasien@giat.id')),
      findsOneWidget,
    );

    // Enter 4 digits OTP
    final otpFields = find.descendant(
      of: find.byType(VerificationCodeScreen),
      matching: find.byType(TextFormField),
    );
    expect(otpFields, findsNWidgets(4));

    await tester.enterText(otpFields.at(0), '1');
    await tester.enterText(otpFields.at(1), '2');
    await tester.enterText(otpFields.at(2), '3');
    await tester.enterText(otpFields.at(3), '4');
    await tester.pumpAndSettle();

    // Tap Selanjutnya
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // 3. ResetPasswordScreen should now be open
    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    expect(find.text('Buat password baru anda'), findsOneWidget);
    expect(find.text('Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);

    final passFields = find.descendant(
      of: find.byType(ResetPasswordScreen),
      matching: find.byType(TextFormField),
    );
    expect(passFields, findsNWidgets(2));

    await tester.enterText(passFields.at(0), 'passwordBaru123');
    await tester.enterText(passFields.at(1), 'passwordBaru123');
    await tester.pumpAndSettle();

    // Tap Konfirmasi Password Baru
    await tester.ensureVisible(find.text('Konfirmasi Password Baru'));
    await tester.tap(find.text('Konfirmasi Password Baru'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    // Verify Success Dialog is shown
    expect(find.textContaining('Kata Sandi Berhasil Diubah'), findsOneWidget);
    expect(find.text('Masuk Sekarang'), findsOneWidget);

    // Tap Masuk Sekarang -> should redirect to LoginScreen
    await tester.tap(find.text('Masuk Sekarang'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
