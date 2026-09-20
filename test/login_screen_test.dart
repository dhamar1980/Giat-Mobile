import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders all components correctly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Brand Logo
    expect(find.text('GIAT'), findsOneWidget);
    expect(find.text('Ginjal'), findsOneWidget);
    expect(find.text('Sehat'), findsOneWidget);

    // Verify Chat Bubbles
    expect(
      find.text('Selamat datang kembali. Jaga kesehatan\nginjalmu bersama GIAT.✨✨'),
      findsOneWidget,
    );
    expect(find.text('12.00'), findsOneWidget);
    expect(find.text('Masuk ke GIAT'), findsOneWidget);

    // Verify Form Fields & Labels
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Masukkan email atau username'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Masukkan kata sandi'), findsOneWidget);
    expect(find.text('Lupa kata sandi?'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('atau'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);

    // Verify Footer RichText
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Belum punya akun?'),
      ),
      findsOneWidget,
    );
  });
}
