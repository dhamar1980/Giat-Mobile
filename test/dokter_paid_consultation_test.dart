import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/dokter/konsultasi/dokter_konsultasi_screen.dart';
import 'package:giat/screens/dokter/models/dokter_models.dart';

void main() {
  testWidgets('DokterConsultation unread badge renders only when messageCount > 0', (tester) async {
    tester.view.physicalSize = const Size(450, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterKonsultasiScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify screen title and tabs
    expect(find.text('Daftar Konsultasi'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Terjadwal'), findsWidgets);
    expect(find.text('Selesai'), findsWidgets);

    // Initial mock data has 1 ongoing consultation with 2 messages (Budi Santoso)
    expect(find.text('2 Pesan'), findsOneWidget);

    // Patients with 0 unread messages should not have a "0 Pesan" badge
    expect(find.text('0 Pesan'), findsNothing);
  });

  test('DokterConsultation copyWith works as expected', () {
    const original = DokterConsultation(
      id: 'c-test',
      patientName: 'Siti Aisyah',
      initials: 'SA',
      status: KonsultasiStatus.berlangsung,
      scheduledTimeText: '14:00 WIB',
      messageCount: 14,
      lastMessage: 'Halo dokter',
      lastTime: '10:00',
      patientId: 'p-test',
    );

    final updated = original.copyWith(messageCount: 0);
    expect(updated.messageCount, 0);
    expect(updated.patientName, 'Siti Aisyah');
    expect(updated.status, KonsultasiStatus.berlangsung);
  });
}

