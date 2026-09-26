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
  final bool? showBottomGradient;
  final bool smallTopGradient;
  final bool showGradient;
  final bool showLines;
  final Color baseColor;

  const GiatBackground({
    super.key,
    this.child,
    this.fixedSize,
    this.showBottomWaves = false,
    this.showBottomGradient,
    this.smallTopGradient = false,
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
        showBottomGradient: showBottomGradient,
        smallTopGradient: smallTopGradient,
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
  final bool? showBottomGradient;
  final bool smallTopGradient;
  final bool showGradient;
  final bool showLines;
  final Color baseColor;

  const GiatBackgroundPainter({
    this.fixedSize,
    this.showBottomWaves = false,
    this.showBottomGradient,
    this.smallTopGradient = false,
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
      showBottomGradient: showBottomGradient,
      smallTopGradient: smallTopGradient,
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
    bool? showBottomGradient,
    bool smallTopGradient = false,
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

      if (smallTopGradient) {
        // Compact top gradient: shifted high so it stays at the top edge
        // and NEVER touches or bleeds down over the logo / kidney badge at y >= 60px
        final paint0Small = Paint()
          ..shader = ui.Gradient.linear(
            const Offset(155.649, -460.0),
            const Offset(155.649, -60.0),
            [
              const Color(0xEB35FF8A).withValues(alpha: 0.7 * 0.92549),
              const Color(0xFF33915B).withValues(alpha: 0.7),
            ],
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(155.649, -260.0),
            width: 200.0 * 2,
            height: 160.0 * 2,
          ),
          paint0Small,
        );

        final paint1Small = Paint()
          ..shader = ui.Gradient.linear(
            const Offset(45.1344, -320.0),
            const Offset(45.1344, -30.0),
            [
              const Color(0xFF2ECC71).withValues(alpha: 0.7),
              const Color(0xFF82F7D8).withValues(alpha: 0.7),
            ],
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(45.1344, -180.0),
            width: 150.0 * 2,
            height: 120.0 * 2,
          ),
          paint1Small,
        );
      } else {
        // Standard full top gradient
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
      }

      // ── BOTTOM-RIGHT GRADIENT (Luminous Mint/Emerald Aura at Bottom-Right) ──
      final hasBottomGradient = showBottomGradient ?? showBottomWaves;
      if (hasBottomGradient) {
        final screenH = h / scale;

        // Bottom Right Ellipse 0
        final paintBR0 = Paint()
          ..shader = ui.Gradient.linear(
            Offset(402.0 - 100.0, screenH + 200.0),
            Offset(402.0 - 100.0, screenH - 220.0),
            [
              const Color(0xEB35FF8A).withValues(alpha: 0.65 * 0.92549),
              const Color(0xFF33915B).withValues(alpha: 0.65),
            ],
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(402.0 - 100.0, screenH - 20.0),
            width: 240.0 * 2,
            height: 220.0 * 2,
          ),
          paintBR0,
        );

        // Bottom Right Ellipse 1
        final paintBR1 = Paint()
          ..shader = ui.Gradient.linear(
            Offset(402.0 - 30.0, screenH + 150.0),
            Offset(402.0 - 30.0, screenH - 160.0),
            [
              const Color(0xFF2ECC71).withValues(alpha: 0.65),
              const Color(0xFF82F7D8).withValues(alpha: 0.65),
            ],
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 55);

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(402.0 - 30.0, screenH + 20.0),
            width: 180.0 * 2,
            height: 160.0 * 2,
          ),
          paintBR1,
        );
      }

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

    // ── 4. EXACT FIGMA BOTTOM CONTOURS (15 SVG Lines rotated 180° for Welcome/Auth) ──
    if (showBottomWaves) {
      canvas.save();
      canvas.scale(scale, scale);

      final botStrokePaint = Paint()
        ..color = const Color(0xFF2ECC71).withValues(alpha: 0.135)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final screenH = h / scale;
      const shiftY = 85.0;
      final yBase = screenH - shiftY;

      // 15 mathematical flowing contour lines rotated 180° and anchored to span the full bottom area
      for (int i = 0; i < 15; i++) {
        final dx = i * 8.734;
        final dy = i * 17.917;

        final path = Path()
          ..moveTo(402.0 - (712.656 + dx), yBase - (-348.394 + dy))
          ..cubicTo(
            402.0 - (662.34 + dx), yBase - (-323.385 + dy),
            402.0 - (648.313 + dx), yBase - (-352.077 + dy),
            402.0 - (598.002 + dx), yBase - (-327.07 + dy),
          )
          ..cubicTo(
            402.0 - (547.692 + dx), yBase - (-302.063 + dy),
            402.0 - (561.721 + dx), yBase - (-273.354 + dy),
            402.0 - (511.412 + dx), yBase - (-248.33 + dy),
          )
          ..cubicTo(
            402.0 - (461.096 + dx), yBase - (-223.321 + dy),
            402.0 - (447.069 + dx), yBase - (-252.013 + dy),
            402.0 - (396.754 + dx), yBase - (-227.004 + dy),
          )
          ..cubicTo(
            402.0 - (346.438 + dx), yBase - (-201.994 + dy),
            402.0 - (360.472 + dx), yBase - (-173.288 + dy),
            402.0 - (310.163 + dx), yBase - (-148.264 + dy),
          )
          ..cubicTo(
            402.0 - (259.847 + dx), yBase - (-123.254 + dy),
            402.0 - (245.82 + dx), yBase - (-151.947 + dy),
            402.0 - (195.51 + dx), yBase - (-126.94 + dy),
          )
          ..cubicTo(
            402.0 - (145.2 + dx), yBase - (-101.933 + dy),
            402.0 - (159.228 + dx), yBase - (-73.2237 + dy),
            402.0 - (108.92 + dx), yBase - (-48.2 + dy),
          )
          ..cubicTo(
            402.0 - (58.6038 + dx), yBase - (-23.1905 + dy),
            402.0 - (44.5768 + dx), yBase - (-51.883 + dy),
            402.0 - (-5.73891 + dx), yBase - (-26.8736 + dy),
          )
          ..cubicTo(
            402.0 - (-56.0546 + dx), yBase - (-1.86414 + dy),
            402.0 - (-42.0206 + dx), yBase - (26.8426 + dy),
            402.0 - (-92.3293 + dx), yBase - (51.8664 + dy),
          )
          ..cubicTo(
            402.0 - (-142.638 + dx), yBase - (76.8902 + dy),
            402.0 - (-156.672 + dx), yBase - (48.1834 + dy),
            402.0 - (-206.988 + dx), yBase - (73.1928 + dy),
          )
          ..cubicTo(
            402.0 - (-257.303 + dx), yBase - (98.2023 + dy),
            402.0 - (-243.268 + dx), yBase - (126.926 + dy),
            402.0 - (-293.589 + dx), yBase - (151.938 + dy),
          );

        canvas.drawPath(path, botStrokePaint);
      }

      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GiatBackgroundPainter oldDelegate) =>
      oldDelegate.fixedSize != fixedSize ||
      oldDelegate.showBottomWaves != showBottomWaves ||
      oldDelegate.showBottomGradient != showBottomGradient ||
      oldDelegate.smallTopGradient != smallTopGradient ||
      oldDelegate.showGradient != showGradient ||
      oldDelegate.showLines != showLines ||
      oldDelegate.baseColor != baseColor;
}
