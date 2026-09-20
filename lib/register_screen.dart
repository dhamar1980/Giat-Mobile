import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/giat_auth_background.dart';
import 'syarat_ketentuan_screen.dart';
import 'kebijakan_privasi_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // Current Step (0 = Step 1: Info Pribadi, 1 = Step 2: Akun & Keamanan)
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1 Controllers & Keys
  final _step1FormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Step 2 Controllers & Keys
  final _step2FormKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _agreeTerms = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  // Animations
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _bubble1Slide;
  late final Animation<Offset> _bubble2Slide;
  late final Animation<Offset> _cardSlide;

  // Color Palette matching design & screenshots
  static const _primaryDarkGreen = Color(0xFF065A37);
  static const _bubbleGreen = Color(0xFF22C55E);
  static const _bubbleDarkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _linkMintGreen = Color(0xFF34D399);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    _bubble1Slide = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.1, 0.65, curve: Curves.easeOutCubic),
    ));

    _bubble2Slide = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.25, 0.8, curve: Curves.easeOutCubic),
    ));

    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    ));

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pageController.dispose();
    _nameCtrl.dispose();
    _nikCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_currentStep > 0) {
      _goToStep(0);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handleNextStep1() {
    if (!_step1FormKey.currentState!.validate()) return;
    _goToStep(1);
  }

  Future<void> _handleRegister() async {
    if (!_step2FormKey.currentState!.validate()) return;

    if (!_agreeTerms) {
      _showSnack(
        'Harap setujui Syarat & Ketentuan serta Kebijakan Privasi.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Show success dialog
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pendaftaran Berhasil! 🎉',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Akun GIAT Anda telah berhasil dibuat. Silakan masuk untuk mulai memantau kesehatan ginjal Anda.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // close dialog
                    Navigator.of(context).pop(); // return to login
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonDarkGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Masuk Sekarang',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isError ? const Color(0xFFEF4444) : _primaryDarkGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(
        msg,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          _goToStep(0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAF7),
        body: Stack(
          children: [
            // ── Background Topography + Glow (Tetap Diam Saat Keyboard Terbuka) ──
            Positioned(
              top: 0,
              left: 0,
              width: screenSize.width,
              height: screenSize.height,
              child: GiatAuthBackground(
                screenSize: screenSize,
                showBottomWaves: false,
              ),
            ),

            // ── Main Content ──
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Top Header (Back Button, Logo, Chat Bubbles) ──
                  _buildTopSection(),

                  const SizedBox(height: 12),

                  // ── Bottom Green Multi-Step Form Card ──
                  Expanded(
                    child: SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildBottomCard(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOP SECTION: KEMBALI BUTTON + LOGO + CHAT BUBBLES
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Tombol Kembali (Top Left Pill) ──
          FadeTransition(
            opacity: _fadeAnim,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleBack,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF0F172A),
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back,
                          size: 16,
                          color: Color(0xFF0F172A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Kembali',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Logo GIAT | Ginjal Sehat ──
          FadeTransition(
            opacity: _fadeAnim,
            child: const Center(
              child: _RegisterGiatLogoHeader(),
            ),
          ),

          const SizedBox(height: 20),

          // ── Bubble 1 (Right): Greeting message with checkmarks ──
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _bubble1Slide,
              child: Align(
                alignment: Alignment.centerRight,
                child: _RegisterRightChatBubble(
                  color: _bubbleGreen,
                  text:
                      'Daftar untuk mulai menjaga kesehatan ginjal bersama GIAT.',
                  time: '12.00',
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Bubble 2 (Left): "Buat Akun GIAT di bawah" ──
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _bubble2Slide,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _RegisterLeftChatBubble(
                  color: _bubbleDarkGreen,
                  text: 'Buat Akun GIAT di bawah',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM CARD WITH MULTI-STEP FORM
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomCard() {
    final screenSize = MediaQuery.sizeOf(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF22B062),
            Color(0xFF16964F),
            Color(0xFF09522C),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 28,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
        child: Stack(
          children: [
            // Subtle topographic wave contours at the bottom of the card only
            Positioned.fill(
              child: CustomPaint(
                painter: GiatCardBottomWavePainter(
                  screenHeight: screenSize.height,
                ),
              ),
            ),

            // Card Inner Scrollable Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // ── Stepper Indicator (01 ------ 02) ──
                _buildStepperIndicator(),

                const SizedBox(height: 18),

                // ── Multi-Step PageView ──
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentStep = index);
                    },
                    children: [
                      _buildStep1View(),
                      _buildStep2View(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEPPER INDICATOR (01 ------- 02)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStepperIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circle 01
              _buildStepCircle(stepNumber: 1, isActive: _currentStep == 0, isCompleted: _currentStep > 0),
              
              // Dashed connecting line
              Container(
                width: 68,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CustomPaint(
                  size: const Size(60, 2),
                  painter: _DashedLinePainter(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ),

              // Circle 02
              _buildStepCircle(stepNumber: 2, isActive: _currentStep == 1, isCompleted: false),
            ],
          ),
          const SizedBox(height: 4),
          // Numbers 01 & 02 labels underneath
          SizedBox(
            width: 104,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '01',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '02',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle({
    required int stepNumber,
    required bool isActive,
    required bool isCompleted,
  }) {
    if (isActive) {
      // Concentric active ring with filled inner dot
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
            color: Colors.white,
            width: 2.2,
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );
    } else if (isCompleted) {
      // Completed step: solid white ring
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: Colors.white,
            width: 2.2,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.check,
          size: 12,
          color: _primaryDarkGreen,
        ),
      );
    } else {
      // Inactive step: simple hollow ring
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 2.0,
          ),
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 1 VIEW: NAMA LENGKAP, NIK, EMAIL
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStep1View() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Field: Nama Lengkap ──
            _buildFieldLabel('Nama Lengkap'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              decoration: _inputDecoration(hint: 'Masukkan nama lengkap'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama lengkap tidak boleh kosong';
                }
                if (val.trim().length < 3) {
                  return 'Nama minimal 3 karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Field: NIK (Nomor Induk Kependudukan) ──
            _buildFieldLabel('NIK (Nomor Induk Kependudukan)'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _nikCtrl,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              decoration: _inputDecoration(hint: 'Masukkan 16 digit NIK'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'NIK tidak boleh kosong';
                }
                if (val.trim().length != 16) {
                  return 'NIK harus terdiri dari 16 digit angka';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Field: Email ──
            _buildFieldLabel('Email'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              decoration: _inputDecoration(hint: 'Masukkan email'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Email tidak boleh kosong';
                }
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(val.trim())) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Tombol Selanjutnya ──
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _handleNextStep1,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonDarkGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Selanjutnya',
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Footer: Sudah punya akun? Masuk sekarang ──
            _buildLoginFooter(),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 2 VIEW: ALAMAT, KATA SANDI, KONFIRMASI KATA SANDI, TERMS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildStep2View() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Field: Alamat ──
            _buildFieldLabel('Alamat'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _addressCtrl,
              keyboardType: TextInputType.streetAddress,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              decoration: _inputDecoration(hint: 'Masukkan alamat lengkap'),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Alamat tidak boleh kosong';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Field: Kata Sandi ──
            _buildFieldLabel('Kata Sandi'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              textInputAction: TextInputAction.next,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              decoration: _inputDecoration(
                hint: 'Masukkan kata sandi',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 21,
                  ),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Kata sandi tidak boleh kosong';
                }
                if (val.length < 6) {
                  return 'Kata sandi minimal 6 karakter';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Field: Konfirmasi Kata Sandi ──
            _buildFieldLabel('Konfirmasi Kata Sandi'),
            const SizedBox(height: 7),
            TextFormField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirmPass,
              textInputAction: TextInputAction.done,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              decoration: _inputDecoration(
                hint: 'Masukkan kembali kata sandi',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 21,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPass = !_obscureConfirmPass,
                  ),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Konfirmasi kata sandi tidak boleh kosong';
                }
                if (val != _passCtrl.text) {
                  return 'Kata sandi tidak cocok';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Terms & Conditions Checkbox ──
            GestureDetector(
              onTap: () => setState(() => _agreeTerms = !_agreeTerms),
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2, right: 10),
                    decoration: BoxDecoration(
                      color: _agreeTerms ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.8,
                      ),
                    ),
                    child: _agreeTerms
                        ? const Icon(
                            Icons.check,
                            size: 15,
                            color: _buttonDarkGreen,
                          )
                        : null,
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Saya menyetujui '),
                          TextSpan(
                            text: 'Syarat & Ketentuan',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              color: Colors.white,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SyaratKetentuanScreen(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: ' dan '),
                          TextSpan(
                            text: 'Kebijakan Privasi',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              color: Colors.white,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const KebijakanPrivasiScreen(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: ' GIAT.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Tombol Daftar ──
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonDarkGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      _buttonDarkGreen.withValues(alpha: 0.7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Daftar',
                        style: GoogleFonts.inter(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Footer: Sudah punya akun? Masuk sekarang ──
            _buildLoginFooter(),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLoginFooter() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: Colors.white,
              ),
              children: [
                const TextSpan(
                  text: 'Sudah punya akun? ',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
                TextSpan(
                  text: 'Masuk sekarang',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _linkMintGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF9CA3AF),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _buttonDarkGreen,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFFCA5A5),
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.5,
        ),
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: 11.5,
        color: const Color(0xFFFFE4E6),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHED LINE PAINTER FOR STEPPER
// ─────────────────────────────────────────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(math.min(startX + dashWidth, size.width), y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGO COMPONENT
// ─────────────────────────────────────────────────────────────────────────────
class _RegisterGiatLogoHeader extends StatelessWidget {
  const _RegisterGiatLogoHeader();

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF065A37);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'GIAT',
          style: GoogleFonts.outfit(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: brandGreen,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 2.8,
          height: 32,
          decoration: BoxDecoration(
            color: brandGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ginjal',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: brandGreen,
                height: 1.1,
              ),
            ),
            Text(
              'Sehat',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: brandGreen,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPEECH BUBBLES
// ─────────────────────────────────────────────────────────────────────────────
class _RegisterRightChatBubble extends StatelessWidget {
  final Color color;
  final String text;
  final String time;

  const _RegisterRightChatBubble({
    required this.color,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RegisterRightBubbleShapePainter(color: color),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 275),
        padding: const EdgeInsets.only(
          left: 14,
          right: 18,
          top: 10,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13.2,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    time,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const _RegisterBlueDoubleCheck(size: 13),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterLeftChatBubble extends StatelessWidget {
  final Color color;
  final String text;

  const _RegisterLeftChatBubble({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RegisterLeftBubbleShapePainter(color: color),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.only(
          left: 18,
          right: 16,
          top: 10,
          bottom: 10,
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _RegisterBlueDoubleCheck extends StatelessWidget {
  final double size;
  const _RegisterBlueDoubleCheck({this.size = 14});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.3,
      height: size,
      child: CustomPaint(
        painter: _RegisterDoubleCheckPainter(),
      ),
    );
  }
}

class _RegisterDoubleCheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path1 = Path()
      ..moveTo(0, size.height * 0.52)
      ..lineTo(size.width * 0.28, size.height * 0.88)
      ..lineTo(size.width * 0.68, size.height * 0.12);

    final path2 = Path()
      ..moveTo(size.width * 0.32, size.height * 0.52)
      ..lineTo(size.width * 0.60, size.height * 0.88)
      ..lineTo(size.width * 1.0, size.height * 0.12);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RegisterRightBubbleShapePainter extends CustomPainter {
  final Color color;
  const _RegisterRightBubbleShapePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 14.0;
    const tailWidth = 8.0;

    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius),
          radius: const Radius.circular(radius))
      ..lineTo(size.width, size.height - 10)
      ..lineTo(size.width + tailWidth, size.height)
      ..lineTo(size.width - 10, size.height)
      ..lineTo(radius, size.height)
      ..arcToPoint(Offset(0, size.height - radius),
          radius: const Radius.circular(radius))
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0),
          radius: const Radius.circular(radius))
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RegisterLeftBubbleShapePainter extends CustomPainter {
  final Color color;
  const _RegisterLeftBubbleShapePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 14.0;
    const tailWidth = 8.0;

    final path = Path()
      ..moveTo(radius, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius),
          radius: const Radius.circular(radius))
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(Offset(size.width - radius, size.height),
          radius: const Radius.circular(radius))
      ..lineTo(10, size.height)
      ..lineTo(-tailWidth, size.height)
      ..lineTo(0, size.height - 10)
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0),
          radius: const Radius.circular(radius))
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
