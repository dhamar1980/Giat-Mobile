import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'apotek_status_layanan_screen.dart';
import 'apotek_jam_operasional_screen.dart';
import 'apotek_area_layanan_screen.dart';
import 'apotek_riwayat_aktivitas_screen.dart';
import 'apotek_pusat_bantuan_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PROFIL UTAMA APOTEK (Revisi Sesuai Screenshot Mockup Figma)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekProfileScreen extends StatefulWidget {
  final String apotekerName;
  final VoidCallback? onLogout;
  final bool showBackButton;

  const ApotekProfileScreen({
    super.key,
    this.apotekerName = 'Apt. Aminah, S.Farm',
    this.onLogout,
    this.showBackButton = false,
  });

  @override
  State<ApotekProfileScreen> createState() => _ApotekProfileScreenState();
}

class _ApotekProfileScreenState extends State<ApotekProfileScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF7FAF8);
  static const _border = Color(0xFFE2E8F0);

  String _avatarType = 'asset'; // 'asset', 'network', 'default'
  String _avatarPath = 'assets/images/dokter_apoteker.jpg';

  final List<Map<String, String>> _presetAvatars = [
    {
      'name': 'Apt. Aminah (Resmi)',
      'path': 'assets/images/dokter_apoteker.jpg',
      'type': 'asset',
    },
    {
      'name': 'Apt. Sarah (Farmasi)',
      'path': 'assets/images/sarah_amelia.jpg',
      'type': 'asset',
    },
    {
      'name': 'Apt. Rina',
      'path': 'https://images.unsplash.com/photo-1594824813629-87a70197d19a?auto=format&fit=crop&q=80&w=300',
      'type': 'network',
    },
    {
      'name': 'Apt. Budi',
      'path': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300',
      'type': 'network',
    },
    {
      'name': 'Apt. Diana',
      'path': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300',
      'type': 'network',
    },
  ];

  Widget _buildAvatarImage() {
    if (_avatarType == 'default') {
      return Container(
        color: const Color(0xFFDCFCE7),
        child: const Center(
          child: Icon(Icons.local_pharmacy_rounded, size: 52, color: _darkGreen),
        ),
      );
    } else if (_avatarType == 'network') {
      return Image.network(
        _avatarPath,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          color: const Color(0xFFDCFCE7),
          child: const Center(
            child: Icon(Icons.person_rounded, size: 52, color: _darkGreen),
          ),
        ),
      );
    } else {
      return Image.asset(
        _avatarPath,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Container(
          color: const Color(0xFF044E2F),
          child: const Center(
            child: Icon(Icons.person_rounded, size: 52, color: Colors.white),
          ),
        ),
      );
    }
  }

  void _showChangeProfilePhotoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
              'Ganti Foto Profil Apoteker',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih foto profil apoteker yang jelas dan profesional',
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
                  _avatarPath = 'assets/images/dokter_apoteker.jpg';
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
                  _avatarType = 'network';
                  _avatarPath = 'https://images.unsplash.com/photo-1594824813629-87a70197d19a?auto=format&fit=crop&q=80&w=300';
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

            // Action: Avatar Preset
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 10, left: 8),
              child: Text(
                'Pilihan Avatar Apoteker',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _presetAvatars.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, idx) {
                  final item = _presetAvatars[idx];
                  final isSelected = _avatarPath == item['path'];

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
                            'Avatar ${item['name']} berhasil diterapkan!',
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
                  _avatarPath = '';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Foto profil berhasil dihapus (avatar bawaan)',
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

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar dari Akun Apoteker',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari sesi apoteker saat ini?',
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.onLogout != null) {
                widget.onLogout!();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text('Keluar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Stack(
          children: [
            // Topography lines watermark in background
            Positioned.fill(
              child: CustomPaint(
                painter: _ProfileTopographyPainter(),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Organic Curved Green Header (Fixed at top, does not scroll)
                _buildHeader(context),

                // Scrollable content below pinned header
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.only(bottom: 36),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          // Card Jam Operasional & Area Layanan
                          _buildOperationalCard(),

                          const SizedBox(height: 22),

                          // Section 1: Pengaturan Layanan & Keamanan
                          _buildSettingsSection(),

                          const SizedBox(height: 22),

                          // Section 2: Akun
                          _buildAccountSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER SECTION (Mockup: Green gradient, curved edge & circular avatar)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return ClipPath(
      clipper: _ProfileHeaderOrganicClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF22C55E),
              Color(0xFF10B981),
              Color(0xFF0F7644),
              Color(0xFF065A37),
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _HeaderWaveOverlayPainter(),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Navigation Row: Back button (if enabled) & "✏️ Edit" pill button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (widget.showBackButton && Navigator.of(context).canPop())
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
                          )
                        else
                          const SizedBox.shrink(),

                        // Tombol "✏️ Edit"
                        GestureDetector(
                          onTap: () => _showChangeProfilePhotoModal(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
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
                                const Icon(Icons.edit, size: 13, color: Color(0xFF0F172A)),
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

                    const SizedBox(height: 12),

                    // Circular Avatar with White Border & Camera Edit Badge
                    GestureDetector(
                      onTap: () => _showChangeProfilePhotoModal(context),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
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

                    const SizedBox(height: 14),

                    // Name
                    Text(
                      widget.apotekerName,
                      style: GoogleFonts.inter(
                        fontSize: 19.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // Subtitle / Role
                    Text(
                      'Petugas Apotek',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w500,
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

  // ───────────────────────────────────────────────────────────────────────────
  // OPERATIONAL INFORMATION CARD (Jam Operasional & Area Layanan)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOperationalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Jam Operasional
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ApotekJamOperasionalScreen()),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 19,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Jam Operasional',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 27),
                    child: Text(
                      '08.00 - 21.00',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Area Layanan
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ApotekAreaLayananScreen()),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 19,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Area Layanan',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 27),
                    child: Text(
                      'Malang',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PENGATURAN LAYANAN & KEAMANAN SECTION
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pengaturan Layanan & Keamanan'),
        const SizedBox(height: 10),

        // Card 1: Status Layanan
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ApotekStatusLayananScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _buttonDarkGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.vpn_key_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Status Layanan',
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
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Card 2: Riwayat Aktivitas & Pusat Bantuan
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                // Riwayat Aktivitas
                InkWell(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ApotekRiwayatAktivitasScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _buttonDarkGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(Icons.description_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Riwayat Aktivitas',
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
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),

                // Pusat Bantuan
                InkWell(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ApotekPusatBantuanScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _buttonDarkGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(Icons.help_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Pusat Bantuan',
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
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // AKUN SECTION (Keluar)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Akun'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _showLogoutConfirmation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFDC2626),
                      size: 24,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM CLIPPERS & PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

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
    final opacities = [0.06, 0.08, 0.10, 0.12, 0.09, 0.07];

    for (int i = 0; i < opacities.length; i++) {
      wavePaint.color = baseColor.withValues(alpha: opacities[i]);
      final y0 = (h * 0.28) + (i * 42.0);

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
