import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/pasien/konsultasi/dokter_detail_screen.dart';

void main() {
  testWidgets('DokterDetailScreen renders curved header, doctor profile, penilaian, info tambahan, jadwal, and sticky button', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterDetailScreen(
          doctor: {
            'name': 'Dr. Budi Santoso',
            'specialty': 'Spesialis Ginjal & Hipertensi',
            'rating': 4.9,
            'experience': '15+',
            'avatarUrl': '',
            'isOnline': true,
          },
        ),
      ),
    );
    await tester.pump();

    // 1. Verify Top Header
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Dr. Budi Santoso'), findsOneWidget);
    expect(find.text('Spesialis Ginjal & Hipertensi'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);

    // 2. Verify Informasi Penilaian Section
    expect(find.text('Informasi Penilaian'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    expect(find.text('Ulasan Pasien'), findsOneWidget);
    expect(find.text('15+'), findsOneWidget);
    expect(find.text('Tahun Pengalaman'), findsOneWidget);

    // 3. Verify Informasi Tambahan Section
    expect(find.text('Informasi Tambahan'), findsOneWidget);
    expect(find.text('Spesialisasi'), findsOneWidget);
    expect(find.text('Penyakit Dalam, Ginjal, Hipertensi, Hemodialisis'), findsOneWidget);
    expect(find.text('Informasi Praktik'), findsOneWidget);
    expect(find.text('Layanan Telemedice Video & Chat'), findsOneWidget);

    // 4. Verify Jadwal Praktik Section
    expect(find.text('Jadwal Praktik'), findsOneWidget);
    expect(find.text('Senin - Jumat'), findsNWidgets(2));
    expect(find.text('09:00 - 16:00'), findsOneWidget);
    expect(find.text('Sabtu'), findsOneWidget);
    expect(find.text('09:00 - 13:00'), findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);

    // 5. Verify Tentang Dokter Section
    expect(find.text('Tentang Dokter'), findsOneWidget);
    expect(find.textContaining('Dokter yang memberikan layanan konsultasi kesehatan'), findsOneWidget);

    // 6. Verify Card Beri Penilaian (Rating & Ulasan Pasien)
    expect(find.text('Beri Penilaian'), findsOneWidget);
    expect(
      find.text('Bagaimana pengalaman konsultasimu dengan Dokter Budi Santoso?'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    expect(find.text('Ketuk bintang untuk menilai'), findsOneWidget);
    expect(find.text('Ulasan (opsional)'), findsOneWidget);
    expect(find.text('Ceritakan pengalamanmu...'), findsOneWidget);
    expect(find.text('Konsultasi Sekarang'), findsOneWidget);

    // Verify rating interaction: Tap 5th star
    await tester.tap(find.byIcon(Icons.star_rounded).last);
    await tester.pump();

    // Verify typing review
    await tester.enterText(
      find.widgetWithText(TextField, 'Ceritakan pengalamanmu...'),
      'Pelayanan dokter sangat memuaskan dan responsif.',
    );
    await tester.pump();
    expect(find.text('Pelayanan dokter sangat memuaskan dan responsif.'), findsOneWidget);

    // Verify Kirim Penilaian Saja button
    expect(find.text('Kirim Penilaian Saja'), findsOneWidget);
    await tester.tap(find.text('Kirim Penilaian Saja'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Penilaian (5★) dan ulasan Anda berhasil disimpan'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
