import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/dokter/dokter_home_screen.dart';
import 'package:giat/screens/dokter/konsultasi/dokter_room_chat_screen.dart';
import 'package:giat/screens/dokter/resep/dokter_review_resep_sheet.dart';
import 'package:giat/utils/time_utils.dart';

void main() {
  test('TimeUtils.cleanTimeString correctly extracts clean time without Time( wrapper', () {
    expect(TimeUtils.cleanTimeString(null), isNull);
    expect(TimeUtils.cleanTimeString(''), isNull);
    expect(TimeUtils.cleanTimeString('Time(10:26:16.000)'), '10:26');
    expect(TimeUtils.cleanTimeString('Time(14:30:00)'), '14:30');
    expect(TimeUtils.cleanTimeString('Time(08:05)'), '08:05');
    expect(TimeUtils.cleanTimeString('10:26:16'), '10:26');
    expect(TimeUtils.cleanTimeString('14:30'), '14:30');
    expect(TimeUtils.cleanTimeString('2026-11-10T10:26:00'), '10:26');
  });

  testWidgets('DokterHomeScreen renders live dashboard data when provided', (tester) async {
    tester.view.physicalSize = const Size(450, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterHomeScreen(doctorName: 'dr. Andi Wijaya, Sp.PD-KGH'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial render
    expect(find.text('Pesan Terbaru'), findsOneWidget);
    expect(find.text('Jadwal Hari ini'), findsOneWidget);
    expect(find.text('Berikut Ringkasan aktivitas Anda hari ini.'), findsOneWidget);

    // Verify quick menu buttons
    expect(find.text('Konsultasi'), findsWidgets);
    expect(find.text('Pasien'), findsWidgets);
    expect(find.text('Jadwal'), findsWidgets);

    // Verify tapping on chat navigates to chat screen
    await tester.tap(find.text('Budi Santoso').first);
    await tester.pumpAndSettle();
    expect(find.byType(DokterRoomChatScreen), findsOneWidget);

    // Pop back
    Navigator.of(tester.element(find.byType(DokterRoomChatScreen))).pop();
    await tester.pumpAndSettle();

    // Verify tapping on prescription activity card navigates to review prescription screen
    await tester.tap(find.text('Membuat resep').first);
    await tester.pumpAndSettle();
    expect(find.byType(DokterReviewResepScreen), findsOneWidget);
  });

  testWidgets('DokterHomeScreen formats Time(...) objects in schedule properly without Time(- Time(', (tester) async {
    tester.view.physicalSize = const Size(450, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockDashboard = {
      'dokter': {
        'nama': 'dr. Andi Wijaya, Sp.PD-KGH',
      },
      'pesan_terbaru': [
        {
          'id': 'msg-1',
          'id_pasien': 'p-1',
          'nama_pasien': 'Siti Aisyah',
          'last_message': 'Halo dok',
          'created_at': '2026-11-10T20:33:00',
        }
      ],
      'jadwal_hari_ini': [
        {
          'id': 'sch-1',
          'id_pasien': 'p-1',
          'nama_pasien': 'Siti Aisyah',
          'jam_mulai': 'Time(10:26:16.000)',
          'jam_selesai': 'Time(11:00:00.000)',
          'status': 'berlangsung',
          'jenis_layanan': 'chat',
        }
      ],
      'konsultasi_terbaru': {
        'id': 'c-1',
        'nama_pasien': 'Siti Aisyah',
        'jam_mulai': 'Time(10:26:16.000)',
        'keluhan_awal': 'Pemeriksaan rutin ginjal',
        'status': 'berlangsung',
      },
      'ringkasan_aktivitas': {
        'konsultasi': {
          'id': 'c-1',
          'nama_pasien': 'Siti Aisyah',
          'jam_mulai': 'Time(10:26:16.000)',
          'keluhan_awal': 'Pemeriksaan rutin ginjal',
          'status': 'berlangsung',
        },
      },
    };

    await tester.pumpWidget(
      MaterialApp(
        home: DokterHomeScreen(
          doctorName: 'dr. Andi Wijaya, Sp.PD-KGH',
          initialDashboardData: mockDashboard,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify schedule time renders clean: '10:26 - 11:00 WIB'
    expect(find.text('10:26 - 11:00 WIB'), findsOneWidget);

    // Verify NO text contains 'Time('
    expect(find.textContaining('Time('), findsNothing);
  });
}

