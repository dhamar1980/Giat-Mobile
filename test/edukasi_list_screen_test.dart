import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/screens/pasien/edukasi/edukasi_list_screen.dart';

void main() {
  testWidgets('EdukasiListScreen renders search bar, category chips without checkmark, and filters articles', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EdukasiListScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title
    expect(find.text('Pusat Edukasi Ginjal'), findsOneWidget);

    // Verify search bar exists
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Cari artikel kesehatan ginjal...'), findsOneWidget);

    // Verify category chips exist
    expect(find.widgetWithText(ChoiceChip, 'Semua'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Nutrisi & Diet'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Pola Hidup'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Info CKD'), findsOneWidget);

    // Verify ChoiceChips have showCheckmark: false
    final choiceChips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    for (final chip in choiceChips) {
      expect(chip.showCheckmark, isFalse, reason: 'ChoiceChip should not show a checkmark');
    }

    // Verify initial articles
    expect(find.text('Kenali Tanda-Tanda Penyakit Ginjal Sejak Dini'), findsOneWidget);
    expect(find.text('Makanan & Nutrisi Sehat untuk Menjaga Fungsi Ginjal'), findsOneWidget);

    // Test text search
    await tester.enterText(find.byType(TextField), 'Nutrisi');
    await tester.pumpAndSettle();

    expect(find.text('Makanan & Nutrisi Sehat untuk Menjaga Fungsi Ginjal'), findsOneWidget);
    expect(find.text('Kenali Tanda-Tanda Penyakit Ginjal Sejak Dini'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    // Test category filter tap
    await tester.tap(find.widgetWithText(ChoiceChip, 'Pola Hidup'));
    await tester.pumpAndSettle();

    expect(find.text('Pentingnya Menjaga Tekanan Darah bagi Pasien Ginjal'), findsOneWidget);
    expect(find.text('Kenali Tanda-Tanda Penyakit Ginjal Sejak Dini'), findsNothing);
  });
}
