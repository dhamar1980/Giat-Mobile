import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/admin_models.dart';
import '../widgets/admin_header.dart';

class AdminAkunScreen extends StatefulWidget {
  final AdminUserRole? initialRoleFilter;
  final Widget? trailingAction;

  const AdminAkunScreen({
    super.key,
    this.initialRoleFilter,
    this.trailingAction,
  });

  @override
  State<AdminAkunScreen> createState() => _AdminAkunScreenState();
}

class _AdminAkunScreenState extends State<AdminAkunScreen> {
  static const _primaryGreen = Color(0xFF006D37);
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _textColor = Color(0xFF091D2E);
  static const _subtextColor = Color(0xFF475569);
  static const _border = Color(0xFFE2E8F0);

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua', 'pasien', 'dokter', 'apotek', 'admin', 'nonaktif'

  @override
  void initState() {
    super.initState();
    if (widget.initialRoleFilter != null) {
      _selectedFilter = widget.initialRoleFilter!.key;
    }
  }

  @override
  void didUpdateWidget(covariant AdminAkunScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRoleFilter != oldWidget.initialRoleFilter) {
      setState(() => _selectedFilter = widget.initialRoleFilter?.key ?? 'Semua');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AdminAccount> _getFilteredAccounts(AdminStore store) {
    final byFilter = store.accounts.where((a) {
      if (_selectedFilter != 'Semua') return a.role.key == _selectedFilter;
      return true;
    }).toList();

    if (_searchQuery.trim().isEmpty) return byFilter;
    final q = _searchQuery.toLowerCase().trim();
    return byFilter.where((a) {
      return a.nama.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q) ||
          (a.noHp ?? '').toLowerCase().contains(q) ||
          (a.keterangan ?? '').toLowerCase().contains(q) ||
          a.role.label.toLowerCase().contains(q);
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

  void _showAddAccountSheet() {
    final store = AdminStore.instance;
    final namaCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final noHpCtrl = TextEditingController();
    final ketCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'password123');
    AdminUserRole selectedRole = AdminUserRole.pasien;
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
                      'Tambah Akun Pengguna Baru',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Buat akun baru dan tentukan hak akses (role) di sistem GIAT.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pilihan Role
                    Text(
                      'Hak Akses (Role)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AdminUserRole.values.map((r) {
                        final isSelected = selectedRole == r;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedRole = r),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? r.color : r.softColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? r.color : r.color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  r.icon,
                                  size: 16,
                                  color: isSelected ? Colors.white : r.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  r.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : r.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedRole.description,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildInputField(
                      controller: namaCtrl,
                      label: selectedRole == AdminUserRole.apotek
                          ? 'Nama Apotek / Apoteker'
                          : 'Nama Lengkap',
                      hint: selectedRole == AdminUserRole.dokter
                          ? 'Contoh: dr. Siti Rahma, Sp.PD'
                          : (selectedRole == AdminUserRole.apotek
                              ? 'Contoh: Apotek Kimia Farma Pasteur'
                              : 'Masukkan nama lengkap'),
                      icon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildInputField(
                      controller: emailCtrl,
                      label: 'Alamat Email',
                      hint: 'contoh@giat.id',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                        if (!v.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildInputField(
                      controller: noHpCtrl,
                      label: 'Nomor Telepon / WhatsApp',
                      hint: '0812xxxxxxxx',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    _buildInputField(
                      controller: ketCtrl,
                      label: selectedRole == AdminUserRole.dokter
                          ? 'Spesialisasi / Instansi'
                          : (selectedRole == AdminUserRole.apotek
                              ? 'Alamat Apotek'
                              : 'Keterangan Tambahan (Opsional)'),
                      hint: selectedRole == AdminUserRole.dokter
                          ? 'Contoh: Spesialis Penyakit Dalam'
                          : (selectedRole == AdminUserRole.apotek
                              ? 'Contoh: Jl. Pasteur No. 45, Bandung'
                              : 'Contoh: Pasien CKD Stadium 1'),
                      icon: Icons.info_outline_rounded,
                    ),
                    const SizedBox(height: 12),

                    _buildInputField(
                      controller: passCtrl,
                      label: 'Kata Sandi Awal',
                      hint: 'Minimal 6 karakter',
                      icon: Icons.lock_outline_rounded,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Kata sandi minimal 6 karakter'
                          : null,
                    ),
                    const SizedBox(height: 20),

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
                          final newAcc = AdminAccount(
                            id: store.newId(),
                            nama: namaCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            noHp: noHpCtrl.text.trim().isEmpty ? null : noHpCtrl.text.trim(),
                            role: selectedRole,
                            createdAt: DateTime.now(),
                            keterangan:
                                ketCtrl.text.trim().isEmpty ? null : ketCtrl.text.trim(),
                          );
                          store.addAccount(newAcc);
                          Navigator.pop(ctx);
                          _showSnack(
                            'Akun ${newAcc.nama} (${newAcc.role.label}) berhasil dibuat!',
                          );
                        },
                        child: Text(
                          'Simpan & Buat Akun',
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

  void _showChangeRoleSheet(AdminAccount acc) {
    final store = AdminStore.instance;
    AdminUserRole chosen = acc.role;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                'Ubah Hak Akses Pengguna',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${acc.nama} (${acc.email})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ...AdminUserRole.values.map((r) {
                final isSelected = chosen == r;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setModalState(() => chosen = r),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? r.softColor : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? r.color : _border,
                          width: isSelected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: r.softColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(r.icon, color: r.color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r.description,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected ? r.color : const Color(0xFFCBD5E1),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
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
                    final oldRole = acc.role;
                    store.changeRole(acc, chosen);
                    Navigator.pop(ctx);
                    if (oldRole != chosen) {
                      _showSnack(
                        'Hak akses ${acc.nama} diubah menjadi ${chosen.label}',
                      );
                    }
                  },
                  child: Text(
                    'Simpan Hak Akses',
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
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, size: 19, color: const Color(0xFF64748B)),
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
          final filtered = _getFilteredAccounts(store);

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
                      title: 'Kelola Akun Pengguna 👥',
                      subtitle:
                          'Tambah akun baru dan atur hak akses role (Pasien, Dokter, Apotek, Admin) pengguna GIAT. ✨',
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
                                            'Cari nama, email, atau role...',
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
                                  _buildFilterChip(
                                    'Semua',
                                    'Semua (${store.totalAccounts})',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    'pasien',
                                    'Pasien (${store.countRole(AdminUserRole.pasien)})',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    'dokter',
                                    'Dokter (${store.countRole(AdminUserRole.dokter)})',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    'apotek',
                                    'Apotek (${store.countRole(AdminUserRole.apotek)})',
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                    'admin',
                                    'Admin (${store.countRole(AdminUserRole.admin)})',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // List of Accounts
                            Expanded(
                              child: filtered.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: filtered.length,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                        parent: BouncingScrollPhysics(),
                                      ),
                                      itemBuilder: (context, index) {
                                        final acc = filtered[index];
                                        return _buildAccountCard(acc);
                                      },
                                    ),
                            ),

                            // Bottom Button: "Tambah Akun Pengguna Baru"
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
              Icons.person_search_outlined,
              size: 40,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Tidak ada akun pada filter ini',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Klik tombol di bawah untuk menambah akun baru',
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
        onPressed: _showAddAccountSheet,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tambah Akun Pengguna Baru',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryGreen : _border,
          ),
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

  Widget _buildAccountCard(AdminAccount acc) {
    Color iconBgColor;
    switch (acc.role) {
      case AdminUserRole.pasien:
        iconBgColor = const Color(0xFFE0F2FE);
        break;
      case AdminUserRole.dokter:
        iconBgColor = const Color(0xFFD5E8F0);
        break;
      case AdminUserRole.apotek:
        iconBgColor = const Color(0xFFFEF3C7);
        break;
      case AdminUserRole.admin:
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
                      acc.role.icon,
                      color: _textColor,
                      size: 26,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Info Column: Name + Role Badge, Email, Keterangan & Role Action
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
                                acc.nama,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _textColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showChangeRoleSheet(acc),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _textColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  acc.role.label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          acc.email,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _subtextColor,
                          ),
                        ),
                        if (acc.keterangan != null &&
                            acc.keterangan!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            acc.keterangan!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _showChangeRoleSheet(acc),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.manage_accounts_outlined,
                                  size: 13,
                                  color: _primaryGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Ubah Hak Akses',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: _primaryGreen,
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}

