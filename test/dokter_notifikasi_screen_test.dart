import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/dokter/notifikasi/dokter_notifikasi_screen.dart';
import 'package:giat/screens/dokter/konsultasi/dokter_room_chat_screen.dart';

void main() {
  testWidgets('DokterNotifikasiScreen renders header, filter chips, and notification cards', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterNotifikasiScreen(doctorName: 'dr. Andi Wijaya, Sp.PD-KGH'),
      ),
    );
    await tester.pumpAndSettle();

    // Check header bar
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);

    // Check filter chips
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Belum Dibaca'), findsOneWidget);

    // Check notification items rendered
    expect(find.text('Konsultasi Baru'), findsOneWidget);
    expect(find.text('Jadwal konsultasi'), findsOneWidget);
    expect(find.text('Update Sistem'), findsOneWidget);

    // Filter toggle
    await tester.tap(find.text('Belum Dibaca'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();

    // Tap notification card to open bottom sheet
    await tester.tap(find.text('Konsultasi Baru'));
    await tester.pumpAndSettle();

    expect(find.text('Buka Ruang Konsultasi'), findsOneWidget);

    // Tap 'Buka Ruang Konsultasi'
    await tester.tap(find.text('Buka Ruang Konsultasi'));
    await tester.pumpAndSettle();

    expect(find.byType(DokterRoomChatScreen), findsOneWidget);

    // Pop back
    Navigator.of(tester.element(find.byType(DokterRoomChatScreen))).pop();
    await tester.pumpAndSettle();

    // Tap system notification card
    await tester.tap(find.text('Update Sistem'));
    await tester.pumpAndSettle();

    expect(find.text('Tutup'), findsOneWidget);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
  });

  testWidgets('DokterNotifikasiScreen dismisses notification on swipe', (tester) async {
    tester.view.physicalSize = const Size(450, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterNotifikasiScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Konsultasi Baru'), findsOneWidget);

    // Swipe card to dismiss from right to left
    final dismissibleFinder = find.byType(Dismissible).first;
    final startPoint = tester.getTopRight(dismissibleFinder) + const Offset(-20, 30);
    await tester.dragFrom(startPoint, const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Konsultasi Baru'), findsNothing);
    expect(find.text('Notifikasi dihapus'), findsOneWidget);
  });
}
