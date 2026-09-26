import 'package:flutter/material.dart';
import 'giat_background.dart';

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
    GiatBackgroundPainter.paintBackground(
      canvas,
      size,
      fixedSize: fixedSize,
      showBottomWaves: showBottomWaves,
      showGradient: true,
      showLines: true,
      baseColor: baseColor,
    );
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
