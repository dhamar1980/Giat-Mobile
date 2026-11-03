import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../login_screen.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/pasien_api_service.dart';
import '../../../syarat_ketentuan_screen.dart';
import '../../../kebijakan_privasi_screen.dart';
import 'kata_sandi_keamanan_screen.dart';
import 'edit_informasi_pribadi_screen.dart';
import '../../../widgets/giat_background.dart';
import '../../../utils/time_utils.dart';

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

  File? _avatarFile;
  String _avatarType = 'default'; // 'asset', 'network', 'file', 'default'
  String _avatarPath = '';
  bool _isUploadingPhoto = false;

  // Real data untuk Ringkasan Kesehatan
  String _statusGinjal = 'Stabil';
  Color _statusGinjalColor = const Color(0xFF10B981);
  String _konsultasiTerakhir = 'Memuat...';
  String _pengingatBerikutnya = 'Memuat...';

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
        : '';
    _email = '';
    _tanggalLahir = '';
    _jenisKelamin = '';
    _golonganDarah = '';
    _alamat = '';
    _loadProfile();
  }

  void _setAvatarFromPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      _avatarType = 'default';
      _avatarPath = '';
      _avatarFile = null;
      return;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      _avatarType = 'network';
      _avatarPath = trimmed;
      _avatarFile = null;
    } else if (File(trimmed).existsSync()) {
      _avatarType = 'file';
      _avatarPath = trimmed;
      _avatarFile = File(trimmed);
    } else if (trimmed.startsWith('assets/')) {
      _avatarType = 'asset';
      _avatarPath = trimmed;
      _avatarFile = null;
    } else {
      _avatarType = 'default';
      _avatarPath = trimmed;
      _avatarFile = null;
    }
  }

  Future<void> _loadProfile() async {
    // 1. Muat dari cache lokal UserModel agar data instan muncul
    try {
      final user = await StorageService().getUser();
      if (user != null && mounted) {
        setState(() {
          if (user.nama.isNotEmpty) _nama = user.nama;
          if (user.email.isNotEmpty) _email = user.email;
          if (user.alamat != null && user.alamat!.isNotEmpty) _alamat = user.alamat!;
          if (user.jenisKelamin != null && user.jenisKelamin!.isNotEmpty) _jenisKelamin = user.jenisKelamin!;
          if (user.tanggalLahir != null && user.tanggalLahir!.isNotEmpty) {
            _tanggalLahir = TimeUtils.formatBirthDate(user.tanggalLahir!);
          }
          if (user.golonganDarah != null && user.golonganDarah!.isNotEmpty) _golonganDarah = user.golonganDarah!;
          if (user.fotoProfile != null && user.fotoProfile!.isNotEmpty) {
            _setAvatarFromPath(user.fotoProfile!);
          }
        });
      }
    } catch (_) {}

    // 2. Muat profil real dari API backend Pasien
    try {
      final res = await PasienApiService().getProfile();
      if (res.success && res.data != null && mounted) {
        final d = res.data!;
        setState(() {
          if (d['nama'] != null && d['nama'].toString().isNotEmpty) _nama = d['nama'].toString();
          if (d['email'] != null && d['email'].toString().isNotEmpty) _email = d['email'].toString();
          if (d['alamat'] != null && d['alamat'].toString().isNotEmpty) _alamat = d['alamat'].toString();
          if (d['jenis_kelamin'] != null && d['jenis_kelamin'].toString().isNotEmpty) _jenisKelamin = d['jenis_kelamin'].toString();
          if (d['tanggal_lahir'] != null && d['tanggal_lahir'].toString().isNotEmpty) {
            _tanggalLahir = TimeUtils.formatBirthDate(d['tanggal_lahir'].toString());
          }
          if (d['golongan_darah'] != null && d['golongan_darah'].toString().isNotEmpty) _golonganDarah = d['golongan_darah'].toString();
          if (d['foto_profile'] != null && d['foto_profile'].toString().isNotEmpty) {
            _setAvatarFromPath(d['foto_profile'].toString());
          }
        });
      }
    } catch (_) {}

    // 3. Muat ringkasan kesehatan real
    await _loadRingkasanKesehatan();
  }

  Future<void> _loadRingkasanKesehatan() async {
    // A. Status Kesehatan Ginjal (dari ringkasan pemantauan real)
    try {
      final cachedSummary = StorageService().getPantauSummaryCache();
      if (cachedSummary != null) {
        _applyPantauSummary(cachedSummary);
      }
      final pantauRes = await PasienApiService().getPantauSummary();
      if (pantauRes.success && pantauRes.data != null && mounted) {
        _applyPantauSummary(pantauRes.data!);
      }
    } catch (_) {}

    // B. Konsultasi Terakhir (dari riwayat konsultasi real)
    try {
      final konsultasiRes = await PasienApiService().getRiwayatKonsultasi();
      if (konsultasiRes.success && konsultasiRes.data != null && mounted) {
        final list = konsultasiRes.data!;
        if (list.isNotEmpty) {
          final first = list.first;
          final rawDate = first['tanggal'] ?? first['created_at'] ?? first['waktu_mulai'] ?? first['jadwal'] ?? first['waktu'];
          if (rawDate != null) {
            setState(() {
              _konsultasiTerakhir = TimeUtils.formatDate(rawDate, useIndonesianMonth: true);
            });
          } else {
            setState(() {
              _konsultasiTerakhir = 'Belum ada riwayat';
            });
          }
        } else {
          setState(() {
            _konsultasiTerakhir = 'Belum ada riwayat';
          });
        }
      } else if (mounted) {
        setState(() {
          _konsultasiTerakhir = 'Belum ada riwayat';
        });
      }
    } catch (_) {
      if (mounted && _konsultasiTerakhir == 'Memuat...') {
        setState(() {
          _konsultasiTerakhir = 'Belum ada riwayat';
        });
      }
    }

    // C. Pengingat Berikutnya (dari jadwal pengingat real hari ini / aktif)
    try {
      final remRes = await PasienApiService().getRemindersHariIni();
      List<dynamic> remList = [];
      if (remRes.success && remRes.data != null && remRes.data!.isNotEmpty) {
        remList = remRes.data!;
      } else {
        final allRemRes = await PasienApiService().getReminders();
        if (allRemRes.success && allRemRes.data != null) {
          remList = allRemRes.data!;
        }
      }

      if (remList.isNotEmpty && mounted) {
        final firstRem = remList.first;
        final name = firstRem['nama']?.toString() ?? firstRem['judul']?.toString() ?? firstRem['title']?.toString() ?? 'Obat';
        final timeRaw = firstRem['waktu']?.toString() ?? firstRem['time']?.toString() ?? '08:00';
        final timeStr = TimeUtils.formatChatTime(timeRaw, separator: ':');
        setState(() {
          _pengingatBerikutnya = '$name - $timeStr';
        });
      } else if (mounted) {
        setState(() {
          _pengingatBerikutnya = 'Tidak ada jadwal aktif';
        });
      }
    } catch (_) {
      if (mounted && _pengingatBerikutnya == 'Memuat...') {
        setState(() {
          _pengingatBerikutnya = 'Tidak ada jadwal aktif';
        });
      }
    }
  }

  void _applyPantauSummary(Map<String, dynamic> data) {
    final rawKondisi = data['kondisi_tubuh'] ?? data['kondisi'] ?? data['status'] ?? data['status_ginjal'];
    if (rawKondisi != null && rawKondisi.toString().trim().isNotEmpty && mounted) {
      final str = rawKondisi.toString().trim();
      final lower = str.toLowerCase();
      Color col = const Color(0xFF10B981);
      if (lower.contains('buruk') || lower.contains('kritis') || lower.contains('bahaya')) {
        col = const Color(0xFFEF4444);
      } else if (lower.contains('waspada') || lower.contains('perhatian') || lower.contains('sedang') || lower.contains('kurang')) {
        col = const Color(0xFFF59E0B);
      }
      setState(() {
        _statusGinjal = str;
        _statusGinjalColor = col;
      });
    }
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
          _tanggalLahir = TimeUtils.formatBirthDate(result['birthDate']!);
        }
        if (result['gender'] != null && result['gender']!.isNotEmpty) {
          _jenisKelamin = result['gender']!;
        }
        if (result['address'] != null && result['address']!.isNotEmpty) {
          _alamat = result['address']!;
          final detected = TimeUtils.detectTimeZone(address: _alamat);
          TimeUtils.setTimeZone(detected);
        }
        if (result['bloodType'] != null && result['bloodType']!.isNotEmpty) {
          _golonganDarah = result['bloodType']!;
        }
      });

      // Synchronize changes to backend API: PUT /pasien/profile
      final dbBirthDate = TimeUtils.toDbDate(_tanggalLahir);
      final dbGender = _jenisKelamin == 'Perempuan' ? 'P' : (_jenisKelamin == 'Laki-laki' ? 'L' : _jenisKelamin);
      PasienApiService().updateProfile({
        'nama': _nama,
        'alamat': _alamat,
        'jenis_kelamin': dbGender,
        'tanggal_lahir': dbBirthDate,
        'gol_darah': _golonganDarah,
        'golongan_darah': _golonganDarah,
      });

      // Simpan juga ke local user cache
      try {
        final currentUser = await StorageService().getUser();
        if (currentUser != null) {
          final updated = UserModel(
            id: currentUser.id,
            nama: _nama,
            email: currentUser.email,
            noHp: currentUser.noHp,
            alamat: _alamat,
            jenisKelamin: dbGender,
            nik: currentUser.nik,
            fotoProfile: currentUser.fotoProfile,
            firebaseUid: currentUser.firebaseUid,
            authProvider: currentUser.authProvider,
            role: currentUser.role,
            spesialisasi: currentUser.spesialisasi,
            instansi: currentUser.instansi,
            noStr: currentUser.noStr,
            noSip: currentUser.noSip,
            tanggalLahir: dbBirthDate,
            golonganDarah: _golonganDarah,
          );
          await StorageService().saveUser(updated);
        }
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Informasi pribadi & kesehatan berhasil disimpan ke server!',
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

  Future<void> _pickImage(ImageSource source) async {
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
      setState(() {
        _avatarFile = file;
        _avatarType = 'file';
        _avatarPath = file.path;
        _isUploadingPhoto = true;
      });

      // Update local storage langsung agar foto langsung persisten
      final currentUser = await StorageService().getUser();
      if (currentUser != null) {
        final updatedUser = UserModel(
          id: currentUser.id,
          nama: currentUser.nama,
          email: currentUser.email,
          noHp: currentUser.noHp,
          alamat: currentUser.alamat,
          jenisKelamin: currentUser.jenisKelamin,
          nik: currentUser.nik,
          fotoProfile: file.path,
          firebaseUid: currentUser.firebaseUid,
          authProvider: currentUser.authProvider,
          role: currentUser.role,
          spesialisasi: currentUser.spesialisasi,
          instansi: currentUser.instansi,
          noStr: currentUser.noStr,
          noSip: currentUser.noSip,
          tanggalLahir: currentUser.tanggalLahir,
          golonganDarah: currentUser.golonganDarah,
        );
        await StorageService().saveUser(updatedUser);
      }

      // Unggah ke backend server GIAT
      final res = await PasienApiService().updateFotoProfile(file);
      if (!mounted) return;
      setState(() {
        _isUploadingPhoto = false;
      });

      final newUrl = res.data?['foto_profile'] ?? res.data?['foto'] ?? res.data?['image_url'] ?? res.data?['url'];
      if (newUrl != null && newUrl.toString().startsWith('http')) {
        setState(() {
          _avatarType = 'network';
          _avatarPath = newUrl.toString();
        });
        if (currentUser != null) {
          final netUser = UserModel(
            id: currentUser.id,
            nama: currentUser.nama,
            email: currentUser.email,
            noHp: currentUser.noHp,
            alamat: currentUser.alamat,
            jenisKelamin: currentUser.jenisKelamin,
            nik: currentUser.nik,
            fotoProfile: newUrl.toString(),
            firebaseUid: currentUser.firebaseUid,
            authProvider: currentUser.authProvider,
            role: currentUser.role,
            spesialisasi: currentUser.spesialisasi,
            instansi: currentUser.instansi,
            noStr: currentUser.noStr,
            noSip: currentUser.noSip,
            tanggalLahir: currentUser.tanggalLahir,
            golonganDarah: currentUser.golonganDarah,
          );
          await StorageService().saveUser(netUser);
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Foto profil berhasil diperbarui!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _darkGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
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
              'Pilih sumber foto dari kamera atau galeri handphone Anda.',
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
                _pickImage(ImageSource.camera);
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
                _pickImage(ImageSource.gallery);
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
                        _avatarFile = null;
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
                  _avatarFile = null;
                  _avatarPath = '';
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
    if (_isUploadingPhoto) {
      return Container(
        color: const Color(0xFFDCFCE7),
        child: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _darkGreen),
          ),
        ),
      );
    }
    if (_avatarFile != null && _avatarFile!.existsSync()) {
      return Image.file(_avatarFile!, fit: BoxFit.cover);
    }
    if (_avatarPath.isNotEmpty && File(_avatarPath).existsSync()) {
      return Image.file(File(_avatarPath), fit: BoxFit.cover);
    }
    if (_avatarType == 'network' || _avatarPath.startsWith('http://') || _avatarPath.startsWith('https://')) {
      return Image.network(
        _avatarPath,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          color: const Color(0xFFDCFCE7),
          child: const Icon(Icons.person_rounded, size: 56, color: _darkGreen),
        ),
      );
    }
    if (_avatarType == 'asset' && _avatarPath.startsWith('assets/')) {
      return Image.asset(
        _avatarPath,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          color: const Color(0xFFDCFCE7),
          child: const Icon(Icons.person_rounded, size: 56, color: _darkGreen),
        ),
      );
    }
    return Container(
      color: const Color(0xFFDCFCE7),
      child: const Icon(
        Icons.person_rounded,
        size: 56,
        color: _darkGreen,
      ),
    );
  }

  void _handleLogout() {
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
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
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

  void _showTimeZoneDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final current = TimeUtils.activeTimeZone;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Zona Waktu Indonesia',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Waktu chat, pemantauan, dan jadwal konsultasi disesuaikan dengan lokasi Anda.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ...IndonesianTimeZone.values.map((zone) {
                final isSelected = current == zone;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8F5E9) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _darkGreen : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? _darkGreen : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        zone.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    title: Text(
                      zone.fullName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      'UTC+0${zone.offsetHours}:00',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: _darkGreen)
                        : null,
                    onTap: () async {
                      final navigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      await TimeUtils.setTimeZone(zone);
                      navigator.pop();
                      if (!mounted) return;
                      setState(() {});
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Zona waktu berhasil diset ke ${zone.name} (${zone.fullName})'),
                          backgroundColor: _darkGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _handleDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hapus Akun Pengguna?',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          'Tindakan ini tidak dapat dibatalkan. Seluruh data rekam medis, pemantauan ginjal, dan akun Anda akan dihapus permanen dari server GIAT.',
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF4B5563), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await AuthService().deleteAccount();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Akun berhasil dihapus.'),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Hapus Akun',
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
                    // Top Navigation Row: Tombol Kembali saja (Tombol Edit kuning dihapus sesuai permintaan)
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
                        const SizedBox.shrink(),
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

  String _displayJenisKelamin(String raw) {
    final trimmed = raw.trim();
    if (trimmed.toUpperCase() == 'P' || trimmed.toLowerCase() == 'perempuan') {
      return 'Perempuan';
    }
    if (trimmed.toUpperCase() == 'L' || trimmed.toLowerCase() == 'laki-laki') {
      return 'Laki-laki';
    }
    return trimmed.isNotEmpty ? trimmed : '-';
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
          // 1. Status Kesehatan Ginjal (Real Data)
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
                decoration: BoxDecoration(
                  color: _statusGinjalColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _statusGinjal,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. Konsultasi Terakhir (Real Data)
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
            _konsultasiTerakhir,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 18),

          // 3. Pengingat Berikutnya (Real Data)
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
            _pengingatBerikutnya,
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
                  value: TimeUtils.formatBirthDate(_tanggalLahir),
                ),
                const SizedBox(height: 16),
                _buildPersonalItem(
                  icon: Icons.wc_rounded,
                  label: 'Jenis Kelamin',
                  value: _displayJenisKelamin(_jenisKelamin),
                ),
                const SizedBox(height: 16),
                _buildPersonalItem(
                  icon: Icons.water_drop_outlined,
                  label: 'Golongan Darah',
                  value: _golonganDarah.isNotEmpty ? _golonganDarah : '-',
                ),
                const SizedBox(height: 16),
                _buildPersonalItem(
                  icon: Icons.home_rounded,
                  label: 'Alamat',
                  value: _alamat.isNotEmpty ? _alamat : '-',
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _showTimeZoneDialog,
                  borderRadius: BorderRadius.circular(11),
                  child: _buildPersonalItem(
                    icon: Icons.schedule_rounded,
                    label: 'Zona Waktu Indonesia',
                    value: '${TimeUtils.getTimeZoneName()} (${TimeUtils.getTimeZoneFullName()})',
                  ),
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
              onTap: _handleLogout,
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

        const SizedBox(height: 12),

        // 4. Hapus Akun Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFEE2E2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _handleDeleteAccount,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_forever_rounded,
                      color: Color(0xFFB91C1C),
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Hapus Akun Pengguna',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB91C1C),
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
