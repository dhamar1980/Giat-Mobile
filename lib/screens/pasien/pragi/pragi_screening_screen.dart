import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pragi_state_service.dart';
import 'pragi_topography_background.dart';
import 'pragi_processing_screen.dart';

class PragiScreeningScreen extends StatefulWidget {
  const PragiScreeningScreen({super.key});

  @override
  State<PragiScreeningScreen> createState() => _PragiScreeningScreenState();
}

class _PragiScreeningScreenState extends State<PragiScreeningScreen> {
  int _currentStep = 1;
  final int _totalSteps = 16;

  static const _darkGreen = Color(0xFF065A37);
  static const _accentGreen = Color(0xFF10B981);
  static const _selectedCardBg = Color(0xFFE0F2FE);

  // ───────────────────────────────────────────────────────────────────────────
  // FORM STATE ANSWERS (16 QUESTIONS)
  // ───────────────────────────────────────────────────────────────────────────
  // 1. Jenis Kelamin (A. Laki-laki, B. Perempuan)
  String? _selectedGender;

  // 2. Kelompok Usia (A to M)
  String _selectedAgeRange = '45–49 tahun';

  // 3. Tinggi & Berat Badan
  final TextEditingController _heightController = TextEditingController(text: '168');
  final TextEditingController _weightController = TextEditingController(text: '65');
  double _calculatedBmi = 23.0;

  // 4. Ras / Etnis (A to E)
  String? _selectedRace;

  // 5. Evaluasi Kesehatan Umum (A to E)
  String? _generalHealth;

  // 6. Kesehatan Fisik (0 hingga 30 hari)
  int _physicalHealthDays = 0;

  // 7. Kesehatan Mental (0 hingga 30 hari)
  int _mentalHealthDays = 0;

  // 8. Durasi Tidur Harian (1 hingga 24 jam)
  int _sleepHours = 7;

  // 9. Riwayat Penyakit Jantung (A. Ya, B. Tidak)
  bool? _hasHeartDisease;

  // 10. Riwayat Stroke (A. Ya, B. Tidak)
  bool? _hasStroke;

  // 11. Riwayat Diabetes (A to D)
  String? _diabetesStatus;

  // 12. Riwayat Asma (A. Ya, B. Tidak)
  bool? _hasAsthma;

  // 13. Kebiasaan Merokok (A. Ya, B. Tidak)
  bool? _hasSmokingHistory;

  // 14. Konsumsi Alkohol (A. Ya, B. Tidak)
  bool? _hasExcessiveAlcohol;

  // 15. Aktivitas Fisik (A. Ya, B. Tidak)
  bool? _hasPhysicalActivity;

  // 16. Kesulitan Berjalan (A. Ya, B. Tidak)
  bool? _hasMobilityDifficulty;

