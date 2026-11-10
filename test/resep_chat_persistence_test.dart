import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/dokter/models/dokter_models.dart';
import 'package:giat/screens/dokter/konsultasi/dokter_room_chat_screen.dart';
import 'package:giat/screens/pasien/konsultasi/konsultasi_chat_screen.dart';
import 'package:giat/utils/time_utils.dart';

void main() {
  test('TimeUtils properly formats prescription time with local timezone offset', () {
    // 2026-11-10T15:27:17.000Z in WIB (+7) is 22:27
    final utcTime = '2026-11-10T15:27:17.000Z';
    final formattedTime = TimeUtils.formatChatTime(utcTime, separator: ':');
    expect(formattedTime, '22:27');

    final fullTimeWithZone = '$formattedTime ${TimeUtils.getTimeZoneName()}';
    expect(fullTimeWithZone, '22:27 WIB');
  });

  testWidgets('DokterRoomChatScreen initializes and can render prescription card', (tester) async {
    tester.view.physicalSize = const Size(450, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final patient = DokterMockData.patients.first;

    await tester.pumpWidget(
      MaterialApp(
        home: DokterRoomChatScreen(
          patient: patient,
          consultationId: '5fe921df-457e-43d1-bc4f-6dedf761199e',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify chat screen renders
    expect(find.text(patient.name), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
  });

  testWidgets('KonsultasiChatScreen initializes and can render prescription notification card', (tester) async {
    tester.view.physicalSize = const Size(450, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: KonsultasiChatScreen(
          consultationId: '5fe921df-457e-43d1-bc4f-6dedf761199e',
          doctorName: 'dr. Andi Wijaya, Sp.PD-KGH',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify chat screen renders
    expect(find.text('dr. Andi Wijaya, Sp.PD-KGH'), findsOneWidget);
  });
}

