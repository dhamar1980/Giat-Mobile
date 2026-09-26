import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../syarat_ketentuan_screen.dart';
import '../../../kebijakan_privasi_screen.dart';
import '../../../login_screen.dart';
import 'kata_sandi_keamanan_screen.dart';
import 'edit_informasi_pribadi_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROFIL PASIEN - GIAT HEALTHCARE
// ─────────────────────────────────────────────────────────────────────────────

class ProfilePasienScreen extends StatefulWidget {
  final String userName;

  const ProfilePasienScreen({
    super.key,
    this.userName = 'Sarah Amelia',
  });

  @override
  State<ProfilePasienScreen> createState() => _ProfilePasienScreenState();
}

class _ProfilePasienScreenState extends State<ProfilePasienScreen> {
  static const _darkGreen = Color(0xFF065A37);

  late String _nama;
  late String _email;
  late String _tanggalLahir;
  late String _jenisKelamin;
  late String _golonganDarah;
  late String _alamat;

  String _avatarType = 'asset'; // 'asset', 'network', 'default'
  String _avatarPath = 'assets/images/sarah_amelia.jpg';

  final List<Map<String, String>> _presetAvatars = [
    {
      'name': 'Sarah (Medis)',
      'path': 'assets/images/sarah_amelia.jpg',
      'type': 'asset',
    },
    {
      'name': 'Dokter Siti',
      'path': 'https://images.unsplash.com/photo-1594824813629-87a70197d19a?auto=format&fit=crop&q=80&w=300',
      'type': 'network',
    },
    {
      'name': 'Dokter Andi',
      'path': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300',
      'type': 'network',
    },
    {
      'name': 'Rina (Pasien)',
      'path': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=300',
      'type': 'network',
    },
    {
      'name': 'Maya (Pasien)',
      'path': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300',
      'type': 'network',
    },
  ];

  @override
  void initState() {
    super.initState();
    _nama = widget.userName.isNotEmpty && widget.userName != 'Pasien'
        ? widget.userName
        : 'Sarah Amelia';
    _email = 'sarah.amelia@Gmail.com';
    _tanggalLahir = '12 Mei 1985';
    _jenisKelamin = 'Perempuan';
    _golonganDarah = 'O Positif (O+)';
    _alamat = 'Jl. Merdeka No. 123, Jakarta\nSelatan';
  }

