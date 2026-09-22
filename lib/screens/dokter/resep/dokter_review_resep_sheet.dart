import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dokter_models.dart';
import 'dokter_tambah_obat_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REVIEW RESEP DOKTER (Figma Node: 1620-6976 & 1008-19355)
// ─────────────────────────────────────────────────────────────────────────────

class DokterReviewResepScreen extends StatefulWidget {
  final DokterPatient patient;
  final List<DokterPrescriptionItem>? initialItems;
  final ValueChanged<List<DokterPrescriptionItem>>? onPrescriptionPublished;

  const DokterReviewResepScreen({
    super.key,
    required this.patient,
    this.initialItems,
    this.onPrescriptionPublished,
  });

  @override
  State<DokterReviewResepScreen> createState() => _DokterReviewResepScreenState();
}

class _DokterReviewResepScreenState extends State<DokterReviewResepScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  late List<DokterPrescriptionItem> _prescriptions;

  @override
  void initState() {
    super.initState();
    _prescriptions = widget.initialItems != null
        ? List.from(widget.initialItems!)
        : List.from(widget.patient.currentMedicines.isNotEmpty
            ? widget.patient.currentMedicines
            : DokterMockData.initialPrescriptions);
  }

  void _navigateToAddMedicine([DokterPrescriptionItem? itemToEdit, int? index]) async {
    final result = await Navigator.of(context).push<DokterPrescriptionItem>(
      MaterialPageRoute(
        builder: (_) => DokterTambahObatScreen(
          patient: widget.patient,
          initialItem: itemToEdit,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (index != null) {
          _prescriptions[index] = result;
        } else {
          _prescriptions.add(result);
        }
      });
    }
  }

  void _publishPrescription() {
    if (_prescriptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 obat sebelum menerbitkan resep.')),
      );
      return;
    }

    widget.onPrescriptionPublished?.call(_prescriptions);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resep untuk ${widget.patient.name} berhasil diterbitkan!'),
        backgroundColor: _darkGreen,
      ),
    );

    Navigator.of(context).pop(_prescriptions);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;

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
          'Buat Resep',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
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
                    // Patient Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                p.initials,
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _darkGreen),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Usia: ${p.age} Tahun  •  Kelamin: ${p.gender}',
                                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Alamat: ${p.address}',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section Title: Daftar Obat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daftar Obat',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                        Text(
                          '${_prescriptions.length} Obat',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _darkGreen),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (_prescriptions.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.medication_outlined, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 10),
                            Text(
                              'Belum ada obat yang ditambahkan.',
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _prescriptions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, idx) {
                          final item = _prescriptions[idx];
                          return _buildPrescriptionCard(item, idx);
                        },
                      ),

                    const SizedBox(height: 18),

                    // Button Tambah Obat
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _darkGreen,
                          side: const BorderSide(color: _darkGreen, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () => _navigateToAddMedicine(),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(
                          'Tambah Obat',
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Publish Button Container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _publishPrescription,
                  child: Text(
                    'Terbitkan Resep',
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

  Widget _buildPrescriptionCard(DokterPrescriptionItem item, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.medicineName,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity}  •  ${item.frequency}  •  ${item.duration}',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              // Action Buttons: Edit & Hapus
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _navigateToAddMedicine(item, index),
                    child: Text('Edit', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _darkGreen)),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      setState(() => _prescriptions.removeAt(index));
                    },
                    child: Text('Hapus', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFEF4444))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Dianjurkan: ${item.usageTime}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
          if (item.specialNotes != null && item.specialNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Catatan: ${item.specialNotes}',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}
