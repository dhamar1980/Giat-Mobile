import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/pasien/obat/daftar_obat_screen.dart';
import 'package:giat/screens/pasien/obat/lacak_obat_screen.dart';
import 'package:giat/screens/pasien/obat/riwayat_obat_screen.dart';

void main() {
  testWidgets('DaftarObatScreen navigates to LacakObatScreen when clicking Lacak Obat', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DaftarObatScreen(userName: 'Pasien Test'),
      ),
    );

    await tester.pump();

    // Verify Lacak Obat button is present
    final lacakFinder = find.text('Lacak Obat');
    expect(lacakFinder, findsOneWidget);

    // Scroll until visible if needed and tap
    await tester.ensureVisible(lacakFinder);
    await tester.pumpAndSettle();
    await tester.tap(lacakFinder);
    await tester.pumpAndSettle();

    // Verify LacakObatScreen is opened
    expect(find.byType(LacakObatScreen), findsOneWidget);
    expect(find.text('#G-9021'), findsWidgets);
    expect(find.text('Aktivitas Pengiriman'), findsOneWidget);
    expect(find.text('Alamat Tujuan Pengiriman'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsNothing);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
  });

  testWidgets('DaftarObatScreen navigates to RiwayatObatScreen when clicking Lihat Riwayat', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DaftarObatScreen(userName: 'Pasien Test'),
      ),
    );

    await tester.pump();

    // Verify Lihat Riwayat button is present
    final riwayatFinder = find.text('Lihat Riwayat');
    expect(riwayatFinder, findsOneWidget);

    await tester.ensureVisible(riwayatFinder);
    await tester.pumpAndSettle();
    await tester.tap(riwayatFinder);
    await tester.pumpAndSettle();

    // Verify RiwayatObatScreen is opened
    expect(find.byType(RiwayatObatScreen), findsOneWidget);
    expect(find.text('Riwayat Pembelian Obat'), findsOneWidget);
    expect(find.text('Melalui Resep Dokter'), findsWidgets);
    expect(find.text('Obat Bebas (Tanpa Resep Dokter)'), findsOneWidget);
  });

  testWidgets('RiwayatObatScreen displays filter chips and orders properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RiwayatObatScreen(userName: 'Pasien Test'),
      ),
    );

    await tester.pump();

    // Verify title and filters
    expect(find.text('Riwayat Pembelian Obat'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Dengan Resep'), findsOneWidget);
    expect(find.text('Obat Bebas'), findsOneWidget);

    // Verify purchase card details
    expect(find.text('#G-9021'), findsOneWidget);
    expect(find.text('#G-8812'), findsOneWidget);
    expect(find.text('#G-8450'), findsOneWidget);

    // Tap filter "Obat Bebas"
    await tester.tap(find.text('Obat Bebas'));
    await tester.pump();

    // Should now show non-prescription order and filter out prescription orders
    expect(find.text('#G-8450'), findsOneWidget);
    expect(find.text('#G-9021'), findsNothing);
  });
}
