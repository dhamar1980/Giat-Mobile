import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../profile/profile_pasien_screen.dart';
import '../widgets/pasien_bottom_navbar.dart';
import 'catat_kondisi_screen.dart';
import 'riwayat_pemantauan_screen.dart';
import '../../../widgets/giat_background.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL DATA PENCATATAN BERAT BADAN
// ─────────────────────────────────────────────────────────────────────────────

class WeightRecord {
  final String date;
  final double weight;
  final String note;

  const WeightRecord({
    required this.date,
    required this.weight,
    this.note = '',
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTAU: MONITORING KESEHATAN PASIEN (Figma Screen: Pantau Pasien)
// ─────────────────────────────────────────────────────────────────────────────

class PantauDashboardScreen extends StatefulWidget {
  final String userName;
  final bool isEmbedded;

  const PantauDashboardScreen({
    super.key,
    this.userName = 'Pasien',
    this.isEmbedded = false,
  });

  @override
  State<PantauDashboardScreen> createState() => _PantauDashboardScreenState();
}

class _PantauDashboardScreenState extends State<PantauDashboardScreen> {
  // Theme colors matching the design
  static const _darkGreen = Color(0xFF065A37);
  static const _buttonGreen = Color(0xFF044E2F);
  static const _bubbleDarkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);

  // User health tracking state
  double _heightCm = 170.0;
  double _currentWeight = 65.2;
  String _kondisiTubuh = 'Baik';
  String _keluhan = 'Tidak Ada';

  // Weight records for line chart (01 Sep, 05 Sep, 10 Sep, 15 Sep)
  late List<WeightRecord> _weightRecords;

  // Complete history records
  late List<PemantauanRecord> _allHistoryRecords;

  @override
  void initState() {
    super.initState();
    _weightRecords = [
      const WeightRecord(date: '01 Sep', weight: 65.0, note: 'Normal'),
      const WeightRecord(date: '05 Sep', weight: 65.5, note: 'Pola makan teratur'),
      const WeightRecord(date: '10 Sep', weight: 64.8, note: 'Aktivitas cukup'),
      const WeightRecord(date: '15 Sep', weight: 65.2, note: 'Terakhir dicatat'),
    ];

    _allHistoryRecords = [
      const PemantauanRecord(
        dateStr: '06 September 2026 • 07:30 WIB',
        badgeText: 'Terbaru',
        imt: 22.5,
        heightCm: 170,
        weightKg: 65.0,
        kondisiTubuh: 'Baik',
        keluhan: 'Tidak ada keluhan',
      ),
      const PemantauanRecord(
        dateStr: '06 September 2026 • 07:15 WIB',
        badgeText: '1 hari lalu',
        imt: 22.6,
        heightCm: 170,
        weightKg: 65.5,
        kondisiTubuh: 'Kurang Baik',
        keluhan: 'Mudah lelah',
      ),
      const PemantauanRecord(
        dateStr: '07 September 2026 • 06:15 WIB',
        badgeText: '2 hari lalu',
        imt: 22.5,
        heightCm: 170,
        weightKg: 65.0,
        kondisiTubuh: 'Baik',
        keluhan: 'Tidak ada keluhan',
      ),
    ];
  }

  // Calculate IMT
  double get _calculatedImt {
    final hMeter = _heightCm / 100.0;
    if (hMeter <= 0) return 22.5;
    final val = _currentWeight / (hMeter * hMeter);
    return double.parse(val.toStringAsFixed(1));
  }

  String get _imtCategory {
    final imt = _calculatedImt;
    if (imt < 18.5) return 'Kurus';
    if (imt <= 24.9) return 'Normal';
    if (imt <= 29.9) return 'Kelebihan';
    return 'Obesitas';
  }

  String _formatNumber(double val) {
    return val.toStringAsFixed(1).replaceAll('.', ',');
  }

  Future<void> _handleOpenCatatKondisi() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CatatKondisiScreen(
          currentWeight: _currentWeight,
          heightCm: _heightCm,
          userName: widget.userName,
        ),
      ),
    );

