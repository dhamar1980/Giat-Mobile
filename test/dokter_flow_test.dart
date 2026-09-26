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

    // Verify bottom nav & quick menu items
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Konsultasi'), findsWidgets);
    expect(find.text('Pasien'), findsWidgets);
    expect(find.text('Jadwal'), findsWidgets);
    expect(find.text('Profil'), findsOneWidget);

    // Tap Konsultasi tab
    await tester.tap(find.text('Konsultasi').last);
    await tester.pumpAndSettle();
    expect(find.text('Daftar Konsultasi'), findsOneWidget);

    // Tap Pasien center button
    await tester.tap(find.text('Pasien').last);
    await tester.pumpAndSettle();
    expect(find.text('Daftar Pasien'), findsOneWidget);

    // Tap Jadwal tab
    await tester.tap(find.text('Jadwal').last);
    await tester.pumpAndSettle();
    expect(find.text('Jadwal Pasien'), findsOneWidget);

    // Tap Profil tab
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Dokter'), findsWidgets);
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

    final patient = DokterMockData.patients.firstWhere((p) => p.name == 'Budi Santoso');
    await tester.pumpWidget(
      MaterialApp(
        home: DokterRoomChatScreen(patient: patient),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Online Sekarang'), findsOneWidget);

    // Verify (+) button exists
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    // Tap (+) button to open review resep screen
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Buat Resep'), findsOneWidget);
    expect(find.text('Daftar Obat'), findsOneWidget);
    expect(find.text('Candesartan 8mg'), findsOneWidget);
    expect(find.text('Furosemide 40mg'), findsOneWidget);
    expect(find.text('Tambah Obat'), findsOneWidget);
    expect(find.text('Terbitkan Resep'), findsOneWidget);

    // Tap "Tambah Obat" to open Tambah Obat screen
    await tester.tap(find.text('Tambah Obat'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Obat'), findsOneWidget);
    expect(find.text('Cari Obat....'), findsOneWidget);
    expect(find.text('Dosis'), findsOneWidget);
    expect(find.text('Jumlah'), findsOneWidget);
    expect(find.text('Frekuensi'), findsOneWidget);
    expect(find.text('Durasi'), findsOneWidget);
    expect(find.text('Cara Penggunaan'), findsOneWidget);

    // Tap "Kembali" to return to Buat Resep screen
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Resep'), findsOneWidget);

    // Tap "Terbitkan Resep" (scroll into view first)
    await tester.ensureVisible(find.text('Terbitkan Resep'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terbitkan Resep'));
    await tester.pumpAndSettle();

    // Verify returning to room chat and prescription message posted
    expect(find.text('Resep Digital Diterbitkan'), findsOneWidget);
    expect(find.text('Terkirim ke Pasien di Menu Resep Dokter'), findsOneWidget);
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

  testWidgets('DokterDetailPasienScreen renders patient details, metrics, and opens Buat Resep', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final patient = DokterMockData.patients.firstWhere((p) => p.name == 'Siti Wijaya');
    await tester.pumpWidget(
      MaterialApp(
        home: DokterDetailPasienScreen(patient: patient),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Pasien'), findsOneWidget);
    expect(find.text('Siti Wijaya'), findsOneWidget);
    expect(find.text('Mulai Konsultasi'), findsOneWidget);
    expect(find.text('Buat Resep'), findsOneWidget);
    expect(find.text('Pantau Kondisi Pasien Terakhir'), findsOneWidget);
    expect(find.text('Berat Badan'), findsOneWidget);
    expect(find.text('48'), findsOneWidget);
    expect(find.text('Tinggi Badan'), findsOneWidget);
    expect(find.text('1.6'), findsOneWidget);
    expect(find.text('Kurang Baik'), findsOneWidget);
    expect(find.text('Mudah Lelah'), findsOneWidget);
    expect(find.text('Obat Saat Ini'), findsOneWidget);

    // Tap Buat Resep from Detail Pasien screen
    await tester.tap(find.text('Buat Resep'));
    await tester.pumpAndSettle();

    // Verify Buat Resep screen is opened
    expect(find.text('Daftar Obat'), findsOneWidget);
    expect(find.text('Candesartan 8mg'), findsOneWidget);
    expect(find.text('Tambah Obat'), findsOneWidget);
    expect(find.text('Terbitkan Resep'), findsOneWidget);
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
    expect(find.text('Selesai'), findsNWidgets(2)); // counter + badge
    expect(find.text('Berlangsung'), findsOneWidget);
    expect(find.text('Mendatang'), findsNWidgets(2)); // counter + badge
    expect(find.text('Senin, 01 Agu'), findsOneWidget);
    expect(find.text('Siti Wijaya'), findsOneWidget);
    expect(find.text('Siti Rahmawati'), findsOneWidget);
    expect(find.text('Andi Wijaya'), findsOneWidget);
    expect(find.text('Mulai Chat'), findsOneWidget);
    expect(find.text('Detail'), findsOneWidget);
    expect(find.text('Lihat Detail'), findsNWidgets(2));

    // Test tap Mulai Chat navigates to DokterRoomChatScreen
    await tester.tap(find.text('Mulai Chat'));
    await tester.pumpAndSettle();
    expect(find.text('Ketik pesan...'), findsOneWidget);
    expect(find.text('Online Sekarang'), findsOneWidget);

    // Pop back to schedule
    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
    navigatorState.pop();
    await tester.pumpAndSettle();

    // Test tap Detail on Siti Rahmawati navigates to DokterDetailPasienScreen
    await tester.tap(find.text('Detail'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Pasien'), findsOneWidget);
    expect(find.text('Siti Rahmawati'), findsWidgets);

    navigatorState.pop();
    await tester.pumpAndSettle();

    // Test tap Lihat Detail on Siti Wijaya
    await tester.tap(find.text('Lihat Detail').first);
    await tester.pumpAndSettle();
    expect(find.text('Detail Pasien'), findsOneWidget);
    expect(find.text('Siti Wijaya'), findsWidgets);
  });

  testWidgets('DokterProfileScreen and sub-screens render accurately', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterProfileScreen(
          doctorName: 'Dr. Andi Pratama',
          specialty: 'Spesialis Penyakti Dalam / Ginjal',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profil Dokter'), findsWidgets);
    expect(find.text('Dr. Andi Pratama'), findsWidgets);
    expect(find.text('Profile Dokter'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Keamanan'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);

    // 1. Test Navigasi ke Detail Profile Dokter & Modal Ganti Foto Profil (Tombol Edit Kuning)
    await tester.tap(find.text('Profile Dokter'));
    await tester.pumpAndSettle();

    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Informasi Profesional'), findsOneWidget);
    expect(find.text('Spesialisasi'), findsOneWidget);
    expect(find.text('No. STR'), findsOneWidget);
    expect(find.text('No. SIP'), findsOneWidget);
    expect(find.text('Institusi'), findsOneWidget);
    expect(find.text('RS Medika Utama'), findsOneWidget);
    expect(find.text('Praktik'), findsOneWidget);
    expect(find.text('Alamat Praktik'), findsOneWidget);
    expect(find.text('Jl. Sehat No. 12, Jember'), findsOneWidget);
    expect(find.text('Jadwal Praktik'), findsOneWidget);

    // Tap Tombol Edit Kuning untuk memicu modal ganti foto profil
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Ganti Foto Profil'), findsOneWidget);
    expect(find.text('Ambil Foto dari Kamera'), findsOneWidget);
    expect(find.text('Pilih dari Galeri Foto'), findsOneWidget);
    expect(find.text('Pilihan Avatar Dokter'), findsOneWidget);
    expect(find.text('Hapus Foto Profil'), findsOneWidget);

    // Pilih dari Kamera
    await tester.tap(find.text('Ambil Foto dari Kamera'));
    await tester.pumpAndSettle();

    // Kembali ke Halaman Utama Profil Dokter
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    // 2. Test Navigasi ke Pengaturan Notifikasi Dokter
    await tester.tap(find.text('Notifikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Konsultasi Baru'), findsOneWidget);
    expect(find.text('Pengingat Jadwal'), findsOneWidget);
    expect(find.text('Update Sistem'), findsOneWidget);

    // Kembali
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    // 3. Test Navigasi ke Keamanan Akun
    await tester.tap(find.text('Keamanan'));
    await tester.pumpAndSettle();

    expect(find.text('Keamanan Akun'), findsOneWidget);
    expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    expect(find.text('Sesi Aktif'), findsOneWidget);

    // 4. Test Navigasi ke Form Ganti Kata Sandi (Screenshot Terbaru)
    await tester.tap(find.text('Ubah Kata Sandi'));
    await tester.pumpAndSettle();

    expect(find.text('Perbarui Kata Sandi'), findsWidgets);
    expect(find.text('Ganti Kata Sandi'), findsOneWidget);
    expect(find.text('Kata Sandi Saat Ini'), findsOneWidget);
    expect(find.text('Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Kata sandi minimal 8 karakter.'), findsOneWidget);

    // Kembali ke Keamanan Akun
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();

    // 5. Test Navigasi ke Riwayat Perangkat (Sesi Aktif)
    await tester.tap(find.text('Sesi Aktif'));
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Perangkat'), findsOneWidget);
    expect(find.text('Perangkat Ini'), findsOneWidget);
    expect(find.text('Smartphoone Android'), findsOneWidget);
    expect(find.text('Sesi Lainnya'), findsOneWidget);
    expect(find.text('Iphone 18'), findsOneWidget);
    expect(find.text('Keluarkan Perangkat'), findsWidgets);
  });
}

