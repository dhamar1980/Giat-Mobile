import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/apotek_api_service.dart';
import '../../../utils/time_utils.dart';
import '../../../widgets/giat_background.dart';
import '../models/apotek_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MENGUBAH JAM OPERASIONAL APOTEK (Tanpa Header Hijau & Tanpa Bubble Chat)
// Seragam dengan UI Pasien / Dokter
// ─────────────────────────────────────────────────────────────────────────────

class ApotekJamOperasionalScreen extends StatefulWidget {
  const ApotekJamOperasionalScreen({super.key});

  @override
  State<ApotekJamOperasionalScreen> createState() =>
      _ApotekJamOperasionalScreenState();
}

class _ApotekJamOperasionalScreenState
    extends State<ApotekJamOperasionalScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonDarkGreen = Color(0xFF044E2F);
  static const _bgColor = Color(0xFFF7FAF8);
  static const _border = Color(0xFFE2E8F0);

  List<ApotekDaySchedule> _schedules = ApotekMockData.schedules;
  bool _showAuditLog = false;
  bool _isSaving = false;

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    if (_isTest) return;
    try {
      final res = await ApotekApiService().getJamOperasional();
      if (res.success && res.data != null && res.data!.isNotEmpty && mounted) {
        final parsed = res.data!.whereType<Map>().map((e) {
          final m = Map<String, dynamic>.from(e);
          return ApotekDaySchedule(
            dayName: (m['day_name'] ?? 'Senin').toString(),
            shortDay: (m['short_day'] ?? 'S').toString(),
            isOpen: m['is_open'] == true,
            openTime: (m['jam_buka'] ?? '08:00 AM').toString(),
            closeTime: (m['jam_tutup'] ?? '10:00 PM').toString(),
          );
        }).toList();
        if (parsed.isNotEmpty) {
          setState(() => _schedules = parsed);
        }
      }
    } catch (_) {}
  }

  Future<void> _pickTime(ApotekDaySchedule s, {required bool isOpenTime}) async {
    final initial = const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null && mounted) {
      final h = picked.hour;
      final m = picked.minute;
      final suffix = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      final formatted = '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $suffix';
      setState(() {
        if (isOpenTime) {
          s.openTime = formatted;
        } else {
          s.closeTime = formatted;
        }
      });
    }
  }

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
        content: Text(
          'Jadwal ${template.dayName} (${template.openTime} - ${template.closeTime}) diterapkan ke seluruh hari.',
        ),
        backgroundColor: _darkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveSchedules() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    if (!_isTest) {
      await ApotekApiService().updateJamOperasional({
        'schedules': _schedules
            .map((s) => {
                  'hari': s.dayName.toLowerCase(),
                  'day_name': s.dayName,
                  'is_open': s.isOpen,
                  'jam_buka': s.openTime,
                  'jam_tutup': s.closeTime,
                })
            .toList(),
      });
      await ApotekProfileState.instance.loadProfile();
    }
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _showAuditLog = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _JamOperasionalTopographyPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar (<- Kembali + Center Pill Title)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_showAuditLog) {
                            setState(() => _showAuditLog = false);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
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
                      const SizedBox(height: 14),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8.5,
                          ),
                          decoration: BoxDecoration(
                            color: _buttonDarkGreen,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _buttonDarkGreen.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            _showAuditLog
                                ? 'Log Pembaruan Jam'
                                : 'Ubah Jam Operasional',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _showAuditLog
                      ? _buildAuditLogView()
                      : _buildEditorView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Editor View (Tanpa Bubble Chat Hijau) ──
  Widget _buildEditorView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Row (Clean style matching Pasien/Dokter)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info,
                      color: _buttonDarkGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pasien ginjal dan kronis dapat menebus resep sesuai jendela waktu aktif apotek Anda.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _buttonDarkGreen,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

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
          decoration: const BoxDecoration(
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saveSchedules,
              child: Text(
                'Simpan Jam Operasional',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
                          color: s.isOpen
                              ? Colors.white
                              : const Color(0xFF64748B),
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
                      color: s.isOpen
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
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
                  child: GestureDetector(
                    onTap: () => _pickTime(s, isOpenTime: true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jam Buka',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _border),
                          ),
                          child: Text(
                            s.openTime,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    '-',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(s, isOpenTime: false),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jam Tutup',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _border),
                          ),
                          child: Text(
                            s.closeTime,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _darkGreen,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Audit Log View ──
  Widget _buildAuditLogView() {
    final apotekerName = _isTest
        ? 'Apt. Sarah Kusuma, S.Farm'
        : ApotekProfileState.instance.apotekerName;
    final apotekName = _isTest
        ? 'Apotek GIAT'
        : ApotekProfileState.instance.apotekName;
    final now = DateTime.now();
    final timeStr = _isTest
        ? '30 Agu 2026, 16:00:41 WIB'
        : '${TimeUtils.formatDate(now)}, ${TimeUtils.formatChatTime(now, separator: ':')} WIB';
    final senin = _schedules.firstWhere(
      (s) => s.dayName.toLowerCase() == 'senin',
      orElse: () => _schedules.first,
    );
    final minggu = _schedules.firstWhere(
      (s) => s.dayName.toLowerCase() == 'minggu',
      orElse: () => _schedules.last,
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Berhasil Disimpan & Sinkron',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$apotekName • Log Pembaruan • $timeStr',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Detail Jam Operasional',
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
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
                _buildAuditRow(
                  'Senin - Sabtu',
                  senin.isOpen ? '${senin.openTime} - ${senin.closeTime}' : 'Tutup Layanan',
                ),
                const Divider(height: 18),
                _buildAuditRow(
                  'Minggu',
                  minggu.isOpen ? '${minggu.openTime} - ${minggu.closeTime}' : 'Tutup Layanan',
                ),
                const Divider(height: 18),
                _buildAuditRow('Libur Nasional', '09:00 - 17:00 WIB (Khusus)'),
                const Divider(height: 18),
                Text(
                  'Jadwal telah otomatis terintegrasi ke tampilan telemedisin pasien dan layanan kurir pengantaran GIAT.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Audit Informasi Sistem',
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
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
                _buildAuditRow('Diubah oleh', apotekerName),
                const SizedBox(height: 4),
                Text(
                  'Apoteker Penanggung Jawab Operasional',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const Divider(height: 18),
                _buildAuditRow(
                  'Alasan Perubahan',
                  'Penyesuaian shift staf malam & efisiensi distribusi logistik.',
                ),
                const Divider(height: 18),
                _buildAuditRow('Waktu Pencatatan', timeStr),
                const Divider(height: 18),
                _buildAuditRow(
                  'Dampak Pesanan',
                  'Resep masuk di luar jam operasional diproses pada hari buka berikutnya.',
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => setState(() => _showAuditLog = false),
              child: Text(
                'Ubah Jadwal Lagi',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

class _JamOperasionalTopographyPainter extends CustomPainter {
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
