import 'package:flutter/material.dart';

/// Topography background painter matching GIAT & PRAGI aesthetic
class PragiTopographyPainter extends CustomPainter {
  final Color lineColor;

  PragiTopographyPainter({
    this.lineColor = const Color(0xFF10B981),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Top Wave Contours
    for (int i = 0; i < 6; i++) {
      final path = Path();
      final yOffset = -20.0 + (i * 22.0);
      path.moveTo(-20, yOffset + 40);
      path.quadraticBezierTo(
        size.width * 0.25,
        yOffset + 10,
        size.width * 0.55,
        yOffset + 50,
      );
      path.quadraticBezierTo(
        size.width * 0.85,
        yOffset + 85,
        size.width + 30,
        yOffset + 25,
      );
      canvas.drawPath(path, paint);
    }

    // Bottom Wave Contours
    for (int i = 0; i < 5; i++) {
      final path = Path();
      final yOffset = size.height - 200.0 + (i * 28.0);
      path.moveTo(-20, yOffset + 30);
      path.quadraticBezierTo(
        size.width * 0.35,
        yOffset + 70,
        size.width * 0.65,
        yOffset + 20,
      );
      path.quadraticBezierTo(
        size.width * 0.9,
        yOffset - 15,
        size.width + 30,
        yOffset + 40,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
