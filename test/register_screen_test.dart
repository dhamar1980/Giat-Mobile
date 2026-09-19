import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/register_screen.dart';

void main() {
  testWidgets('RegisterScreen step 1 and step 2 render correctly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Brand Logo & Header
    expect(find.text('GIAT'), findsOneWidget);
    expect(find.text('Ginjal'), findsOneWidget);
    expect(find.text('Sehat'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);

    // Verify Chat Bubbles
    expect(
      find.text('Daftar untuk mulai menjaga kesehatan ginjal bersama GIAT.'),
      findsOneWidget,
    );
    expect(find.text('Buat Akun GIAT di bawah'), findsOneWidget);

    // Verify Step 1 Form Fields
    expect(find.text('Nama Lengkap'), findsOneWidget);
    expect(find.text('Masukkan nama lengkap'), findsOneWidget);
    expect(find.text('NIK (Nomor Induk Kependudukan)'), findsOneWidget);
    expect(find.text('Masukkan 16 digit NIK'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Masukkan email'), findsOneWidget);
    expect(find.text('Selanjutnya'), findsOneWidget);

    // Fill Step 1 Valid Data
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Masukkan nama lengkap'),
      'Budi Santoso',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Masukkan 16 digit NIK'),
      '3201234567890123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Masukkan email'),
      'budi@gmail.com',
    );

    // Tap Selanjutnya
    await tester.tap(find.text('Selanjutnya'));
    await tester.pumpAndSettle();

    // Verify Step 2 Form Fields
    expect(find.text('Alamat'), findsOneWidget);
    expect(find.text('Masukkan alamat lengkap'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
    expect(find.text('Masukkan kata sandi'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);
    expect(find.text('Masukkan kembali kata sandi'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Saya menyetujui'),
      ),
      findsOneWidget,
    );
    expect(find.text('Daftar'), findsOneWidget);
  });
}
