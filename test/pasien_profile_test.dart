import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/models/user_model.dart';
import 'package:giat/screens/pasien/profile/profile_pasien_screen.dart';
import 'package:giat/services/storage_service.dart';
import 'package:giat/utils/time_utils.dart';

void main() {
  group('TimeUtils.formatBirthDate', () {
    test('formats ISO8601 UTC timestamp string without timezone shift', () {
      expect(TimeUtils.formatBirthDate('1998-04-12T00:00:00.000000Z'), '12 April 1998');
      expect(TimeUtils.formatBirthDate('1998-04-12T00:00:00Z'), '12 April 1998');
      expect(TimeUtils.formatBirthDate('1998-04-12'), '12 April 1998');
      expect(TimeUtils.formatBirthDate('1985-05-12 00:00:00'), '12 Mei 1985');
    });

    test('preserves already formatted dates', () {
      expect(TimeUtils.formatBirthDate('12 April 1998'), '12 April 1998');
      expect(TimeUtils.formatBirthDate('12 Mei 1985'), '12 Mei 1985');
    });

    test('handles null and empty values', () {
      expect(TimeUtils.formatBirthDate(null), '-');
      expect(TimeUtils.formatBirthDate(''), '-');
      expect(TimeUtils.formatBirthDate('-'), '-');
    });

    test('converts to db date format YYYY-MM-DD', () {
      expect(TimeUtils.toDbDate('12 April 1998'), '1998-04-12');
      expect(TimeUtils.toDbDate('1998-04-12T00:00:00.000000Z'), '1998-04-12');
    });
  });

  group('ProfilePasienScreen Widget Tests', () {
    setUp(() async {
      final user = UserModel(
        id: 10,
        nama: 'Siti Aisyah',
        email: 'siti.aisyah@gmail.com',
        role: 'pasien',
        alamat: 'Jl. Dago Asri No. 12, Coblong, Kota Bandung',
        jenisKelamin: 'P',
        tanggalLahir: '1998-04-12T00:00:00.000000Z',
        golonganDarah: 'O',
      );
      await StorageService().saveUser(user);
    });

    tearDown(() async {
      await StorageService().clearAuth();
    });

    testWidgets('renders real user info and formats birth date properly', (tester) async {
      tester.view.physicalSize = const Size(450, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfilePasienScreen(userName: 'Siti Aisyah'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Name & Email
      expect(find.text('Siti Aisyah'), findsOneWidget);
      expect(find.text('siti.aisyah@gmail.com'), findsOneWidget);

      // Verify birth date is formatted as '12 April 1998' and NOT '1998-04-12T00:00:00.000000Z'
      expect(find.text('12 April 1998'), findsOneWidget);
      expect(find.textContaining('000000Z'), findsNothing);

      // Verify Gender is formatted to 'Perempuan' instead of just 'P'
      expect(find.text('Perempuan'), findsOneWidget);

      // Verify Blood Type and Address
      expect(find.text('O'), findsOneWidget);
      expect(find.text('Jl. Dago Asri No. 12, Coblong, Kota Bandung'), findsOneWidget);

      // Verify Yellow Edit button is REMOVED
      expect(find.widgetWithText(GestureDetector, 'Edit'), findsNothing);

      // Verify Kembali button is present
      expect(find.text('Kembali'), findsOneWidget);

      // Verify Camera icon badge exists for changing profile photo
      expect(find.byIcon(Icons.camera_alt_rounded), findsWidgets);
    });
  });
}

