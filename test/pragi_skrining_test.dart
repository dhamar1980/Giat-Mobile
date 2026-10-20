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

    test('PragiHasilSkrining parses 201 API response with AI ML features correctly', () {
      final mockResponse = {
        "success": true,
        "message": "Skrining AI PRAGI berhasil diproses dan diprediksi",
        "data": {
          "id_pragi": "60a1df28-1b2c-47ea-8d4e-c1e194e82df4",
          "label": "Berisiko Penyakit Ginjal Kronis (CKD)",
          "prediction": 1,
          "confidence_percent": 62.62,
          "probability": {
            "ckd": 0.6262,
            "no_ckd": 0.3738
          },
          "kategori_risiko": "tinggi",
          "hasil_prediksi": "Berisiko Penyakit Ginjal Kronis (CKD)",
          "skor": 10,
          "probabilitas": 0.6262,
          "rekomendasi": "PERINGATAN AI (Tingkat Keyakinan AI: 62.62%): Model Machine Learning mendeteksi indikasi kuat Berisiko Penyakit Ginjal Kronis (CKD).",
          "faktor_risiko": [
            "Riwayat Diabetes / Pradiabetes",
            "Kurang Aktivitas Fisik (Sedentari)",
            "Kelebihan Berat Badan / Overweight (BMI: 26.45)",
            "Kondisi Kesehatan Umum Menurun (Fair/Poor)",
            "Usia Lanjut (60 tahun ke atas)",
            "Pola Waktu Tidur Tidak Optimal (5 jam/hari)"
          ],
          "sumber_prediksi": "python_ml_api",
          "is_fallback": false,
          "tanggal_screening": "2026-10-20T19:02:00+08:00"
        }
      };

      final dataMap = mockResponse['data'] as Map<String, dynamic>;
      final hasil = PragiHasilSkrining.fromJson(dataMap);

      expect(hasil.idPragi, '60a1df28-1b2c-47ea-8d4e-c1e194e82df4');
      expect(hasil.label, 'Berisiko Penyakit Ginjal Kronis (CKD)');
      expect(hasil.prediction, 1);
      expect(hasil.confidencePercent, 62.62);
      expect(hasil.probabilityCkd, 0.6262);
      expect(hasil.probabilityNoCkd, 0.3738);
      expect(hasil.probabilitas, 0.6262);
      expect(hasil.kategoriRisiko, 'tinggi');
      expect(hasil.isRisikoTinggi, isTrue);
      expect(hasil.isRisikoSedang, isFalse);
      expect(hasil.formattedKategori, 'Risiko Tinggi');
      expect(hasil.sumberPrediksi, 'python_ml_api');
      expect(hasil.isFallback, isFalse);
      expect(hasil.displayCkdPercentage, 62.62);
      expect(hasil.displayNoCkdPercentage, closeTo(37.38, 0.01));
      expect(hasil.faktorRisiko.length, 6);
      expect(hasil.rekomendasi, contains('Tingkat Keyakinan AI: 62.62%'));
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

    testWidgets('PragiResultScreen renders results, confidence, and action buttons for Risiko Tinggi AI', (WidgetTester tester) async {
      final mockHasil = PragiHasilSkrining(
        idPragi: '60a1df28-1b2c-47ea-8d4e-c1e194e82df4',
        label: 'Berisiko Penyakit Ginjal Kronis (CKD)',
        prediction: 1,
        confidencePercent: 62.62,
        probabilityCkd: 0.6262,
        probabilityNoCkd: 0.3738,
        kategoriRisiko: 'tinggi',
        hasilPrediksi: 'Berisiko Penyakit Ginjal Kronis (CKD)',
        skor: 10,
        probabilitas: 0.6262,
        rekomendasi: 'Segera jadwalkan konsultasi telemedisin dengan Dokter Ginjal (Nefrolog).',
        faktorRisiko: [
          'Riwayat Diabetes / Pradiabetes',
          'Kelebihan Berat Badan / Overweight (BMI: 26.45)'
        ],
        sumberPrediksi: 'python_ml_api',
        tanggalScreening: '2026-10-20T19:02:00+08:00',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PragiResultScreen(hasil: mockHasil),
        ),
      );

      await tester.pumpAndSettle();

      // Verify category badge, label & confidence badge
      expect(find.text('RISIKO TINGGI'), findsOneWidget);
      expect(find.text('Berisiko Penyakit Ginjal Kronis (CKD)'), findsOneWidget);
      expect(find.text('Keyakinan AI: 62.6%'), findsOneWidget);
      expect(find.text('Total Skor Risiko: 10 poin'), findsOneWidget);

      // Verify dual probability comparison bar labels
      expect(find.text('Berisiko CKD: 62.6%'), findsOneWidget);
      expect(find.text('Bebas CKD: 37.4%'), findsOneWidget);

      // Verify risk factors
      expect(find.text('Riwayat Diabetes / Pradiabetes'), findsOneWidget);
      expect(find.text('Kelebihan Berat Badan / Overweight (BMI: 26.45)'), findsOneWidget);

      // Verify buttons: "Konsultasi Dokter Ginjal Sekarang", "Riwayat Skrining", "Ke Beranda"
      expect(find.text('Konsultasi Dokter Ginjal Sekarang'), findsOneWidget);
      expect(find.text('Riwayat Skrining'), findsOneWidget);
      expect(find.text('Ke Beranda'), findsOneWidget);
    });
  });
}
