import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/pasien/obat/pembayaran_model.dart';
import 'package:giat/screens/pasien/obat/pembayaran_qris_screen.dart';
import 'package:giat/screens/pasien/obat/pembayaran_transfer_bank_screen.dart';
import 'package:giat/screens/pasien/obat/pembayaran_berhasil_screen.dart';

void main() {
  testWidgets('PembayaranQrisScreen renders order data and actions properly', (WidgetTester tester) async {
    const testData = OrderCheckoutData(
      orderNumber: 'ORD-20260901-TEST',
      prescriptionNumber: 'RX-TEST-001',
      totalAmountFormatted: 'Rp. 790.000,00',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PembayaranQrisScreen(
          userName: 'Pasien Test',
          orderData: testData,
        ),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify key texts
    expect(find.text('Payment Checkout'), findsOneWidget);
    expect(find.text('ORD-20260901-TEST'), findsOneWidget);
    expect(find.text('RX-TEST-001'), findsOneWidget);
    expect(find.text('Rp. 790.000,00'), findsOneWidget);
    expect(find.text('Scan QRIS untuk Membayar'), findsOneWidget);
    expect(find.text('NMID : ID12039437'), findsOneWidget);
    expect(find.text('Saya Sudah Membayar'), findsOneWidget);
    expect(find.text('Batalkan Pembayaran'), findsOneWidget);
  });

  testWidgets('PembayaranTransferBankScreen renders VA data and bank selector properly', (WidgetTester tester) async {
    const testData = OrderCheckoutData(
      orderNumber: 'ORD-20260901-TEST',
      prescriptionNumber: 'RX-TEST-001',
      totalAmountFormatted: 'Rp. 790.000,00',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PembayaranTransferBankScreen(
          userName: 'Pasien Test',
          orderData: testData,
        ),
      ),
    );

    await tester.pump();

    // Verify key texts
    expect(find.text('Transfer Virtual Account'), findsOneWidget);
    expect(find.text('8077 0812 3456 7890'), findsOneWidget);
    expect(find.text('BCA Virtual Account'), findsWidgets);
    expect(find.text('Saya Sudah Membayar'), findsOneWidget);
    expect(find.text('Batalkan Pembayaran'), findsOneWidget);
  });

  testWidgets('PembayaranBerhasilScreen renders tracking timeline and details', (WidgetTester tester) async {
    const testData = OrderCheckoutData(
      orderNumber: 'ORD-20260901-TEST',
      prescriptionNumber: 'RX-TEST-001',
      totalAmountFormatted: 'Rp. 790.000,00',
      paymentMethod: 'QRIS',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: PembayaranBerhasilScreen(
          userName: 'Pasien Test',
          orderData: testData,
        ),
      ),
    );

    await tester.pump();

    // Verify status and order tracking
    expect(find.text('Pembayaran Berhasil'), findsWidgets);
    expect(find.text('Status Pesanan'), findsOneWidget);
    expect(find.text('Pesanan Dibuat'), findsOneWidget);
    expect(find.text('Menunggu Verifikasi Apoteker'), findsOneWidget);
    expect(find.text('Kembali ke Obat'), findsOneWidget);

    // Tap Kembali ke Obat button
    await tester.tap(find.text('Kembali ke Obat'));
    await tester.pumpAndSettle();

    // Verify it navigates to MasterLayout displaying the Obat tab
    expect(find.byType(PembayaranBerhasilScreen), findsNothing);
  });
}
