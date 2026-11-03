import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/admin_models.dart';
import '../widgets/admin_header.dart';

class AdminEdukasiScreen extends StatefulWidget {
  final Widget? trailingAction;

  const AdminEdukasiScreen({
    super.key,
    this.trailingAction,
  });

  @override
  State<AdminEdukasiScreen> createState() => _AdminEdukasiScreenState();
}

class _AdminEdukasiScreenState extends State<AdminEdukasiScreen> {
  static const _primaryGreen = Color(0xFF006D37);
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _textColor = Color(0xFF091D2E);
  static const _subtextColor = Color(0xFF475569);
  static const _border = Color(0xFFE2E8F0);

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua', 'Info CKD', 'Nutrisi & Diet', 'Pola Hidup', 'Draft'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AdminEdukasi> _getFilteredEdukasi(AdminStore store) {
    final byFilter = store.edukasi.where((e) {
      if (_selectedFilter != 'Semua') return e.kategori == _selectedFilter;
      return true;
    }).toList();

    if (_searchQuery.trim().isEmpty) return byFilter;
    final q = _searchQuery.toLowerCase().trim();
    return byFilter.where((e) {
      return e.judul.toLowerCase().contains(q) ||
          e.ringkasan.toLowerCase().contains(q) ||
          e.kategori.toLowerCase().contains(q) ||
          e.penulis.toLowerCase().contains(q);
    }).toList();
  }

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

  static const List<Map<String, String>> _presetArticleImages = [
    {
      'label': 'Pemeriksaan Ginjal',
      'url': 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=600&q=80',
    },
    {
      'label': 'Nutrisi & Diet',
      'url': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=600&q=80',
    },
    {
      'label': 'Pola Hidup Sehat',
      'url': 'https://images.unsplash.com/photo-1505576399279-565b52d4ac71?auto=format&fit=crop&w=600&q=80',
    },
    {
      'label': 'Konsultasi Medis',
      'url': 'https://images.unsplash.com/photo-1631815588090-d4bfec5b1ccb?auto=format&fit=crop&w=600&q=80',
    },
    {
      'label': 'Obat & Suplemen',
      'url': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=600&q=80',
    },
    {
      'label': 'Ilustrasi Ginjal',
      'url': 'assets/images/kidneys.jpg',
    },
  ];

  void _showEdukasiFormSheet({AdminEdukasi? existing}) {
    final store = AdminStore.instance;
    final judulCtrl = TextEditingController(text: existing?.judul ?? '');
    final ringkasanCtrl = TextEditingController(text: existing?.ringkasan ?? '');
    final kontenCtrl = TextEditingController(text: existing?.konten ?? '');
    final penulisCtrl =
        TextEditingController(text: existing?.penulis ?? 'Tim Medis GIAT');
    String selectedGambar =
        existing?.gambar ?? _presetArticleImages.first['url']!;
    final gambarUrlCtrl = TextEditingController(
      text: selectedGambar.startsWith('http') ? selectedGambar : '',
    );
    String kategori = existing?.kategori ?? AdminStore.edukasiKategori.first;
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();
    final picker = ImagePicker();

    Future<void> showFallbackGalleryDialog(
      BuildContext modalCtx,
      void Function(void Function()) setModalState, {
      String? infoMessage,
    }) async {
      await showDialog<void>(
        context: modalCtx,
        builder: (dCtx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Pilih Gambar Artikel Edukasi',
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (infoMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            infoMessage,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF92400E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Pilih salah satu gambar sampul di bawah ini:',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _presetArticleImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (_, idx) {
                    final preset = _presetArticleImages[idx];
                    final url = preset['url']!;
                    final label = preset['label']!;
                    final isSelected = selectedGambar == url;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedGambar = url;
                          gambarUrlCtrl.text =
                              url.startsWith('http') ? url : '';
                        });
                        Navigator.pop(dCtx);
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildArticleImage(
                              url,
                              fallback: Container(
                                color: const Color(0xFFDCFCE7),
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: _darkGreen,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? _darkGreen
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                            alignment: Alignment.bottomLeft,
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text(
                'Tutup',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: _darkGreen,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Future<void> pickImageFromDevice(
      BuildContext modalCtx,
      ImageSource source,
      void Function(void Function()) setModalState,
    ) async {
      try {
        if (source == ImageSource.camera) {
          final status = await Permission.camera.request();
          if (!status.isGranted) {
            if (!modalCtx.mounted) return;
            await showFallbackGalleryDialog(
              modalCtx,
              setModalState,
              infoMessage:
                  'Izin kamera belum diberikan. Berikan izin Kamera di Pengaturan HP atau pilih gambar sampul di bawah ini.',
            );
            return;
          }
        }

        final XFile? picked = await picker.pickImage(
          source: source,
          maxWidth: 640,
          maxHeight: 640,
          imageQuality: 65,
        );
        if (picked == null) return;
        final bytes = await picked.readAsBytes();
        final ext = picked.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
        final dataUri = 'data:image/$ext;base64,${base64Encode(bytes)}';
        setModalState(() {
          selectedGambar = dataUri;
          gambarUrlCtrl.clear();
        });
      } on MissingPluginException {
        if (!modalCtx.mounted) return;
        await showFallbackGalleryDialog(
          modalCtx,
          setModalState,
          infoMessage:
              'Plugin Galeri/Kamera baru saja ditambahkan. Lakukan Stop lalu jalankan ulang "flutter run" (bukan sekadar Hot Reload) agar Galeri & Kamera HP aktif. Sementara itu Anda bisa memilih gambar di bawah:',
        );
      } catch (e) {
        if (!modalCtx.mounted) return;
        await showFallbackGalleryDialog(
          modalCtx,
          setModalState,
          infoMessage:
              'Tidak dapat membuka Galeri/Kamera perangkat saat ini. Silakan pilih gambar sampul di bawah atau lakukan Stop & "flutter run" ulang:',
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
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
                      existing == null
                          ? 'Tambah Artikel Edukasi Kesehatan'
                          : 'Edit Artikel Edukasi Kesehatan',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Artikel yang dipublikasikan akan langsung tampil pada menu Edukasi Pasien.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kategori
                    Text(
                      'Kategori Edukasi',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AdminStore.edukasiKategori.map((kat) {
                        final isSelected = kategori == kat;
                        return GestureDetector(
                          onTap: () => setModalState(() => kategori = kat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _darkGreen
                                  : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? _darkGreen
                                    : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Text(
                              kat,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : _darkGreen,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // ── Gambar Artikel Edukasi ──
                    Text(
                      'Gambar Artikel Edukasi',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kotak Pratinjau Gambar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 140,
                                  width: double.infinity,
                                  child: _buildArticleImage(
                                    selectedGambar,
                                    height: 140,
                                    width: double.infinity,
                                    fallback: Container(
                                      height: 140,
                                      color: const Color(0xFFDCFCE7),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 38,
                                            color: _darkGreen,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Pratinjau Gambar Artikel',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: _darkGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.image_outlined,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          selectedGambar.startsWith('data:image/')
                                              ? 'Gambar Perangkat'
                                              : 'Sampul Artikel',
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Tombol Pilih dari Galeri / Kamera
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _darkGreen,
                                    side: const BorderSide(
                                      color: Color(0xFFBBF7D0),
                                    ),
                                    backgroundColor: const Color(0xFFF0FDF4),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => pickImageFromDevice(
                                    ctx,
                                    ImageSource.gallery,
                                    setModalState,
                                  ),
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                    size: 17,
                                  ),
                                  label: Text(
                                    'Pilih Galeri',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _darkGreen,
                                    side: const BorderSide(
                                      color: Color(0xFFBBF7D0),
                                    ),
                                    backgroundColor: const Color(0xFFF0FDF4),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => pickImageFromDevice(
                                    ctx,
                                    ImageSource.camera,
                                    setModalState,
                                  ),
                                  icon: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 17,
                                  ),
                                  label: Text(
                                    'Kamera',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          Text(
                            'Atau pilih gambar sampul cepat:',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 62,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _presetArticleImages.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, idx) {
                                final preset = _presetArticleImages[idx];
                                final presetUrl = preset['url']!;
                                final isPicked = selectedGambar == presetUrl;
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedGambar = presetUrl;
                                      gambarUrlCtrl.text =
                                          presetUrl.startsWith('http')
                                              ? presetUrl
                                              : '';
                                    });
                                  },
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 78,
                                        height: 62,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isPicked
                                                ? _darkGreen
                                                : const Color(0xFFCBD5E1),
                                            width: isPicked ? 2.2 : 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: _buildArticleImage(
                                            presetUrl,
                                            width: 78,
                                            height: 62,
                                            fallback: Container(
                                              color: const Color(0xFFDCFCE7),
                                              child: const Icon(
                                                Icons.image_outlined,
                                                color: _darkGreen,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isPicked)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: _darkGreen,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_rounded,
                                              size: 11,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),
                          TextFormField(
                            controller: gambarUrlCtrl,
                            onChanged: (v) {
                              final trimmed = v.trim();
                              if (trimmed.isNotEmpty) {
                                setModalState(() => selectedGambar = trimmed);
                              }
                            },
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Atau tempel tautan URL gambar (https://...)',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Icons.link_rounded,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: _darkGreen,
                                  width: 1.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: judulCtrl,
                      label: 'Judul Artikel',
                      hint: 'Masukkan judul artikel edukasi...',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Judul artikel wajib diisi'
                          : null,
                    ),

                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: ringkasanCtrl,
                      label: 'Ringkasan Singkat',
                      hint: '1-2 kalimat ringkasan untuk kartu pratinjau...',
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Ringkasan wajib diisi'
                          : null,
                    ),

                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: kontenCtrl,
                      label: 'Konten Lengkap Artikel',
                      hint: 'Tulis isi materi edukasi kesehatan ginjal...',
                      maxLines: 5,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Konten artikel wajib diisi'
                          : null,
                    ),

                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: penulisCtrl,
                      label: 'Penulis / Narasumber',
                      hint: 'Tim Medis GIAT',
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
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSaving = true);
                                final finalGambar =
                                    selectedGambar.trim().isNotEmpty
                                        ? selectedGambar.trim()
                                        : 'assets/images/kidneys.jpg';
                                final item = AdminEdukasi(
                                  id: existing?.id ?? store.newId(),
                                  judul: judulCtrl.text.trim(),
                                  kategori: kategori,
                                  ringkasan: ringkasanCtrl.text.trim(),
                                  konten: kontenCtrl.text.trim(),
                                  gambar: finalGambar,
                                  penulis: penulisCtrl.text.trim().isEmpty
                                      ? 'Tim Medis GIAT'
                                      : penulisCtrl.text.trim(),
                                  durasiBaca: existing?.durasiBaca ?? 4,
                                  status: EdukasiStatus.published,
                                  createdAt:
                                      existing?.createdAt ?? DateTime.now(),
                                  updatedAt: DateTime.now(),
                                );
                                await store.saveEdukasi(item);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                _showSnack(
                                  existing == null
                                      ? 'Artikel edukasi berhasil ditambahkan!'
                                      : 'Artikel edukasi berhasil diperbarui!',
                                );
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                existing == null
                                    ? 'Simpan Artikel'
                                    : 'Simpan Perubahan',
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
      ),
    );
  }

  void _showPreviewSheet(AdminEdukasi item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.9,
        minChildSize: 0.45,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ListView(
            controller: scrollCtrl,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildArticleImage(
                  item.gambar,
                  height: 170,
                  width: double.infinity,
                  fallback: Container(
                    height: 170,
                    color: const Color(0xFFDCFCE7),
                    child: const Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 52,
                        color: _darkGreen,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.kategori,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.judul,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Oleh ${item.penulis} • ${adminFormatDate(item.updatedAt)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  item.ringkasan,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _darkGreen,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.konten,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF1E293B),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(AdminEdukasi item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Hapus Artikel Edukasi?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'Artikel "${item.judul}" akan dihapus secara permanen.',
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              AdminStore.instance.deleteEdukasi(item);
              Navigator.pop(ctx);
              _showSnack('Artikel edukasi dihapus', isError: true);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final filtered = _getFilteredEdukasi(store);

          return Scaffold(
            backgroundColor: _bgColor,
            body: Stack(
              children: [
                // ── Background Topography ──
                const Positioned.fill(
                  child: CustomPaint(painter: AdminTopographyPainter()),
                ),

                Column(
                  children: [
                    // ── Top Header Bar (sama dengan Home, tanpa tombol Kembali) ──
                    AdminCurvedHeader(
                      title: 'Kelola Edukasi Kesehatan 📖',
                      subtitle:
                          'Publikasikan, perbarui, dan kelola artikel edukasi kesehatan ginjal untuk pasien GIAT. ✨',
                      trailingAction: widget.trailingAction,
                    ),

                    const SizedBox(height: 14),

                    // ── Main Content Area ──
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Bar Kapsul
                            Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: _border),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 14),
                                  const Icon(
                                    Icons.search_rounded,
                                    color: Color(0xFF64748B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchCtrl,
                                      onChanged: (v) =>
                                          setState(() => _searchQuery = v),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        color: _textColor,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Cari judul artikel, kategori, penulis...',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildFilterChip('Semua'),
                                  const SizedBox(width: 8),
                                  ...AdminStore.edukasiKategori.map(
                                    (k) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: _buildFilterChip(k),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // List of Edukasi Articles
                            Expanded(
                              child: filtered.isEmpty
                                  ? _buildEmptyState()
                                  : RefreshIndicator(
                                      color: _darkGreen,
                                      onRefresh: store.fetchEdukasi,
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: filtered.length,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(
                                          parent: BouncingScrollPhysics(),
                                        ),
                                        itemBuilder: (context, index) {
                                          final item = filtered[index];
                                          return _buildEdukasiCard(item);
                                        },
                                      ),
                                    ),
                            ),

                            // Bottom Button: "Tambah Artikel Edukasi Baru"
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              child: _buildAddButton(),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              size: 40,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada artikel pada kategori ini',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Klik tombol di bawah untuk menambah artikel edukasi baru',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _subtextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: _primaryGreen.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _showEdukasiFormSheet(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Tambah Artikel Edukasi Baru',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _primaryGreen : _border),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : _subtextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildArticleImage(
    String path, {
    double? width,
    double? height,
    required Widget fallback,
  }) {
    if (path.startsWith('data:image/')) {
      try {
        final commaIdx = path.indexOf(',');
        final b64 = (commaIdx >= 0 ? path.substring(commaIdx + 1) : path).replaceAll(RegExp(r'\s+'), '');
        return Image.memory(
          base64Decode(b64),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  Widget _buildEdukasiCard(AdminEdukasi item) {
    Color iconBgColor = const Color(0xFFD5E8F0);
    if (item.kategori.contains('Nutrisi')) {
      iconBgColor = const Color(0xFFE0F2FE);
    } else if (item.kategori.contains('Pola Hidup')) {
      iconBgColor = const Color(0xFFEDE9FE);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle decorative organic bubble on the left (Figma Bubbles)
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: CustomPaint(
                painter: AdminCardBubblePainter(),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon / Thumbnail Container (58x58 with rounded corners like Reminder Card)
                GestureDetector(
                  onTap: () => _showPreviewSheet(item),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildArticleImage(
                        item.gambar,
                        width: 58,
                        height: 58,
                        fallback: const Center(
                          child: Icon(
                            Icons.menu_book_outlined,
                            color: _textColor,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Info Column: Title + Category Pill, Ringkasan & Quick Actions
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.judul,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _textColor,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _textColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.kategori,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.ringkasan,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: _subtextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildSmallAction(
                              icon: Icons.visibility_outlined,
                              label: 'Baca',
                              color: const Color(0xFF0284C7),
                              onTap: () => _showPreviewSheet(item),
                            ),
                            _buildSmallAction(
                              icon: Icons.edit_outlined,
                              label: 'Edit',
                              color: _primaryGreen,
                              onTap: () =>
                                  _showEdukasiFormSheet(existing: item),
                            ),
                            _buildSmallAction(
                              icon: Icons.delete_outline_rounded,
                              label: 'Hapus',
                              color: const Color(0xFFDC2626),
                              onTap: () => _confirmDelete(item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

