import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/pasien/konsultasi/konsultasi_video_call_screen.dart';
import 'package:giat/screens/dokter/konsultasi/dokter_video_call_screen.dart';

void main() {
  testWidgets('KonsultasiVideoCallScreen (Pasien) renders full video call controls, PiP, and status', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: KonsultasiVideoCallScreen(
          doctorName: 'Dr. Anisa Putri',
          specialty: 'Dokter Umum',
          avatarUrl: '',
        ),
      ),
    );
    await tester.pump();

    // Verify Doctor Info in Top Bar
    expect(find.text('Dr. Anisa Putri'), findsWidgets);
    expect(find.text('Dokter Umum'), findsOneWidget);

    // Verify Video Call Badges
    expect(find.text('HD 1080p'), findsOneWidget);

    // Verify PiP Camera preview exists
    expect(find.text('Anda (Pasien)'), findsOneWidget);

    // Verify Modern Control Bar buttons (Mic, Video, Speaker, End Call) - Pesan is removed
    expect(find.text('Mic'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Speaker'), findsOneWidget);
    expect(find.text('Pesan'), findsNothing);
    expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);

    // Toggle Mic
    await tester.tap(find.text('Mic'));
    await tester.pump();
    expect(find.text('Mute'), findsOneWidget);

    // Toggle Video
    await tester.tap(find.text('Video'));
    await tester.pump();
    expect(find.text('Video Off'), findsOneWidget);
  });

  testWidgets('DokterVideoCallScreen (Dokter) renders full video call controls, PiP, and status', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterVideoCallScreen(
          patientName: 'Budi Santoso',
          specialty: 'Spesialis Ginjal & Hipertensi',
        ),
      ),
    );
    await tester.pump();

    // Verify Patient Info in Top Bar
    expect(find.text('Budi Santoso'), findsWidgets);
    expect(find.text('Pasien'), findsOneWidget);

    // Verify Video Call Badges
    expect(find.text('HD 1080p'), findsOneWidget);

    // Verify PiP Camera preview exists
    expect(find.text('Anda (Dokter)'), findsOneWidget);

    // Verify Modern Control Bar buttons - Pesan is removed
    expect(find.text('Mic'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('Speaker'), findsOneWidget);
    expect(find.text('Pesan'), findsNothing);
    expect(find.byIcon(Icons.call_end_rounded), findsOneWidget);

    // Toggle Mic
    await tester.tap(find.text('Mic'));
    await tester.pump();
    expect(find.text('Mute'), findsOneWidget);

    // Toggle Video
    await tester.tap(find.text('Video'));
    await tester.pump();
    expect(find.text('Video Off'), findsOneWidget);
  });
}
