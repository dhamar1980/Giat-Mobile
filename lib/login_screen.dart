import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'master_layout.dart';
import 'register_screen.dart';
import 'dokter_home_screen.dart';
import 'apoteker_home_screen.dart';
import 'forgot_password_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Demo credentials — untuk simulasi login
// ─────────────────────────────────────────────────────────────────────────────
const _demoUsers = [
  // 1. Pasien (email "pasien", password "pasien")
  {'email': 'pasien', 'password': 'pasien', 'role': 'pasien', 'name': 'Pasien'},
  {'email': 'pasien@giat.id', 'password': 'pasien', 'role': 'pasien', 'name': 'Pasien'},
  {'email': 'pasien@giat.id', 'password': '123456', 'role': 'pasien', 'name': 'Pasien'},

  // 2. Dokter (email "dokter", password "dokter")
  {'email': 'dokter', 'password': 'dokter', 'role': 'dokter', 'name': 'Dr. Andi Pratama'},
  {'email': 'dokter@giat.id', 'password': 'dokter', 'role': 'dokter', 'name': 'Dr. Andi Pratama'},
  {'email': 'dokter@giat.id', 'password': '123456', 'role': 'dokter', 'name': 'Dr. Andi Pratama'},

  // 3. Apoteker (email "apoteker", password "apoteker")
  {'email': 'apoteker', 'password': 'apoteker', 'role': 'apoteker', 'name': 'Budi'},
  {'email': 'apoteker@giat.id', 'password': 'apoteker', 'role': 'apoteker', 'name': 'Budi'},
  {'email': 'apoteker@giat.id', 'password': '123456', 'role': 'apoteker', 'name': 'Budi'},
];

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN SCREEN (Figma Node: 1018:4273)
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePass = true;
  bool _isLoading = false;

  // Animations
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _bubble1Slide;
  late final Animation<Offset> _bubble2Slide;
  late final Animation<Offset> _cardSlide;

  // Colors based on Figma design
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
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final email = _emailCtrl.text.trim().toLowerCase();
    final pass = _passCtrl.text.trim();
    final match = _demoUsers.where(
      (u) => u['email'] == email && u['password'] == pass,
    );

    setState(() => _isLoading = false);

    if (match.isEmpty) {
      _showSnack('Email/Username atau kata sandi salah.', isError: true);
      return;
    }

    final user = match.first;
    final role = user['role'];
    final name = user['name'] ?? 'Pengguna';

    _showSnack('Berhasil masuk sebagai $role 🎉');

    Widget targetScreen;
    if (role == 'dokter') {
      targetScreen = DokterHomeScreen(doctorName: name);
    } else if (role == 'apoteker') {
      targetScreen = ApotekerHomeScreen(apotekerName: name);
    } else {
      targetScreen = MasterLayout(userName: name);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => targetScreen,
      ),
    );
  }

  void _handleGoogleLogin() {
    _showSnack('Google Sign-In akan segera tersedia.');
  }

  void _handleForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }

  void _handleRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      body: Stack(
        children: [
          // ── Background Topography + Glow ──
          Positioned.fill(
            child: CustomPaint(
              painter: _LoginTopographyPainter(),
            ),
          ),

          // ── Scrollable Layout ──
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Top Header Section (Logo + Chat Bubbles) ──
                          _buildTopSection(),

                          const SizedBox(height: 18),

                          // ── Bottom Green Form Card ──
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
  // TOP SECTION: LOGO + CHAT BUBBLES
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // Logo GIAT | Ginjal Sehat
          FadeTransition(
            opacity: _fadeAnim,
            child: const Center(
              child: _GiatLogoHeader(),
            ),
          ),

          const SizedBox(height: 26),

          // Bubble 1 (Right): Greeting message with checkmarks
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _bubble1Slide,
              child: Align(
                alignment: Alignment.centerRight,
                child: _RightChatBubble(
                  color: _bubbleGreen,
                  text:
                      'Selamat datang kembali. Jaga kesehatan\nginjalmu bersama GIAT.✨✨',
                  time: '12.00',
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Bubble 2 (Left): "Masuk ke GIAT"
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _bubble2Slide,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _LeftChatBubble(
                  color: _bubbleDarkGreen,
                  text: 'Masuk ke GIAT',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BOTTOM SECTION: GREEN FORM CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBottomCard() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(34),
        topRight: Radius.circular(34),
      ),
      child: Stack(
        children: [
          // Green Card Background Gradient + subtle wavy contour lines
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF22B062),
                    Color(0xFF15964F),
                    Color(0xFF07663A),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _CardTopographyOverlayPainter(),
            ),
          ),

          // Form Content
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 34),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label Email
                  Text(
                    'Email',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email Input
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _inputDecoration(hint: 'Masukkan email atau username'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email atau username tidak boleh kosong';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Label Kata Sandi
                  Text(
                    'Kata Sandi',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Kata Sandi Input
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscurePass,
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
                          color: const Color(0xFF4B5563),
                          size: 22,
                        ),
                        splashRadius: 20,
                        onPressed: () {
                          setState(() => _obscurePass = !_obscurePass);
                        },
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Kata sandi tidak boleh kosong';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  // Lupa kata sandi?
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _handleForgotPassword,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Lupa kata sandi?',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Tombol Masuk
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonDarkGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
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
                              'Masuk',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider "atau"
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'atau',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tombol Masuk dengan Google
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleGoogleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1F2937),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _GoogleGLogo(size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Masuk dengan Google',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer: Belum punya akun? Daftar sekarang
                  Center(
                    child: GestureDetector(
                      onTap: _handleRegister,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: Colors.white,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Belum punya akun? ',
                                style: TextStyle(fontWeight: FontWeight.w400),
                              ),
                              TextSpan(
                                text: 'Daftar sekarang',
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
                  ),
                ],
              ),
            ),
          ),
        ],
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
// LOGO COMPONENT
// ─────────────────────────────────────────────────────────────────────────────
class _GiatLogoHeader extends StatelessWidget {
  const _GiatLogoHeader();

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
class _RightChatBubble extends StatelessWidget {
  final Color color;
  final String text;
  final String time;

