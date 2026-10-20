import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GIAT HEADER STYLE & CURVE OVERLAY (Unified Design System)
/// ─────────────────────────────────────────────────────────────────────────────
/// Menjamin seluruh tampilan header berlatar hijau di semua role (Pasien, Dokter, Apotek)
/// memiliki warna gradien hijau, kurva gelombang, dan kelengkungan yang 100% konsisten.
class GiatHeaderStyle {
  // Signature GIAT Header Linear Gradient (Top to Bottom)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF22C55E), // Fresh green top
      Color(0xFF16A34A), // Vibrant emerald mid
      Color(0xFF0D7A3E), // Deep rich forest green bottom
    ],
  );

  // Border radius standar 36px untuk sudut bawah kiri & kanan
  static const BorderRadius borderRadius = BorderRadius.only(
    bottomLeft: Radius.circular(36),
    bottomRight: Radius.circular(36),
  );

  // Box decoration header utama
  static BoxDecoration get headerDecoration => const BoxDecoration(
    gradient: backgroundGradient,
    borderRadius: borderRadius,
  );

  // Warna tema bubble chat
  static const Color chatBubbleGreen = Color(0xFF006D37);
  static const Color chatBubbleTextSecondary = Color(0xE6006D37); // alpha: 0.9

  // Box decoration bubble chat yang seragam & konsisten
  static BoxDecoration get chatBubbleDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(16),
      bottomLeft: Radius.circular(4),
    ),
    border: Border.all(
      color: chatBubbleGreen,
      width: 1.0,
    ),
    boxShadow: [
      BoxShadow(
        color: chatBubbleGreen.withValues(alpha: 0.18),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

/// CustomPainter untuk garis kurva organik putih transparan pada header hijau GIAT
class GiatHeaderCurvePainter extends CustomPainter {
  const GiatHeaderCurvePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final yOffset = 40.0 + (i * 40);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.25,
        yOffset + 30,
        size.width * 0.75,
        yOffset - 30,
        size.width,
        yOffset + 20,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget helper pembungkus garis kurva header yang ter-clip rapi sesuai radius
class GiatHeaderCurvesOverlay extends StatelessWidget {
  const GiatHeaderCurvesOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: GiatHeaderStyle.borderRadius,
        child: const CustomPaint(
          painter: GiatHeaderCurvePainter(),
        ),
      ),
    );
  }
}
