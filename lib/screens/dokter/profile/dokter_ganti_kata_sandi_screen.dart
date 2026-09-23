import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GANTI KATA SANDI DOKTER (Figma Node: 1008-18794)
// ─────────────────────────────────────────────────────────────────────────────

class DokterGantiKataSandiScreen extends StatefulWidget {
  const DokterGantiKataSandiScreen({super.key});

  @override
  State<DokterGantiKataSandiScreen> createState() => _DokterGantiKataSandiScreenState();
}

class _DokterGantiKataSandiScreenState extends State<DokterGantiKataSandiScreen> {
  static const _darkGreen = Color(0xFF044E2F);
  static const _redAlert = Color(0xFFB91C1C);
  static const _border = Color(0xFFE2E8F0);

  final _formKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Kata sandi berhasil diperbarui!',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: Stack(
        children: [
          // Background Topography
          Positioned.fill(
            child: CustomPaint(
              painter: _GantiSandiTopographyPainter(),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top Navigation Row (<- Kembali) ──
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back, size: 15, color: Color(0xFF0F172A)),
                            const SizedBox(width: 5),
                            Text(
                              'Kembali',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Pill Title: Perbarui Kata Sandi ──
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
                        decoration: BoxDecoration(
                          color: _darkGreen,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _darkGreen.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Perbarui Kata Sandi',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Red Info Alert Row (Screenshot) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info,
                          color: _redAlert,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gunakan kata sandi yang kuat dengan minimal 8 karakter untuk menjaga keamanan akun GIAT Anda.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: _redAlert,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Section Title: Ganti Kata Sandi ──
                    Text(
                      'Ganti Kata Sandi',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Card Form Ganti Kata Sandi ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.025),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kata Sandi Saat Ini
                          _buildLabel('Kata Sandi Saat Ini'),
                          TextFormField(
                            controller: _oldPassCtrl,
                            obscureText: _obscureOld,
                            decoration: _inputDecoration(
                              hint: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureOld ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: const Color(0xFF64748B),
                                ),
                                onPressed: () => setState(() => _obscureOld = !_obscureOld),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Kata sandi saat ini wajib diisi' : null,
                          ),

                          const SizedBox(height: 16),

                          // Kata Sandi Baru
                          _buildLabel('Kata Sandi Baru'),
                          TextFormField(
                            controller: _newPassCtrl,
                            obscureText: _obscureNew,
                            decoration: _inputDecoration(
                              hint: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: const Color(0xFF64748B),
                                ),
                                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Kata sandi baru wajib diisi';
                              if (v.length < 8) return 'Minimal 8 karakter';
                              return null;
                            },
                          ),

                          const SizedBox(height: 8),

                          // Info text: Kata sandi minimal 8 karakter.
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'Kata sandi minimal 8 karakter.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Konfirmasi Kata Sandi Baru
                          _buildLabel('Konfirmasi Kata Sandi Baru'),
                          TextFormField(
                            controller: _confirmPassCtrl,
                            obscureText: _obscureConfirm,
                            decoration: _inputDecoration(
                              hint: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: const Color(0xFF64748B),
                                ),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
                              if (v != _newPassCtrl.text) return 'Konfirmasi kata sandi tidak cocok';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit Button: Perbarui Kata Sandi
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: _submit,
                        child: Text(
                          'Perbarui Kata Sandi',
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8), letterSpacing: 2),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _darkGreen, width: 1.5)),
    );
  }
}

class _GantiSandiTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;

    const baseColor = Color(0xFF10B981);
    final opacities = [0.06, 0.08, 0.10, 0.12, 0.09, 0.07];

    // Top subtle waves
    for (int i = 0; i < opacities.length; i++) {
      wavePaint.color = baseColor.withValues(alpha: opacities[i]);
      final y0 = (h * 0.08) + (i * 28.0);

      final path = Path()
        ..moveTo(-30, y0)
        ..cubicTo(
          w * 0.30,
          y0 - 24,
          w * 0.65,
          y0 + 35,
          w + 30,
          y0 - 15,
        );

      canvas.drawPath(path, wavePaint);
    }

    // Bottom subtle waves
    for (int i = 0; i < opacities.length; i++) {
      wavePaint.color = baseColor.withValues(alpha: opacities[i]);
      final y0 = (h * 0.62) + (i * 35.0);

      final path = Path()
        ..moveTo(-20, y0)
        ..cubicTo(
          w * 0.40,
          y0 + 35,
          w * 0.70,
          y0 - 35,
          w + 40,
          y0 + 15,
        );

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

