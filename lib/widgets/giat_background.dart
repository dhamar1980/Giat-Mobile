import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GIAT UNIFIED BACKGROUND (Figma Node 1018:5009)
/// ─────────────────────────────────────────────────────────────────────────────
/// Features:
/// 1. Exact SVG Gradient:
///    - Ellipse 0: cx=155.649, cy=-195.924, rx=321.351, ry=302.076,
///      linear gradient #35FF8A -> #33915B with Gaussian Blur (stdDeviation: 100)
///    - Ellipse 1: cx=45.1344, cy=-78.7778, rx=235.135, ry=221.031,
///      linear gradient #2ECC71 -> #82F7D8 with Gaussian Blur (stdDeviation: 50)
///    - Master group opacity: 0.7
/// 2. Exact SVG Topographic Contour Lines:
///    - 15 organic flowing bezier curves spanning across the top header/background
///    - Stroke color #2ECC71 with opacity 0.135 (0.45 group * 0.30 path opacity)
///    - Proportionally scales to device width (Figma reference width: 402px)
/// 3. Optional bottom waves (for auth/welcome screens)
/// 4. Fixed size support to prevent shifts when keyboard opens
class GiatBackground extends StatelessWidget {
  final Widget? child;
  final Size? fixedSize;
  final bool showBottomWaves;
  final bool showGradient;
  final bool showLines;
  final Color baseColor;

  const GiatBackground({
    super.key,
    this.child,
    this.fixedSize,
    this.showBottomWaves = false,
    this.showGradient = true,
    this.showLines = true,
    this.baseColor = const Color(0xFFF6FAF7),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GiatBackgroundPainter(
        fixedSize: fixedSize,
        showBottomWaves: showBottomWaves,
        showGradient: showGradient,
        showLines: showLines,
        baseColor: baseColor,
      ),
      child: child,
    );
  }
}

/// CustomPainter that renders the exact Figma 1018:5009 background.
class GiatBackgroundPainter extends CustomPainter {
  final Size? fixedSize;
  final bool showBottomWaves;
  final bool showGradient;
  final bool showLines;
  final Color baseColor;

