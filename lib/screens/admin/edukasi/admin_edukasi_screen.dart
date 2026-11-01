import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  void _showEdukasiFormSheet({AdminEdukasi? existing}) {
    final store = AdminStore.instance;
    final judulCtrl = TextEditingController(text: existing?.judul ?? '');
    final ringkasanCtrl = TextEditingController(text: existing?.ringkasan ?? '');
    final kontenCtrl = TextEditingController(text: existing?.konten ?? '');
    final penulisCtrl =
        TextEditingController(text: existing?.penulis ?? 'Tim Medis GIAT');
    final durasiCtrl =
        TextEditingController(text: '${existing?.durasiBaca ?? 4}');
    String kategori = existing?.kategori ?? AdminStore.edukasiKategori.first;
    final formKey = GlobalKey<FormState>();

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
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: penulisCtrl,
                            label: 'Penulis / Narasumber',
                            hint: 'Tim Medis GIAT',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: durasiCtrl,
                            label: 'Baca (Menit)',
                            hint: '4',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
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
                          if (!formKey.currentState!.validate()) return;
                          final durasi =
                              int.tryParse(durasiCtrl.text.trim()) ?? 4;
                          final item = AdminEdukasi(
                            id: existing?.id ?? store.newId(),
                            judul: judulCtrl.text.trim(),
                            kategori: kategori,
                            ringkasan: ringkasanCtrl.text.trim(),
                            konten: kontenCtrl.text.trim(),
                            gambar: existing?.gambar ?? 'assets/images/kidneys.jpg',
                            penulis: penulisCtrl.text.trim().isEmpty
                                ? 'Tim Medis GIAT'
                                : penulisCtrl.text.trim(),
                            durasiBaca: durasi,
                            status: EdukasiStatus.published,
                            createdAt: existing?.createdAt ?? DateTime.now(),
                            updatedAt: DateTime.now(),
                          );
                          store.saveEdukasi(item);
                          Navigator.pop(ctx);
                          _showSnack(
                            existing == null
                                ? 'Artikel edukasi berhasil ditambahkan!'
                                : 'Artikel edukasi berhasil diperbarui!',
                          );
                        },
                        child: Text(
                          existing == null ? 'Simpan Artikel' : 'Simpan Perubahan',
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
                  const SizedBox(width: 8),
                  Text(
                    '• ${item.durasiBaca} menit baca',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
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

