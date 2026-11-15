import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/dokter/models/dokter_models.dart';
import 'package:giat/screens/dokter/profile/dokter_profile_screen.dart';
import 'package:giat/screens/dokter/profile/dokter_informasi_profile_screen.dart';

void main() {
  setUp(() {
    DokterProfileState.instance.syncFromUser(
      name: 'dr. Andi Wijaya, Sp.PD-KGH',
      spec: 'Dokter Ginjal & Hipertensi',
    );
  });

  tearDown(() {
    DokterProfileState.instance.syncFromUser(
      name: 'Dr. Andi Pratama',
      spec: 'Spesialis Penyakit Dalam / Ginjal',
    );
  });

  testWidgets('DokterProfileScreen header avatar, name, and specialty are perfectly centered horizontally', (tester) async {
    const screenWidth = 400.0;
    tester.view.physicalSize = const Size(screenWidth, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterProfileScreen(
          doctorName: 'dr. Andi Wijaya, Sp.PD-KGH',
          specialty: 'Dokter Ginjal & Hipertensi',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final allTexts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList();
    print('ALL TEXTS IN DOKTER PROFILE: $allTexts');

    final screenCenterX = screenWidth / 2; // 200.0

    // 1. Verify Avatar Center X
    final avatarFinder = find.byType(ClipOval).first;
    final avatarCenter = tester.getCenter(avatarFinder);
    expect((avatarCenter.dx - screenCenterX).abs(), lessThan(1.5),
        reason: 'Avatar center X (${avatarCenter.dx}) should be at screen center ($screenCenterX)');

    // 2. Verify Doctor Name Center X
    final nameFinder = find.text(DokterProfileState.instance.doctorName);
    final nameCenter = tester.getCenter(nameFinder);
    expect((nameCenter.dx - screenCenterX).abs(), lessThan(1.5),
        reason: 'Doctor name center X (${nameCenter.dx}) should be at screen center ($screenCenterX)');

    // 3. Verify Doctor Specialty Center X
    final specFinder = find.text(DokterProfileState.instance.specialty);
    final specCenter = tester.getCenter(specFinder);
    expect((specCenter.dx - screenCenterX).abs(), lessThan(1.5),
        reason: 'Doctor specialty center X (${specCenter.dx}) should be at screen center ($screenCenterX)');
  });

  testWidgets('DokterInformasiProfileScreen header avatar and texts are also centered', (tester) async {
    const screenWidth = 400.0;
    tester.view.physicalSize = const Size(screenWidth, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: DokterInformasiProfileScreen(
          doctorName: 'dr. Andi Wijaya, Sp.PD-KGH',
          specialty: 'Dokter Ginjal & Hipertensi',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final screenCenterX = screenWidth / 2; // 200.0

    final avatarFinder = find.byType(ClipOval).first;
    final avatarCenter = tester.getCenter(avatarFinder);
    expect((avatarCenter.dx - screenCenterX).abs(), lessThan(1.5));

    final nameFinder = find.text(DokterProfileState.instance.doctorName);
    final nameCenter = tester.getCenter(nameFinder);
    expect((nameCenter.dx - screenCenterX).abs(), lessThan(1.5));
  });
}
