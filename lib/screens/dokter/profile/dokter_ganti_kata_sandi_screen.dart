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
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF8FAF9);
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
      const SnackBar(
        content: Text('Kata sandi berhasil diperbarui!'),
        backgroundColor: _darkGreen,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Perbarui Kata Sandi',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gunakan kata sandi yang kuat dengan minimal 8 karakter untuk menjaga keamanan akun GIAT Anda.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 24),

                // Kata Sandi Saat Ini
                _buildLabel('Kata Sandi Saat Ini'),
                TextFormField(
                  controller: _oldPassCtrl,
                  obscureText: _obscureOld,
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureOld ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: const Color(0xFF64748B)),
                      onPressed: () => setState(() => _obscureOld = !_obscureOld),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Kata sandi saat ini wajib diisi' : null,
                ),

                const SizedBox(height: 18),

                // Kata Sandi Baru
                _buildLabel('Kata Sandi Baru'),
                TextFormField(
                  controller: _newPassCtrl,
                  obscureText: _obscureNew,
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    helperText: 'Kata sandi minimal 8 karakter.',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: const Color(0xFF64748B)),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Kata sandi baru wajib diisi';
                    if (v.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Konfirmasi Kata Sandi Baru
                _buildLabel('Konfirmasi Kata Sandi Baru'),
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: const Color(0xFF64748B)),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
                    if (v != _newPassCtrl.text) return 'Konfirmasi kata sandi tidak cocok';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _submit,
                    child: Text(
                      'Perbarui Kata Sandi',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon, String? helperText}) {
    return InputDecoration(
      hintText: hint,
      helperText: helperText,
      helperStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _darkGreen, width: 1.5)),
    );
  }
}