  @override
  void initState() {
    super.initState();
    _recalculateBmi();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _recalculateBmi() {
    final double? h = double.tryParse(_heightController.text);
    final double? w = double.tryParse(_weightController.text);
    if (h != null && w != null && h > 0 && w > 0) {
      final double hMeter = h / 100;
      setState(() {
        _calculatedBmi = w / (hMeter * hMeter);
      });
    }
  }

  String _getBmiCategory(double bmi) {
    if (bmi < 18.5) return 'Berat Badan Kurang';
    if (bmi < 23.0) return 'Berat Badan Normal / Ideal';
    if (bmi < 25.0) return 'Kelebihan Berat Badan';
    return 'Obesitas';
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFFF59E0B);
    if (bmi < 23.0) return const Color(0xFF10B981);
    if (bmi < 25.0) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  String _getCategoryForStep(int step) {
    if (step <= 4) return 'Demografi Pasien';
    if (step <= 8) return 'Status Kesehatan & Pola Harian';
    if (step <= 12) return 'Riwayat Medis & Klinis';
    return 'Gaya Hidup & Mobilitas';
  }

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 1:
        return _selectedGender != null && _selectedGender!.isNotEmpty;
      case 2:
        return _selectedAgeRange.isNotEmpty;
      case 3:
        final h = double.tryParse(_heightController.text);
        final w = double.tryParse(_weightController.text);
        return h != null && w != null && h > 0 && w > 0;
      case 4:
        return _selectedRace != null && _selectedRace!.isNotEmpty;
      case 5:
        return _generalHealth != null && _generalHealth!.isNotEmpty;
      case 6:
        return _physicalHealthDays >= 0 && _physicalHealthDays <= 30;
      case 7:
        return _mentalHealthDays >= 0 && _mentalHealthDays <= 30;
      case 8:
        return _sleepHours >= 1 && _sleepHours <= 24;
      case 9:
        return _hasHeartDisease != null;
      case 10:
        return _hasStroke != null;
      case 11:
        return _diabetesStatus != null && _diabetesStatus!.isNotEmpty;
      case 12:
        return _hasAsthma != null;
      case 13:
        return _hasSmokingHistory != null;
      case 14:
        return _hasExcessiveAlcohol != null;
      case 15:
        return _hasPhysicalActivity != null;
      case 16:
        return _hasMobilityDifficulty != null;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_isCurrentStepValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih atau isi jawaban terlebih dahulu'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Risk Assessment Calculation Logic
      int riskPoints = 0;
      if (_hasHeartDisease == true) riskPoints += 2;
      if (_hasStroke == true) riskPoints += 2;
      if (_diabetesStatus == 'Ya' || _diabetesStatus == 'Ya, tetapi hanya saat hamil (diabetes gestasional)') {
        riskPoints += 2;
      }
      if (_diabetesStatus == 'Tidak, tetapi pernah diberitahu prediabetes / batas gula darah tinggi') {
        riskPoints += 1;
      }
      if (_hasAsthma == true) riskPoints += 1;
      if (_hasSmokingHistory == true) riskPoints += 1;
      if (_hasExcessiveAlcohol == true) riskPoints += 1;
      if (_hasPhysicalActivity == false) riskPoints += 1;
      if (_hasMobilityDifficulty == true) riskPoints += 1;
      if (_calculatedBmi >= 30) riskPoints += 1;
      if (_physicalHealthDays > 14) riskPoints += 1;
      if (_mentalHealthDays > 14) riskPoints += 1;
      if (_sleepHours < 6 || _sleepHours > 9) riskPoints += 1;
      if (_generalHealth == 'Buruk (Poor)' || _generalHealth == 'Cukup / Biasa Saja (Fair)') {
        riskPoints += 1;
      }

      final String riskLevel = (riskPoints >= 5)
          ? 'Tinggi'
          : (riskPoints >= 2 ? 'Sedang' : 'Rendah');

      final result = PragiScreeningResult(
        id: 'scr-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        gender: _selectedGender ?? 'Laki-laki',
        ageRange: _selectedAgeRange,
        heightCm: double.tryParse(_heightController.text) ?? 168,
        weightKg: double.tryParse(_weightController.text) ?? 65,
        bmi: _calculatedBmi,
        race: _selectedRace ?? 'Asia (Asian)',
        generalHealth: _generalHealth ?? 'Baik (Good)',
        physicalHealthDays: _physicalHealthDays,
        mentalHealthDays: _mentalHealthDays,
        sleepHours: _sleepHours,
        hasHeartDisease: _hasHeartDisease ?? false,
        hasStroke: _hasStroke ?? false,
        diabetesStatus: _diabetesStatus ?? 'Tidak',
        hasAsthma: _hasAsthma ?? false,
        hasPhysicalActivity: _hasPhysicalActivity ?? true,
        hasSmokingHistory: _hasSmokingHistory ?? false,
        hasExcessiveAlcohol: _hasExcessiveAlcohol ?? false,
        hasMobilityDifficulty: _hasMobilityDifficulty ?? false,
        riskLevel: riskLevel,
        riskScore: 'Tingkat $riskLevel',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PragiProcessingScreen(result: result),
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 12),
                      // Center Category Pill
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                              fontSize: 13,
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
                        // Step Progress Card
                        _buildProgressCard(),

                        const SizedBox(height: 18),

                        // Question Chat Bubble with PRAGI Avatar
                        _buildQuestionBubble(),

                        const SizedBox(height: 18),

                        // Section Title: Jawaban Anda
                        Center(
                          child: Text(
                            'Jawaban Anda',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Step-specific Input Widget
                        _buildStepContent(),

                        const SizedBox(height: 20),

                        // Info Card ("Mengapa data ini dibutuhkan?")
                        _buildStepInfoCard(),

                        const SizedBox(height: 24),

                        // Lanjutkan Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _darkGreen,
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
                                  _currentStep == _totalSteps ? 'Selesai & Analisis' : 'Lanjutkan',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentStep == _totalSteps
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.arrow_circle_right_outlined,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

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
  Widget _buildProgressCard() {
    final double progress = _currentStep / _totalSteps;

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
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4.5,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(_darkGreen),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Status',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '$_currentStep / $_totalSteps',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
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
                  _currentStep == _totalSteps
                      ? 'Langkah Terakhir'
                      : 'Langkah $_currentStep Dari $_totalSteps',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mohon isi sesuai dengan kondisi atau data yang sebenarnya!',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    height: 1.35,
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
  // QUESTION BUBBLE WITH MASCOT
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildQuestionBubble() {
    final questionData = _getQuestionDataForStep(_currentStep);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Mascot Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _accentGreen, width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/pragi.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.smart_toy_rounded, size: 20, color: _darkGreen),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Green Chat Bubble
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: _darkGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      questionData['question'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    if (questionData['subQuestion'] != null &&
                        questionData['subQuestion']!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        questionData['subQuestion']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFD1FAE5),
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'PRAGI',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF86EFAC),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.done_all, size: 14, color: Color(0xFF86EFAC)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (questionData['footnote'] != null && questionData['footnote']!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              questionData['footnote']!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF475569),
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP CONTENT DISPATCHER (16 STEPS)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Gender();
      case 2:
        return _buildStep2AgeRange();
      case 3:
        return _buildStep3HeightWeight();
      case 4:
        return _buildStep4Race();
      case 5:
        return _buildStep5GeneralHealth();
      case 6:
        return _buildStep6PhysicalHealth();
      case 7:
        return _buildStep7MentalHealth();
      case 8:
        return _buildStep8SleepDuration();
      case 9:
        return _buildStep9HeartDisease();
      case 10:
        return _buildStep10Stroke();
      case 11:
        return _buildStep11Diabetes();
      case 12:
        return _buildStep12Asthma();
      case 13:
        return _buildStep13Smoking();
      case 14:
        return _buildStep14Alcohol();
      case 15:
        return _buildStep15PhysicalActivity();
      case 16:
        return _buildStep16Mobility();
      default:
        return const SizedBox.shrink();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP WIDGETS
  // ───────────────────────────────────────────────────────────────────────────

  // Step 1: Jenis Kelamin
  Widget _buildStep1Gender() {
    return Column(
      children: [
        _buildOptionCard(
          optionLetter: 'A',
          title: 'Laki-laki',
          subtitle: 'Pria',
          icon: Icons.male_rounded,
          isSelected: _selectedGender == 'Laki-laki',
          onTap: () => setState(() => _selectedGender = 'Laki-laki'),
        ),
        _buildOptionCard(
          optionLetter: 'B',
          title: 'Perempuan',
          subtitle: 'Wanita',
          icon: Icons.female_rounded,
          isSelected: _selectedGender == 'Perempuan',
          onTap: () => setState(() => _selectedGender = 'Perempuan'),
        ),
      ],
    );
  }

  // Step 2: Kelompok Usia (13 options A-M)
  Widget _buildStep2AgeRange() {
    final ageOptions = [
      {'letter': 'A', 'label': '18–24 tahun'},
      {'letter': 'B', 'label': '25–29 tahun'},
      {'letter': 'C', 'label': '30–34 tahun'},
      {'letter': 'D', 'label': '35–39 tahun'},
      {'letter': 'E', 'label': '40–44 tahun'},
      {'letter': 'F', 'label': '45–49 tahun'},
      {'letter': 'G', 'label': '50–54 tahun'},
      {'letter': 'H', 'label': '55–59 tahun'},
      {'letter': 'I', 'label': '60–64 tahun'},
      {'letter': 'J', 'label': '65–69 tahun'},
      {'letter': 'K', 'label': '70–74 tahun'},
      {'letter': 'L', 'label': '75–79 tahun'},
      {'letter': 'M', 'label': '80 tahun ke atas'},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ageOptions.map((opt) {
        final letter = opt['letter']!;
        final label = opt['label']!;
        final isSelected = _selectedAgeRange == label;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAgeRange = label;
            });
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 50) / 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _selectedCardBg : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFFE2E8F0),
                width: isSelected ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? _darkGreen : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected ? _darkGreen : const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Step 3: Tinggi dan Berat Badan (Auto BMI)
  Widget _buildStep3HeightWeight() {
    final bmiCategory = _getBmiCategory(_calculatedBmi);
    final bmiColor = _getBmiColor(_calculatedBmi);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tinggi Badan',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _selectedCardBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _recalculateBmi(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                'CM',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'Berat Badan',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _selectedCardBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _recalculateBmi(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Text(
                'KG',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Auto BMI Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calculate_outlined, color: _darkGreen, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Indeks Massa Tubuh (IMT / BMI)',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _calculatedBmi.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'kg/m²',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: bmiColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: bmiColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            bmiCategory,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: bmiColor,
                            ),
                          ),
                        ),
                      ],
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

  // Step 4: Ras / Etnis
  Widget _buildStep4Race() {
    final races = [
      {'letter': 'A', 'title': 'Asia (Asian)'},
      {'letter': 'B', 'title': 'Kulit Hitam / Afrika (Black)'},
      {'letter': 'C', 'title': 'Hispanik / Latin (Hispanic)'},
      {'letter': 'D', 'title': 'Kulit Putih (White)'},
      {'letter': 'E', 'title': 'Lainnya (Other)'},
    ];

    return Column(
      children: races.map((r) {
        return _buildOptionCard(
          optionLetter: r['letter']!,
          title: r['title']!,
          isSelected: _selectedRace == r['title'],
          onTap: () => setState(() => _selectedRace = r['title']),
        );
      }).toList(),
    );
  }

  // Step 5: Evaluasi Kesehatan Umum
  Widget _buildStep5GeneralHealth() {
    final healthLevels = [
      {'letter': 'A', 'title': 'Sangat Baik Sekali (Excellent)'},
      {'letter': 'B', 'title': 'Sangat Baik (Very Good)'},
      {'letter': 'C', 'title': 'Baik (Good)'},
      {'letter': 'D', 'title': 'Cukup / Biasa Saja (Fair)'},
      {'letter': 'E', 'title': 'Buruk (Poor)'},
    ];

    return Column(
      children: healthLevels.map((h) {
        return _buildOptionCard(
          optionLetter: h['letter']!,
          title: h['title']!,
          isSelected: _generalHealth == h['title'],
          onTap: () => setState(() => _generalHealth = h['title']),
        );
      }).toList(),
    );
  }

  // Step 6: Kesehatan Fisik (0 hingga 30 hari)
  Widget _buildStep6PhysicalHealth() {
    return _buildNumericPickerCard(
      currentValue: _physicalHealthDays,
      unit: 'Hari',
      min: 0,
      max: 30,
      description: _physicalHealthDays == 0
          ? 'Kesehatan fisik terasa prima dan tidak ada kendala sakit fisik.'
          : '$_physicalHealthDays hari dalam 30 hari terakhir merasa kurang sehat fisik.',
      quickPresets: [0, 3, 7, 14, 30],
      onChanged: (val) => setState(() => _physicalHealthDays = val),
    );
  }

  // Step 7: Kesehatan Mental (0 hingga 30 hari)
  Widget _buildStep7MentalHealth() {
    return _buildNumericPickerCard(
      currentValue: _mentalHealthDays,
      unit: 'Hari',
      min: 0,
      max: 30,
      description: _mentalHealthDays == 0
          ? 'Kondisi mental dan suasana hati terasa tenang, stabil, dan prima.'
          : '$_mentalHealthDays hari dalam 30 hari terakhir mengalami stres atau beban emosional.',
      quickPresets: [0, 3, 7, 14, 30],
      onChanged: (val) => setState(() => _mentalHealthDays = val),
    );
  }

  // Step 8: Durasi Tidur Harian (1 hingga 24 jam)
  Widget _buildStep8SleepDuration() {
    String sleepQuality;
    if (_sleepHours < 6) {
      sleepQuality = 'Kurang dari rekomendasi standar kesehatan (potensi kelelahan).';
    } else if (_sleepHours <= 8) {
      sleepQuality = 'Durasi tidur optimal untuk regenerasi sel tubuh dan fungsi ginjal.';
    } else {
      sleepQuality = 'Durasi tidur lebih panjang dari rata-rata kebutuhan harian.';
    }

    return _buildNumericPickerCard(
      currentValue: _sleepHours,
      unit: 'Jam',
      min: 1,
      max: 24,
      description: sleepQuality,
      quickPresets: [5, 6, 7, 8, 9],
      onChanged: (val) => setState(() => _sleepHours = val),
    );
  }

  // Step 9: Riwayat Penyakit Jantung
  Widget _buildStep9HeartDisease() {
    return Column(
      children: [
        _buildOptionCard(
          optionLetter: 'A',
          title: 'Ya',
          subtitle: 'Pernah diberitahu tenaga medis menderita penyakit jantung koroner atau serangan jantung',
          isSelected: _hasHeartDisease == true,
          onTap: () => setState(() => _hasHeartDisease = true),
        ),
        _buildOptionCard(
          optionLetter: 'B',
          title: 'Tidak',
          subtitle: 'Tidak pernah mengalami atau diberitahu menderita penyakit jantung',
          isSelected: _hasHeartDisease == false,
          onTap: () => setState(() => _hasHeartDisease = false),
        ),
      ],
    );
  }

  // Step 10: Riwayat Stroke
  Widget _buildStep10Stroke() {
    return Column(
      children: [
        _buildOptionCard(
          optionLetter: 'A',
          title: 'Ya',
          subtitle: 'Pernah diberitahu dokter/tenaga medis pernah mengalami stroke',
          isSelected: _hasStroke == true,
          onTap: () => setState(() => _hasStroke = true),
        ),
        _buildOptionCard(
          optionLetter: 'B',
          title: 'Tidak',
          subtitle: 'Tidak pernah mengalami atau didiagnosis stroke',
          isSelected: _hasStroke == false,
          onTap: () => setState(() => _hasStroke = false),
        ),
      ],
    );
  }

  // Step 11: Riwayat Diabetes (4 Options)
  Widget _buildStep11Diabetes() {
    return Column(
      children: [
        _buildOptionCard(
          optionLetter: 'A',
          title: 'Ya',
          subtitle: 'Pernah didiagnosis dokter memiliki diabetes (kencing manis)',
          isSelected: _diabetesStatus == 'Ya',
          onTap: () => setState(() => _diabetesStatus = 'Ya'),
        ),
        _buildOptionCard(
          optionLetter: 'B',
          title: 'Ya, tetapi hanya saat hamil (diabetes gestasional)',
          subtitle: 'Kenaikan gula darah hanya terjadi saat masa kehamilan',
          isSelected: _diabetesStatus == 'Ya, tetapi hanya saat hamil (diabetes gestasional)',
          onTap: () => setState(() => _diabetesStatus = 'Ya, tetapi hanya saat hamil (diabetes gestasional)'),
        ),
        _buildOptionCard(
          optionLetter: 'C',
          title: 'Tidak, tetapi pernah diberitahu prediabetes / batas gula darah tinggi',
          subtitle: 'Kadar gula darah di atas normal / batas toleransi glukosa',
          isSelected: _diabetesStatus == 'Tidak, tetapi pernah diberitahu prediabetes / batas gula darah tinggi',
          onTap: () => setState(() => _diabetesStatus = 'Tidak, tetapi pernah diberitahu prediabetes / batas gula darah tinggi'),
        ),
        _buildOptionCard(
          optionLetter: 'D',
          title: 'Tidak',
          subtitle: 'Kadar gula darah normal dan tidak pernah didiagnosis diabetes',
          isSelected: _diabetesStatus == 'Tidak',
          onTap: () => setState(() => _diabetesStatus = 'Tidak'),
        ),
      ],
    );
  }

  // Step 12: Riwayat Asma
  Widget _buildStep12Asthma() {
    return Column(
      children: [
        _buildOptionCard(
          optionLetter: 'A',
          title: 'Ya',
          subtitle: 'Pernah diberitahu dokter atau tenaga medis bahwa menderita asma',
          isSelected: _hasAsthma == true,
          onTap: () => setState(() => _hasAsthma = true),
        ),
        _buildOptionCard(
          optionLetter: 'B',
          title: 'Tidak',
          subtitle: 'Tidak memiliki riwayat asma bronkial',
          isSelected: _hasAsthma == false,
          onTap: () => setState(() => _hasAsthma = false),
        ),
      ],
    );
  }

  // Step 13: Kebiasaan Merokok
  Widget _buildStep13Smoking() {
    return Column(
      children: [
        _buildOptionCard(
          optionLetter: 'A',
          title: 'Ya',
          subtitle: 'Pernah merokok minimal 100 batang (sekitar 5 bungkus) sepanjang hidup',
          isSelected: _hasSmokingHistory == true,
          onTap: () => setState(() => _hasSmokingHistory = true),
        ),
        _buildOptionCard(
          optionLetter: 'B',
          title: 'Tidak',
          subtitle: 'Kurang dari 100 batang atau tidak pernah merokok sama sekali',
          isSelected: _hasSmokingHistory == false,
          onTap: () => setState(() => _hasSmokingHistory = false),
        ),
      ],
    );
  }

  // Step 14: Konsumsi Alkohol
  Widget _buildStep14Alcohol() {
    return Column(
      children: [
        // Standard intake guideline card
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline_rounded, color: _darkGreen, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kriteria Konsumsi Alkohol Berlebihan:',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Pria: Lebih dari 14 gelas / takaran standar per minggu\n• Wanita: Lebih dari 7 gelas / takaran standar per minggu',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '*1 takaran standar setara ±330 ml bir (5%) atau ±150 ml anggur (12%).',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        _buildOptionCard(
          optionLetter: 'A',
          title: 'Ya',
          subtitle: 'Mengonsumsi alkohol melebihi ambang batas yang disebutkan',
          isSelected: _hasExcessiveAlcohol == true,
          onTap: () => setState(() => _hasExcessiveAlcohol = true),
        ),
        _buildOptionCard(
          optionLetter: 'B',
          title: 'Tidak',
          subtitle: 'Di bawah ambang batas tersebut atau tidak mengonsumsi alkohol',
          isSelected: _hasExcessiveAlcohol == false,
          onTap: () => setState(() => _hasExcessiveAlcohol = false),
        ),
      ],
    );
  }

  // Step 15: Aktivitas Fisik
  Widget _buildStep15PhysicalActivity() {
    return Column(
      children: [
        _buildOptionCard(
          optionLetter: 'A',
          title: 'Ya',
          subtitle: 'Rutin berolahraga atau beraktivitas fisik (jalan kaki, bersepeda, senam, dll) dalam 30 hari terakhir',
          isSelected: _hasPhysicalActivity == true,
          onTap: () => setState(() => _hasPhysicalActivity = true),
        ),
        _buildOptionCard(
          optionLetter: 'B',
          title: 'Tidak',
          subtitle: 'Hanya aktivitas sedentari / tidak melakukan olahraga teratur dalam 30 hari terakhir',
          isSelected: _hasPhysicalActivity == false,
          onTap: () => setState(() => _hasPhysicalActivity = false),
        ),
      ],
    );
  }

  // Step 16: Kesulitan Berjalan
  Widget _buildStep16Mobility() {
    return Column(
      children: [
        _buildOptionCard(
          optionLetter: 'A',
          title: 'Ya',
          subtitle: 'Mengalami kesulitan serius atau butuh bantuan saat berjalan atau menaiki anak tangga',
          isSelected: _hasMobilityDifficulty == true,
          onTap: () => setState(() => _hasMobilityDifficulty = true),
        ),
        _buildOptionCard(
          optionLetter: 'B',
          title: 'Tidak',
          subtitle: 'Dapat berjalan dan menaiki tangga secara mandiri tanpa kesulitan serius',
          isSelected: _hasMobilityDifficulty == false,
          onTap: () => setState(() => _hasMobilityDifficulty = false),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // REUSABLE OPTION CARD (A, B, C, D, E)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOptionCard({
    required String optionLetter,
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? _selectedCardBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF60A5FA) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? _darkGreen : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                optionLetter,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (icon != null) ...[
              Icon(icon, size: 20, color: isSelected ? _darkGreen : const Color(0xFF64748B)),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: isSelected ? _darkGreen : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NUMERIC PICKER COMPONENT (STEPS 6, 7, 8)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildNumericPickerCard({
    required int currentValue,
    required String unit,
    required int min,
    required int max,
    required String description,
    required List<int> quickPresets,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        children: [
          // Large Visual Readout
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$currentValue',
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: _darkGreen,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Stepper Buttons (- and +)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: currentValue > min
                    ? () => onChanged(currentValue - 1)
                    : null,
                icon: const Icon(Icons.remove, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF1E293B),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 20),
              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _darkGreen,
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    thumbColor: _darkGreen,
                    overlayColor: _darkGreen.withValues(alpha: 0.15),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: currentValue.toDouble().clamp(min.toDouble(), max.toDouble()),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: (max - min) > 0 ? (max - min) : 1,
                    onChanged: (val) => onChanged(val.round()),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              IconButton.filledTonal(
                onPressed: currentValue < max
                    ? () => onChanged(currentValue + 1)
                    : null,
                icon: const Icon(Icons.add, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFDCFCE7),
                  foregroundColor: _darkGreen,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Quick Presets
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: quickPresets.map((preset) {
              final isPresetSelected = currentValue == preset;
              return ChoiceChip(
                label: Text('$preset $unit'),
                selected: isPresetSelected,
                onSelected: (_) => onChanged(preset),
                selectedColor: _darkGreen,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPresetSelected ? Colors.white : const Color(0xFF334155),
                ),
                backgroundColor: const Color(0xFFF8FAFC),
                side: BorderSide(
                  color: isPresetSelected ? _darkGreen : const Color(0xFFE2E8F0),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Description Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // INFO CARD PER STEP
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStepInfoCard() {
    final infoData = _getInfoDataForStep(_currentStep);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: _darkGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  infoData['title'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  infoData['text'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF475569),
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

  Map<String, String> _getQuestionDataForStep(int step) {
    switch (step) {
      case 1:
        return {
          'question': 'Apakah jenis kelamin Bapak/Ibu?',
          'subQuestion': '(Pilih jenis kelamin sesuai identitas KTP Bapak/Ibu.)',
        };
      case 2:
        return {
          'question': 'Berapa kelompok usia Bapak/Ibu saat ini?',
          'subQuestion': '(Pilih kelompok rentang usia Bapak/Ibu saat ini.)',
        };
      case 3:
        return {
          'question': 'Berapa tinggi badan dan berat badan Bapak/Ibu saat ini?',
          'subQuestion': '(Sistem akan menghitung Indeks Massa Tubuh / BMI secara otomatis)',
        };
      case 4:
        return {
          'question': 'Manakah kelompok ras/etnis yang paling menggambarkan Bapak/Ibu?',
          'subQuestion': '(Pilih salah satu kelompok ras atau etnis)',
        };
      case 5:
        return {
          'question': 'Secara umum, bagaimana Bapak/Ibu menilai kondisi kesehatan Bapak/Ibu saat ini?',
          'subQuestion': '(Evaluasi subjektif terhadap kondisi kebugaran dan kesehatan Anda)',
        };
      case 6:
        return {
          'question': 'Dalam 30 hari terakhir, berapa hari kesehatan fisik Bapak/Ibu (termasuk sakit fisik dan cedera) terasa tidak baik?',
          'subQuestion': '(Pilihan angka 0 hingga 30 hari)',
        };
      case 7:
        return {
          'question': 'Dalam 30 hari terakhir, berapa hari kesehatan mental Bapak/Ibu (termasuk stres, depresi, atau masalah emosional) terasa tidak baik?',
          'subQuestion': '(Pilihan angka 0 hingga 30 hari)',
        };
      case 8:
        return {
          'question': 'Berapa rata-rata jam tidur yang Bapak/Ibu dapatkan dalam rentang waktu 24 jam sehari?',
          'subQuestion': '(Pilihan angka 1 hingga 24 jam)',
        };
      case 9:
        return {
          'question': 'Apakah Bapak/Ibu pernah diberitahu oleh tenaga medis memiliki penyakit jantung koroner atau pernah mengalami serangan jantung?',
          'subQuestion': '(Termasuk riwayat serangan jantung atau penyakit jantung koroner)',
        };
      case 10:
        return {
          'question': 'Apakah Bapak/Ibu pernah diberitahu oleh tenaga medis mengalami stroke?',
          'subQuestion': '(Pernah mengalami stroke iskemik/hemoragik atau stroke ringan/TIA)',
        };
      case 11:
        return {
          'question': 'Apakah Bapak/Ibu pernah diberitahu oleh tenaga medis memiliki diabetes (kencing manis)?',
          'subQuestion': '(Pilih salah satu kondisi yang paling menggambarkan Bapak/Ibu)',
        };
      case 12:
        return {
          'question': 'Apakah Bapak/Ibu pernah diberitahu oleh dokter atau tenaga medis bahwa Bapak/Ibu menderita asma?',
          'subQuestion': '(Riwayat asma bronkial atau masalah penyempitan saluran napas kronis)',
        };
      case 13:
        return {
          'question': 'Apakah Bapak/Ibu pernah merokok minimal 100 batang (sekitar 5 bungkus) sepanjang hidup Bapak/Ibu?',
          'subQuestion': '(Total konsumsi rokok mencapai minimal 100 batang sepanjang hidup)',
        };
      case 14:
        return {
          'question': 'Apakah Bapak/Ibu mengonsumsi alkohol secara berlebihan (pria >14 gelas/minggu, wanita >7 gelas/minggu)?',
          'subQuestion': '(Pria >14 takaran/minggu, wanita >7 takaran/minggu)',
        };
      case 15:
        return {
          'question': 'Selain pekerjaan rutin, apakah Bapak/Ibu melakukan aktivitas fisik atau olahraga (seperti berjalan kaki, bersepeda, berkebun, atau senam) dalam 30 hari terakhir?',
          'subQuestion': '(Aktivitas fisik teratur minimal 20-30 menit dalam sebulan terakhir)',
        };
      case 16:
        return {
          'question': 'Apakah Bapak/Ibu mengalami kesulitan serious untuk berjalan atau menaiki tangga?',
          'subQuestion': '(Keterbatasan fisik, kelemahan tungkai, atau butuh bantuan saat berjalan)',
          'footnote': '*Meliputi kesulitan menaiki tangga, kelemahan sendi, atau keterbatasan mobilitas harian.',
        };
      default:
        return {'question': '', 'subQuestion': ''};
    }
  }

  Map<String, String> _getInfoDataForStep(int step) {
    switch (step) {
      case 1:
        return {
          'title': 'Mengapa data ini dibutuhkan?',
          'text': 'Perhitungan laju filtrasi ginjal (eGFR) menggunakan rumus baku CKD-EPI yang memperhitungkan faktor biologis jenis kelamin secara spesifik dan akurat.',
        };
      case 2:
        return {
          'title': 'Mengapa data usia dibutuhkan?',
          'text': 'Fungsi penyaringan nefron ginjal mengalami penurunan fisiologis alami seiring bertambahnya usia, sehingga menjadi parameter penting dalam skrining.',
        };
      case 3:
        return {
          'title': 'Mengapa IMT penting?',
          'text': 'Kelebihan berat badan (obesitas) meningkatkan tekanan glomerulus dan memaksa ginjal bekerja lebih keras (hiperfiltrasi).',
        };
      case 4:
        return {
          'title': 'Mengapa data ras/etnis dibutuhkan?',
          'text': 'Studi klinis epidemiologi menunjukkan variasi predisposisi genetik dan vaskular terhadap risiko penyakit ginjal serta hipertensi pada populasi tertentu.',
        };
      case 5:
        return {
          'title': 'Mengapa evaluasi kesehatan umum penting?',
          'text': 'Penilaian subjektif kesehatan mencerminkan status kebugaran multisistemik dan kesejahteraan tubuh secara menyeluruh.',
        };
      case 6:
        return {
          'title': 'Mengapa data kesehatan fisik dibutuhkan?',
          'text': 'Jumlah hari sakit fisik mencerminkan tingkat morbiditas aktif yang dapat memberikan beban metabolik tambahan pada organ ekskresi ginjal.',
        };
      case 7:
        return {
          'title': 'Mengapa kesehatan mental diperhitungkan?',
          'text': 'Beban stres emosional dan depresi memicu aktivasi aksis HPA serta hormon stres yang berdampak langsung pada tekanan darah dan perfusi ginjal.',
        };
      case 8:
        return {
          'title': 'Mengapa durasi tidur penting?',
          'text': 'Ritme sirkadian saat tidur mengatur ritme filtrasi ginjal malam hari serta keseimbangan elektrolit dan kontrol tekanan darah.',
        };
      case 9:
        return {
          'title': 'Mengapa faktor ini penting?',
          'text': 'Penyakit jantung dan gangguan fungsi ginjal saling memengaruhi erat dalam sindrom kardiorenal tubuh.',
        };
      case 10:
        return {
          'title': 'Mengapa informasi stroke penting?',
          'text': 'Kesehatan pembuluh darah otak dan ginjal memiliki keterkaitan erat dalam sirkulasi mikrovaskular dan endotel pembuluh darah.',
        };
      case 11:
        return {
          'title': 'Keterkaitan Diabetes dan Ginjal',
          'text': 'Diabetes merupakan penyebab nomor satu nefropati dan gagal ginjal kronis di seluruh dunia akibat kerusakan kapiler glomerulus.',
        };
      case 12:
        return {
          'title': 'Mengapa data asma dibutuhkan?',
          'text': 'Peradangan saluran napas kronis serta riwayat penggunaan obat kortikosteroid berpotensi memengaruhi fungsi metabolik dan ginjal.',
        };
      case 13:
        return {
          'title': 'Mengapa riwayat merokok penting?',
          'text': 'Paparan nikotin dan racun tembakau memicu vasokonstriksi pembuluh ginjal dan mempercepat proses aterosklerosis renal.',
        };
      case 14:
        return {
          'title': 'Mengapa konsumsi alkohol diperhatikan?',
          'text': 'Asupan alkohol berlebih memicu dehidrasi seluler, beban metabolik hepatorenal, dan gangguan regulasi cairan tubuh.',
        };
      case 15:
        return {
          'title': 'Mengapa aktivitas fisik penting?',
          'text': 'Olahraga teratur menjaga sirkulasi vaskular, meningkatkan sensitivitas insulin, dan mempertahankan laju filtrasi ginjal yang sehat.',
        };
      case 16:
        return {
          'title': 'Mengapa mobilitas penting?',
          'text': 'Kemampuan mobilitas mandiri mencerminkan kebugaran fungsional kardiorespirasi dan toleransi beban sirkulasi tubuh.',
        };
      default:
        return {'title': '', 'text': ''};
    }
  }
}