    if (result != null && mounted) {
      final double newWeight = (result['weight'] as num).toDouble();
      final double newHeight = (result['height'] as num).toDouble();
      final String newKondisi = result['kondisi'] as String;
      final String newKeluhan = result['keluhan'] as String;

      setState(() {
        _currentWeight = newWeight;
        _heightCm = newHeight;
        _kondisiTubuh = newKondisi;
        _keluhan = newKeluhan;

        // Add to line chart points
        _weightRecords = List.from(_weightRecords)
          ..removeAt(0)
          ..add(WeightRecord(
            date: 'Hari Ini',
            weight: newWeight,
            note: newKondisi,
          ));

        // Add to history records
        _allHistoryRecords = [
          PemantauanRecord(
            dateStr: 'Hari Ini • ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} WIB',
            badgeText: 'Terbaru',
            imt: _calculatedImt,
            heightCm: newHeight.toInt(),
            weightKg: newWeight,
            kondisiTubuh: newKondisi,
            keluhan: newKeluhan == 'Tidak Ada' ? 'Tidak ada keluhan' : newKeluhan,
          ),
          ..._allHistoryRecords,
        ];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan kondisi hari ini berhasil disimpan! ✅'),
          backgroundColor: _darkGreen,
        ),
      );
    }
  }

  void _handleOpenRiwayat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiwayatPemantauanScreen(
          userName: widget.userName,
          records: _allHistoryRecords,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Top Header Banner with Curved Arc & Chat Bubbles (Fixed at top, does not scroll) ──
        _buildHeaderSection(),

        // ── Scrollable Body Content Below Header ──
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.only(bottom: 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── 2. Kondisi Tubuh Saat Ini ──
                  _buildKondisiTubuhSection(),

                  const SizedBox(height: 22),

                  // ── 3. Kondisi Hari Ini ──
                  _buildKondisiHariIniSection(),

                  const SizedBox(height: 22),

                  // ── 4. Perkembangan Berat Badan (Chart) ──
                  _buildPerkembanganBeratBadanSection(),

                  const SizedBox(height: 22),

                  // ── 5. Tips untukmu ──
                  _buildTipsSection(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PantauTopographyPainter(),
            ),
          ),
          Positioned.fill(
            child: content,
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PantauTopographyPainter(),
            ),
          ),
          Positioned.fill(
            child: content,
          ),
        ],
      ),
      bottomNavigationBar: PasienBottomNavbar(
        currentIndex: 3,
        userName: widget.userName,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. TOP HEADER BANNER (Gradient, Organic Curves & 1 Chat Bubble)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderSection() {
    final topPadding = widget.isEmbedded
        ? (MediaQuery.of(context).padding.top + 78)
        : (MediaQuery.of(context).padding.top + 16);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF22C55E),
            Color(0xFF16A34A),
            Color(0xFF0D7A3E),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
      ),
      child: Stack(
        children: [
          // Background organic curves
          Positioned.fill(
            child: CustomPaint(
              painter: _PantauHeaderCurvePainter(),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Standalone top action pill (bell & profile)
                if (!widget.isEmbedded) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                size: 22,
                                color: Color(0xFF1F2937),
                              ),
                              tooltip: 'Notifikasi',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tidak ada notifikasi baru.')),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfilePasienScreen(userName: widget.userName),
                                  ),
                                );
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF044E2F),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_rounded, size: 20, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Single Chat Bubble ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pantau Kesehatan yuk.. 👋',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _bubbleDarkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Catat kondisi tubuhmu dan lihat perkembangannya dari waktu ke waktu ✨✨',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _bubbleDarkGreen.withValues(alpha: 0.9),
                            height: 1.35,
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

  // ───────────────────────────────────────────────────────────────────────────
  // 2. SECTION: KONDISI TUBUH SAAT INI (IMT, Tinggi, Berat)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKondisiTubuhSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kondisi Tubuh Saat Ini',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle corner contour decoration
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    painter: _CardCornerContoursPainter(),
                  ),
                ),
              ),
              // Top-right status badge (e.g. Normal)
              Positioned(
                top: 16,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF044E2F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _imtCategory,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  children: [
                    // IMT value centered
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'IMT',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatNumber(_calculatedImt),
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Two columns: Tinggi Badan & Berat Badan
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Tinggi Badan',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${_heightCm.toInt()}',
                                      style: GoogleFonts.inter(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'cm',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Berat Badan',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${_currentWeight.toInt()}',
                                      style: GoogleFonts.inter(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'kg',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. SECTION: KONDISI HARI INI (Cards + Action Button)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKondisiHariIniSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kondisi Hari Ini',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 1: Kondisi Tubuh
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: const Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        color: Color(0xFF15803D),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kondisi Tubuh',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _kondisiTubuh,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Card 2: Keluhan
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cardBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Color(0xFF15803D),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keluhan',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _keluhan,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Full width green button: + Catat Kondisi hari Ini
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _buttonGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _handleOpenCatatKondisi,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle_outline_rounded, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Catat  Kondisi hari Ini',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. SECTION: PERKEMBANGAN BERAT BADAN (Chart & Highlight Banner)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPerkembanganBeratBadanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Perkembangan Berat Badan',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _handleOpenRiwayat,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Riwayat',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _darkGreen,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_circle_right_outlined,
                    size: 18,
                    color: _darkGreen,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header inside card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terakhir dicatat (15 Sep)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _formatNumber(_currentWeight),
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              TextSpan(
                                text: ' kg',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Pill: Catatan Terakhir
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF065A37),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_weightRecords.length} Catatan Terakhir',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Custom Line Chart ──
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WeightLineChartPainter(records: _weightRecords),
                ),
              ),

              const SizedBox(height: 12),

              // ── Highlight Status Tubuh Container ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0F2FE)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Highlight Status Tubuh:   ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      'IMT Saat Ini: ${_formatNumber(_calculatedImt)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA7F3D0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _imtCategory,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. SECTION: TIPS UNTUKMU
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTipsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EDF8)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF5EEAD4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF044E2F),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tips untukmu',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Jaga pola makan seimbang, tetap aktif bergerak, dan perhatikan perubahan kondisi tubuhmu.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE2EDF8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF0F766E),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Jika kamu memiliki penyakit ginjal, kebutuhan cairan dapat berbeda pada setiap orang. Ikuti anjuran dokter mengenai jumlah cairan yang sesuai untukmu.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                      height: 1.45,
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

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: LINE CHART BERAT BADAN
// ─────────────────────────────────────────────────────────────────────────────

