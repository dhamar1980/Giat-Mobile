import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/dokter/jadwal/dokter_jadwal_screen.dart';
import 'package:giat/screens/dokter/konsultasi/dokter_room_chat_screen.dart';
import 'package:giat/screens/dokter/pasien/dokter_detail_pasien_screen.dart';
import 'package:giat/screens/dokter/models/dokter_models.dart';

void main() {
  final now = DateTime.now();
  final todayIso =
      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final tomorrowIso =
      '${now.add(const Duration(days: 1)).year.toString().padLeft(4, '0')}-${now.add(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${now.add(const Duration(days: 1)).day.toString().padLeft(2, '0')}';

  final testPatientSiti = const DokterPatient(
    id: 'p-siti',
    name: 'Siti Aisyah',
    initials: 'SA',
    age: 28,
    gender: 'Perempuan',
    address: 'Jl. Dago Asri No. 12, Bandung',
    weightKg: 60.0,
    heightM: 1.60,
    condition: 'Baik',
    complaint: 'Pemeriksaan rutin ginjal',
    complaintDetail: 'Kondisi stabil',
    currentMedicines: [],
    consultationId: 'c-today-1',
    paymentStatus: 'lunas',
  );

  final testPatientBudi = const DokterPatient(
    id: 'p-budi',
    name: 'Budi Prasetyo',
    initials: 'BP',
    age: 35,
    gender: 'Laki-laki',
    address: 'Jl. Riau No. 102, Bandung',
    weightKg: 72.0,
    heightM: 1.72,
    condition: 'Stabil',
    complaint: 'Sering pusing dan bengkak',
    complaintDetail: 'Bengkak pergelangan kaki',
    currentMedicines: [],
    consultationId: 'c-today-2',
    paymentStatus: 'lunas',
  );

  final testRealSchedules = [
    DokterScheduleItem(
      id: 'c-today-1',
      time: '09:00 - 09:30',
      patientName: 'Siti Aisyah',
      status: 'Selesai',
      serviceType: 'Chat Konsultasi',
      patientId: 'p-siti',
      date: todayIso,
      patient: testPatientSiti,
      consultationId: 'c-today-1',
    ),
    DokterScheduleItem(
      id: 'c-today-2',
      time: '10:30 - 11:00',
      patientName: 'Budi Prasetyo',
      status: 'Aktif',
      serviceType: 'Chat Konsultasi',
      patientId: 'p-budi',
      date: todayIso,
      patient: testPatientBudi,
      consultationId: 'c-today-2',
    ),
    const DokterScheduleItem(
      id: 'c-tomorrow-1',
      time: '10:00 - 10:30',
      patientName: 'Nurul Hidayah',
      status: 'Mendatang',
      serviceType: 'Chat Konsultasi',
      patientId: 'p-nurul',
      date: '2099-01-01',
    ),
  ];

  testWidgets('DokterJadwalScreen renders real schedule data, dynamic counters, and navigates', (tester) async {
    tester.view.physicalSize = const Size(450, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: DokterJadwalScreen(
          initialSchedules: testRealSchedules,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Jadwal Pasien'), findsOneWidget);
    expect(find.text('Jumlah Konsultasi Hari Ini'), findsOneWidget);

    // Verify Today Counters (2 consultations today: 1 Selesai, 1 Aktif/Berlangsung, 0 Mendatang)
    expect(find.text('02'), findsOneWidget); // Total count for today
    expect(find.text('01'), findsNWidgets(2)); // Selesai count & Berlangsung count
    expect(find.text('00'), findsOneWidget); // Mendatang count

    // Verify Today Schedule Items
    expect(find.text('Siti Aisyah'), findsOneWidget);
    expect(find.text('Budi Prasetyo'), findsOneWidget);
    expect(find.text('09:00 - 09:30'), findsOneWidget);
    expect(find.text('10:30 - 11:00'), findsOneWidget);

    // Verify Actions for Selesai (Lihat Detail) and Aktif (Mulai Chat, Detail)
    expect(find.text('Lihat Detail'), findsOneWidget);
    expect(find.text('Mulai Chat'), findsOneWidget);
    expect(find.text('Detail'), findsOneWidget);

    // Tap Mulai Chat on active session -> navigates to room chat
    await tester.tap(find.text('Mulai Chat'));
    await tester.pumpAndSettle();
    expect(find.byType(DokterRoomChatScreen), findsOneWidget);
    expect(find.text('Budi Prasetyo'), findsWidgets);

    // Pop back
    Navigator.of(tester.element(find.byType(DokterRoomChatScreen))).pop();
    await tester.pumpAndSettle();

    // Tap Detail on active session -> navigates to patient detail
    await tester.tap(find.text('Detail'));
    await tester.pumpAndSettle();
    expect(find.byType(DokterDetailPasienScreen), findsOneWidget);
    expect(find.text('Detail Pasien'), findsOneWidget);
    expect(find.text('Budi Prasetyo'), findsWidgets);

    Navigator.of(tester.element(find.byType(DokterDetailPasienScreen))).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('DokterJadwalScreen shows empty state when selected date has no schedules', (tester) async {
    tester.view.physicalSize = const Size(450, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterJadwalScreen(
          initialSchedules: [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Empty State
    expect(find.text('Jadwal Pasien'), findsOneWidget);
    expect(find.text('00'), findsWidgets); // 00 for total and counters
    expect(find.text('Tidak Ada Jadwal Konsultasi'), findsOneWidget);
    expect(find.text('Belum ada pasien yang terjadwal pada tanggal ini.'), findsOneWidget);
  });
}
