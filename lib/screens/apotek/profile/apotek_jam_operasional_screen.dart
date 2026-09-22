import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/apotek_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MENGUBAH JAM OPERASIONAL APOTEK (Figma Node: 1100-26849 & 1100-25230)
// ─────────────────────────────────────────────────────────────────────────────

class ApotekJamOperasionalScreen extends StatefulWidget {
  const ApotekJamOperasionalScreen({super.key});

  @override
  State<ApotekJamOperasionalScreen> createState() => _ApotekJamOperasionalScreenState();
}

class _ApotekJamOperasionalScreenState extends State<ApotekJamOperasionalScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF8FAF9);
  static const _border = Color(0xFFE2E8F0);

  final List<ApotekDaySchedule> _schedules = ApotekMockData.schedules;
  bool _showAuditLog = false;

  void _applyToAll(ApotekDaySchedule template) {
    setState(() {
      for (final s in _schedules) {
        s.isOpen = template.isOpen;
        s.openTime = template.openTime;
        s.closeTime = template.closeTime;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Jadwal ${template.dayName} (${template.openTime} - ${template.closeTime}) diterapkan ke seluruh hari.'),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveSchedules() {
    setState(() {
      _showAuditLog = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () {
            if (_showAuditLog) {
              setState(() => _showAuditLog = false);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _showAuditLog ? 'Log Pembaruan Jam' : 'Ubah Jam Operasional',
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
        child: _showAuditLog ? _buildAuditLogView() : _buildEditorView(),
      ),
    );
  }

  // ── Editor View (Figma Node 1100:26849) ──
  Widget _buildEditorView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chat Info Header
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.schedule_rounded, color: _darkGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Layanan Telefarmasi • Ketersediaan Resep Otomatis',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF14532D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pasien ginjal dan kronis dapat menebus resep sesuai jendela waktu aktif apotek Anda.',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF166534)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Days List
                ..._schedules.map((schedule) => _buildDayScheduleCard(schedule)),

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
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonDarkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveSchedules,
              child: Text(
                'Simpan Jam Operasional',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayScheduleCard(ApotekDaySchedule s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: s.isOpen ? _darkGreen : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        s.shortDay,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: s.isOpen ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    s.dayName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    s.isOpen ? 'Buka Layanan' : 'Tutup Layanan',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: s.isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch.adaptive(
                    value: s.isOpen,
                    activeColor: _darkGreen,
                    onChanged: (val) {
                      setState(() => s.isOpen = val);
                    },
                  ),
                ],
              ),
            ],
          ),

          if (s.isOpen) ...[
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jam Buka', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAF9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _border),
                        ),
                        child: Text(
                          s.openTime,
                          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('-', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jam Tutup', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAF9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _border),
                        ),
                        child: Text(
                          s.closeTime,
                          style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _applyToAll(s),
                child: Text(
                  'Terapkan ke Semua Hari',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _darkGreen),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Audit Log View (Figma Node 1100:25230) ──
  Widget _buildAuditLogView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Berhasil Disimpan & Sinkron',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF14532D)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Apotek GIAT • Log Pembaruan • Hari ini, 16:00 WIB',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Detail Perubahan Jadwal Card
          Text('Detail Jam Operasional', style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
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
                _buildAuditRow('Senin - Sabtu', '08:00 - 21:00 WIB'),
                const Divider(height: 18),
                _buildAuditRow('Minggu', '08:00 - 20:00 WIB (Tutup 1 jam lebih awal)'),
                const Divider(height: 18),
                _buildAuditRow('Libur Nasional', '09:00 - 17:00 WIB (Khusus)'),
                const Divider(height: 18),
                Text(
                  'Jadwal telah otomatis terintegrasi ke tampilan telemedisin pasien dan layanan kurir pengantaran GIAT.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569), height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Audit Informasi Sistem (Figma Node 1100:25230)
          Text('Audit Informasi Sistem', style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
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
                _buildAuditRow('Diubah oleh', 'Apt. Sarah Kusuma, S.Farm'),
                const SizedBox(height: 4),
                Text('Staf Admin Operasional Apotek', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8))),
                const Divider(height: 18),
                _buildAuditRow('Alasan Perubahan', 'Penyesuaian shift staf malam & efisiensi distribusi logistik.'),
                const Divider(height: 18),
                _buildAuditRow('Waktu Pencatatan', '30 Agu 2026, 16:00:41 WIB'),
                const Divider(height: 18),
                _buildAuditRow('Dampak Pesanan', 'Resep masuk setelah pukul 20:00 WIB diproses Senin 08:00 WIB.'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _darkGreen,
                side: const BorderSide(color: _darkGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => _showAuditLog = false),
              child: Text('Ubah Jadwal Lagi', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
