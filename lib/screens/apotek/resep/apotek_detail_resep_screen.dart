import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL RESEP DOKTER (Figma Node: 1100-22582, 1100-23057 & 1100-22735)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekDetailResepScreen extends StatefulWidget {
  final ApotekRecipe recipe;
  final VoidCallback? onStatusChanged;
  final Function(int targetTab)? onNavigateToOrderTab;

  const ApotekDetailResepScreen({
    super.key,
    required this.recipe,
    this.onStatusChanged,
    this.onNavigateToOrderTab,
  });

  @override
  State<ApotekDetailResepScreen> createState() => _ApotekDetailResepScreenState();
}

class _ApotekDetailResepScreenState extends State<ApotekDetailResepScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  /// Figma Node 1100:23057: Pop Up Validasi Mulai Proses Resep
  void _showAcceptConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Mulai Proses Resep?',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Pesanan ${widget.recipe.id} akan dipindahkan ke daftar resep yang sedang diproses. Pastikan resep dan ketersediaan obat telah diperiksa.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF475569),
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _buttonDarkGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final newOrder = ApotekMockData.acceptRecipeAndCreateOrder(widget.recipe);
              setState(() {});
              widget.onStatusChanged?.call();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Resep diverifikasi! Pesanan ${newOrder.id} masuk ke antrean MENUNGGU.',
                  ),
                  backgroundColor: _darkGreen,
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Buka Pesanan',
                    textColor: const Color(0xFF86EFAC),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onNavigateToOrderTab?.call(0);
                    },
                  ),
                ),
              );
            },
            child: Text(
              'Mulai Proses',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _advanceRecipeStatus() {
    if (widget.recipe.status == ApotekRecipeStatus.belumDiverifikasi) {
      _showAcceptConfirmationDialog();
    } else if (widget.recipe.status == ApotekRecipeStatus.diverifikasi) {
      setState(() {
        widget.recipe.status = ApotekRecipeStatus.selesai;
        widget.recipe.completedTime = 'Hari ini, 15:30 WIB';
      });
      widget.onStatusChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Penyiapan resep ${widget.recipe.id} telah selesai.'),
          backgroundColor: _darkGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;

    String badgeText;
    Color badgeBg;
    Color badgeColor;
    String actionBtnText;
    bool isCompleted = r.status == ApotekRecipeStatus.selesai;

    switch (r.status) {
      case ApotekRecipeStatus.belumDiverifikasi:
        badgeText = 'Belum Diverifikasi';
        badgeBg = const Color(0xFFFEF3C7);
        badgeColor = const Color(0xFFB45309);
        actionBtnText = 'Terima Resep';
        break;
      case ApotekRecipeStatus.diverifikasi:
        badgeText = 'Diverifikasi';
        badgeBg = const Color(0xFFDCFCE7);
        badgeColor = const Color(0xFF15803D);
        actionBtnText = 'Selesaikan Resep';
        break;
      case ApotekRecipeStatus.selesai:
        badgeText = 'Selesai';
        badgeBg = const Color(0xFFF1F5F9);
        badgeColor = const Color(0xFF64748B);
        actionBtnText = 'Resep Selesai';
        break;
    }

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
          'Detail Resep',
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Summary Card (Figma Node 1100:22582) ──
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.medical_services_rounded, color: _darkGreen, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.id,
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Pasien: ${r.patientName}',
                                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Jumlah Obat: ${r.items.length} item obat',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Informasi Pasien ──
                    Text(
                      'Informasi Pasien',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPatientRow('Nama Pasien', r.patientName),
                          const Divider(height: 18),
                          _buildPatientRow('Nomor Resep', r.medRecNo),
                          const Divider(height: 18),
                          _buildPatientRow('Dokter', r.doctorName),
                          const Divider(height: 18),
                          _buildPatientRow('Tanggal Resep', r.dateText),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Daftar Obat ──
                    Text(
                      'Daftar Obat',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),

                    ...r.items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.medicineName,
                                    style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    item.qtyText,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _darkGreen),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.formAndPack}  •  ${item.doseRule}',
                                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF475569)),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.usageNotes,
                                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        )),

                    // ── Catatan Verifikasi (Figma Node 1100:22735) ──
                    if (r.status == ApotekRecipeStatus.diverifikasi || r.status == ApotekRecipeStatus.selesai) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Catatan Verifikasi',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resep telah diverifikasi oleh apoteker.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF14532D),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    r.verifiedTime ?? '31 Agustus 2026, 22:15 WIB',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted ? const Color(0xFF94A3B8) : _buttonDarkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isCompleted ? null : _advanceRecipeStatus,
                  child: Text(
                    actionBtnText,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
