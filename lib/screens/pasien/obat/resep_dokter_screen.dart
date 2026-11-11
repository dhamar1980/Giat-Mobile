import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_resep_screen.dart';
import 'checkout_resep_screen.dart';
import '../profile/profile_pasien_screen.dart';
import '../../../services/pasien_api_service.dart';
import '../../../utils/time_utils.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN RESEP DOKTER (Sesuai Desain Figma / Gambar 1 & 2)
// ─────────────────────────────────────────────────────────────────────────────

class ResepDokterScreen extends StatefulWidget {
  final String userName;

  const ResepDokterScreen({
    super.key,
    this.userName = 'Pasien',
  });

  @override
  State<ResepDokterScreen> createState() => _ResepDokterScreenState();
}

class _ResepDokterScreenState extends State<ResepDokterScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _badgeDark = Color(0xFF0F172A);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);
  static const _redStatus = Color(0xFFDC2626);
  static const _greyStatus = Color(0xFF64748B);
  static const _infoBoxBg = Color(0xFFF1F5F9);

  // Daftar data resep dokter
  List<ResepDokterData> _resepList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resepList = [];
    _fetchLiveResep(showLoading: true);
  }

  Future<void> _fetchLiveResep({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await PasienApiService().getResepPasien();
      if (res.success && res.data != null && res.data!.isNotEmpty && mounted) {
        final List<ResepDokterData> parsed = [];
        for (var item in res.data!) {
          if (item is Map) {
            final m = Map<String, dynamic>.from(item);
            final rxNo = (m['no_resep'] ?? m['id_resep'] ?? m['id'] ?? 'RXP-2026').toString();
            final statusStr = (m['status'] ?? '').toString().toLowerCase();

            String statusLabel = 'Belum Ditebus';
            if (statusStr == 'selesai' || statusStr == 'sudah ditebus' || statusStr == 'sudah_ditebus') {
              statusLabel = 'Sudah Ditebus';
            } else if (statusStr == 'kadaluwarsa' || statusStr == 'expired') {
              statusLabel = 'Kadaluwarsa';
            }

            final rawTgl = m['tanggal_resep'] ?? m['created_at'];
            final tglDate = rawTgl != null ? DateTime.tryParse(rawTgl.toString()) : null;
            final tglStr = tglDate != null
                ? TimeUtils.formatDate(tglDate, useIndonesianMonth: true)
                : (rawTgl?.toString() ?? 'Hari ini');

            final expiryDate = tglDate != null
                ? tglDate.add(const Duration(days: 14))
                : DateTime.now().add(const Duration(days: 14));
            final expiryStr = 's.d. ${TimeUtils.formatDate(expiryDate, useIndonesianMonth: true)}';

            final docName = (m['nama_dokter'] ?? 'dr. Spesialis GIAT').toString();
            final docSpec = (m['spesialisasi_dokter'] ?? 'Spesialis Ginjal Hipertensi').toString();
            final docSip = m['no_sip_dokter'] != null
                ? 'SIP: ${m['no_sip_dokter']}'
                : 'SIP: 446/SIP.D/35.09/2024';
            final docImg = (m['foto_dokter'] ?? 'assets/images/dokter_apoteker.jpg').toString();

            final rawItems = m['items'] as List<dynamic>? ?? [];
            final List<ResepObatItem> medItems = [];
            for (var ir in rawItems) {
              if (ir is Map) {
                final irMap = Map<String, dynamic>.from(ir);
                final medName = (irMap['nama_obat'] ?? 'Obat Ginjal').toString();
                final cat = (irMap['catatan_khusus'] ?? 'Protokol Nefrologi GIAT').toString();
                final dosis = (irMap['dosis'] ?? '').toString();
                final aturan = (irMap['aturan_pakai'] ?? '').toString();
                final waktu = (irMap['waktu_penggunaan'] ?? '').toString();
                final qty = irMap['jumlah'] != null ? '${irMap['jumlah']} tab' : '30 tab';

                final aturanCombined = [
                  if (dosis.isNotEmpty) dosis,
                  if (aturan.isNotEmpty) aturan,
                  if (waktu.isNotEmpty) waktu,
                ].join(' • ');

                medItems.add(ResepObatItem(
                  id: irMap['id']?.toString(),
                  name: medName,
                  category: cat.isNotEmpty ? cat : 'Protokol Nefrologi GIAT',
                  badgeText: 'Obat Keras',
                  aturanPakai: aturanCombined.isNotEmpty ? aturanCombined : 'Sesuai petunjuk dokter',
                  jumlahObat: qty,
                  price: int.tryParse(irMap['harga']?.toString() ?? '') ?? 50000,
                ));
              }
            }

            if (medItems.isEmpty) {
              medItems.add(ResepObatItem(
                name: 'Protokol Obat Ginjal',
                category: m['diagnosis']?.toString() ?? 'Nefrologi GIAT',
                badgeText: 'Obat Keras',
                aturanPakai: 'Minum teratur sesuai petunjuk',
                jumlahObat: '30 tab',
                price: 50000,
              ));
            }

            parsed.add(ResepDokterData(
              id: (m['id'] ?? m['id_resep'])?.toString(),
              rxNumber: rxNo.startsWith('No.') ? rxNo : 'No. $rxNo',
              status: statusLabel,
              tanggalTerbit: tglStr,
              masaBerlaku: expiryStr,
              doctorName: docName,
              doctorSpecialty: docSpec,
              doctorSip: docSip,
              doctorImage: docImg,
              mitraPharmacy: 'farmasi mitra GIAT',
              medications: medItems,
            ));
          }
        }

        if (mounted) {
          setState(() {
            _resepList = parsed;
          });
        }
      } else if (mounted) {
        setState(() {
          _resepList = [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching live resep dokter: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Belum Ditebus':
        return _redStatus;
      case 'Sudah Ditebus':
        return _darkGreen;
      case 'Kadaluwarsa':
        return _greyStatus;
      default:
        return _redStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topography Curves
          Positioned.fill(
            child: CustomPaint(
              painter: _ResepDokterTopographyPainter(),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              color: _darkGreen,
              onRefresh: () => _fetchLiveResep(showLoading: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top Navigation Bar: <- Kembali & Notification/Avatar Pill ──
                    _buildTopBar(context),

                    const SizedBox(height: 16),

                    // ── Center Pill Title: Resep Dokter ──
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: _darkGreen,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _darkGreen.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Resep Dokter',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Daftar Kartu Resep Dokter ──
                    if (_isLoading && _resepList.isEmpty) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(color: _darkGreen),
                        ),
                      ),
                    ] else if (_resepList.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _cardBorderColor),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada resep dokter aktif.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      ..._resepList.map((resep) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildResepCard(context, resep),
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOP BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Pill Button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF0F172A), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back, size: 16, color: Color(0xFF0F172A)),
                const SizedBox(width: 6),
                Text(
                  'Kembali',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action Pill (Bell & Profile Avatar)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CARD RESEP DOKTER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildResepCard(BuildContext context, ResepDokterData resep) {
    final isBelumDitebus = resep.status == 'Belum Ditebus';
    final isSudahDitebus = resep.status == 'Sudah Ditebus';
    final isKadaluwarsa = resep.status == 'Kadaluwarsa';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(resep.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  resep.status,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Row 2: Doctor Profile & Specialty
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  resep.doctorImage,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 54,
                    height: 54,
                    color: const Color(0xFFDCFCE7),
                    child: const Icon(Icons.person_rounded, color: _darkGreen, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resep.doctorName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      resep.doctorSpecialty,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Row 3: Tanggal & Badge Jumlah Jenis Obat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                resep.tanggalTerbit,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _badgeDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${resep.medications.length} Jenis Obat',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Container Preview Obat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _infoBoxBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (resep.medications.isNotEmpty) ...[
                  for (int i = 0; i < resep.medications.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    _buildMedicationPreviewRow(
                      '${resep.medications[i].name}:',
                      resep.medications[i].aturanPakai.isNotEmpty
                          ? '${resep.medications[i].aturanPakai} (${resep.medications[i].jumlahObat})'
                          : resep.medications[i].jumlahObat,
                    ),
                  ],
                ] else ...[
                  _buildMedicationPreviewRow(
                    'Obat Terapi Ginjal:',
                    'Sesuai anjuran dokter (30 tab)',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Note / Verification Text
          if (isBelumDitebus)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Dapat ditebus di ${resep.mitraPharmacy}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF065A37),
                    ),
                  ),
                ),
              ],
            )
          else if (isSudahDitebus)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF059669),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ditebus via ${resep.mitraPharmacy}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF065A37),
                    ),
                  ),
                ),
              ],
            )
          else if (isKadaluwarsa)
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: _redStatus,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    resep.warningMessage ?? 'Masa berlaku resep terlewati (maks. 14 hari)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _redStatus,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 14),

          // Action Buttons
          if (isBelumDitebus)
            Row(
              children: [
                // Tombol Lihat Detail (Outlined)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => _navigateToDetail(context, resep),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: _darkGreen, width: 1.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lihat Detail',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _darkGreen,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_circle_right_outlined,
                            color: _darkGreen,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Tombol Tebus Resep (Solid Green)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _handleTebusResep(context, resep),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _darkGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Tebus Resep',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.local_pharmacy_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // Single Full-Width Outlined Button: Lihat Detail Resep
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => _navigateToDetail(context, resep),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _darkGreen, width: 1.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lihat Detail Resep',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_circle_right_outlined,
                      color: _darkGreen,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationPreviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToDetail(BuildContext context, ResepDokterData resep) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailResepScreen(
          userName: widget.userName,
          resepData: resep,
        ),
      ),
    );
    if (mounted) {
      _fetchLiveResep(showLoading: false);
    }
  }

  Future<void> _handleTebusResep(BuildContext context, ResepDokterData resep) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutResepScreen(
          userName: widget.userName,
          resepData: resep,
        ),
      ),
    );
    if (mounted) {
      _fetchLiveResep(showLoading: false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: TOPOGRAPHY BACKGROUND FOR RESEP DOKTER SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _ResepDokterTopographyPainter extends CustomPainter {
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