class _WeightLineChartPainter extends CustomPainter {
  final List<WeightRecord> records;

  _WeightLineChartPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    const leftPadding = 24.0;
    const rightPadding = 24.0;
    const topPadding = 28.0;
    const bottomPadding = 42.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Find min and max weight
    double minWeight = 64.4;
    double maxWeight = 65.8;

    // Draw horizontal dashed grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final y = topPadding + (chartHeight / 2) * i;
      _drawDashedLine(canvas, Offset(leftPadding - 8, y), Offset(size.width - rightPadding + 8, y), gridPaint);
    }

    // Calculate point coordinates
    final points = <Offset>[];
    for (int i = 0; i < records.length; i++) {
      final x = leftPadding + (i * (chartWidth / (records.length - 1)));
      final weight = records[i].weight;
      final normalized = (weight - minWeight) / (maxWeight - minWeight);
      final y = topPadding + (1 - normalized.clamp(0.0, 1.0)) * chartHeight;
      points.add(Offset(x, y));
    }

    // 1. Draw gradient fill area under the line
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, topPadding + chartHeight);
    fillPath.lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath.lineTo(points.last.dx, topPadding + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.18),
          const Color(0xFF10B981).withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    // 2. Draw solid line connecting the points
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF044E2F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // 3. Draw nodes and text labels
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isLatest = (i == points.length - 1);
      final rec = records[i];

      // Draw node circle
      if (isLatest) {
        // Solid green circle for current point
        final dotPaint = Paint()..color = const Color(0xFF10B981);
        canvas.drawCircle(pt, 5.5, dotPaint);
      } else {
        // Hollow circle with white center and green ring
        final outerPaint = Paint()
          ..color = const Color(0xFF044E2F)
          ..style = PaintingStyle.fill;
        final innerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(pt, 5.5, outerPaint);
        canvas.drawCircle(pt, 3.2, innerPaint);
      }

      // Draw weight value label (for point 2 '64.8', put it below the point as shown in the design)
      final valStr = rec.weight.toStringAsFixed(1);
      final isBelow = (i == 2); // 64.8 is lowest point, label placed below
      final labelY = isBelow ? (pt.dy + 7) : (pt.dy - 19);

      final textSpan = TextSpan(
        text: valStr,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: isLatest ? FontWeight.w800 : FontWeight.w700,
          color: isLatest ? const Color(0xFF044E2F) : const Color(0xFF0F172A),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(pt.dx - (textPainter.width / 2), labelY),
      );

      // Draw X-axis date label
      final dateSpan = TextSpan(
        text: rec.date,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: isLatest ? FontWeight.w700 : FontWeight.w500,
          color: isLatest ? const Color(0xFF044E2F) : const Color(0xFF334155),
        ),
      );
      final datePainter = TextPainter(
        text: dateSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      datePainter.paint(
        canvas,
        Offset(pt.dx - (datePainter.width / 2), size.height - 18),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(
        Offset(startX, p1.dy),
        Offset(startX + dashWidth, p1.dy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _WeightLineChartPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: CARD CORNER DECORATIVE CONTOURS
// ─────────────────────────────────────────────────────────────────────────────

class _CardCornerContoursPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Top-left organic waves
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offset = 10.0 + (i * 12);
      path.moveTo(0, offset + 20);
      path.cubicTo(
        offset + 10,
        offset + 25,
        offset + 25,
        offset + 10,
        offset + 35,
        0,
      );
      canvas.drawPath(path, paint);
    }

    // Bottom-right organic waves
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final offset = 10.0 + (i * 12);
      path.moveTo(size.width, size.height - (offset + 20));
      path.cubicTo(
        size.width - (offset + 10),
        size.height - (offset + 25),
        size.width - (offset + 25),
        size.height - (offset + 10),
        size.width - (offset + 35),
        size.height,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: HEADER ORGANIC CURVE
// ─────────────────────────────────────────────────────────────────────────────

class _PantauHeaderCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 4; i++) {
      final path = Path();
      final yOffset = 40.0 + (i * 40);
      path.moveTo(0, yOffset);
      path.cubicTo(
        size.width * 0.25,
        yOffset + 30,
        size.width * 0.75,
        yOffset - 30,
        size.width,
        yOffset + 20,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: BACKGROUND TOPOGRAPHY
// ─────────────────────────────────────────────────────────────────────────────

class _PantauTopographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    GiatBackgroundPainter.paintBackground(
      canvas,
      size,
      showGradient: true,
      showLines: true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
