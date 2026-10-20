import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/pasien/notifikasi/pasien_notifikasi_screen.dart';

void main() {
  testWidgets('PasienNotifikasiScreen renders UI with Kembali button, Notifikasi pill, and cards', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PasienNotifikasiScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Check header elements
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);

    // Check notification cards from mock/fallback
    expect(find.text('Update Sistem'), findsOneWidget);
    expect(find.text('Perbaikan bug pada bagian profile'), findsOneWidget);
    expect(find.text('30 menit lalu'), findsOneWidget);

    // Filter chips
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Belum Dibaca'), findsOneWidget);

    // Tap notification card to open detail bottom sheet
    await tester.tap(find.text('Update Sistem'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Notifikasi'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);

    // Close sheet
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Notifikasi'), findsNothing);
  });
}