  Future<void> _navigateToEditInformasiPribadi() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditInformasiPribadiScreen(
          currentName: _nama,
          currentBirthDate: _tanggalLahir,
          currentGender: _jenisKelamin,
          currentAddress: _alamat,
          currentBloodType: _golonganDarah,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (result['name'] != null && result['name']!.isNotEmpty) {
          _nama = result['name']!;
        }
        if (result['birthDate'] != null && result['birthDate']!.isNotEmpty) {
          _tanggalLahir = result['birthDate']!;
        }
        if (result['gender'] != null && result['gender']!.isNotEmpty) {
          _jenisKelamin = result['gender']!;
        }
        if (result['address'] != null && result['address']!.isNotEmpty) {
          _alamat = result['address']!;
        }
        if (result['bloodType'] != null && result['bloodType']!.isNotEmpty) {
          _golonganDarah = result['bloodType']!;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Informasi pribadi & kesehatan berhasil disimpan!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _darkGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showChangeProfilePhotoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Ganti Foto Profil',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih sumber foto atau pilih karakter avatar profil Anda.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            // Action: Kamera
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: _darkGreen, size: 22),
              ),
              title: Text(
                'Ambil Foto dari Kamera',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _avatarType = 'asset';
                  _avatarPath = 'assets/images/sarah_amelia.jpg';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Foto profil berhasil diperbarui dari kamera!',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: _darkGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Action: Galeri
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF4338CA), size: 22),
              ),
              title: Text(
                'Pilih dari Galeri Foto',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _avatarType = 'asset';
                  _avatarPath = 'assets/images/sarah_amelia.jpg';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Foto profil berhasil dipilih dari galeri!',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: _darkGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Pilihan Avatar Siap Pakai
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 10, left: 8),
              child: Text(
                'Pilih Avatar Karakter',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _presetAvatars.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final item = _presetAvatars[index];
                  final isSelected = _avatarPath == item['path'] && _avatarType == item['type'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _avatarType = item['type']!;
                        _avatarPath = item['path']!;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Avatar "${item['name']}" berhasil dipasang!',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: _darkGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? _darkGreen : const Color(0xFFE2E8F0),
                          width: isSelected ? 3 : 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: item['type'] == 'asset'
                            ? Image.asset(item['path']!, fit: BoxFit.cover)
                            : Image.network(
                                item['path']!,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: const Color(0xFFDCFCE7),
                                  child: const Icon(Icons.person, color: _darkGreen),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Action: Hapus Foto Profil
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
              ),
              title: Text(
                'Hapus Foto Profil',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626),
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _avatarType = 'default';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Foto profil berhasil dihapus (menggunakan avatar bawaan)',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (_avatarType == 'default') {
      return Container(
        color: const Color(0xFFDCFCE7),
        child: const Icon(
          Icons.person_rounded,
          size: 56,
          color: _darkGreen,
        ),
      );
    } else if (_avatarType == 'network') {
      return Image.network(
        _avatarPath,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          color: const Color(0xFFDCFCE7),
          child: const Icon(Icons.person_rounded, size: 56, color: _darkGreen),
        ),
      );
    } else {
      return Image.asset(
        _avatarPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            'https://images.unsplash.com/photo-1594824813629-87a70197d19a?auto=format&fit=crop&q=80&w=300',
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(
              color: const Color(0xFFDCFCE7),
              child: const Icon(Icons.person_rounded, size: 56, color: _darkGreen),
            ),
          );
        },
      );
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar dari Akun',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Pasien?',
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
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      body: Stack(
        children: [
          // Background subtle wave contour painter
          Positioned.fill(
            child: CustomPaint(
              painter: _ProfileTopographyPainter(),
            ),
          ),

          // Pinned Header and Scrollable Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Organic Curved Green Header (Fixed at top, does not scroll)
              _buildHeader(topPadding),

              // Scrollable Profile Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),

                      // 1. Ringkasan Kesehatan
                      _buildSectionTitle('Ringkasan Kesehatan'),
                      _buildRingkasanKesehatanCard(),

                      const SizedBox(height: 24),

                      // 2. Informasi Pribadi & Kesehatan
                      _buildSectionTitle('Informasi Pribadi & Kesehatan'),
                      _buildInformasiPribadiCard(),

                      const SizedBox(height: 24),

                      // 3. Pengaturan Akun & Keamanan
                      _buildSectionTitle('Pengaturan Akun & Keamanan'),
                      _buildPengaturanAkunCards(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WIDGET BUILDERS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(double topPadding) {
    return ClipPath(
      clipper: _ProfileHeaderOrganicClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF22C55E), // Vibrant lime/emerald green
              Color(0xFF10B981), // Mint emerald
              Color(0xFF0F7644), // Mid deep forest green
              Color(0xFF065A37), // GIAT deep green
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative organic wave overlay in bottom-left
            Positioned.fill(
              child: CustomPaint(
                painter: _HeaderWaveOverlayPainter(),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
                child: Column(
                  children: [
                    // Top Navigation Row: "Kembali" pill & "Edit" pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tombol "<- Kembali"
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7.5,
                            ),
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
                                const Icon(
                                  Icons.arrow_back,
                                  size: 15,
                                  color: Color(0xFF0F172A),
                                ),
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

                        // Tombol "✏️ Edit"
                        GestureDetector(
                          onTap: _showChangeProfilePhotoModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24), // Vibrant golden amber
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.edit,
                                  size: 13,
                                  color: Color(0xFF0F172A),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Edit',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Avatar Circle with White Border & Camera Edit Badge
                    GestureDetector(
                      onTap: _showChangeProfilePhotoModal,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 106,
                            height: 106,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _buildAvatarImage(),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(6.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // User Name
                    Text(
                      _nama,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 3),

                    // User Email
                    Text(
                      _email,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildRingkasanKesehatanCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Status Kesehatan Ginjal
          Text(
            'Status Kesehatan Ginjal',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Stabil',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. Konsultasi Terakhir
          Text(
            'Konsultasi Terakhir',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '12 Okt 2023',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 18),

          // 3. Pengingat Berikutnya
          Text(
            'Pengingat Berikutnya',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Obat - 20:00',
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformasiPribadiCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _navigateToEditInformasiPribadi,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              children: [
                _buildPersonalItem(
                  icon: Icons.cake_outlined,
                  label: 'Tanggal Lahir',
                  value: _tanggalLahir,
                ),
                const SizedBox(height: 16),
                _buildPersonalItem(
                  icon: Icons.wc_rounded,
                  label: 'Jenis Kelamin',
                  value: _jenisKelamin,
                ),
                const SizedBox(height: 16),
                _buildPersonalItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Golongan Darah',
                  value: _golonganDarah,
                ),
                const SizedBox(height: 16),
                _buildPersonalItem(
                  icon: Icons.home_rounded,
                  label: 'Alamat',
                  value: _alamat,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _darkGreen,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPengaturanAkunCards() {
    return Column(
      children: [
        // 1. Kata Sandi & Keamanan Card
        Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KataSandiKeamananScreen(
                      userName: _nama,
                      initialEmail: _email,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _darkGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.vpn_key_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Kata Sandi & Keamanan',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
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
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Kebijakan Privasi & Syarat Ketentuan Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Kebijakan Privasi
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const KebijakanPrivasiScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _darkGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.privacy_tip_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Kebijakan Privasi',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
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
                ),
              ),
              const Divider(height: 1, indent: 74, color: Color(0xFFF1F5F9)),
              // Syarat & Ketentuan
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SyaratKetentuanScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _darkGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.description_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Syarat & Ketentuan',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
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
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Keluar (Logout) Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _handleLogout(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFDC2626),
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Keluar',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM CLIPPERS & PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

/// Clipper for the organic curved green header
class _ProfileHeaderOrganicClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 38);

    // Organic wavy curve matching the design mockup
    path.cubicTo(
      size.width * 0.28,
      size.height + 16,
      size.width * 0.72,
      size.height + 12,
      size.width,
      size.height - 30,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Subtle overlay wave inside the green header (bottom-left)
class _HeaderWaveOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.45);
    path.cubicTo(
      size.width * 0.35,
      size.height * 0.55,
      size.width * 0.20,
      size.height * 0.85,
      0,
      size.height - 30,
    );
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = const Color(0xFF34D399).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.cubicTo(
      size.width * 0.40,
      size.height * 0.75,
      size.width * 0.15,
      size.height * 0.95,
      0,
      size.height,
    );
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for the subtle topographic wave lines on the screen background
class _ProfileTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;

    const baseColor = Color(0xFF10B981);

    // Subtle wave contour lines across the middle and lower right
    final opacities = [0.06, 0.08, 0.10, 0.12, 0.09, 0.07];

    for (int i = 0; i < opacities.length; i++) {
      wavePaint.color = baseColor.withValues(alpha: opacities[i]);
      final y0 = (h * 0.42) + (i * 38.0);

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
