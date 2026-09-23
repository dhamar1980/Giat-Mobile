import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/dokter/dokter_home_screen.dart';
import 'package:giat/screens/dokter/notifikasi/dokter_notifikasi_screen.dart';
import 'package:giat/screens/dokter/konsultasi/dokter_konsultasi_screen.dart';
import 'package:giat/screens/dokter/konsultasi/dokter_room_chat_screen.dart';
import 'package:giat/screens/dokter/konsultasi/dokter_video_call_screen.dart';
import 'package:giat/screens/dokter/pasien/dokter_detail_pasien_screen.dart';
import 'package:giat/screens/dokter/jadwal/dokter_jadwal_screen.dart';
import 'package:giat/screens/dokter/profile/dokter_profile_screen.dart';
import 'package:giat/screens/dokter/models/dokter_models.dart';

void main() {
  testWidgets('DokterHomeScreen renders greeting, recent messages, schedule, and tabs', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterHomeScreen(doctorName: 'Dr. Andi Pratama'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify greetings
    expect(find.textContaining('Dr. Andi Pratama'), findsOneWidget);
    expect(find.textContaining('Berikut ringkasan aktivitas'), findsOneWidget);

    // Verify sections
    expect(find.text('Pesan Terbaru'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsWidgets);
    expect(find.text('Siti Wijaya'), findsWidgets);
    expect(find.text('Jadwal Hari ini'), findsOneWidget);
    expect(find.text('Ahmad Hidayat'), findsOneWidget);

    // Verify bottom nav items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Konsultasi'), findsWidgets);
    expect(find.text('Pasien'), findsOneWidget);
    expect(find.text('Jadwal'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Tap Konsultasi tab
    await tester.tap(find.text('Konsultasi').last);
    await tester.pumpAndSettle();
    expect(find.text('Daftar Konsultasi'), findsOneWidget);

    // Tap Pasien center button
    await tester.tap(find.text('Pasien'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Pasien'), findsOneWidget);

    // Tap Jadwal tab
    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();
    expect(find.text('Jadwal Pasien'), findsOneWidget);

    // Tap Profil tab
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Dokter'), findsOneWidget);
  });

  testWidgets('DokterHomeScreen renders Ringkasan Aktivitas below Jadwal and scrolls to it', (tester) async {
    tester.view.physicalSize = const Size(450, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterHomeScreen(doctorName: 'Dr. Andi Pratama'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all sections are rendered continuously on the home screen
    expect(find.text('Pesan Terbaru'), findsOneWidget);
    expect(find.text('Jadwal Hari ini'), findsOneWidget);
    expect(find.text('Berikut Ringkasan aktivitas Anda hari ini.'), findsOneWidget);
    expect(find.text('Konsultasi'), findsWidgets);
    expect(find.text('Membuat resep'), findsWidgets);
    expect(find.text('Paracetamol 500 mg'), findsOneWidget);
    expect(find.text('Amoxicillin 500 mg'), findsOneWidget);
    expect(find.text('2 Tablet'), findsOneWidget);
    expect(find.text('1 Tablet'), findsOneWidget);
    expect(find.text('2 item obat'), findsOneWidget);

    // Tap on bubble 2 to scroll to summary
    await tester.tap(find.textContaining('Berikut ringkasan aktivitas'));
    await tester.pumpAndSettle();

    // Tap on bubble 1 to scroll back to top
    await tester.tap(find.textContaining('Dr. Andi Pratama'), warnIfMissed: false);
    await tester.pumpAndSettle();
  });

  testWidgets('DokterNotifikasiScreen renders list of notifications', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterNotifikasiScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Konsultasi Baru'), findsOneWidget);
    expect(find.text('Jadwal konsultasi'), findsOneWidget);
    expect(find.text('Update Sistem'), findsOneWidget);
  });

  testWidgets('DokterKonsultasiScreen filters by status and searches', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterKonsultasiScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daftar Konsultasi'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Terjadwal'), findsWidgets);
    expect(find.text('Selesai'), findsWidgets);

    // Tap 'Terjadwal' tab
    await tester.tap(find.text('Terjadwal').first);
    await tester.pumpAndSettle();
    expect(find.text('Lestari Putri'), findsOneWidget);
    expect(find.text('Lesti Purnama'), findsOneWidget);

    // Tap 'Selesai' tab
    await tester.tap(find.text('Selesai').first);
    await tester.pumpAndSettle();
    expect(find.text('Hendra Kurniawan'), findsOneWidget);
    expect(find.text('Sudah Selesai'), findsOneWidget);
  });

  testWidgets('DokterRoomChatScreen renders messages and opens prescription sheet', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final patient = DokterMockData.patients.first;
    await tester.pumpWidget(
      MaterialApp(
        home: DokterRoomChatScreen(patient: patient),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Online Sekarang'), findsOneWidget);
    expect(find.text('Konsultasi Hasil Lab'), findsOneWidget);
    expect(find.text('Keluhan Gejala Baru'), findsOneWidget);

    // Verify (+) button exists
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    // Tap (+) button to open review resep screen
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Buat Resep'), findsOneWidget);
    expect(find.text('Daftar Obat'), findsOneWidget);
    expect(find.text('Candesartan 8mg'), findsOneWidget);
    expect(find.text('Terbitkan Resep'), findsOneWidget);
  });

  testWidgets('DokterVideoCallScreen renders call controls', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterVideoCallScreen(patientName: 'Budi Santoso'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsWidgets);
    expect(find.text('Spesialis Ginjal & Hipertensi'), findsOneWidget);
    expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
  });

  testWidgets('DokterDetailPasienScreen renders patient details and metrics', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final patient = DokterMockData.patients[1]; // Siti Wijaya
    await tester.pumpWidget(
      MaterialApp(
        home: DokterDetailPasienScreen(patient: patient),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Pasien'), findsOneWidget);
    expect(find.text('Siti Wijaya'), findsOneWidget);
    expect(find.text('Mulai Konsultasi'), findsOneWidget);
    expect(find.text('Pantau Kondisi Pasien Terakhir'), findsOneWidget);
    expect(find.text('Berat Badan'), findsOneWidget);
    expect(find.text('48'), findsOneWidget);
    expect(find.text('Tinggi Badan'), findsOneWidget);
    expect(find.text('1.6'), findsOneWidget);
    expect(find.text('Kurang Baik'), findsOneWidget);
    expect(find.text('Mudah Lelah'), findsOneWidget);
  });

  testWidgets('DokterJadwalScreen renders daily counters and timeline', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterJadwalScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jadwal Pasien'), findsOneWidget);
    expect(find.text('Jumlah Konsultasi Hari Ini'), findsOneWidget);
    expect(find.text('04'), findsOneWidget);
    expect(find.text('Senin, 01 Agu'), findsOneWidget);
    expect(find.text('Siti Wijaya'), findsOneWidget);
    expect(find.text('Siti Rahmawati'), findsOneWidget);
    expect(find.text('Andi Wijaya'), findsOneWidget);
  });

  testWidgets('DokterProfileScreen and sub-screens render accurately', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterProfileScreen(
          doctorName: 'Dr. Andi Pratama',
          specialty: 'Spesialis Penyakit Dalam / Ginjal',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil Dokter'), findsOneWidget);
    expect(find.text('Dr. Andi Pratama'), findsOneWidget);
    expect(find.text('Informasi Profil'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Keamanan Akun'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);

    // Tap Keamanan Akun
    await tester.tap(find.text('Keamanan Akun'));
    await tester.pumpAndSettle();
    expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    expect(find.text('Sesi Aktif'), findsOneWidget);
  });
}
