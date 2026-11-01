import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/admin_models.dart';
import '../widgets/admin_header.dart';

class AdminUpdateSistemScreen extends StatefulWidget {
  final Widget? trailingAction;

  const AdminUpdateSistemScreen({
    super.key,
    this.trailingAction,
  });

  @override
  State<AdminUpdateSistemScreen> createState() =>
      _AdminUpdateSistemScreenState();
}

class _AdminUpdateSistemScreenState extends State<AdminUpdateSistemScreen> {
  static const _primaryGreen = Color(0xFF006D37);
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _textColor = Color(0xFF091D2E);
  static const _subtextColor = Color(0xFF475569);
  static const _border = Color(0xFFE2E8F0);

  UpdateTipe? _selectedTipe; // null = Semua

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

  void _showAddUpdateSheet() {
    final store = AdminStore.instance;
    final judulCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    UpdateTipe tipe = UpdateTipe.fitur;
    String targetRole = 'semua';
    final formKey = GlobalKey<FormState>();

    final targets = const [
      {'key': 'semua', 'label': 'Semua Pengguna'},
      {'key': 'pasien', 'label': 'Pasien'},
      {'key': 'dokter', 'label': 'Dokter'},
      {'key': 'apotek', 'label': 'Apotek'},
    ];

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
                      'Kirim Notifikasi Update Sistem',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Publikasikan informasi pembaruan aplikasi atau jadwal pemeliharaan ke pengguna GIAT.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tipe Update
                    Text(
                      'Tipe Pembaruan',
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
                      children: UpdateTipe.values.map((t) {
                        final isSelected = tipe == t;
                        return GestureDetector(
                          onTap: () => setModalState(() => tipe = t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? t.color
                                  : t.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? t.color
                                    : t.color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  t.icon,
                                  size: 16,
                                  color: isSelected ? Colors.white : t.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  t.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : t.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),
                    // Target Penerima
                    Text(
                      'Target Penerima Notifikasi',
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
                      children: targets.map((tg) {
                        final isSelected = targetRole == tg['key'];
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => targetRole = tg['key']!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _darkGreen
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? _darkGreen : _border,
                              ),
                            ),
                            child: Text(
                              tg['label']!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: judulCtrl,
                      label: 'Judul Update',
                      hint: 'Contoh: Pembaruan Fitur Chat',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Judul wajib diisi'
                          : null,
                    ),

                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: deskripsiCtrl,
                      label: 'Rincian / Pesan Notifikasi Update',
                      hint:
                          'Jelaskan rincian fitur baru, perbaikan bug, atau jadwal pemeliharaan sistem...',
                      maxLines: 4,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Deskripsi wajib diisi'
                          : null,
                    ),

                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _buttonDarkGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final newUpdate = AdminSystemUpdate(
                            id: store.newId(),
                            versi: '',
                            judul: judulCtrl.text.trim(),
                            deskripsi: deskripsiCtrl.text.trim(),
                            tipe: tipe,
                            targetRole: targetRole,
                            isPenting: false,
                            publishedAt: DateTime.now(),
                          );
                          store.addUpdate(newUpdate);
                          Navigator.pop(ctx);
                          _showSnack(
                            'Notifikasi "${newUpdate.judul}" berhasil dikirim ke ${newUpdate.targetLabel}!',
                          );
                        },
                        icon: const Icon(Icons.campaign_rounded, size: 20),
                        label: Text(
                          'Publikasikan & Kirim Notifikasi',
                          style: GoogleFonts.inter(
                            fontSize: 14,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
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
          final filtered = _selectedTipe == null
              ? store.updates
              : store.updates.where((u) => u.tipe == _selectedTipe).toList();

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
                      title: 'Update Notifikasi Sistem 📢',
                      subtitle:
                          'Kirim notifikasi update sistem baru & lihat riwayat notifikasi yang sudah dipublikasikan (dikirim). ✨',
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
                            // Filter Chips Tipe Update
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildFilterChip(null, 'Semua'),
                                  const SizedBox(width: 8),
                                  ...UpdateTipe.values.map(
                                    (t) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: _buildFilterChip(t, t.label),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Keterangan bahwa daftar ini adalah riwayat notifikasi yang sudah dikirim
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 15,
                                  color: _primaryGreen,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Riwayat Notifikasi yang Sudah Dipublikasikan (Dikirim)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _subtextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // List of Update Notifications
                            Expanded(
                              child: filtered.isEmpty
                                  ? _buildEmptyState()
                                  : RefreshIndicator(
                                      color: _darkGreen,
                                      onRefresh: store.fetchSystemUpdates,
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: filtered.length,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(
                                          parent: BouncingScrollPhysics(),
                                        ),
                                        itemBuilder: (context, index) {
                                          final u = filtered[index];
                                          return _buildUpdateCard(u);
                                        },
                                      ),
                                    ),
                            ),

                            // Bottom Button: "Kirim Notifikasi Update Sistem"
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
              Icons.notifications_paused_outlined,
              size: 40,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada notifikasi update',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Klik tombol di bawah untuk mengirim notifikasi update baru',
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
        onPressed: _showAddUpdateSheet,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign_rounded, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Kirim Notifikasi Update Sistem',
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

  Widget _buildFilterChip(UpdateTipe? tipe, String label) {
    final isSelected = _selectedTipe == tipe;
    return GestureDetector(
      onTap: () => setState(() => _selectedTipe = tipe),
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

  Widget _buildUpdateCard(AdminSystemUpdate u) {
    Color iconBgColor;
    switch (u.tipe) {
      case UpdateTipe.fitur:
        iconBgColor = const Color(0xFFD5E8F0);
        break;
      case UpdateTipe.perbaikan:
        iconBgColor = const Color(0xFFE0F2FE);
        break;
      case UpdateTipe.pemeliharaan:
        iconBgColor = const Color(0xFFEDE9FE);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _border,
          width: 0.8,
        ),
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
                // Icon Container (Soft background with rounded corners like Reminder Card)
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      u.tipe.icon,
                      color: _textColor,
                      size: 26,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Info Column: Title + Time Pill, Subtitle & Target/Status
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
                                u.judul,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _textColor,
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
                                u.waktuText ?? adminTimeAgo(u.publishedAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          u.deskripsi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _subtextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: u.tipe.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                u.tipe.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: u.tipe.color,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Terkirim • ${u.targetLabel}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryGreen,
                                ),
                              ),
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
}