  const _RightChatBubble({
    required this.color,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RightBubbleShapePainter(color: color),
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
                  const _BlueDoubleCheck(size: 13),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftChatBubble extends StatelessWidget {
  final Color color;
  final String text;

  const _LeftChatBubble({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LeftBubbleShapePainter(color: color),
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

// ─────────────────────────────────────────────────────────────────────────────
// DOUBLE CHECKMARK ICON (CYAN/BLUE)
// ─────────────────────────────────────────────────────────────────────────────
class _BlueDoubleCheck extends StatelessWidget {
  final double size;
  const _BlueDoubleCheck({this.size = 14});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.3,
      height: size,
      child: CustomPaint(
        painter: _DoubleCheckPainter(),
      ),
    );
  }
}

class _DoubleCheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // First checkmark
    final path1 = Path()
      ..moveTo(0, size.height * 0.52)
      ..lineTo(size.width * 0.28, size.height * 0.88)
      ..lineTo(size.width * 0.68, size.height * 0.12);

    // Second overlapping checkmark
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

// ─────────────────────────────────────────────────────────────────────────────
// BUBBLE SHAPE PAINTERS
// ─────────────────────────────────────────────────────────────────────────────
class _RightBubbleShapePainter extends CustomPainter {
  final Color color;
  const _RightBubbleShapePainter({required this.color});

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

class _LeftBubbleShapePainter extends CustomPainter {
  final Color color;
  const _LeftBubbleShapePainter({required this.color});

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

// ─────────────────────────────────────────────────────────────────────────────
// GOOGLE 4-COLOR ICON PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _GoogleGLogo extends StatelessWidget {
  final double size;
  const _GoogleGLogo({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width, size.height);
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final Rect rect = Rect.fromCircle(center: Offset(cx, cy), radius: s * 0.44);
    final double strokeW = s * 0.22;

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.butt;

    // Google G arcs:
    // Red: Top (~200 deg to 345 deg)
    canvas.drawArc(rect, -math.pi * 0.85, math.pi * 0.75, false, paintRed);
    // Yellow: Left (~135 deg to 220 deg)
    canvas.drawArc(rect, -math.pi * 1.35, math.pi * 0.55, false, paintYellow);
    // Green: Bottom (~45 deg to 140 deg)
    canvas.drawArc(rect, math.pi * 0.15, math.pi * 0.70, false, paintGreen);
    // Blue: Right (~ -25 deg to 50 deg)
    canvas.drawArc(rect, -math.pi * 0.15, math.pi * 0.35, false, paintBlue);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - s * 0.04, cy - strokeW / 2, s * 0.48, strokeW),
      Radius.circular(strokeW * 0.2),
    );
    canvas.drawRRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND TOPOGRAPHY PAINTER (TOP & FULL SCREEN)
// ─────────────────────────────────────────────────────────────────────────────
class _LoginTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Base background color
    canvas.drawRect(rect, Paint()..color = const Color(0xFFF6FAF7));

    // Radial Mint Glow at top-right
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.9, -0.85),
        radius: 0.95,
        colors: [
          const Color(0xFF6EE7B7).withValues(alpha: 0.32),
          const Color(0xFFA7F3D0).withValues(alpha: 0.18),
          const Color(0xFFF6FAF7).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);

    // Topographic organic lines
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final lineConfigs = [
      [h * -0.02, h * 0.08, 0.22],
      [h * 0.03, h * 0.14, 0.24],
      [h * 0.08, h * 0.20, 0.22],
      [h * 0.14, h * 0.27, 0.20],
      [h * 0.21, h * 0.35, 0.18],
      [h * 0.28, h * 0.43, 0.16],
      [h * 0.36, h * 0.52, 0.15],
      [h * 0.45, h * 0.62, 0.16],
      [h * 0.55, h * 0.72, 0.18],
      [h * 0.65, h * 0.82, 0.20],
      [h * 0.75, h * 0.92, 0.22],
      [h * 0.85, h * 1.02, 0.24],
    ];

    for (final cfg in lineConfigs) {
      linePaint.color = const Color(0xFF10B981).withValues(alpha: cfg[2]);
      final startY = cfg[0];
      final endY = cfg[1];

      final path = Path()
        ..moveTo(-30, startY)
        ..cubicTo(
          w * 0.25,
          startY + (endY - startY) * 0.25 + 15,
          w * 0.72,
          startY + (endY - startY) * 0.75 - 15,
          w + 30,
          endY,
        );

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD TOPOGRAPHY OVERLAY PAINTER (SUBTLE WAVES ON GREEN CARD)
// ─────────────────────────────────────────────────────────────────────────────
class _CardTopographyOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    final waveOffsets = [
      0.08, 0.18, 0.28, 0.40, 0.52, 0.65, 0.78, 0.90, 1.02
    ];

    for (int i = 0; i < waveOffsets.length; i++) {
      final yFactor = waveOffsets[i];
      linePaint.color = Colors.white.withValues(alpha: 0.08 + (i % 3) * 0.03);

      final startY = h * yFactor;
      final endY = h * (yFactor + 0.12);

      final path = Path()
        ..moveTo(-20, startY)
        ..cubicTo(
          w * 0.3,
          startY + 20,
          w * 0.7,
          endY - 20,
          w + 20,
          endY,
        );

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
