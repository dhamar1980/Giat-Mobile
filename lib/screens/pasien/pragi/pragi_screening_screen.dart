import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/pragi_model.dart';
import '../../../services/pasien_api_service.dart';
import 'pragi_topography_background.dart';
import 'pragi_processing_screen.dart';

class PragiScreeningScreen extends StatefulWidget {
  const PragiScreeningScreen({super.key});

  @override
  State<PragiScreeningScreen> createState() => _PragiScreeningScreenState();
}

class _PragiScreeningScreenState extends State<PragiScreeningScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _accentGreen = Color(0xFF10B981);
  static const _selectedCardBg = Color(0xFFE0F2FE);

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
  bool _showBmiCalculator = false;

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FF),
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: PragiTopographyPainter())),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_darkGreen),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Memuat 16 Kuesioner AI PRAGI...',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Menghubungkan ke API Backend GIAT',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      body: Stack(
        children: [
          // Background Topography
          Positioned.fill(
            child: CustomPaint(
              painter: PragiTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back Pill
                          GestureDetector(
                            onTap: _previousStep,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_back, size: 16, color: Color(0xFF1E293B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Kembali',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Step Counter Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '$_answeredCount / $totalQuestions Terisi',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0369A1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Center Category Pill
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                          decoration: BoxDecoration(
                            color: _darkGreen,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _darkGreen.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            _getCategoryForStep(_currentStep),
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Step Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress Card
                        _buildProgressCard(progressRatio, totalQuestions),

                        const SizedBox(height: 16),

                        // Question Chat Bubble with PRAGI Avatar
                        _buildQuestionBubble(q),

                        const SizedBox(height: 18),

                        // Section Title: Jawaban Anda
                        Center(
                          child: Text(
                            'Pilihan Jawaban Anda',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Dynamic Input Component
                        _buildDynamicInput(q),

                        const SizedBox(height: 20),

                        // Medical Info Card ("Mengapa data ini dibutuhkan?")
                        _buildStepInfoCard(q),

                        const SizedBox(height: 24),

                        // Next / Submit Button
                        _buildActionButton(totalQuestions),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PROGRESS CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildProgressCard(double progress, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress Arc
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  valueColor: const AlwaysStoppedAnimation<Color>(_accentGreen),
                  backgroundColor: const Color(0xFFE2E8F0),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _darkGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pertanyaan $_currentStep dari $total',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _currentStep == total
                      ? 'Langkah Terakhir: Siap untuk analisis AI'
                      : 'Isi dengan jujur sesuai kondisi aktual tubuh Anda',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // QUESTION SPEECH BUBBLE WITH MASCOT
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildQuestionBubble(PragiPertanyaan q) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PRAGI Mascot Circle
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _darkGreen.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/pragi.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFDCFCE7),
                child: const Icon(Icons.smart_toy_rounded, size: 26, color: _darkGreen),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Speech Bubble
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PRAGI AI ASSISTANT',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _darkGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        q.kodeField,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  q.pertanyaan,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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

  // 1. Tipe Input: BINARY (Switch Card / Radio Buttons: Yes & No)
  Widget _buildBinaryInput(PragiPertanyaan q) {
    final currentVal = _jawaban[q.kodeField]?.toString();
    final bool isYes = currentVal == 'Yes';
    final bool isNo = currentVal == 'No';

    return Row(
      children: [
        // Pilihan: YA (Yes)
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _jawaban[q.kodeField] = 'Yes';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: isYes ? _selectedCardBg : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isYes ? _darkGreen : const Color(0xFFE2E8F0),
                  width: isYes ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isYes
                        ? _darkGreen.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isYes ? _darkGreen : const Color(0xFFF1F5F9),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: isYes ? Colors.white : const Color(0xFF94A3B8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ya',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isYes ? _darkGreen : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Benar / Sesuai',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Pilihan: TIDAK (No)
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _jawaban[q.kodeField] = 'No';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: isNo ? _selectedCardBg : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isNo ? _darkGreen : const Color(0xFFE2E8F0),
                  width: isNo ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isNo
                        ? _darkGreen.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isNo ? _darkGreen : const Color(0xFFF1F5F9),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: isNo ? Colors.white : const Color(0xFF94A3B8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isNo ? _darkGreen : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tidak Pernah',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Tipe Input: NUMBER (Numeric Stepper, Direct TextField, Range Check, Satuan, & BMI Helper)
  Widget _buildNumberInput(PragiPertanyaan q) {
    final num currentNum = num.tryParse(_numberController.text) ?? (q.min ?? 0);
    final String satuan = q.satuan ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Display Row
          Row(
            children: [
              // Decrement Button
              IconButton(
                onPressed: () {
                  final double step = (q.kodeField == 'BMI') ? 0.5 : 1.0;
                  final double next = currentNum.toDouble() - step;
                  if (q.min != null && next < q.min!) return;
                  final formatted = (q.kodeField == 'BMI')
                      ? next.toStringAsFixed(1)
                      : next.toInt().toString();
                  _numberController.text = formatted;
                  _jawaban[q.kodeField] = num.parse(formatted);
                  setState(() {});
                },
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: _darkGreen,
                iconSize: 32,
              ),

              // Digital Value Input
              Expanded(
                child: TextField(
                  controller: _numberController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _darkGreen,
                  ),
                  decoration: InputDecoration(
                    suffixText: satuan.isNotEmpty ? ' $satuan' : null,
                    suffixStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final parsed = num.tryParse(val);
                    if (parsed != null) {
                      _jawaban[q.kodeField] = parsed;
                      setState(() {});
                    }
                  },
                ),
              ),

              // Increment Button
              IconButton(
                onPressed: () {
                  final double step = (q.kodeField == 'BMI') ? 0.5 : 1.0;
                  final double next = currentNum.toDouble() + step;
                  if (q.max != null && next > q.max!) return;
                  final formatted = (q.kodeField == 'BMI')
                      ? next.toStringAsFixed(1)
                      : next.toInt().toString();
                  _numberController.text = formatted;
                  _jawaban[q.kodeField] = num.parse(formatted);
                  setState(() {});
                },
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: _darkGreen,
                iconSize: 32,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Range Info Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Rentang valid: ${q.min ?? 0} s/d ${q.max ?? 100} $satuan',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ),

          // Helper Kalkulator BMI Khusus Field BMI
          if (q.kodeField == 'BMI') ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),

            GestureDetector(
              onTap: () {
                setState(() {
                  _showBmiCalculator = !_showBmiCalculator;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_outlined, color: _darkGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kalkulator IMT dari Tinggi & Berat Badan',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _darkGreen,
                        ),
                      ),
                    ),
                    Icon(
                      _showBmiCalculator ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: _darkGreen,
                    ),
                  ],
                ),
              ),
            ),

            if (_showBmiCalculator) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tinggi Badan (cm)', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _tbController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '168',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => _calculateAndSetBmi(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Berat Badan (kg)', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _bbController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '65',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => _calculateAndSetBmi(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],

          // Preset Chips untuk PhysicalHealth / MentalHealth / SleepTime
          if (q.kodeField == 'SleepTime') ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [5, 6, 7, 8, 9].map((hours) {
                final isSel = currentNum == hours;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$hours Jam'),
                    selected: isSel,
                    selectedColor: _darkGreen,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSel ? Colors.white : const Color(0xFF334155),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        _numberController.text = hours.toString();
                        _jawaban[q.kodeField] = hours;
                        setState(() {});
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // 3. Tipe Input: SELECT (Card Options & Bottom Sheet Selector)
  Widget _buildSelectInput(PragiPertanyaan q) {
    final currentVal = _jawaban[q.kodeField]?.toString();
    final options = q.opsiJawaban;

    // Jika opsi lebih dari 4 (seperti AgeCategory atau Race), sertakan tombol pemilih Bottom Sheet
    final bool hasManyOptions = options.length > 4;

    return Column(
      children: [
        if (hasManyOptions) ...[
          // Bottom Sheet trigger button
          GestureDetector(
            onTap: () => _showSelectBottomSheet(q),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _darkGreen, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _darkGreen.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.list_alt_rounded, color: _darkGreen, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilihan Terpilih:',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                        ),
                        Text(
                          _getOptionLabel(q, currentVal),
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Buka Daftar',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0369A1),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF0369A1), size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // List kartu pilihan langsung
        ...options.map((opt) {
          final isSelected = currentVal == opt.nilai.toString();

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _jawaban[q.kodeField] = opt.nilai;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? _selectedCardBg : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _darkGreen : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.8 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? _darkGreen.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? _darkGreen : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                        color: isSelected ? _darkGreen : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.circle, size: 10, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        opt.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? _darkGreen : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _getOptionLabel(PragiPertanyaan q, String? val) {
    if (val == null || val.isEmpty) return 'Belum dipilih (Ketuk untuk memilih)';
    for (var opt in q.opsiJawaban) {
      if (opt.nilai.toString() == val) return opt.label;
    }
    return val;
  }

  void _showSelectBottomSheet(PragiPertanyaan q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Opsi untuk ${q.kodeField}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                q.pertanyaan,
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: q.opsiJawaban.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final opt = q.opsiJawaban[index];
                    final isSel = _jawaban[q.kodeField]?.toString() == opt.nilai.toString();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      title: Text(
                        opt.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? _darkGreen : const Color(0xFF1E293B),
                        ),
                      ),
                      trailing: isSel
                          ? const Icon(Icons.check_circle_rounded, color: _darkGreen)
                          : null,
                      onTap: () {
                        setState(() {
                          _jawaban[q.kodeField] = opt.nilai;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP INFO CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStepInfoCard(PragiPertanyaan q) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: _darkGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mengapa data ini dibutuhkan?',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getMedicalExplanation(q.kodeField),
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ACTION BUTTON: LANJUTKAN / ANALISIS SKRINING SEKARANG
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildActionButton(int total) {
    final bool isLastStep = _currentStep == total;
    final bool canSubmit = isLastStep && _areAllQuestionsAnswered;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLastStep
              ? (canSubmit ? _darkGreen : const Color(0xFF047857))
              : _darkGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastStep ? 'Analisis Skrining Sekarang' : 'Lanjutkan',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isLastStep ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
