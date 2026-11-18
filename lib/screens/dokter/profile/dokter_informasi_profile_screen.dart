import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../models/user_model.dart';
import '../../../services/dokter_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/jember_location_service.dart';
import '../../../widgets/giat_real_map_widget.dart';
import '../../../config/api_config.dart';
import '../models/dokter_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// INFORMASI PROFILE DOKTER (Figma Node: 1008-19748 / Screenshot 3 & 4)
// ─────────────────────────────────────────────────────────────────────────────

class DokterInformasiProfileScreen extends StatefulWidget {
  final String? doctorName;
  final String? specialty;

  const DokterInformasiProfileScreen({
    super.key,
    this.doctorName,
    this.specialty,
  });

  @override
  State<DokterInformasiProfileScreen> createState() => _DokterInformasiProfileScreenState();
}

class _DokterInformasiProfileScreenState extends State<DokterInformasiProfileScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    if (widget.doctorName != null && widget.doctorName!.isNotEmpty) {
      DokterProfileState.instance.syncFromUser(
        name: widget.doctorName,
        spec: widget.specialty,
      );
    }
    DokterProfileState.instance.loadProfile(fallbackName: widget.doctorName);
  }

  Future<void> _showEditProfileDialog(DokterProfileState profileState) async {
    final namaCtrl = TextEditingController(text: profileState.doctorName);
    final specCtrl = TextEditingController(text: profileState.specialty);
    final strCtrl = TextEditingController(text: profileState.strNumber);
    final sipCtrl = TextEditingController(text: profileState.sipNumber);
    final instCtrl = TextEditingController(text: profileState.institution);
    final addrCtrl = TextEditingController(text: profileState.practiceAddress);
    final schedCtrl = TextEditingController(text: profileState.practiceSchedule);
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Profil Dokter',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField('Nama Lengkap', namaCtrl),
                const SizedBox(height: 10),
                _buildEditField('Spesialisasi', specCtrl),
                const SizedBox(height: 10),
                _buildEditField('No. STR', strCtrl),
                const SizedBox(height: 10),
                _buildEditField('No. SIP', sipCtrl),
                const SizedBox(height: 10),
                _buildEditField('Institusi', instCtrl),
                const SizedBox(height: 10),
                _buildEditField('Alamat Praktik', addrCtrl),
                const SizedBox(height: 10),
                _buildEditField('Jadwal Praktik', schedCtrl),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      setModalState(() => isSaving = true);
                      final payload = {
                        'nama': namaCtrl.text.trim(),
                        'spesialisasi': specCtrl.text.trim(),
                        'no_str': strCtrl.text.trim(),
                        'no_sip': sipCtrl.text.trim(),
                        'institusi': instCtrl.text.trim(),
                        'alamat_praktik': addrCtrl.text.trim(),
                        'jadwal_praktik': schedCtrl.text.trim(),
                      };
                      final res = await DokterApiService().updateProfile(
                        payload,
                        doctorName: widget.doctorName,
                      );
                      profileState.syncFromUser(
                        name: payload['nama'],
                        spec: payload['spesialisasi'],
                        str: payload['no_str'],
                        sip: payload['no_sip'],
                        inst: payload['institusi'],
                        address: payload['alamat_praktik'],
                        schedule: payload['jadwal_praktik'],
                      );
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              res.message.isNotEmpty
                                  ? res.message
                                  : 'Profil dokter berhasil diperbarui!',
                            ),
                            backgroundColor: _darkGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Simpan',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _darkGreen, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source, DokterProfileState profileState) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final file = File(picked.path);
      profileState.updateAvatar(type: 'file', path: file.path);

      // Update local storage
      final user = await StorageService().getUser();
      if (user != null) {
        final updated = UserModel(
          id: user.id,
          nama: user.nama,
          email: user.email,
          noHp: user.noHp,
          alamat: user.alamat,
          jenisKelamin: user.jenisKelamin,
          nik: user.nik,
          fotoProfile: file.path,
          firebaseUid: user.firebaseUid,
          authProvider: user.authProvider,
          role: user.role,
          spesialisasi: user.spesialisasi,
          instansi: user.instansi,
          noStr: user.noStr,
          noSip: user.noSip,
          tanggalLahir: user.tanggalLahir,
          golonganDarah: user.golonganDarah,
        );
        await StorageService().saveUser(updated);
      }

      final res = await DokterApiService().updateFotoProfil(file);
      final newUrl = res.data?['foto_profile'] ?? res.data?['foto_profil'] ?? res.data?['foto'] ?? res.data?['url'];
      if (newUrl != null && newUrl.toString().isNotEmpty) {
        final resolvedUrl = ApiConfig.resolveImageUrl(newUrl.toString());
        profileState.updateAvatar(type: 'network', path: resolvedUrl);
        final user = await StorageService().getUser();
        if (user != null) {
          final updated = UserModel(
            id: user.id,
            nama: user.nama,
            email: user.email,
            noHp: user.noHp,
            alamat: user.alamat,
            jenisKelamin: user.jenisKelamin,
            nik: user.nik,
            fotoProfile: resolvedUrl,
            firebaseUid: user.firebaseUid,
            authProvider: user.authProvider,
            role: user.role,
            spesialisasi: user.spesialisasi,
            instansi: user.instansi,
            noStr: user.noStr,
            noSip: user.noSip,
            tanggalLahir: user.tanggalLahir,
            golonganDarah: user.golonganDarah,
          );
          await StorageService().saveUser(updated);
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Foto profil dokter berhasil diperbarui!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _darkGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih atau mengunggah foto: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showChangeProfilePhotoModal(BuildContext context) {
    final profileState = DokterProfileState.instance;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Padding(
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
              'Pilih sumber foto atau gunakan avatar profil dokter yang tersedia.',
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
                _pickImage(context, ImageSource.camera, profileState);
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
                _pickImage(context, ImageSource.gallery, profileState);
              },
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Action: Avatar Preset
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 10, left: 8),
              child: Text(
                'Pilihan Avatar Dokter',
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
                itemCount: profileState.presetAvatars.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, idx) {
                  final item = profileState.presetAvatars[idx];
                  final isSelected = profileState.avatarPath == item['path'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      profileState.updateAvatar(
                        type: item['type']!,
                        path: item['path']!,
                      );
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
                profileState.resetAvatar();
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
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = DokterProfileState.instance;

    return ListenableBuilder(
      listenable: profileState,
      builder: (context, _) {
        final currentName = profileState.doctorName;
        final currentSpecialty = profileState.specialty;

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAF8),
          body: Stack(
            children: [
              // Subtle background topography wave lines
              Positioned.fill(
                child: CustomPaint(
                  painter: _ProfileTopographyPainter(),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Organic Curved Green Header with Kembali & Yellow Edit buttons (Fixed at top, does not scroll)
                  _buildHeader(context, currentName, currentSpecialty, profileState),

                  // Scrollable content below pinned header
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                    const SizedBox(height: 20),

                    // Section 1: Informasi Profesional
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Informasi Profesional',
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Spesialisasi
                    _buildFieldBlock(
                      label: 'Spesialisasi',
                      content: Text(
                        currentSpecialty,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    // No. STR
                    _buildFieldBlock(
                      label: 'No. STR',
                      content: Text(
                        profileState.strNumber,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    // No. SIP
                    _buildFieldBlock(
                      label: 'No. SIP',
                      content: Text(
                        profileState.sipNumber,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    // Institusi
                    _buildFieldBlock(
                      label: 'Institusi',
                      content: Row(
                        children: [
                          const Icon(
                            Icons.add_box_outlined,
                            size: 19,
                            color: Color(0xFF0F172A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              profileState.institution,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Section 2: Praktik
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Praktik',
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Alamat Praktik
                    _buildFieldBlock(
                      label: 'Alamat Praktik',
                      content: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 19,
                            color: Color(0xFF0F172A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              profileState.practiceAddress,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Map Preview Card Real Rumah Sakit Kota Jember
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Builder(
                        builder: (ctx) {
                          final hospital = JemberLocationService.instance
                              .resolveDoctorHospitalInJember(
                            institution: profileState.institution,
                            address: profileState.practiceAddress,
                            doctorName: profileState.doctorName,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GiatRealMapWidget(
                                centerLat: hospital.latitude,
                                centerLng: hospital.longitude,
                                initialZoom: 14.5,
                                height: 195,
                                markers: [
                                  GiatMapMarker(
                                    id: 'rs_dokter_jember',
                                    title: profileState.institution,
                                    subtitle: profileState.practiceAddress,
                                    latitude: hospital.latitude,
                                    longitude: hospital.longitude,
                                    type: GiatMapMarkerType.dokter,
                                    isSelected: true,
                                    isPulsing: true,
                                  ),
                                ],
                                topBadgeText: 'Lokasi Praktik RS • Kota Jember',
                                bottomBannerTitle: profileState.institution,
                                bottomBannerSubtitle:
                                    '${profileState.practiceAddress} (${hospital.latitude.toStringAsFixed(4)}, ${hospital.longitude.toStringAsFixed(4)})',
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showJemberLocationPickerModal(
                                      context,
                                      title: 'Atur Lokasi Praktik RS di Kota Jember',
                                      initialAddress: profileState.practiceAddress,
                                      initialLat: hospital.latitude,
                                      initialLng: hospital.longitude,
                                    );
                                    if (picked != null && mounted) {
                                      profileState.updatePracticeCoordinates(
                                        lat: picked.latitude,
                                        lng: picked.longitude,
                                        address: picked.address,
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _darkGreen,
                                    side: const BorderSide(color: _darkGreen, width: 1.2),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.my_location_rounded, size: 16),
                                  label: Text(
                                    'Atur Lokasi Praktik RS di Jember (GPS / Peta)',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Jadwal Praktik
                    _buildFieldBlock(
                      label: 'Jadwal Praktik',
                      content: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 19,
                            color: Color(0xFF0F172A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              profileState.practiceSchedule,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildFieldBlock({required String label, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String specialty, DokterProfileState profileState) {
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
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _HeaderWaveOverlayPainter(),
              ),
            ),
            SafeArea(
              bottom: false,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top Navigation Row: "Kembali" pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Tombol "<- Kembali"
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
                          GestureDetector(
                            onTap: () => _showEditProfileDialog(profileState),
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
                                  const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF065A37)),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Edit',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF065A37),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Avatar Circle with White Border
                      Center(
                        child: GestureDetector(
                          onTap: () => _showChangeProfilePhotoModal(context),
                          child: Container(
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
                              child: profileState.buildAvatarWidget(size: 104, iconSize: 52),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Doctor Name
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Doctor Specialty
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          specialty,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
    GiatBackgroundPainter.paintBackground(
      canvas,
      size,
      showGradient: false,
      showLines: true,
    );
    }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stylized map painter matching the clinic area snapshot in Screenshot 4
class _DokterClinicMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base Map Background
    final bgPaint = Paint()..color = const Color(0xFFEDF2E8);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Parks & Greenery Areas
    final parkPaint = Paint()..color = const Color(0xFFD6EAC9);
    // Taman Suropati (top right)
    final park1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.58, h * 0.18, w * 0.36, h * 0.38),
      const Radius.circular(12),
    );
    canvas.drawRRect(park1, parkPaint);

    // Smaller green patch (left center)
    final park2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.45, w * 0.18, h * 0.32),
      const Radius.circular(8),
    );
    canvas.drawRRect(park2, parkPaint);

    // 3. Roads & Streets
    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFD3DBCF)
      ..style = PaintingStyle.stroke;

    void drawRoad(Path path, double width) {
      roadBorderPaint.strokeWidth = width + 2;
      canvas.drawPath(path, roadBorderPaint);
      roadPaint.strokeWidth = width;
      canvas.drawPath(path, roadPaint);
    }

    // Main horizontal avenue
    final hRoad1 = Path()
      ..moveTo(0, h * 0.42)
      ..lineTo(w, h * 0.38);
    drawRoad(hRoad1, 18);

    // Secondary horizontal street
    final hRoad2 = Path()
      ..moveTo(0, h * 0.78)
      ..lineTo(w, h * 0.74);
    drawRoad(hRoad2, 12);

    // Vertical avenue (Jalan HOS Cokroaminoto)
    final vRoad1 = Path()
      ..moveTo(w * 0.32, 0)
      ..lineTo(w * 0.32, h);
    drawRoad(vRoad1, 16);

    // Diagonal connector (Jalan Yusuf Adiwinata)
    final diagRoad = Path()
      ..moveTo(w * 0.32, h * 0.40)
      ..lineTo(w * 0.58, h * 0.76);
    drawRoad(diagRoad, 14);

    // Secondary vertical street (Jalan Teuku Umar)
    final vRoad2 = Path()
      ..moveTo(w * 0.72, h * 0.38)
      ..lineTo(w * 0.72, h);
    drawRoad(vRoad2, 12);

    // 4. Subtle Street & Place Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    void drawLabel(String text, Offset pos, {double fontSize = 8, Color color = const Color(0xFF64748B)}) {
      textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, pos);
    }

    drawLabel('Taman Suropati', Offset(w * 0.65, h * 0.32), fontSize: 8.5, color: const Color(0xFF3F6212));
    drawLabel('Jalan Yusuf Adiwinata', Offset(w * 0.40, h * 0.52), fontSize: 7.5);
    drawLabel('Jalan Teuku Umar', Offset(w * 0.74, h * 0.58), fontSize: 7.5);
    drawLabel('Jalan HOS Cokroaminoto', Offset(w * 0.33, h * 0.16), fontSize: 7.5);

    // 5. Clinic Pin Marker in Center
    final pinCenter = Offset(w * 0.51, h * 0.47);

    // Pin shadow
    canvas.drawOval(
      Rect.fromCenter(center: pinCenter.translate(0, 14), width: 14, height: 6),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    // Pin icon background circle
    final pinBgPaint = Paint()..color = const Color(0xFF044E2F);
    canvas.drawCircle(pinCenter, 13, pinBgPaint);

    // White outline
    final pinBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(pinCenter, 13, pinBorderPaint);

    // Cross / Location symbol inside pin
    final crossPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(pinCenter.translate(-4.5, 0), pinCenter.translate(4.5, 0), crossPaint);
    canvas.drawLine(pinCenter.translate(0, -4.5), pinCenter.translate(0, 4.5), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

