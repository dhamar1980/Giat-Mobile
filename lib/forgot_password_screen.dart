import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'verification_code_screen.dart';
import 'widgets/giat_auth_background.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LUPA KATA SANDI SCREEN (Figma Node: 1018-5399)
// ─────────────────────────────────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _bubble1Slide;
  late final Animation<Offset> _bubble2Slide;
  late final Animation<Offset> _cardSlide;

  // Colors based on Figma design
  static const _darkGreen = Color(0xFF065A37);
  static const _bubbleGreen = Color(0xFF22C55E);
  static const _bubbleDarkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _linkMintGreen = Color(0xFF34D399);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Logika 1: Kirimkan kode verifikasi ke email sesuai yang diinputkan user
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    setState(() => _isLoading = false);
    final email = _emailCtrl.text.trim();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kode verifikasi telah dikirimkan ke $email',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );

    // Logika 2: Langsung membuka halaman kode verifikasi
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationCodeScreen(email: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
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

          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Ensure card stretches down to bottom when space permits,
                // but never squishes below 290px when keyboard appears!
                const topEstimatedHeight = 310.0;
                final cardMinHeight = (constraints.maxHeight - topEstimatedHeight).clamp(290.0, double.infinity);

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Top Bar & Logo ──
                            _buildTopBar(),

                            // ── Chat Bubbles Section ──
                            _buildChatBubblesSection(),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // ── Bottom Form Card ──
                        SlideTransition(
                          position: _cardSlide,
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: _buildBottomCard(minHeight: cardMinHeight),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOP BAR (Figma Node 1018:5399)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Pill Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF044E2F), width: 1.2),
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
                  const Icon(Icons.arrow_back, size: 16, color: Color(0xFF044E2F)),
                  const SizedBox(width: 6),
                  Text(
                    'Kembali',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF044E2F),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Logo GIAT | Ginjal Sehat
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GIAT',
                  style: GoogleFonts.inter(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: _darkGreen,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 2,
                  height: 30,
                  color: _darkGreen.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ginjal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _darkGreen,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Sehat',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _darkGreen,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CHAT BUBBLES SECTION (Figma Node 1018:5399)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildChatBubblesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Bubble 1 (Right green)
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _bubble1Slide,
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _bubbleGreen,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Jangan khawatir. Masukkan email yang terdaftar untuk mendapatkan kode verifikasi.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bubble 2 (Left dark green)
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _bubble2Slide,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: _bubbleDarkGreen,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Lupa Kata Sandi?',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM FORM CARD (Figma Node 1018:5399)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomCard({double minHeight = 0}) {
    final screenSize = MediaQuery.sizeOf(context);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(50),
        topRight: Radius.circular(50),
      ),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
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
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: GiatCardBottomWavePainter(
                  screenHeight: screenSize.height,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 34),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Email',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Masukkan email',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        suffixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF64748B),
                          size: 22,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Button Kirim Kode Verifikasi
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _buttonDarkGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleSendOtp,
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
                                'Kirim Kode Verifikasi',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Masuk Sekarang
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: RichText(
                          text: TextSpan(
                            text: 'Sudah ingat kata sandi? ',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: 'Masuk sekarang',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: _linkMintGreen,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
