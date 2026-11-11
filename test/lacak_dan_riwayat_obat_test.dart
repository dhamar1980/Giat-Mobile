import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/pasien/obat/daftar_obat_screen.dart';
import 'package:giat/screens/pasien/obat/lacak_obat_screen.dart';
import 'package:giat/screens/pasien/obat/riwayat_obat_screen.dart';
import 'package:giat/screens/pasien/obat/pembayaran_model.dart';

void main() {
  testWidgets('DaftarObatScreen displays Status Pengiriman empty state or active order', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DaftarObatScreen(userName: 'Pasien Test'),
      ),
    );

    await tester.pump();

    // Verify Status Pengiriman section is present
    expect(find.text('Status Pengiriman'), findsOneWidget);
    expect(find.text('Lihat Riwayat'), findsOneWidget);
    expect(find.text('Belum Ada Pengiriman Aktif'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
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
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Dengan Resep'), findsOneWidget);
    expect(find.text('Obat Bebas'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('RiwayatObatScreen displays empty state when no orders found', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RiwayatObatScreen(userName: 'Pasien Test', autoFetch: false),
      ),
    );

    await tester.pump();

    // Verify title and filters
    expect(find.text('Riwayat Pembelian Obat'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Dengan Resep'), findsOneWidget);
    expect(find.text('Obat Bebas'), findsOneWidget);

    // Verify empty state is displayed instead of mock dummy orders
    expect(find.text('Tidak Ada Riwayat Pembelian'), findsOneWidget);
    expect(find.text('#G-9021'), findsNothing);
    expect(find.text('#G-8812'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('LacakObatScreen renders tracking timeline and order details correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LacakObatScreen(
          userName: 'Siti Aisyah',
          orderId: 'ORD-LSW9MIAVE5',
          status: 'Menunggu Konfirmasi',
          orderData: const OrderCheckoutData(
            orderNumber: 'ORD-LSW9MIAVE5',
            statusPesanan: 'menunggu_konfirmasi',
            statusPembayaran: 'lunas',
            recipientName: 'Siti Aisyah',
            recipientAddress: 'Jl. Merdeka No. 10 Bandung',
            items: [
              {'nama_obat': 'Ketosteril Tab', 'jumlah': 1, 'harga_satuan': 650000}
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Pesanan Obat Pasien'), findsOneWidget);
    expect(find.text('ORD-LSW9MIAVE5'), findsNothing);
    expect(find.text('Aktivitas Pengiriman'), findsOneWidget);
    expect(find.text('Alamat Tujuan Pengiriman'), findsOneWidget);
    expect(find.text('Siti Aisyah • 0812-3456-7891'), findsOneWidget);
    expect(find.text('Ketosteril Tab'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
