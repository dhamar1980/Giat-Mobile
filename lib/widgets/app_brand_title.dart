import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// APP BRAND TITLE ("GINJAL SEHAT")
// Ditampilkan di pojok kiri atas header (di atas kiri bubble chat)
// ─────────────────────────────────────────────────────────────────────────────

class AppBrandTitle extends StatelessWidget {
  final double fontSize;

  const AppBrandTitle({
    super.key,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'GINJAL SEHAT',
      style: GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 0.8,
        height: 1.0,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 1.5),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
