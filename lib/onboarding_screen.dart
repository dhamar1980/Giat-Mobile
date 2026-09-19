import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WELCOME / ONBOARDING SCREEN
// Background: #F7F9FF  |  402×874dp reference
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideBubble1;
  late Animation<Offset> _slideBubble2;
  late Animation<Offset> _slideBottom;

  // ── colour palette ─────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF7F9FF);
  static const _green = Color(0xFF065A37);
  static const _greenMid = Color(0xFF1EAE62);
  static const _bubbleRight = Color(0xFF075B37);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideBubble1 = Tween<Offset>(
      begin: const Offset(0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));

    _slideBubble2 = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
    ));

    _slideBottom = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Subtle topographic wave lines (same as reference) ──────────
          Positioned.fill(
            child: CustomPaint(painter: _TopoBgPainter()),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final topGap    = (h * 0.055).clamp(14.0, 52.0);
                final midGap    = (h * 0.040).clamp(12.0, 40.0);
                final preBtnGap = (h * 0.065).clamp(18.0, 60.0);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 402),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            SizedBox(height: topGap),

                            // ── Circular kidney badge ──────────────────────
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _KidneyBadge(),
                            ),

                            const SizedBox(height: 22),

                            // ── Logo GIAT | Ginjal Sehat ───────────────────
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _GiatLogo(green: _green),
                            ),

                            SizedBox(height: midGap),

                            // ── Chat bubble RIGHT (dark emerald) ──────────
                            SlideTransition(
                              position: _slideBubble1,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _ChatBubble(
                                    isRight: true,
                                    color: _bubbleRight,
                                    text: 'Jaga Ginjal, Jaga Masa Depan\nAnda ✨✨',
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ── Chat bubble LEFT (medium green) ───────────
                            SlideTransition(
                              position: _slideBubble2,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _ChatBubble(
                                    isRight: false,
                                    color: _greenMid,
                                    text:
                                        'Temani perjalanan kesehatan\nginjalmu bersama GIAT.',
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: preBtnGap),

                            // ── Button + Tagline ───────────────────────────
                            SlideTransition(
                              position: _slideBottom,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Column(
                                  children: [
                                    // Tombol Mulai Sekarang
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pushReplacement(
                                            PageRouteBuilder(
                                              pageBuilder: (context2, anim, route) =>
                                                  const LoginScreen(),
                                              transitionsBuilder:
                                                  (context2, anim, route, child) =>
                                                      FadeTransition(
                                                        opacity: anim,
                                                        child: child,
                                                      ),
                                              transitionDuration: const Duration(
                                                  milliseconds: 380),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _green,
                                          foregroundColor: Colors.white,
                                          elevation: 2,
                                          shadowColor:
                                              _green.withValues(alpha: 0.35),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: Text(
                                          'Mulai Sekarang',
                                          style: GoogleFonts.inter(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Tagline
                                    Text(
                                      'Solusi kesehatan ginjal yang mudah dan terpercaya.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF4B5563),
                                        height: 1.5,
                                      ),
                                    ),

                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _GiatLogo extends StatelessWidget {
  final Color green;
  const _GiatLogo({required this.green});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'GIAT',
          style: GoogleFonts.outfit(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
            color: green,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 3,
          height: 38,
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ginjal',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: green,
                  height: 1.1,
                )),
            Text('Sehat',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: green,
                  height: 1.1,
                )),
          ],
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isRight;
  final Color color;
  final String text;

  const _ChatBubble({
    required this.isRight,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: isRight
          ? _RightBubblePainter(color: color)
          : _LeftBubblePainter(color: color),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: EdgeInsets.only(
          left: isRight ? 18 : 22,
          right: isRight ? 22 : 18,
          top: 14,
          bottom: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '12.00',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const _DoubleCheckIcon(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KidneyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.22),
            blurRadius: 32,
            spreadRadius: 8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/kidneys.jpg',
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => const Icon(
            Icons.favorite_rounded,
            size: 68,
            color: Color(0xFF065A37),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _DoubleCheckIcon extends StatelessWidget {
  const _DoubleCheckIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 17,
      height: 12,
      child: CustomPaint(painter: _DblCheckPainter()),
    );
  }
}

class _DblCheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final p1 = Path()
      ..moveTo(0, size.height * 0.55)
      ..lineTo(size.width * 0.28, size.height * 0.9)
      ..lineTo(size.width * 0.68, size.height * 0.15);
    canvas.drawPath(p1, p);

    final p2 = Path()
      ..moveTo(size.width * 0.32, size.height * 0.55)
      ..lineTo(size.width * 0.60, size.height * 0.9)
      ..lineTo(size.width * 1.0, size.height * 0.15);
    canvas.drawPath(p2, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _RightBubblePainter extends CustomPainter {
  final Color color;
  const _RightBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const r = 16.0;
    const tail = 8.0;
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
      ..lineTo(size.width, size.height - 12)
      ..lineTo(size.width + tail, size.height)
      ..lineTo(size.width - 12, size.height)
      ..lineTo(r, size.height)
      ..arcToPoint(Offset(0, size.height - r), radius: const Radius.circular(r))
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: const Radius.circular(r));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _LeftBubblePainter extends CustomPainter {
  final Color color;
  const _LeftBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const r = 16.0;
    const tail = 8.0;
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
          Offset(size.width - r, size.height), radius: const Radius.circular(r))
      ..lineTo(12, size.height)
      ..lineTo(-tail, size.height)
      ..lineTo(0, size.height - 12)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: const Radius.circular(r));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// Subtle topographic wave background matching #F7F9FF design
class _TopoBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Solid background
    canvas.drawRect(rect, Paint()..color = const Color(0xFFF7F9FF));

    // Very subtle radial glow top-left (mint tint)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.85, -0.75),
          radius: 0.85,
          colors: [
            const Color(0xFF27A868).withValues(alpha: 0.07),
            const Color(0xFF27A868).withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );

    // Topographic contour lines
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final contours = [
      _Contour(0, h * 0.10, w * 0.30, h * 0.02, w * 0.70, h * 0.05, h * 0.12, 0.16),
      _Contour(0, h * 0.16, w * 0.28, h * 0.08, w * 0.68, h * 0.12, h * 0.19, 0.18),
      _Contour(0, h * 0.23, w * 0.25, h * 0.15, w * 0.65, h * 0.19, h * 0.26, 0.18),
      _Contour(0, h * 0.30, w * 0.22, h * 0.22, w * 0.62, h * 0.26, h * 0.34, 0.15),
      _Contour(0, h * 0.38, w * 0.20, h * 0.30, w * 0.60, h * 0.34, h * 0.42, 0.13),
      _Contour(0, h * 0.47, w * 0.25, h * 0.38, w * 0.70, h * 0.44, h * 0.50, 0.11),
      _Contour(0, h * 0.57, w * 0.30, h * 0.49, w * 0.75, h * 0.53, h * 0.60, 0.11),
      _Contour(0, h * 0.67, w * 0.35, h * 0.60, w * 0.75, h * 0.64, h * 0.72, 0.14),
      _Contour(0, h * 0.76, w * 0.32, h * 0.68, w * 0.72, h * 0.73, h * 0.80, 0.16),
      _Contour(0, h * 0.84, w * 0.28, h * 0.77, w * 0.68, h * 0.81, h * 0.88, 0.18),
      _Contour(0, h * 0.92, w * 0.25, h * 0.85, w * 0.65, h * 0.89, h * 0.96, 0.20),
      _Contour(0, h * 1.00, w * 0.22, h * 0.93, w * 0.62, h * 0.97, h * 1.04, 0.22),
    ];

    for (final c in contours) {
      linePaint.color =
          const Color(0xFF27A868).withValues(alpha: c.opacity);
      canvas.drawPath(
        Path()
          ..moveTo(-20, c.yStart)
          ..cubicTo(c.cp1x, c.cp1y, c.cp2x, c.cp2y, w + 20, c.yEnd),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _Contour {
  final double yStart, cp1x, cp1y, cp2x, cp2y, yEnd, opacity;
  const _Contour(this.yStart, this.cp1x, this.cp1y, this.cp2x, this.cp2y,
      this.yEnd, double unused, this.opacity);
}
