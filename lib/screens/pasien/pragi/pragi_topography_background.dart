import 'package:flutter/material.dart';
import '../../../widgets/giat_background.dart';

/// Topography background painter matching GIAT & PRAGI aesthetic (Figma 1018:5009)
class PragiTopographyPainter extends CustomPainter {
  final Color lineColor;

  PragiTopographyPainter({
    this.lineColor = const Color(0xFF10B981),
  });

  @override
  void paint(Canvas canvas, Size size) {
    GiatBackgroundPainter.paintBackground(
      canvas,
      size,
      showGradient: true,
      showLines: true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
