import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../onboarding_screen.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/giat_header_style.dart';
import '../models/admin_models.dart';
import '../widgets/admin_header.dart';

class AdminProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const AdminProfileScreen({
    super.key,
    this.onLogout,
  });

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF7FAF8);
  static const _border = Color(0xFFE2E8F0);

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? const Color(0xFFDC2626) : _darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          msg,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showEditProfileSheet() {
    final store = AdminStore.instance;
    final namaCtrl = TextEditingController(text: store.adminNama);
    final emailCtrl = TextEditingController(text: store.adminEmail);
    final noHpCtrl = TextEditingController(text: store.adminNoHp);
    final jabatanCtrl = TextEditingController(text: store.adminJabatan);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Edit Informasi Profil Admin',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildInputField(
                    controller: namaCtrl,
                    label: 'Nama Admin',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: jabatanCtrl,
                    label: 'Jabatan',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: emailCtrl,
                    label: 'Email Admin',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildInputField(
                    controller: noHpCtrl,
                    label: 'Nomor Telepon',
                    icon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonDarkGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          store.adminNama = namaCtrl.text.trim().isEmpty
                              ? store.adminNama
                              : namaCtrl.text.trim();
                          store.adminJabatan = jabatanCtrl.text.trim().isEmpty
                              ? store.adminJabatan
                              : jabatanCtrl.text.trim();
                          store.adminEmail = emailCtrl.text.trim().isEmpty
                              ? store.adminEmail
                              : emailCtrl.text.trim();
                          store.adminNoHp = noHpCtrl.text.trim().isEmpty
                              ? store.adminNoHp
                              : noHpCtrl.text.trim();
                        });
                        Navigator.pop(ctx);
                        _showSnack('Profil Admin berhasil diperbarui!');
                      },
                      child: Text(
                        'Simpan Perubahan',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordSheet() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubah Kata Sandi Admin',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                _buildInputField(
                  controller: oldPassCtrl,
                  label: 'Kata Sandi Saat Ini',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: newPassCtrl,
                  label: 'Kata Sandi Baru',
                  icon: Icons.key_rounded,
                  obscure: true,
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: confirmPassCtrl,
                  label: 'Konfirmasi Kata Sandi Baru',
                  icon: Icons.verified_user_outlined,
                  obscure: true,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _buttonDarkGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (newPassCtrl.text.length < 6) {
                        _showSnack(
                          'Kata sandi baru minimal 6 karakter',
                          isError: true,
                        );
                        return;
                      }
                      if (newPassCtrl.text != confirmPassCtrl.text) {
                        _showSnack(
                          'Konfirmasi kata sandi tidak cocok',
                          isError: true,
                        );
                        return;
                      }
                      Navigator.pop(ctx);
                      _showSnack('Kata sandi Admin berhasil diperbarui!');
                    },
                    child: Text(
                      'Perbarui Kata Sandi',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar dari Akun Admin',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari panel Administrator GIAT?',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (widget.onLogout != null) {
                widget.onLogout!();
              } else {
                await AuthService().logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                }
              }
            },
            child: Text(
              'Keluar',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 19, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _darkGreen, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    final topPadding = MediaQuery.of(context).padding.top;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _bgColor,
          body: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: AdminTopographyPainter()),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Hijau Melengkung Profil Admin
                  Container(
                    width: double.infinity,
                    decoration: GiatHeaderStyle.headerDecoration,
                    child: Stack(
                      children: [
                        const GiatHeaderCurvesOverlay(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            topPadding + 12,
                            20,
                            26,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Material(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () =>
                                          Navigator.of(context).maybePop(),
                                      child: const Padding(
                                        padding: EdgeInsets.all(9),
                                        child: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Profil Administrator',
                                    style: GoogleFonts.inter(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF044E2F),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.admin_panel_settings_rounded,
                                    size: 44,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                store.adminNama,
                                style: GoogleFonts.inter(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${store.adminJabatan} • ${store.adminEmail}',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Text(
                                  'Akses Penuh Sistem GIAT',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ringkasan Sistem
                          Row(
                            children: [
                              _buildMiniStat(
                                '${store.totalAccounts}',
                                'Total Akun',
                                Icons.people_alt_outlined,
                              ),
                              const SizedBox(width: 10),
                              _buildMiniStat(
                                '${store.edukasi.length}',
                                'Artikel Edukasi',
                                Icons.menu_book_outlined,
                              ),
                              const SizedBox(width: 10),
                              _buildMiniStat(
                                '${store.updates.length}',
                                'Update Sistem',
                                Icons.system_update_alt_rounded,
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          _buildSectionTitle('Pengaturan Profil Admin'),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              children: [
                                _buildMenuTile(
                                  icon: Icons.person_outline_rounded,
                                  title: 'Informasi Profil Admin',
                                  subtitle: 'Ubah nama, email, nomor HP & jabatan',
                                  onTap: _showEditProfileSheet,
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: Color(0xFFF1F5F9),
                                ),
                                _buildMenuTile(
                                  icon: Icons.shield_outlined,
                                  title: 'Keamanan & Kata Sandi',
                                  subtitle: 'Perbarui kata sandi akun administrator',
                                  onTap: _showChangePasswordSheet,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          _buildSectionTitle('Akun'),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _border),
                            ),
                            child: _buildMenuTile(
                              icon: Icons.logout_rounded,
                              title: 'Keluar dari Akun Admin',
                              subtitle: 'Akhiri sesi administrator saat ini',
                              iconColor: const Color(0xFFDC2626),
                              titleColor: const Color(0xFFDC2626),
                              onTap: _showLogoutDialog,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Icon(icon, color: _darkGreen, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF475569),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = _darkGreen,
    Color titleColor = const Color(0xFF0F172A),
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

