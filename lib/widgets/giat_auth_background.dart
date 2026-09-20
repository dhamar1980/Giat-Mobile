import 'package:flutter/material.dart';

/// Reusable Background Widget for GIAT Authentication and Onboarding Screens
/// Features:
/// 1. Topographic organic wave contours at the TOP and BOTTOM only.
/// 2. Clean, empty middle section.
/// 3. Luminous mint glowing radial aura at top-right and top-left.
/// 4. Fixed dimensions (anchored to screen height) so it NEVER moves when the keyboard pops up.
class GiatAuthBackground extends StatelessWidget {
  final Size screenSize;
  final bool showBottomWaves;
  final Color baseColor;

  const GiatAuthBackground({
    super.key,
    required this.screenSize,
    this.showBottomWaves = true,
    this.baseColor = const Color(0xFFF6FAF7),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: screenSize.width,
      height: screenSize.height,
      child: CustomPaint(
        size: screenSize,
        painter: GiatTopoWavePainter(
          fixedSize: screenSize,
          showBottomWaves: showBottomWaves,
          baseColor: baseColor,
        ),
      ),
    );
  }
}

/// CustomPainter for the full-screen topographic wave contours and mint glow
class GiatTopoWavePainter extends CustomPainter {
  final Size fixedSize;
  final bool showBottomWaves;
  final Color baseColor;

  const GiatTopoWavePainter({
    required this.fixedSize,
    this.showBottomWaves = true,
    this.baseColor = const Color(0xFFF6FAF7),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Always use fixedSize so keyboard resizing does NOT shift or squish waves
    final w = fixedSize.width;
    final h = fixedSize.height;
    final rect = Offset.zero & fixedSize;

    // 1. Base solid background
    canvas.drawRect(rect, Paint()..color = baseColor);

    // 2. Top-right Luminous Mint Glow (matching Figma & screenshot)
    final glowPaintRight = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.75),
        radius: 0.95,
        colors: [
          const Color(0xFF34D399).withValues(alpha: 0.38),
          const Color(0xFF6EE7B7).withValues(alpha: 0.22),
          const Color(0xFFA7F3D0).withValues(alpha: 0.10),
          baseColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.40, 0.70, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaintRight);

    // 3. Top-left subtle ambient glow
    final glowPaintLeft = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.80, -0.85),
        radius: 0.75,
        colors: [
          const Color(0xFFA7F3D0).withValues(alpha: 0.16),
          baseColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaintLeft);

    // 4. TOP Wave Contours (Organic Topographic Flow)
    // 7 flowing wave lines starting from y=-15 to ~y=140
    // Middle area is completely clear!
    final topWavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;

    const topWaveColor = Color(0xFF2ECC71); // Figma vibrant green
    final topOpacities = [0.32, 0.28, 0.24, 0.20, 0.17, 0.14, 0.11];

    for (int i = 0; i < topOpacities.length; i++) {
      topWavePaint.color = topWaveColor.withValues(alpha: topOpacities[i]);
      final y0 = -18.0 + (i * 22.5);

      final path = Path()
        ..moveTo(-35, y0 + 12)
        ..cubicTo(
          w * 0.22,
          y0 + 34,
          w * 0.46,
          y0 - 18,
          w * 0.70,
          y0 + 26,
        )
        ..cubicTo(
          w * 0.84,
          y0 + 48,
          w * 0.95,
          y0 + 16,
          w + 35,
          y0 + 30,
        );

      canvas.drawPath(path, topWavePaint);
    }

    // 5. BOTTOM Wave Contours (Only when screen doesn't have a solid card covering it)
    if (showBottomWaves) {
      final botWavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round;

      const botWaveColor = Color(0xFF2ECC71);
      // Continuous wave contour lines extending all the way to the bottom edge of the screen
      final botOpacities = [
        0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36
      ];

      for (int i = 0; i < botOpacities.length; i++) {
        botWavePaint.color = botWaveColor.withValues(alpha: botOpacities[i]);
        // Starts from h - 280 and steps down to h + 20 (completely filling the bottom of the screen)
        final y0 = h - 280.0 + (i * 20.0);

        final path = Path()
          ..moveTo(-35, y0 - 12)
          ..cubicTo(
            w * 0.28,
            y0 - 32,
            w * 0.56,
            y0 + 20,
            w * 0.76,
            y0 - 22,
          )
          ..cubicTo(
            w * 0.88,
            y0 - 42,
            w * 0.95,
            y0 - 12,
            w + 35,
            y0 + 8,
          );

        canvas.drawPath(path, botWavePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GiatTopoWavePainter oldDelegate) =>
      oldDelegate.fixedSize != fixedSize ||
      oldDelegate.showBottomWaves != showBottomWaves ||
      oldDelegate.baseColor != baseColor;
}

/// CustomPainter for subtle topographic waves at the bottom of the green card
/// (Behind the Google button and "Belum punya akun?" footer)
class GiatCardBottomWavePainter extends CustomPainter {
  final double screenHeight;

  const GiatCardBottomWavePainter({
    this.screenHeight = 844,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Line paint for bright mint contour lines on the green card
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;

    // Draw 6-7 wavy lines at the bottom 240px of the card
    // The top and middle of the card (where inputs & "Masuk" are) remain completely empty!
    final waveConfigs = [
      // [yOffsetFromBottom, opacity, isWhite]
      [220.0, 0.12, false],
      [190.0, 0.16, false],
      [160.0, 0.20, false],
      [130.0, 0.24, false],
      [100.0, 0.27, false],
      [70.0, 0.30, false],
      [40.0, 0.32, false],
    ];

    for (final cfg in waveConfigs) {
      final yOffsetFromBottom = cfg[0] as double;
      final opacity = cfg[1] as double;
      final isWhite = cfg[2] as bool;

      final color = isWhite ? Colors.white : const Color(0xFF2ECC71);
      linePaint.color = color.withValues(alpha: opacity);

      final y0 = h - yOffsetFromBottom;

      final path = Path()
        ..moveTo(-35, y0 - 14)
        ..cubicTo(
          w * 0.28,
          y0 - 34,
          w * 0.58,
          y0 + 22,
          w * 0.78,
          y0 - 20,
        )
        ..cubicTo(
          w * 0.88,
          y0 - 38,
          w * 0.95,
          y0 - 10,
          w + 35,
          y0 + 10,
        );

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant GiatCardBottomWavePainter oldDelegate) =>
      oldDelegate.screenHeight != screenHeight;
}
