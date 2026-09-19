import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'catat_kesehatan_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PANTAU: MONITORING KESEHATAN GINJAL PASIEN
// ─────────────────────────────────────────────────────────────────────────────

class PantauDashboardScreen extends StatefulWidget {
  final bool isEmbedded;

  const PantauDashboardScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<PantauDashboardScreen> createState() => _PantauDashboardScreenState();
}

class _PantauDashboardScreenState extends State<PantauDashboardScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonGreen = Color(0xFF044E2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _darkGreen, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Pantau Kesehatan Ginjal',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: _darkGreen),
                  tooltip: 'Riwayat Catatan',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Membuka riwayat lengkap rekam medis...')),
                    );
                  },
                ),
              ],
            ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          widget.isEmbedded ? (MediaQuery.of(context).padding.top + 72) : 20,
          20,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEmbedded) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pantau Kesehatan',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.history_rounded, color: _darkGreen, size: 22),
                      tooltip: 'Riwayat Catatan',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Membuka riwayat lengkap rekam medis...')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Status Stadium Ginjal Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF065A37), Color(0xFF15964F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF065A37).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kondisi Ginjal: Stabil (Stadium 3a)',
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'eGFR 58 ml/min • Tensi terkontrol baik',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Metrik Utama Grid
            Text(
              'Indikator Utama',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildMetricCard(
                  title: 'Tekanan Darah',
                  value: '120/80',
                  unit: 'mmHg',
                  status: 'Normal',
                  statusColor: const Color(0xFF16A34A),
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFEF4444),
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  title: 'Kreatinin Serum',
                  value: '1.5',
                  unit: 'mg/dL',
                  status: 'Stabil',
                  statusColor: const Color(0xFF16A34A),
                  icon: Icons.science_rounded,
                  iconColor: const Color(0xFF0284C7),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetricCard(
                  title: 'eGFR Filtrasi',
                  value: '58',
                  unit: 'mL/min',
                  status: 'CKD Stage 3',
                  statusColor: const Color(0xFFD97706),
                  icon: Icons.speed_rounded,
                  iconColor: const Color(0xFFD97706),
                ),
                const SizedBox(width: 12),
                _buildMetricCard(
                  title: 'Asupan Cairan',
                  value: '1.200',
                  unit: '/ 1.500 ml',
                  status: '80% Target',
                  statusColor: const Color(0xFF16A34A),
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF06B6D4),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tren Grafik Mingguan
            Text(
              'Tren Tekanan Darah (7 Hari Terakhir)',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rata-rata: 122/81 mmHg', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _darkGreen)),
                      Text('Target: < 130/80', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBarCol('Sen', 0.65, '120'),
                      _buildBarCol('Sel', 0.70, '124'),
                      _buildBarCol('Rab', 0.62, '118'),
                      _buildBarCol('Kam', 0.68, '122'),
                      _buildBarCol('Jum', 0.75, '128'),
                      _buildBarCol('Sab', 0.64, '120'),
                      _buildBarCol('Min', 0.66, '121'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Catatan Terbaru
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Catatan Terakhir',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                ),
                Text(
                  'Lihat Semua',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _darkGreen),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildLogItem('Pagi Ini, 07:30 WIB', 'Tensi: 120/80 • Asupan Air: 350 ml', 'Kondisi segar, tidak ada bengkak'),
            const SizedBox(height: 8),
            _buildLogItem('Kemarin, 20:00 WIB', 'Tensi: 122/82 • Minum Obat Malam: Selesai', 'Tekanan darah stabil setelah istirahat'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _buttonGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Catat Data', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CatatKesehatanScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                Icon(icon, size: 18, color: iconColor),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                const SizedBox(width: 4),
                Text(unit, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarCol(String day, double heightPct, String label) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B))),
        const SizedBox(height: 4),
        Container(
          width: 18,
          height: 80 * heightPct,
          decoration: BoxDecoration(
            color: _darkGreen,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(day, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
      ],
    );
  }

  Widget _buildLogItem(String time, String title, String note) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_outline_rounded, color: _darkGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 2),
                Text(note, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                const SizedBox(height: 3),
                Text(time, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
