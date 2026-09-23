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

    // 6. Verify Konsultasi Sekarang Button is removed
    expect(find.text('Konsultasi Sekarang'), findsNothing);
  });
}
