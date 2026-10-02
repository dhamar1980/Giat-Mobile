import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/dokter/dokter_home_screen.dart';
import 'package:giat/screens/dokter/models/dokter_models.dart';
import 'package:giat/screens/dokter/profile/dokter_profile_screen.dart';
import 'package:giat/screens/dokter/profile/dokter_informasi_profile_screen.dart';
import 'package:giat/login_screen.dart';

import 'package:giat/models/user_model.dart';
import 'package:giat/services/storage_service.dart';

void main() {
  setUp(() async {
    final budi = UserModel(
      id: 2,
      nama: 'dr. Budi Santoso, Sp.PD-KGH',
      email: 'dr.budi@gmail.com',
      role: 'dokter',
      spesialisasi: 'Spesialis Penyakit Dalam / Konsultan Ginjal Hipertensi (Sp.PD-KGH)',
      instansi: 'RS Medika Utama',
    );
    await StorageService().saveUser(budi);
    DokterProfileState.instance.syncFromUser(
      name: budi.nama,
      spec: budi.spesialisasi,
      inst: budi.instansi,
    );
  });

  tearDown(() async {
    await StorageService().clearAuth();
    DokterProfileState.instance.syncFromUser(
      name: 'Dr. Andi Pratama',
      spec: 'Spesialis Penyakit Dalam / Ginjal',
    );
  });

  testWidgets('DokterProfileScreen dynamically renders dr. Budi Santoso and not Dr. Andi Pratama', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterProfileScreen(
          doctorName: 'dr. Budi Santoso, Sp.PD-KGH',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Must find Dr. Budi
    expect(find.text('dr. Budi Santoso, Sp.PD-KGH'), findsOneWidget);
    // Must NOT find Dr. Andi Pratama
    expect(find.text('Dr. Andi Pratama'), findsNothing);
  });

  testWidgets('DokterHomeScreen with dr. Budi renders correctly on Home and Profile tab', (tester) async {
    tester.view.physicalSize = const Size(450, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterHomeScreen(
          doctorName: 'dr. Budi Santoso, Sp.PD-KGH',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Home greeting
    expect(find.textContaining('dr. Budi Santoso, Sp.PD-KGH'), findsOneWidget);

    // Switch to Profile Tab (index 4)
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    // Profile header must display Dr. Budi
    expect(find.text('dr. Budi Santoso, Sp.PD-KGH'), findsOneWidget);
    expect(find.text('Dr. Andi Pratama'), findsNothing);

    // Tap Profile Dokter menu item to open DokterInformasiProfileScreen
    await tester.tap(find.text('Profile Dokter'));
    await tester.pumpAndSettle();

    expect(find.byType(DokterInformasiProfileScreen), findsOneWidget);
    expect(find.text('dr. Budi Santoso, Sp.PD-KGH'), findsOneWidget);
    expect(find.text('Dr. Andi Pratama'), findsNothing);
  });

  testWidgets('Login as dr.budi connects to DokterHomeScreen with dr. Budi profile', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Enter dr.budi credentials
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'dr.budi@gmail.com');
    await tester.enterText(textFields.at(1), 'password123');

    // Tap Masuk
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pump();
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    // Check if DokterHomeScreen is reached
    expect(find.byType(DokterHomeScreen), findsOneWidget);
    expect(find.textContaining('dr. Budi Santoso'), findsOneWidget);
    expect(find.text('Dr. Andi Pratama'), findsNothing);
  });
}
