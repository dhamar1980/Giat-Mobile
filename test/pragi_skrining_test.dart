import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:giat/models/pragi_model.dart';
import 'package:giat/screens/pasien/pragi/pragi_screening_screen.dart';
import 'package:giat/screens/pasien/pragi/pragi_result_screen.dart';

void main() {
  group('Pragi Models Test', () {
    test('Default 16 Pertanyaan is valid and complete', () {
      final questions = PragiPertanyaan.default16Pertanyaan;
      expect(questions.length, 16);

      // Verify all 16 kodeField exist
      final expectedKeys = [
        'HeartDisease',
        'BMI',
        'Smoking',
        'AlcoholDrinking',
        'Stroke',
        'PhysicalHealth',
        'MentalHealth',
        'DiffWalking',
        'Sex',
        'AgeCategory',
        'Race',
        'Diabetic',
        'PhysicalActivity',
        'GenHealth',
        'SleepTime',
        'Asthma',
      ];

      for (var key in expectedKeys) {
        expect(questions.any((q) => q.kodeField == key), isTrue,
            reason: 'Missing key $key');
      }
    });

    test('PragiHasilSkrining parses 201 API response correctly', () {
      final mockResponse = {
        "success": true,
        "message": "Skrining PRAGI berhasil diproses",
        "data": {
          "id_pragi": "uuid-test-1234",
          "skor": 4,
          "kategori_risiko": "sedang",
          "hasil_prediksi": "Risiko Sedang CKD",
          "rekomendasi": "Disarankan untuk menjaga asupan air putih dan mengurangi garam.",
          "faktor_risiko": [
            "Riwayat Gula Darah Tinggi / Diabetes",
            "Indeks Massa Tubuh (BMI) Berlebih"
          ],
          "tanggal_screening": "2026-10-20T18:30:00Z"
        }
      };

      final dataMap = mockResponse['data'] as Map<String, dynamic>;
      final hasil = PragiHasilSkrining.fromJson(dataMap);

      expect(hasil.idPragi, 'uuid-test-1234');
      expect(hasil.skor, 4);
      expect(hasil.kategoriRisiko, 'sedang');
      expect(hasil.isRisikoSedang, isTrue);
      expect(hasil.isRisikoTinggi, isFalse);
      expect(hasil.formattedKategori, 'Risiko Sedang');
      expect(hasil.hasilPrediksi, 'Risiko Sedang CKD');
      expect(hasil.faktorRisiko.length, 2);
      expect(hasil.rekomendasi, contains('menjaga asupan air putih'));
    });
  });

  group('Pragi UI Screens Test', () {
    testWidgets('PragiScreeningScreen renders properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PragiScreeningScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check top elements
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Pilihan Jawaban Anda'), findsOneWidget);
      expect(find.text('Lanjutkan'), findsOneWidget);
    });

    testWidgets('PragiResultScreen renders results and action buttons for Risiko Sedang', (WidgetTester tester) async {
      final mockHasil = PragiHasilSkrining(
        idPragi: 'test-id',
        skor: 4,
        kategoriRisiko: 'sedang',
        hasilPrediksi: 'Risiko Sedang CKD',
        rekomendasi: 'Kurangi konsumsi natrium dan konsultasikan ke dokter.',
        faktorRisiko: ['Indeks Massa Tubuh (BMI) Berlebih', 'Riwayat Merokok'],
        tanggalScreening: '2026-10-20T18:00:00Z',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PragiResultScreen(hasil: mockHasil),
        ),
      );

      await tester.pumpAndSettle();

      // Verify category badge & score
      expect(find.text('RISIKO SEDANG'), findsOneWidget);
      expect(find.text('Risiko Sedang CKD'), findsOneWidget);
      expect(find.text('Total Skor Risiko: 4 poin'), findsOneWidget);

      // Verify risk factors
      expect(find.text('Indeks Massa Tubuh (BMI) Berlebih'), findsOneWidget);
      expect(find.text('Riwayat Merokok'), findsOneWidget);

      // Verify buttons: "Konsultasi Dokter Sekarang" & "Kembali ke Beranda"
      expect(find.text('Konsultasi Dokter Sekarang'), findsOneWidget);
      expect(find.text('Kembali ke Beranda'), findsOneWidget);
    });
  });
}
