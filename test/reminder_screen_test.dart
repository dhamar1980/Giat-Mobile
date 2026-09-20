import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/pasien/reminder/reminder_list_screen.dart';
import 'package:giat/screens/pasien/reminder/tambah_reminder_screen.dart';

void main() {
  testWidgets('ReminderListScreen renders correctly with stacked header and cards without status badges', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReminderListScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title Badge and Kembali button
    expect(find.text('Reminder Saya'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Hari ini'), findsOneWidget);

    // Verify Initial Cards (Figma 771:5254)
    expect(find.text('Minum Obat'), findsOneWidget);
    expect(find.text('Losartan 50 mg'), findsOneWidget);
    expect(find.text('08:00 WIB'), findsOneWidget);

    expect(find.text('Konsultasi Dokter'), findsOneWidget);
    expect(find.text('Dr. budi Santoso'), findsOneWidget);
    expect(find.text('14:00 WIB'), findsOneWidget);

    // Verify status badges are REMOVED as requested
    expect(find.text('Belum di lakukan'), findsNothing);
    expect(find.text('Akan Datang'), findsNothing);
    expect(find.text('Selesai'), findsNothing);

    // Verify Bottom Button
    expect(find.text('Tambah Reminder Baru'), findsOneWidget);
  });

  testWidgets('TambahReminderScreen renders with stacked header and toggles between Obat and Konsultasi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TambahReminderScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Kembali button
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Tambah Reminder Baru'), findsOneWidget);
    expect(find.text('Pilih Kategori'), findsOneWidget);

    // Default is Obat (Figma 771:4931)
    expect(find.text('Nama Pengingat'), findsOneWidget);
    expect(find.text('Keterangan / Dosis'), findsOneWidget);
    expect(find.text('Pilih Pengulangan'), findsOneWidget);

    // Switch category to Konsultasi (Figma 771:5091)
    await tester.tap(find.text('Obat'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Konsultasi').last);
    await tester.pumpAndSettle();

    // Verify Konsultasi Fields
    expect(find.text('Nama Konsultasi'), findsOneWidget);
    expect(find.text('Lokasi / Link Pertemuan'), findsOneWidget);
    expect(find.text('Catatan Tambahan (Opsional)'), findsOneWidget);
    expect(find.text('Simpan Reminder'), findsOneWidget);
  });
}
