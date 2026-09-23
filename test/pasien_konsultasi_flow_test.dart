import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/pasien/konsultasi/jadwalkan_konsultasi_screen.dart';
import 'package:giat/screens/pasien/konsultasi/pembayaran_konsultasi_screen.dart';
import 'package:giat/screens/pasien/konsultasi/menunggu_pembayaran_qris_screen.dart';
import 'package:giat/screens/pasien/konsultasi/menunggu_pembayaran_va_screen.dart';
import 'package:giat/screens/pasien/konsultasi/pembayaran_berhasil_konsultasi_screen.dart';

void main() {
  testWidgets('JadwalkanKonsultasiScreen renders doctor info, date chips, and time slots', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: JadwalkanKonsultasiScreen(
          doctor: {
            'name': 'Dr. Anisa Putri',
            'specialty': 'Dokter Umum',
            'hospital': 'RS Kedung Dowo',
            'experience': '10 thn pengalaman',
            'rating': 4.9,
            'price': 'Rp 150.000',
            'avatarUrl': '',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title Badge
    expect(find.text('Jadwalkan Konsultasi Baru'), findsOneWidget);

    // Verify Doctor Info
    expect(find.text('Dr. Anisa Putri'), findsWidgets);
    expect(find.text('Dokter Umum'), findsOneWidget);
    expect(find.text('RS Kedung Dowo • 10 thn pengalaman'), findsOneWidget);

    // Verify Date Section
    expect(find.text('Pilih Tanggal Konsultasi'), findsOneWidget);
    expect(find.text('Senin, 01 Agu'), findsOneWidget);

    // Verify Time Section
    expect(find.text('Pilih Waktu'), findsOneWidget);
    expect(find.text('14.00'), findsOneWidget);
    expect(find.text('Dipilih'), findsOneWidget);

    // Verify Ringkasan
    expect(find.text('Ringkasan Jadwal Konsultasi'), findsOneWidget);
    expect(find.text('Rp 150.000'), findsWidgets);

    // Verify Button
    expect(find.text('Lanjutkan Pembayaran'), findsOneWidget);
  });

  testWidgets('PembayaranKonsultasiScreen renders payment methods and breakdown', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: PembayaranKonsultasiScreen(
          doctor: {
            'name': 'Dr. Anisa Putri',
            'specialty': 'Dokter Umum',
            'hospital': 'RS Kedung Dowo',
            'experience': '10 thn pengalaman',
            'rating': 4.9,
            'avatarUrl': '',
          },
          selectedDate: 'Kamis, 20 September 2026',
          selectedTime: '14.00 – 14.30 WIB (30 Menit)',
          price: 'Rp 150.000',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title Badge
    expect(find.text('Pembayaran Konsultasi'), findsOneWidget);

    // Verify Doctor and date/time
    expect(find.text('Dr. Anisa Putri'), findsOneWidget);
    expect(find.text('Kamis, 20 September 2026'), findsOneWidget);
    expect(find.text('14.00 – 14.30 WIB (30 Menit)'), findsOneWidget);

    // Verify Payment Methods
    expect(find.text('Metode Pembayaran'), findsOneWidget);
    expect(find.text('QRIS'), findsOneWidget);
    expect(find.text('Transfer Bank'), findsOneWidget);
    expect(find.text('Instan'), findsOneWidget);

    // Verify Payment Breakdown
    expect(find.text('Detail Pembayaran'), findsOneWidget);
    expect(find.text('Subtotal Konsultasi'), findsOneWidget);
    expect(find.text('Gratis'), findsOneWidget);
    expect(find.text('Total Pembayaran'), findsOneWidget);

    // Verify Perhatian Card
    expect(find.text('Perhatian'), findsOneWidget);
    expect(find.text('Jadwal otomatis masuk ke menu "Konsultasi Saya"'), findsOneWidget);

    // Verify Button
    expect(find.text('Bayar Sekarang'), findsOneWidget);
  });

  testWidgets('MenungguPembayaranQrisScreen renders QRIS code, doctor info, steps, and success dialog', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: MenungguPembayaranQrisScreen(
          doctor: {
            'name': 'Dr. Anisa Putri',
            'specialty': 'Dokter Umum',
            'rating': 4.9,
            'avatarUrl': '',
          },
          selectedDate: '20 Sep 2026',
          selectedTime: '14.00–14.30 WIB',
          price: 'Rp 150.000',
        ),
      ),
    );
    await tester.pump();

    // Verify Title Badge
    expect(find.text('Menunggu Pembayaran QRIS'), findsOneWidget);

    // Verify Sections & Content
    expect(find.text('Scan QRIS untuk Membayar'), findsOneWidget);
    expect(find.text('NMID: ID12039437'), findsOneWidget);
    expect(find.text('Standar Pembayaran Nasional'), findsOneWidget);
    expect(find.text('Unduh QR Code'), findsOneWidget);

    // Verify Doctor Card
    expect(find.text('Menunggu Pembayaran'), findsWidgets);
    expect(find.text('Dr. Anisa Putri'), findsOneWidget);

    // Verify Instruction & Buttons
    expect(find.text('Tata Cara Pembayaran Via QRIS'), findsOneWidget);
    expect(find.text('Saya Sudah Membayar'), findsOneWidget);
    expect(find.text('Ganti Metode Pembayaran'), findsOneWidget);

    // Tap Saya Sudah Membayar -> Opens PembayaranBerhasilKonsultasiScreen
    await tester.tap(find.text('Saya Sudah Membayar'));
    await tester.pumpAndSettle();

    expect(find.text('Pembayaran Berhasil'), findsWidgets);
    expect(find.text('Lihat Konsultasi Saya'), findsOneWidget);
  });

  testWidgets('MenungguPembayaranVaScreen renders VA number, tabs, and switches instructions', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: MenungguPembayaranVaScreen(
          doctor: {
            'name': 'Dr. Anisa Putri',
            'specialty': 'Dokter Umum',
            'rating': 4.9,
            'avatarUrl': '',
          },
          selectedDate: '20 Sep 2026',
          selectedTime: '14.00–14.30 WIB',
          price: 'Rp. 150.000',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title Badge
    expect(find.text('Menunggu Pembayaran Virtual Account'), findsOneWidget);

    // Verify Total Card
    expect(find.text('TOTAL PEMBAYARAN'), findsOneWidget);
    expect(find.text('Rp. 150.000,00'), findsOneWidget);

    // Verify Bank Details
    expect(find.text('BCA Virtual Account'), findsOneWidget);
    expect(find.text('A.N. GIAT Farma / Encep Suryana'), findsOneWidget);
    expect(find.text('8808 1234 5678 9012'), findsWidgets);
    expect(find.text('Salin No. VA'), findsOneWidget);

    // Verify Doctor Info
    expect(find.text('Dr. Anisa Putri'), findsOneWidget);

    // Verify Tabs
    expect(find.text('Petunjuk Transfer'), findsOneWidget);
    expect(find.text('m-Banking'), findsOneWidget);
    expect(find.text('ATM BCA'), findsOneWidget);
    expect(find.text('KlikBCA'), findsOneWidget);

    // Verify initial m-Banking instruction
    expect(find.textContaining('BCA mobile'), findsOneWidget);

    // Switch to ATM BCA tab
    await tester.tap(find.text('ATM BCA'));
    await tester.pumpAndSettle();
    expect(find.textContaining('kartu ATM BCA'), findsOneWidget);

    // Switch to KlikBCA tab
    await tester.tap(find.text('KlikBCA'));
    await tester.pumpAndSettle();
    expect(find.textContaining('KlikBCA Individual'), findsOneWidget);

    // Verify Bottom Buttons
    expect(find.text('Saya Sudah Membayar'), findsOneWidget);
    expect(find.text('Ganti Metode Pembayaran'), findsOneWidget);

    // Tap Saya Sudah Membayar -> Opens PembayaranBerhasilKonsultasiScreen
    await tester.tap(find.text('Saya Sudah Membayar'));
    await tester.pumpAndSettle();

    expect(find.text('Pembayaran Berhasil'), findsWidgets);
    expect(find.text('Lihat Konsultasi Saya'), findsOneWidget);
  });

  testWidgets('PembayaranBerhasilKonsultasiScreen renders transaction details and alert', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: PembayaranBerhasilKonsultasiScreen(
          doctor: {
            'name': 'Dr. Anisa Putri',
            'specialty': 'Dokter Umum',
            'rating': 4.9,
            'avatarUrl': '',
          },
          selectedDate: 'Kamis, 20 September 2026',
          selectedTime: '14.00 – 14.30 WIB (30 Menit)',
          price: 'Rp 150.000',
          paymentMethod: 'qris',
          transactionId: 'GIAT-INV-20260920-0982',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title Badge & Headings
    expect(find.text('Pembayaran Berhasil'), findsWidgets);
    expect(find.text('Booking konsultasi Anda dengan Dr. Anisa Putri telah berhasil dikonfirmasi.'), findsOneWidget);

    // Verify Details
    expect(find.text('Kamis, 20 September 2026'), findsOneWidget);
    expect(find.text('14.00 – 14.30 WIB (30 Menit)'), findsOneWidget);
    expect(find.text('GIAT-INV-20260920-0982'), findsOneWidget);
    expect(find.text('QRIS / Instant Settlement'), findsOneWidget);
    expect(find.text('Total Terbayar'), findsOneWidget);
    expect(find.text('Rp 150.000'), findsOneWidget);

    // Verify Alert Box
    expect(find.text('Jadwal Siap Digunakan'), findsOneWidget);
    expect(find.textContaining('10 menit sebelum jadwal dimulai'), findsOneWidget);

    // Verify Button
    expect(find.text('Lihat Konsultasi Saya'), findsOneWidget);
  });
}

