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
  final int _totalSteps = 10;

  static const _darkGreen = Color(0xFF065A37);
  static const _accentGreen = Color(0xFF10B981);
  static const _selectedCardBg = Color(0xFFE0F2FE);

  // Form State Answers
  String? _selectedGender;
  String _selectedAgeRange = '45 – 49 thn';
  final TextEditingController _heightController = TextEditingController(text: '168');
  final TextEditingController _weightController = TextEditingController(text: '65');
  double _calculatedBmi = 23.0;

  bool? _hasHeartDisease;
  bool? _hasStroke;
  String? _diabetesStatus;
  bool? _hasPhysicalActivity;
  bool? _hasSmokingHistory;
  bool? _hasExcessiveAlcohol;
  bool? _hasMobilityDifficulty;

  @override
  void initState() {
    super.initState();
    _recalculateBmi();
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

  bool _isCurrentStepValid() {
    switch (_currentStep) {
      case 1:
        return _selectedGender != null && _selectedGender!.isNotEmpty;
      case 2:
        return _selectedAgeRange.isNotEmpty;
      case 3:
        return double.tryParse(_heightController.text) != null &&
            double.tryParse(_weightController.text) != null;
      case 4:
        return _hasHeartDisease != null;
      case 5:
        return _hasStroke != null;
      case 6:
        return _diabetesStatus != null && _diabetesStatus!.isNotEmpty;
      case 7:
        return _hasPhysicalActivity != null;
      case 8:
        return _hasSmokingHistory != null;
      case 9:
        return _hasExcessiveAlcohol != null;
      case 10:
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
      // Complete screening -> go to Processing Screen
      final result = PragiScreeningResult(
        id: 'scr-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        gender: _selectedGender ?? 'Laki-laki',
        ageRange: _selectedAgeRange,
        heightCm: double.tryParse(_heightController.text) ?? 168,
        weightKg: double.tryParse(_weightController.text) ?? 65,
        bmi: _calculatedBmi,
        hasHeartDisease: _hasHeartDisease ?? false,
        hasStroke: _hasStroke ?? false,
        diabetesStatus: _diabetesStatus ?? 'Tidak',
        hasPhysicalActivity: _hasPhysicalActivity ?? true,
        hasSmokingHistory: _hasSmokingHistory ?? false,
        hasExcessiveAlcohol: _hasExcessiveAlcohol ?? false,
        hasMobilityDifficulty: _hasMobilityDifficulty ?? false,
        riskLevel: (_hasHeartDisease == true || _hasStroke == true || _diabetesStatus == 'Ya, pernah')
            ? 'Sedang'
            : 'Rendah',
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
                            'Demografi Pasien',
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
                                  'Lanjutkan',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_circle_right_outlined, size: 20),
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
  // PROGRESS CARD (Circular Arc & Title)
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
                      '$_currentStep - 10',
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
                  _currentStep == 10 ? 'Langkah Terakhir' : 'Langkah $_currentStep Dari 10',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mohon isi sesuai dengan kondisi atau data yang sesuai adanya!',
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
                            '12.00',
                            style: GoogleFonts.inter(
                              fontSize: 10,
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
        if (questionData['footnote'] != null) ...[
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
  // STEP CONTENT DISPATCHER
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
        return _buildStep4HeartDisease();
      case 5:
        return _buildStep5Stroke();
      case 6:
        return _buildStep6Diabetes();
      case 7:
        return _buildStep7PhysicalActivity();
      case 8:
        return _buildStep8Smoking();
      case 9:
        return _buildStep9Alcohol();
      case 10:
        return _buildStep10Mobility();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 1: Gender Dropdown
  Widget _buildStep1Gender() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          isExpanded: true,
          hint: Text(
            'Pilih Jenis Kelamin Anda',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
          items: const [
            DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
            DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
          ],
          onChanged: (val) {
            setState(() {
              _selectedGender = val;
            });
          },
        ),
      ),
    );
  }

  // Step 2: Age Range Chips Grid
  Widget _buildStep2AgeRange() {
    final ageOptions = [
      '18 - 24 Tahun',
      '25–29 thn',
      '30 - 34 thn',
      '35 - 39 thn',
      '40 - 44 thn',
      '45 – 49 thn',
      '50 - 54 thn',
      '55 - 59 thn',
      '60 - 64 thn',
      '65 - 69 thn',
      '70 - 74 thn',
      '75 - 79 thn',
      '80 tahun ke atas',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ageOptions.map((age) {
        final isSelected = _selectedAgeRange == age;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAgeRange = age;
            });
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 50) / 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: isSelected ? _selectedCardBg : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    age,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: isSelected ? _darkGreen : const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Step 3: Height & Weight Inputs + Calculated BMI
  Widget _buildStep3HeightWeight() {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Indeks Massa Tubuh (IMT)',
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
                          fontSize: 20,
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
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 4: Heart Disease Card Options
  Widget _buildStep4HeartDisease() {
    return Column(
      children: [
        _buildChoiceCard(
          title: 'Ya, pernah',
          subtitle: 'Pernah didiagnosis dokter memiliki penyakit jantung',
          isSelected: _hasHeartDisease == true,
          onTap: () => setState(() => _hasHeartDisease = true),
        ),
        const SizedBox(height: 12),
        _buildChoiceCard(
          title: 'Tidak Pernah',
          subtitle: 'Tidak pernah memiliki riwayat penyakit jantung',
          isSelected: _hasHeartDisease == false,
          onTap: () => setState(() => _hasHeartDisease = false),
        ),
      ],
    );
  }

  // Step 5: Stroke Card Options
  Widget _buildStep5Stroke() {
    return Column(
      children: [
        _buildChoiceCard(
          title: 'Ya, pernah',
          subtitle: 'Pernah mengalami gejala atau diagnosis stroke',
          isSelected: _hasStroke == true,
          onTap: () => setState(() => _hasStroke = true),
        ),
        const SizedBox(height: 12),
        _buildChoiceCard(
          title: 'Tidak Pernah',
          subtitle: 'Tidak pernah mengalami stroke',
          isSelected: _hasStroke == false,
          onTap: () => setState(() => _hasStroke = false),
        ),
      ],
    );
  }

  // Step 6: Diabetes 4 Options
  Widget _buildStep6Diabetes() {
    return Column(
      children: [
        _buildChoiceCard(
          title: 'Ya, pernah',
          subtitle: 'Didiagnosis diabetes mellitus oleh dokter dan/atau menjalani terapi',
          isSelected: _diabetesStatus == 'Ya, pernah',
          onTap: () => setState(() => _diabetesStatus = 'Ya, pernah'),
        ),
        const SizedBox(height: 10),
        _buildChoiceCard(
          title: 'Ya, tetapi hanya selama kehamilan',
          subtitle: 'Diabetes gestasional pada masa mengandung',
          isSelected: _diabetesStatus == 'Ya, tetapi hanya selama kehamilan',
          onTap: () => setState(() => _diabetesStatus = 'Ya, tetapi hanya selama kehamilan'),
        ),
        const SizedBox(height: 10),
        _buildChoiceCard(
          title: 'Tidak, tetapi pernah diberitahu gula darah tinggi',
          subtitle: 'Kondisi prediabetes atau kadar gula darah puasa di atas normal',
          isSelected: _diabetesStatus == 'Tidak, tetapi pernah diberitahu gula darah tinggi',
          onTap: () => setState(() => _diabetesStatus = 'Tidak, tetapi pernah diberitahu gula darah tinggi'),
        ),
        const SizedBox(height: 10),
        _buildChoiceCard(
          title: 'Tidak',
          subtitle: 'Kadar gula darah normal dan tidak pernah didiagnosis diabetes',
          isSelected: _diabetesStatus == 'Tidak',
          onTap: () => setState(() => _diabetesStatus = 'Tidak'),
        ),
      ],
    );
  }

  // Step 7: Physical Activity Options
  Widget _buildStep7PhysicalActivity() {
    return Column(
      children: [
        _buildChoiceCard(
          title: 'Ya',
          subtitle: 'Rutin melakukan aktivitas fisik atau olahraga dalam sebulan terakhir',
          isSelected: _hasPhysicalActivity == true,
          onTap: () => setState(() => _hasPhysicalActivity = true),
        ),
        const SizedBox(height: 12),
        _buildChoiceCard(
          title: 'Tidak',
          subtitle: 'Hanya aktivitas sedentari atau tidak berolahraga teratur',
          isSelected: _hasPhysicalActivity == false,
          onTap: () => setState(() => _hasPhysicalActivity = false),
        ),
      ],
    );
  }

  // Step 8: Smoking Options
  Widget _buildStep8Smoking() {
    return Column(
      children: [
        _buildChoiceCard(
          title: 'Ya',
          subtitle: 'Pernah merokok 100 batang atau lebih sepanjang hidup',
          isSelected: _hasSmokingHistory == true,
          onTap: () => setState(() => _hasSmokingHistory = true),
        ),
        const SizedBox(height: 12),
        _buildChoiceCard(
          title: 'Tidak',
          subtitle: 'Kurang dari 100 batang atau tidak pernah merokok sama sekali',
          isSelected: _hasSmokingHistory == false,
          onTap: () => setState(() => _hasSmokingHistory = false),
        ),
      ],
    );
  }

  // Step 9: Alcohol Options with Guides
  Widget _buildStep9Alcohol() {
    return Column(
      children: [
        // Standard intake cards
        _buildAlcoholGuide(
          title: 'Pria: Lebih dari 14 takaran minuman per minggu',
        ),
        const SizedBox(height: 8),
        _buildAlcoholGuide(
          title: 'Wanita: Lebih dari 7 takaran minuman per minggu',
        ),
        const SizedBox(height: 8),
        Text(
          '*1 takaran standar setara dengan ±330 ml bir (5%) atau ±150 ml anggur (12%).',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: const Color(0xFF475569),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        _buildChoiceCard(
          title: 'Ya, pernah',
          subtitle: 'Konsumsi melebihi ambang batas yang disebutkan',
          isSelected: _hasExcessiveAlcohol == true,
          onTap: () => setState(() => _hasExcessiveAlcohol = true),
        ),
        const SizedBox(height: 10),
        _buildChoiceCard(
          title: 'Tidak',
          subtitle: 'Di bawah ambang batas tersebut atau tidak mengonsumsi alkohol',
          isSelected: _hasExcessiveAlcohol == false,
          onTap: () => setState(() => _hasExcessiveAlcohol = false),
        ),
      ],
    );
  }

  // Step 10: Mobility Options
  Widget _buildStep10Mobility() {
    return Column(
      children: [
        _buildChoiceCard(
          title: 'Ya',
          subtitle: 'Mengalami hambatan atau butuh bantuan saat berjalan/tangga',
          isSelected: _hasMobilityDifficulty == true,
          onTap: () => setState(() => _hasMobilityDifficulty = true),
        ),
        const SizedBox(height: 12),
        _buildChoiceCard(
          title: 'Tidak',
          subtitle: 'Dapat berjalan dan menaiki tangga dengan mandiri tanpa kendala',
          isSelected: _hasMobilityDifficulty == false,
          onTap: () => setState(() => _hasMobilityDifficulty = false),
        ),
      ],
    );
  }

  Widget _buildAlcoholGuide({required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info_outline_rounded, color: _darkGreen, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _selectedCardBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: isSelected ? _darkGreen : const Color(0xFFCBD5E1),
            ),
          ],
        ),
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
          'question': 'Apakah jenis kelamin Anda?',
          'subQuestion': '(Pilih sesuai identitas resmi KTP Anda.)',
        };
      case 2:
        return {
          'question': 'Berapa kelompok usia Bapak/Ibu?',
          'subQuestion': '(Pilih rentang usia Anda saat ini.)',
        };
      case 3:
        return {
          'question': 'Berapa tinggi dan berat badan Bapak/Ibu?',
          'subQuestion': '(IMT/BMI akan dihitung secara otomatis)',
        };
      case 4:
        return {
          'question': 'Apakah Bapak/Ibu memiliki riwayat penyakit jantung?',
          'subQuestion':
              '(Termasuk riwayat serangan jantung, penyakit jantung koroner, gagal jantung, atau kelainan jantung lainnya.)',
        };
      case 5:
        return {
          'question': 'Apakah Bapak/Ibu memiliki riwayat penyakit Stroke?',
          'subQuestion': '(pernah mengalami stroke atau transient ischemic attack/stroke ringan)',
        };
      case 6:
        return {
          'question': 'Apakah Bapak/Ibu memiliki riwayat penyakit diabetes?',
          'subQuestion': '(Pilih salah satu kategori yang paling menggambarkan kondisi Bapak/Ibu.)',
        };
      case 7:
        return {
          'question':
              'Selain aktivitas rutin seperti bekerja, apakah Bapak/Ibu melakukan aktivitas fisik atau olahraga dalam 30 hari terakhir?',
          'subQuestion':
              '(Contohnya berjalan kaki, bersepeda, berkebun, senam, atau berolahraga teratur minimal 20-30 menit.)',
        };
      case 8:
        return {
          'question':
              'Apakah Bapak/Ibu pernah merokok sedikitnya 100 batang rokok selama hidup?',
          'subQuestion':
              '(100 batang rokok kurang lebih setara dengan 5 bungkus rokok sepanjang hidup Bapak/Ibu.)',
        };
      case 9:
        return {
          'question': 'Apakah Bapak/Ibu mengonsumsi alkohol melebihi batas berikut?',
          'subQuestion': '',
        };
      case 10:
        return {
          'question':
              'Apakah Bapak/Ibu mengalami kesulitan serius saat berjalan atau menaiki tangga?',
          'subQuestion': '',
          'footnote':
              '*Gangguan mobilitas seperti kelemahan sendi, sesak napas saat berjalan, atau membutuhkan alat bantu.',
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
          'text':
              'Perhitungan laju filtrasi ginjal (eGFR) menggunakan rumus baku CKD-EPI yang memperhitungkan faktor biologis jenis kelamin secara spesifik dan akurat.',
        };
      case 2:
        return {
          'title': 'Mengapa data usia dibutuhkan?',
          'text':
              'Fungsi penyaringan nefron ginjal mengalami penurunan fisiologis alami seiring bertambahnya usia, sehingga menjadi parameter penting dalam skrining.',
        };
      case 3:
        return {
          'title': 'Mengapa IMT penting?',
          'text':
              'Kelebihan berat badan (obesitas) meningkatkan tekanan glomerulus dan memaksa ginjal bekerja lebih keras (hiperfiltrasi).',
        };
      case 4:
        return {
          'title': 'Mengapa faktor ini penting?',
          'text':
              'Penyakit jantung dan gangguan fungsi ginjal saling memengaruhi secara erat dalam sistem kardiorenal tubuh. Kondisi jantung memengaruhi perfusi darah menuju ginjal.',
        };
      case 5:
        return {
          'title': 'Mengapa informasi ini penting?',
          'text':
              'Kesehatan pembuluh darah otak dan ginjal memiliki keterkaitan erat dengan sirkulasi mikrovaskular.',
        };
      case 6:
        return {
          'title': 'Keterkaitan Diabetes dan Ginjal',
          'text':
              'Diabetes merupakan salah satu faktor utama yang dapat memengaruhi fungsi penyaringan ginjal.',
        };
      case 7:
        return {
          'title': 'Mengapa informasi ini penting?',
          'text':
              'Hanya aktivitas sedentari atau tidak berolahraga teratur dapat memperlambat metabolisme dan memicu resistensi vaskular.',
        };
      case 8:
        return {
          'title': 'Mengapa informasi ini penting?',
          'text':
              'Paparan nikotin dan zat kimia tembakau dapat mempersempit pembuluh darah kapiler halus di ginjal dan memicu aterosklerosis pembuluh renal.',
        };
      case 9:
        return {
          'title': 'Mengapa informasi ini penting?',
          'text':
              'Asupan alkohol berlebih dapat meningkatkan beban metabolik ginjal dan mempengaruhi regulasi cairan serta tekanan darah sistemik.',
        };
      case 10:
        return {
          'title': 'Mengapa informasi ini penting?',
          'text':
              'Kapasitas mobilitas fisik mencerminkan kebugaran kardiorespirasi dan toleransi beban cairan tubuh.',
        };
      default:
        return {'title': '', 'text': ''};
    }
  }
}
