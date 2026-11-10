import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:giat/screens/pasien/reminder/reminder_list_screen.dart';
import 'package:giat/screens/pasien/reminder/tambah_reminder_screen.dart';
import 'package:giat/screens/pasien/notifikasi/pasien_notifikasi_screen.dart';
import 'package:giat/services/reminder_notification_service.dart';
import 'package:giat/services/storage_service.dart';
import 'package:giat/utils/time_utils.dart';

void main() {
  testWidgets('ReminderListScreen renders correctly with stacked header and cards without status badges', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ReminderListScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title Badge and Kembali button
    expect(find.text('Pengingat Saya'), findsOneWidget);
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
    expect(find.text('Tambah Pengingat Baru'), findsOneWidget);
  });

  testWidgets('TambahReminderScreen renders with stacked header, toggles category and pengulangan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TambahReminderScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Kembali button
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Tambah Pengingat Baru'), findsOneWidget);
    expect(find.text('Pilih Kategori'), findsOneWidget);

    // Default is Obat (Figma 771:4931)
    expect(find.text('Nama Pengingat'), findsOneWidget);
    expect(find.text('Keterangan / Dosis'), findsOneWidget);
    expect(find.text('Pilih Pengulangan'), findsOneWidget);

    // Verify repeat options: only 'Setiap Hari' & 'Sekali Saja', removed: 'Hari Kerja', 'Akhir Pekan', 'Kustom'
    expect(find.text('Setiap Hari'), findsOneWidget);
    await tester.tap(find.text('Setiap Hari'));
    await tester.pumpAndSettle();

    expect(find.text('Sekali Saja'), findsOneWidget);
    expect(find.text('Hari Kerja (Senin - Jumat)'), findsNothing);
    expect(find.text('Akhir Pekan (Sabtu - Minggu)'), findsNothing);
    expect(find.text('Kustom'), findsNothing);

    // Select 'Sekali Saja'
    await tester.tap(find.text('Sekali Saja').last);
    await tester.pumpAndSettle();
    expect(find.text('Sekali Saja'), findsOneWidget);

    // Switch category to Konsultasi (Figma 771:5091)
    await tester.tap(find.text('Obat'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Konsultasi').last);
    await tester.pumpAndSettle();

    // Verify Konsultasi Fields
    expect(find.text('Nama Konsultasi'), findsOneWidget);
    expect(find.text('Lokasi / Link Pertemuan'), findsOneWidget);
    expect(find.text('Catatan Tambahan (Opsional)'), findsOneWidget);
    expect(find.text('Simpan Pengingat'), findsOneWidget);
  });

  testWidgets('Dropdowns open downwards even after re-selecting non-first item', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TambahReminderScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Select 'Konsultasi'
    await tester.tap(find.text('Obat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konsultasi').last);
    await tester.pumpAndSettle();

    // Now 'Konsultasi' is selected. Tap it again to re-open
    final categoryFinder = find.text('Konsultasi');
    final buttonBox = tester.getRect(categoryFinder);

    await tester.tap(categoryFinder);
    await tester.pumpAndSettle();

    // Verify 'Obat' is in the popup and positioned below button
    final obatInPopupFinder = find.text('Obat').last;
    final obatBox = tester.getRect(obatInPopupFinder);
    expect(obatBox.top >= buttonBox.top, isTrue);

    // Close popup by tapping Konsultasi
    await tester.tap(find.text('Konsultasi').last);
    await tester.pumpAndSettle();

    // 2. In Konsultasi form, default repeat is 'Sekali Saja'. Tap repeat dropdown
    final repeatFinder = find.text('Sekali Saja');
    await tester.ensureVisible(repeatFinder);
    await tester.pumpAndSettle();
    final repeatButtonBox = tester.getRect(repeatFinder);

    await tester.tap(repeatFinder);
    await tester.pumpAndSettle();

    final setiapHariInPopupFinder = find.text('Setiap Hari').last;
    final setiapHariBox = tester.getRect(setiapHariInPopupFinder);
    expect(setiapHariBox.top >= repeatButtonBox.top, isTrue);
  });

  testWidgets('When a reminder reaches its scheduled time, it triggers a notification and appears in PasienNotifikasiScreen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();

    final now = TimeUtils.nowInUserZone;
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final dateIso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Save an active reminder scheduled for current time
    await StorageService().saveRemindersCache([
      {
        'id': 'rem-test-due-001',
        'judul': 'Minum Obat Amlodipine 10mg',
        'subjudul': '1 Tablet Sesudah Makan',
        'tipe': 'obat',
        'waktu': '$hh:$mm:00',
        'tanggal': dateIso,
        'pengulangan': 'harian',
        'is_active': true,
      },
    ]);

    // Trigger due check
    await ReminderNotificationService.instance.checkDueReminders(allowInTest: true);

    // Verify notification was created in cache and unread count updated
    final cachedNotifs = StorageService().getNotificationsCache();
    expect(cachedNotifs.isNotEmpty, isTrue);
    expect(
      cachedNotifs.any((n) =>
          (n['judul']?.toString() ?? '').contains('Minum Obat Amlodipine 10mg')),
      isTrue,
    );
    expect(ReminderNotificationService.instance.unreadCountNotifier.value, greaterThanOrEqualTo(1));

    // Render PasienNotifikasiScreen and verify the triggered reminder notification appears
    await tester.pumpWidget(
      const MaterialApp(
        home: PasienNotifikasiScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Minum Obat Amlodipine 10mg'), findsWidgets);
  });
}
