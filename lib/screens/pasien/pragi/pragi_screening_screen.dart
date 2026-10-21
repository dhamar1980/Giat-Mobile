import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/pragi_model.dart';
import '../../../services/pasien_api_service.dart';
import 'pragi_ui_kit.dart';
import 'pragi_processing_screen.dart';

class PragiScreeningScreen extends StatefulWidget {
  const PragiScreeningScreen({super.key});

  @override
  State<PragiScreeningScreen> createState() => _PragiScreeningScreenState();
}

class _PragiScreeningScreenState extends State<PragiScreeningScreen> {
  bool _isLoading = true;
  List<PragiPertanyaan> _questions = [];
  int _currentStep = 1; // 1-based (1 to 16)

  // Map jawaban user: key = kodeField, value = answer ("Yes", 26.45, "Female", etc.)
  final Map<String, dynamic> _jawaban = {};

  // Controllers untuk input angka dinamis
  final TextEditingController _numberController = TextEditingController();

  // Helper kalkulator BMI (Tinggi & Berat Badan)
  final TextEditingController _tbController = TextEditingController(text: '168');
  final TextEditingController _bbController = TextEditingController(text: '65');

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _tbController.dispose();
    _bbController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await PasienApiService().getPragiQuestions();
      if (res.data != null && res.data!.isNotEmpty) {
        _questions = res.data!;
      } else {
        _questions = PragiPertanyaan.default16Pertanyaan;
      }
    } catch (e) {
      _questions = PragiPertanyaan.default16Pertanyaan;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _syncInputForCurrentStep();
      }
    }
  }

  PragiPertanyaan? get _currentQuestion {
    if (_questions.isEmpty || _currentStep < 1 || _currentStep > _questions.length) {
      return null;
    }
    return _questions[_currentStep - 1];
  }

  void _syncInputForCurrentStep() {
    final q = _currentQuestion;
    if (q == null) return;

    if (q.tipeInput == 'number') {
      final val = _jawaban[q.kodeField];
      if (val != null) {
        _numberController.text = val.toString();
      } else {
        // Berikan nilai awal yang masuk akal jika belum ada
        if (q.kodeField == 'BMI') {
          _calculateAndSetBmi(updateTextOnly: false);
        } else if (q.kodeField == 'SleepTime') {
          _numberController.text = '7';
          _jawaban[q.kodeField] = 7;
        } else if (q.kodeField == 'PhysicalHealth' || q.kodeField == 'MentalHealth') {
          _numberController.text = '0';
          _jawaban[q.kodeField] = 0;
        } else {
          _numberController.text = (q.min ?? 0).toString();
          _jawaban[q.kodeField] = q.min ?? 0;
        }
      }
    }
  }

  void _calculateAndSetBmi({bool updateTextOnly = false}) {
    final double? tb = double.tryParse(_tbController.text);
    final double? bb = double.tryParse(_bbController.text);
    if (tb != null && bb != null && tb > 0 && bb > 0) {
      final double tbMeter = tb / 100.0;
      final double calculatedBmi = double.parse((bb / (tbMeter * tbMeter)).toStringAsFixed(2));
      _numberController.text = calculatedBmi.toString();
      if (!updateTextOnly) {
        _jawaban['BMI'] = calculatedBmi;
      }
      setState(() {});
    }
  }

  String _getCategoryForStep(int step) {
    if (step <= 4) return 'Demografi & Parameter Tubuh';
    if (step <= 8) return 'Status Kesehatan & Pola Harian';
    if (step <= 12) return 'Riwayat Medis & Klinis Kronis';
    return 'Gaya Hidup, Mobilitas & Asma';
  }

  String _getMedicalExplanation(String kodeField) {
    switch (kodeField) {
      case 'HeartDisease':
        return 'Penyakit jantung dan ginjal sangat berkaitan erat (Sindrom Kardiorenal). Gangguan sirkulasi darah dapat memengaruhi laju filtrasi ginjal.';
      case 'BMI':
        return 'Indeks Massa Tubuh (IMT) berlebih atau obesitas meningkatkan beban kerja nefron ginjal dan berkaitan dengan risiko hipertensi serta diabetes.';
      case 'Smoking':
        return 'Nikotin dan racun rokok merusak pembuluh darah kapiler halus di ginjal, mempercepat penurunan fungsi ginjal secara signifikan.';
      case 'AlcoholDrinking':
        return 'Konsumsi alkohol berlebih dapat memicu lonjakan tekanan darah dan dehidrasi seluler yang membebani kerja penyaringan ginjal.';
      case 'Stroke':
        return 'Riwayat stroke menandakan adanya gangguan vaskular sistemik yang seringkali berhubungan dengan komplikasi pembuluh darah ginjal.';
      case 'PhysicalHealth':
        return 'Kondisi fisik yang sering sakit dalam sebulan terakhir menjadi indikator tingkat kelemahan sistem imun dan inflamasi kronis.';
      case 'MentalHealth':
        return 'Stres emosional dan gangguan kesehatan mental dapat memicu ketidakseimbangan hormon kortisol yang mempengaruhi tekanan darah dan ginjal.';
      case 'DiffWalking':
        return 'Kesulitan mobilitas fisik atau berjalan dapat mencerminkan komplikasi mikrovaskular, kelemahan otot, atau retensi cairan.';
      case 'Sex':
        return 'Jenis kelamin biologis digunakan dalam perhitungan estimasi Laju Filtrasi Glomerulus (eGFR) dan profil risiko CKD.';
      case 'AgeCategory':
        return 'Fungsi penyaringan ginjal secara alami mengalami penurunan fisiologis seiring bertambahnya usia, terutama di atas 45 tahun.';
      case 'Race':
        return 'Distribusi predisposisi genetik tertentu dapat memengaruhi kerentanan terhadap komplikasi hipertensi dan nefropati.';
      case 'Diabetic':
        return 'Diabetes adalah penyebab utama penyakit ginjal kronis (Nefropati Diabetik) di dunia karena kadar gula tinggi merusak nefron.';
      case 'PhysicalActivity':
        return 'Aktivitas fisik teratur membantu menjaga sensitivitas insulin, kestabilan tekanan darah, dan melancarkan sirkulasi ke ginjal.';
      case 'GenHealth':
        return 'Penilaian kesehatan mandiri berkorelasi kuat dengan kualitas hidup dan deteksi awal penurunan kapasitas fungsional tubuh.';
      case 'SleepTime':
        return 'Tidur cukup (7–8 jam) krusial untuk regenerasi jaringan ginjal dan regulasi ritme sirkadian tekanan darah malam hari.';
      case 'Asthma':
        return 'Kondisi alergi atau inflamasi saluran napas kronis berkaitan dengan respon imunitas sistemik dan penggunaan obat rutin.';
      default:
        return 'Data ini penting untuk pemetaan model algoritma machine learning AI PRAGI dalam mendeteksi risiko ginjal secara presisi.';
    }
  }

  bool _isCurrentStepValid() {
    final q = _currentQuestion;
    if (q == null) return false;

    final val = _jawaban[q.kodeField];
    if (val == null) return false;

    if (q.tipeInput == 'number') {
      final num? parsed = num.tryParse(val.toString());
      if (parsed == null) return false;
      if (q.min != null && parsed < q.min!) return false;
      if (q.max != null && parsed > q.max!) return false;
      return true;
    }

    if (q.tipeInput == 'binary' || q.tipeInput == 'select') {
      return val.toString().trim().isNotEmpty;
    }

    return true;
  }

  bool get _areAllQuestionsAnswered {
    if (_questions.isEmpty) return false;
    for (var q in _questions) {
      final val = _jawaban[q.kodeField];
      if (val == null) return false;
      if (q.tipeInput == 'number') {
        final parsed = num.tryParse(val.toString());
        if (parsed == null) return false;
        if (q.min != null && parsed < q.min!) return false;
        if (q.max != null && parsed > q.max!) return false;
      } else if (val.toString().trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  // ignore: unused_element
  int get _answeredCount {
    int count = 0;
    for (var q in _questions) {
      final val = _jawaban[q.kodeField];
      if (val != null && val.toString().trim().isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  void _nextStep() {
    if (!_isCurrentStepValid()) {
      final q = _currentQuestion;
      String pesan = 'Silakan pilih atau isi jawaban terlebih dahulu';
      if (q != null && q.tipeInput == 'number' && (q.min != null || q.max != null)) {
        pesan = 'Mohon masukkan nilai antara ${q.min ?? 0} s/d ${q.max ?? 100} ${q.satuan ?? ''}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_currentStep < _questions.length) {
      setState(() {
        _currentStep++;
      });
      _syncInputForCurrentStep();
    } else {
      _submitScreening();
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
      _syncInputForCurrentStep();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _submitScreening() {
    // Validasi kelengkapan seluruh pertanyaan
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final val = _jawaban[q.kodeField];
      if (val == null || val.toString().trim().isEmpty) {
        setState(() {
          _currentStep = i + 1;
        });
        _syncInputForCurrentStep();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pertanyaan No. ${i + 1} (${q.kodeField}) belum terisi.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
    }

    // Pastikan seluruh tipe number dikirim sebagai numeric
    final Map<String, dynamic> cleanJawaban = Map<String, dynamic>.from(_jawaban);
    for (var q in _questions) {
      if (q.tipeInput == 'number') {
        final rawVal = cleanJawaban[q.kodeField];
        if (rawVal != null) {
          if (q.kodeField == 'BMI') {
            cleanJawaban[q.kodeField] = double.tryParse(rawVal.toString()) ?? 23.0;
          } else {
            cleanJawaban[q.kodeField] = int.tryParse(rawVal.toString()) ?? (num.tryParse(rawVal.toString()) ?? 0);
          }
        }
      }
    }

    // Pindah ke PragiProcessingScreen untuk pengiriman POST /api/pasien/pragi/skrining
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PragiProcessingScreen(
          jawabanMap: cleanJawaban,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ▼▼▼  DI BAWAH INI HANYA TAMPILAN (UI)  ▼▼▼
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PragiScaffold(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(PragiUi.green),
              ),
              const SizedBox(height: 20),
              Text(
                'Memuat 16 Kuesioner AI PRAGI...',
                style: PragiUi.text(size: 15, weight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Menghubungkan ke API Backend GIAT',
                style: PragiUi.text(size: 12.5, color: PragiUi.muted),
              ),
            ],
          ),
        ),
      );
    }

    final q = _currentQuestion;
    if (q == null) {
      return Scaffold(
        body: Center(
          child: Text('Pertanyaan tidak ditemukan', style: GoogleFonts.inter()),
        ),
      );
    }

    final int totalQuestions = _questions.length;
    final double progressRatio = _currentStep / totalQuestions;
    final bool isLastStep = _currentStep == totalQuestions;
    final String? note = _getQuestionNote(q.kodeField);

    return PragiScaffold(
      child: Column(
        children: [
          PragiHeader(
            chipLabel: _getCategoryForStep(_currentStep),
            onBack: _previousStep,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kartu progres (persentase langkah selesai)
                  PragiRingCard(
                    progress: progressRatio,
                    centerLabel: 'Selesai',
                    centerValue: '${(progressRatio * 100).toInt()}%',
                    title: isLastStep
                        ? 'Langkah Terakhir'
                        : 'Langkah $_currentStep Dari $totalQuestions',
                    subtitle:
                        'Mohon isi sesuai dengan kondisi atau data yang sesuai adanya!',
                  ),
                  const SizedBox(height: 16),

                  // Bubble pertanyaan + maskot
                  PragiBubble(
                    title: q.pertanyaan,
                    hint: _getQuestionHint(q),
                  ),

                  if (note != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      note,
                      style: PragiUi.text(
                        size: 11.5,
                        color: PragiUi.muted,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const PragiSectionLabel('Jawaban Anda'),
                  const SizedBox(height: 14),

                  // Input dinamis
                  _buildDynamicInput(q),

                  const SizedBox(height: 14),

                  // Kartu "Mengapa data ini dibutuhkan?"
                  PragiInfoCard(
                    title: _getInfoTitle(q.kodeField),
                    body: _getMedicalExplanation(q.kodeField),
                  ),

                  const SizedBox(height: 16),

                  // Tombol lanjut / selesai
                  _buildActionButton(totalQuestions),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TEKS PENDUKUNG (hanya tampilan)
  // ───────────────────────────────────────────────────────────────────────────
  String? _getQuestionHint(PragiPertanyaan q) {
    switch (q.kodeField) {
      case 'HeartDisease':
        return '(Termasuk riwayat serangan jantung atau penyakit jantung koroner)';
      case 'BMI':
        return '(Sistem akan menghitung Indeks Massa Tubuh / BMI secara otomatis)';
      case 'Smoking':
        return '(Total konsumsi rokok mencapai minimal 100 batang sepanjang hidup)';
      case 'AlcoholDrinking':
        return '(Pria >14 takaran/minggu, wanita >7 takaran/minggu)';
      case 'Stroke':
        return '(Pernah mengalami stroke iskemik/hemoragik atau stroke ringan/TIA)';
      case 'DiffWalking':
        return '(Keterbatasan fisik, kelemahan tungkai, atau butuh bantuan saat berjalan)';
      case 'Sex':
        return '(Pilih jenis kelamin sesuai identitas KTP Bapak/Ibu.)';
      case 'AgeCategory':
        return '(Pilih kelompok rentang usia Bapak/Ibu saat ini.)';
      case 'Race':
        return '(Pilih salah satu kelompok ras atau etnis)';
      case 'Diabetic':
        return '(Pilih kondisi yang paling sesuai dengan riwayat diabetes)';
      case 'PhysicalActivity':
        return '(Aktivitas fisik teratur minimal 20-30 menit dalam sebulan terakhir)';
      case 'GenHealth':
        return '(Evaluasi subjektif terhadap kondisi kebugaran dan kesehatan Anda)';
      case 'Asthma':
        return '(Riwayat asma bronkial atau masalah penyempitan saluran napas kronis)';
      default:
        if (q.tipeInput == 'number' && (q.min != null || q.max != null)) {
          final unit = (q.satuan ?? '').trim();
          return '(Pilihan angka ${q.min ?? 0} hingga ${q.max ?? 100}${unit.isNotEmpty ? ' $unit' : ''})';
        }
        return null;
    }
  }

  String? _getQuestionNote(String kodeField) {
    if (kodeField == 'DiffWalking') {
      return '*Meliputi kesulitan menaiki tangga, kelemahan sendi, atau keterbatasan mobilitas harian.';
    }
    return null;
  }

  String _getInfoTitle(String kodeField) {
    switch (kodeField) {
      case 'HeartDisease':
        return 'Mengapa faktor ini penting?';
      case 'BMI':
        return 'Mengapa IMT penting?';
      case 'Smoking':
        return 'Mengapa riwayat merokok penting?';
      case 'AlcoholDrinking':
        return 'Mengapa konsumsi alkohol diperhatikan?';
      case 'Stroke':
        return 'Mengapa informasi stroke penting?';
      case 'PhysicalHealth':
        return 'Mengapa data kesehatan fisik dibutuhkan?';
      case 'MentalHealth':
        return 'Mengapa data kesehatan mental dibutuhkan?';
      case 'DiffWalking':
        return 'Mengapa mobilitas penting?';
      case 'Race':
        return 'Mengapa data ras/etnis dibutuhkan?';
      case 'Diabetic':
        return 'Mengapa riwayat diabetes penting?';
      case 'PhysicalActivity':
        return 'Mengapa aktivitas fisik penting?';
      case 'GenHealth':
        return 'Mengapa evaluasi kesehatan umum penting?';
      case 'SleepTime':
        return 'Mengapa durasi tidur penting?';
      case 'Asthma':
        return 'Mengapa data asma dibutuhkan?';
      default:
        return 'Mengapa data ini dibutuhkan?';
    }
  }

  /// Deskripsi (Ya, Tidak) untuk pertanyaan bertipe binary.
  List<String> _getBinaryDescriptions(String kodeField) {
    switch (kodeField) {
      case 'HeartDisease':
        return [
          'Pernah diberitahu tenaga medis menderita penyakit jantung koroner atau serangan jantung',
          'Tidak pernah mengalami atau diberitahu menderita penyakit jantung',
        ];
      case 'Smoking':
        return [
          'Pernah merokok minimal 100 batang (sekitar 5 bungkus) sepanjang hidup',
          'Kurang dari 100 batang atau tidak pernah merokok sama sekali',
        ];
      case 'AlcoholDrinking':
        return [
          'Mengonsumsi alkohol melebihi ambang batas yang disebutkan',
          'Di bawah ambang batas tersebut atau tidak mengonsumsi alkohol',
        ];
      case 'Stroke':
        return [
          'Pernah diberitahu dokter/tenaga medis pernah mengalami stroke',
          'Tidak pernah mengalami atau didiagnosis stroke',
        ];
      case 'DiffWalking':
        return [
          'Mengalami kesulitan serius atau butuh bantuan saat berjalan atau menaiki anak tangga',
          'Dapat berjalan dan menaiki tangga secara mandiri tanpa kesulitan serius',
        ];
      case 'PhysicalActivity':
        return [
          'Rutin berolahraga atau beraktivitas fisik (jalan kaki, bersepeda, senam, dll) dalam 30 hari terakhir',
          'Hanya aktivitas sedentari / tidak melakukan olahraga teratur dalam 30 hari terakhir',
        ];
      case 'Asthma':
        return [
          'Pernah diberitahu dokter atau tenaga medis bahwa menderita asma',
          'Tidak memiliki riwayat asma bronkial',
        ];
      default:
        return [
          'Ya, sesuai dengan kondisi Bapak/Ibu',
          'Tidak, tidak sesuai dengan kondisi Bapak/Ibu',
        ];
    }
  }

  String _getNumberHint(PragiPertanyaan q, num value) {
    switch (q.kodeField) {
      case 'PhysicalHealth':
        if (value <= 0) return 'Kesehatan fisik terasa prima dan tidak ada kendala sakit fisik.';
        if (value <= 7) return 'Kendala kesehatan fisik tergolong ringan.';
        if (value <= 14) return 'Kendala kesehatan fisik cukup sering dirasakan.';
        return 'Kesehatan fisik sering terganggu, pertimbangkan berkonsultasi dengan tenaga medis.';
      case 'MentalHealth':
        if (value <= 0) return 'Kondisi mental dan suasana hati terasa tenang, stabil, dan prima.';
        if (value <= 7) return 'Gangguan suasana hati tergolong ringan.';
        if (value <= 14) return 'Gangguan suasana hati cukup sering dirasakan.';
        return 'Kesehatan mental sering terganggu, pertimbangkan berkonsultasi dengan tenaga profesional.';
      case 'SleepTime':
        if (value < 6) return 'Durasi tidur tergolong kurang dari kebutuhan ideal.';
        if (value <= 9) return 'Durasi tidur berada dalam rentang yang ideal.';
        return 'Durasi tidur tergolong berlebihan.';
      default:
        return 'Geser slider atau gunakan tombol + / − untuk mengatur nilai.';
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DYNAMIC FORM INPUT
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDynamicInput(PragiPertanyaan q) {
    switch (q.tipeInput) {
      case 'binary':
        return _buildBinaryInput(q);
      case 'number':
        return _buildNumberInput(q);
      case 'select':
        return _buildSelectInput(q);
      default:
        return _buildBinaryInput(q);
    }
  }

  // 1. Tipe Input: BINARY (Ya / Tidak)
  Widget _buildBinaryInput(PragiPertanyaan q) {
    final currentVal = _jawaban[q.kodeField]?.toString();
    final bool isYes = currentVal == 'Yes';
    final bool isNo = currentVal == 'No';
    final desc = _getBinaryDescriptions(q.kodeField);

    return Column(
      children: [
        if (q.kodeField == 'AlcoholDrinking') ...[
          _buildAlcoholCriteriaCard(),
          const SizedBox(height: 14),
        ],
        PragiOptionCard(
          letter: 'A',
          title: 'Ya',
          description: desc[0],
          selected: isYes,
          onTap: () {
            setState(() {
              _jawaban[q.kodeField] = 'Yes';
            });
          },
        ),
        const SizedBox(height: 10),
        PragiOptionCard(
          letter: 'B',
          title: 'Tidak',
          description: desc[1],
          selected: isNo,
          onTap: () {
            setState(() {
              _jawaban[q.kodeField] = 'No';
            });
          },
        ),
      ],
    );
  }

  Widget _buildAlcoholCriteriaCard() {
    return PragiCard(
      padding: const EdgeInsets.all(14),
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: PragiUi.cardDecoration(radius: 8),
                child: const Icon(Icons.info_outline_rounded,
                    size: 18, color: PragiUi.green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kriteria Konsumsi Alkohol Berlebihan:',
                  style: PragiUi.text(size: 12.5, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pria: Lebih dari 14 gelas / takaran standar per minggu',
            style: PragiUi.text(size: 12, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            'Wanita: Lebih dari 7 gelas / takaran standar per minggu',
            style: PragiUi.text(size: 12, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            '*1 takaran standar setara ±330 ml bir (5%) atau ±150 ml anggur (12%).',
            style: PragiUi.text(
              size: 11.5,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // 2. Tipe Input: NUMBER (Slider + tombol +/−, atau kalkulator IMT untuk BMI)
  Widget _buildNumberInput(PragiPertanyaan q) {
    if (q.kodeField == 'BMI') {
      return _buildBmiInput(q);
    }

    final num minVal = q.min ?? 0;
    final num maxVal = q.max ?? 100;
    final num currentNum = num.tryParse(_numberController.text) ?? minVal;
    final String satuan = q.satuan ?? '';
    final String unitLabel =
        satuan.isEmpty ? '' : satuan[0].toUpperCase() + satuan.substring(1);
    final bool canSlide = maxVal > minVal;
    final double sliderValue =
        currentNum.toDouble().clamp(minVal.toDouble(), maxVal.toDouble());
    final int divisions = (maxVal - minVal).round();
    final String displayNumber = currentNum % 1 == 0
        ? currentNum.toInt().toString()
        : currentNum.toString();

    void applyValue(num next) {
      final formatted = next.toInt().toString();
      _numberController.text = formatted;
      _jawaban[q.kodeField] = num.parse(formatted);
      setState(() {});
    }

    return PragiCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      radius: 12,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                displayNumber,
                style: PragiUi.text(
                  size: 44,
                  weight: FontWeight.w700,
                  color: PragiUi.green,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unitLabel,
                style: PragiUi.text(size: 16, color: PragiUi.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Tombol kurang
              GestureDetector(
                onTap: () {
                  final double next = currentNum.toDouble() - 1.0;
                  if (q.min != null && next < q.min!) return;
                  applyValue(next);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE5E7EB),
                  ),
                  child: const Icon(Icons.remove, color: PragiUi.ink, size: 24),
                ),
              ),
              Expanded(
                child: canSlide
                    ? SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 5,
                          activeTrackColor: PragiUi.green,
                          inactiveTrackColor: const Color(0xFFE0E0E0),
                          thumbColor: PragiUi.green,
                          overlayColor: PragiUi.green.withValues(alpha: 0.12),
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10),
                        ),
                        child: Slider(
                          value: sliderValue,
                          min: minVal.toDouble(),
                          max: maxVal.toDouble(),
                          divisions: divisions > 0 ? divisions : null,
                          onChanged: (v) => applyValue(v.round()),
                        ),
                      )
                    : const SizedBox(height: 44),
              ),
              // Tombol tambah
              GestureDetector(
                onTap: () {
                  final double next = currentNum.toDouble() + 1.0;
                  if (q.max != null && next > q.max!) return;
                  applyValue(next);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFD7F5E4),
                  ),
                  child: const Icon(Icons.add, color: PragiUi.green, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getNumberHint(q, currentNum),
            textAlign: TextAlign.center,
            style: PragiUi.text(size: 12.5, color: PragiUi.muted, height: 1.45),
          ),
        ],
      ),
    );
  }

  // Input khusus BMI: Tinggi & Berat Badan → IMT otomatis
  Widget _buildBmiInput(PragiPertanyaan q) {
    final double bmiValue = double.tryParse(_numberController.text) ??
        (num.tryParse(_jawaban['BMI']?.toString() ?? '')?.toDouble() ?? 0.0);
    final _BmiCategory cat = _BmiCategory.from(bmiValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMeasureField(
          label: 'Tinggi Badan',
          unit: 'CM',
          controller: _tbController,
          hint: '168',
        ),
        const SizedBox(height: 14),
        _buildMeasureField(
          label: 'Berat Badan',
          unit: 'KG',
          controller: _bbController,
          hint: '65',
        ),
        const SizedBox(height: 14),
        PragiCard(
          padding: const EdgeInsets.all(12),
          radius: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: PragiUi.cardDecoration(radius: 12),
                child: const Icon(Icons.calculate_outlined,
                    size: 24, color: PragiUi.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Indeks Massa Tubuh (IMT / BMI)',
                      style: PragiUi.text(size: 12.5, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          bmiValue.toStringAsFixed(1),
                          style: PragiUi.text(
                            size: 24,
                            weight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'kg/m²',
                          style: PragiUi.text(size: 12.5, color: PragiUi.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: cat.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: cat.color.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          cat.label,
                          style: PragiUi.text(
                            size: 11,
                            weight: FontWeight.w600,
                            color: cat.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasureField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PragiUi.text(size: 13, weight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: PragiUi.text(size: 14),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: PragiUi.selectedBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  unit,
                  style: PragiUi.text(size: 13, weight: FontWeight.w700),
                ),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: PragiUi.green, width: 1.5),
            ),
          ),
          onChanged: (_) => _calculateAndSetBmi(),
        ),
      ],
    );
  }

  // 3. Tipe Input: SELECT (daftar pilihan A, B, C ... atau grid 2 kolom)
  Widget _buildSelectInput(PragiPertanyaan q) {
    final currentVal = _jawaban[q.kodeField]?.toString();
    final options = q.opsiJawaban;
    final bool useGrid = options.length > 6;

    void select(PragiPertanyaanOption opt) {
      setState(() {
        _jawaban[q.kodeField] = opt.nilai;
      });
    }

    if (useGrid) {
      return LayoutBuilder(
        builder: (context, constraints) {
          const double gap = 10;
          final double itemWidth = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: List.generate(options.length, (i) {
              final opt = options[i];
              return SizedBox(
                width: itemWidth,
                child: PragiOptionCard(
                  letter: String.fromCharCode(65 + i),
                  title: opt.label,
                  compact: true,
                  selected: currentVal == opt.nilai.toString(),
                  onTap: () => select(opt),
                ),
              );
            }),
          );
        },
      );
    }

    return Column(
      children: List.generate(options.length, (i) {
        final opt = options[i];
        IconData? icon;
        if (q.kodeField == 'Sex') {
          final v = opt.nilai.toString().toLowerCase();
          icon = v == 'male' ? Icons.male_rounded : Icons.female_rounded;
        }
        return Padding(
          padding: EdgeInsets.only(bottom: i == options.length - 1 ? 0 : 10),
          child: PragiOptionCard(
            letter: String.fromCharCode(65 + i),
            title: opt.label,
            leadingIcon: icon,
            selected: currentVal == opt.nilai.toString(),
            onTap: () => select(opt),
          ),
        );
      }),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ACTION BUTTON: LANJUTKAN / SELESAI DAN ANALISIS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildActionButton(int total) {
    final bool isLastStep = _currentStep == total;
    final bool canSubmit = isLastStep && _areAllQuestionsAnswered;

    return PragiPrimaryButton(
      label: isLastStep ? 'Selesai dan Analisis' : 'Lanjutkan',
      icon: isLastStep
          ? Icons.check_circle_outline_rounded
          : Icons.arrow_circle_right_outlined,
      color: isLastStep && !canSubmit ? PragiUi.greenDeep : PragiUi.green,
      onPressed: _nextStep,
    );
  }
}

/// Kategori IMT untuk label berwarna pada kartu IMT (tampilan saja).
class _BmiCategory {
  final String label;
  final Color color;
  final Color background;

  const _BmiCategory(this.label, this.color, this.background);

  static _BmiCategory from(double bmi) {
    if (bmi <= 0) {
      return const _BmiCategory(
          'Belum dihitung', Color(0xFF64748B), Color(0xFFF1F5F9));
    }
    if (bmi < 18.5) {
      return const _BmiCategory(
          'Berat Badan Kurang', Color(0xFF2563EB), Color(0xFFEFF6FF));
    }
    if (bmi < 23) {
      return const _BmiCategory(
          'Berat Badan Normal', Color(0xFF059669), Color(0xFFECFDF5));
    }
    if (bmi < 25) {
      return const _BmiCategory(
          'Kelebihan Berat Badan', Color(0xFFEA7A4B), Color(0xFFFFF1EA));
    }
    return const _BmiCategory(
        'Obesitas', Color(0xFFDC2626), Color(0xFFFEF2F2));
  }
}