  const GiatBackgroundPainter({
    this.fixedSize,
    this.showBottomWaves = false,
    this.showGradient = true,
    this.showLines = true,
    this.baseColor = const Color(0xFFF6FAF7),
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintBackground(
      canvas,
      size,
      fixedSize: fixedSize,
      showBottomWaves: showBottomWaves,
      showGradient: showGradient,
      showLines: showLines,
      baseColor: baseColor,
    );
  }

  /// Centralized static drawing routine so existing custom painters can
  /// delegate directly without breaking hierarchy or widget trees.
  static void paintBackground(
    Canvas canvas,
    Size size, {
    Size? fixedSize,
    bool showBottomWaves = false,
    bool showGradient = true,
    bool showLines = true,
    Color baseColor = const Color(0xFFF6FAF7),
  }) {
    final effectiveSize = fixedSize ?? size;
    final w = effectiveSize.width;
    final h = effectiveSize.height;

    // 1. Draw base solid canvas
    final bgRect = Offset.zero & effectiveSize;
    canvas.drawRect(bgRect, Paint()..color = baseColor);

    canvas.save();
    canvas.clipRect(bgRect);

    // Scaling factor relative to Figma 402px standard width
    final scale = w / 402.0;

    // ── 2. EXACT FIGMA GRADIENT (SVG Node 1018:5009) ──
    if (showGradient) {
      canvas.save();
      canvas.scale(scale, scale);

      // Ellipse 0: cx=155.649, cy=-195.924, rx=321.351, ry=302.076
      // Gradient flipped 180deg: #35FF8A (opacity 0.925) at top, #33915B at bottom
      final paint0 = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(155.649, -498.0),
          const Offset(155.649, 106.152),
          [
            const Color(0xEB35FF8A).withValues(alpha: 0.7 * 0.92549),
            const Color(0xFF33915B).withValues(alpha: 0.7),
          ],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(155.649, -195.924),
          width: 321.351 * 2,
          height: 302.076 * 2,
        ),
        paint0,
      );

      // Ellipse 1: cx=45.1344, cy=-78.7778, rx=235.135, ry=221.031
      // Gradient #2ECC71 -> #82F7D8
      final paint1 = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(45.1344, -299.809),
          const Offset(45.1344, 142.253),
          [
            const Color(0xFF2ECC71).withValues(alpha: 0.7),
            const Color(0xFF82F7D8).withValues(alpha: 0.7),
          ],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(45.1344, -78.7778),
          width: 235.135 * 2,
          height: 221.031 * 2,
        ),
        paint1,
      );

      canvas.restore();
    }

    // ── 3. EXACT FIGMA TOPOGRAPHIC CONTOUR LINES (SVG Node 1018:5009) ──
    if (showLines) {
      canvas.save();
      canvas.scale(scale, scale);

      final strokePaint = Paint()
        ..color = const Color(0xFF2ECC71).withValues(alpha: 0.135) // 0.45 * 0.30
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // 15 mathematical flowing contour lines from SVG
      for (int i = 0; i < 15; i++) {
        final dx = i * 8.734;
        final dy = i * 17.917;

        final path = Path()
          ..moveTo(712.656 + dx, -348.394 + dy)
          ..cubicTo(662.34 + dx, -323.385 + dy, 648.313 + dx, -352.077 + dy, 598.002 + dx, -327.07 + dy)
          ..cubicTo(547.692 + dx, -302.063 + dy, 561.721 + dx, -273.354 + dy, 511.412 + dx, -248.33 + dy)
          ..cubicTo(461.096 + dx, -223.321 + dy, 447.069 + dx, -252.013 + dy, 396.754 + dx, -227.004 + dy)
          ..cubicTo(346.438 + dx, -201.994 + dy, 360.472 + dx, -173.288 + dy, 310.163 + dx, -148.264 + dy)
          ..cubicTo(259.847 + dx, -123.254 + dy, 245.82 + dx, -151.947 + dy, 195.51 + dx, -126.94 + dy)
          ..cubicTo(145.2 + dx, -101.933 + dy, 159.228 + dx, -73.2237 + dy, 108.92 + dx, -48.2 + dy)
          ..cubicTo(58.6038 + dx, -23.1905 + dy, 44.5768 + dx, -51.883 + dy, -5.73891 + dx, -26.8736 + dy)
          ..cubicTo(-56.0546 + dx, -1.86414 + dy, -42.0206 + dx, 26.8426 + dy, -92.3293 + dx, 51.8664 + dy)
          ..cubicTo(-142.638 + dx, 76.8902 + dy, -156.672 + dx, 48.1834 + dy, -206.988 + dx, 73.1928 + dy)
          ..cubicTo(-257.303 + dx, 98.2023 + dy, -243.268 + dx, 126.926 + dy, -293.589 + dx, 151.938 + dy);

        canvas.drawPath(path, strokePaint);
      }

      canvas.restore();
    }

    // ── 4. OPTIONAL BOTTOM CONTOURS (For Auth/Welcome screens) ──
    if (showBottomWaves) {
      final botWavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round;

      const botWaveColor = Color(0xFF2ECC71);
      final botOpacities = [
        0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20, 0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36
      ];

      for (int i = 0; i < botOpacities.length; i++) {
        botWavePaint.color = botWaveColor.withValues(alpha: botOpacities[i]);
        final y0 = h - 280.0 + (i * 20.0);

        final path = Path()
          ..moveTo(-35, y0 - 12)
          ..cubicTo(
            w * 0.28,
            y0 - 32,
            w * 0.56,
            y0 + 20,
            w * 0.76,
            y0 - 18,
          )
          ..cubicTo(
            w * 0.86,
            y0 - 36,
            w * 0.94,
            y0 - 8,
            w + 35,
            y0 + 10,
          );

        canvas.drawPath(path, botWavePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GiatBackgroundPainter oldDelegate) =>
      oldDelegate.fixedSize != fixedSize ||
      oldDelegate.showBottomWaves != showBottomWaves ||
      oldDelegate.showGradient != showGradient ||
      oldDelegate.showLines != showLines ||
      oldDelegate.baseColor != baseColor;
}
