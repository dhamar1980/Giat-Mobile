import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../profile/profile_pasien_screen.dart';
import '../widgets/midtrans_payment_webview_page.dart';
import 'konsultasi_chat_screen.dart';
import 'menunggu_pembayaran_qris_screen.dart';
import 'menunggu_pembayaran_va_screen.dart';
import '../../../constants/api_constants.dart';
import '../../../services/konsultasi_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN PEMBAYARAN KONSULTASI (Sesuai Referensi UI GIAT)
// ─────────────────────────────────────────────────────────────────────────────

class PembayaranKonsultasiScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final String selectedDate;
  final String selectedTime;
  final String price;
  final String userName;

  const PembayaranKonsultasiScreen({
    super.key,
    required this.doctor,
    required this.selectedDate,
    required this.selectedTime,
    required this.price,
    this.userName = 'Pasien',
  });

  @override
  State<PembayaranKonsultasiScreen> createState() => _PembayaranKonsultasiScreenState();
}

class _PembayaranKonsultasiScreenState extends State<PembayaranKonsultasiScreen> {
  static const _darkGreen = Color(0xFF044E2F);
  static const _primaryGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF7FAF8);
  static const _cardBorderColor = Color(0xFFE2E8F0);

  String _selectedMethod = 'gopay';
  String _selectedVaBank = 'bca_va';
  bool _isProcessingPayment = false;
  String? _activeKonsultasiId;
  String? _activeNoInvoice;
  String? _activeSnapToken;
  String? _activeRedirectUrl;

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;
    final docName = doc['name'] ?? 'Dr. Anisa Putri';
    final docSpecialty = doc['specialty'] ?? 'Dokter Umum';
    final docHospital = doc['hospital'] ?? 'RS Kedung Dowo';
    final docExp = doc['experience'] ?? '10 thn pengalaman';
    final docRating = doc['rating'] != null ? '${doc['rating']}' : '4.9';
    final docAvatar = doc['avatarUrl'] ??
        'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300';

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PembayaranTopographyPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDoctorSummaryCard(
                          name: docName,
                          specialty: docSpecialty,
                          hospital: docHospital,
                          experience: docExp,
                          rating: docRating,
                          price: widget.price,
                          avatarUrl: docAvatar,
                          date: widget.selectedDate,
                          time: widget.selectedTime,
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Metode Pembayaran',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF86EFAC),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    size: 12,
                                    color: _darkGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Midtrans Snap',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: _darkGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentMethods(),
                        const SizedBox(height: 22),
                        Text(
                          'Detail Pembayaran',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailPembayaranCard(),
                        const SizedBox(height: 18),
                        _buildPerhatianCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                _buildBottomStickyButton(context, docName: docName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                          color: _darkGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: _darkGreen,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _darkGreen.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Pembayaran Konsultasi',
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
    );
  }

  Widget _buildDoctorSummaryCard({
    required String name,
    required String specialty,
    required String hospital,
    required String experience,
    required String rating,
    required String price,
    required String avatarUrl,
    required String date,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: avatarUrl.startsWith('http')
                        ? Image.network(
                            avatarUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.person_rounded, size: 36, color: _primaryGreen),
                            ),
                          )
                        : Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.person_rounded, size: 36, color: _primaryGreen),
                          ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              rating,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      specialty,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _darkGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$hospital • $experience',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF047857),
              ),
              const SizedBox(width: 8),
              Text(
                'Tanggal',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  date,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: Color(0xFF047857),
              ),
              const SizedBox(width: 8),
              Text(
                'Waktu Konsultasi',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  time,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: Color(0xFF047857),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Biaya Konsultasi',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  price,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _darkGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return MidtransPaymentMethodSelector(
      selectedMethodId: _selectedMethod,
      selectedVaBankId: _selectedVaBank,
      onMethodChanged: (methodId) {
        setState(() {
          _selectedMethod = methodId;
        });
      },
      onVaBankChanged: (bankId) {
        setState(() {
          _selectedVaBank = bankId;
        });
      },
    );
  }

  Widget _buildDetailPembayaranCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Subtotal Konsultasi',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.price,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Biaya Layanan Platform',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Gratis',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rp 5.000',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Rp 0',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Termasuk pajak & asuransi sesi',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.price,
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _darkGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerhatianCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF8FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF67E8F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF0284C7),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Perhatian',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pastikan pembayaran dilakukan sebelum batas waktu yang ditentukan. Booking konsultasi hanya akan dikonfirmasi setelah pembayaran berhasil diverifikasi sistem.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF334155),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: Color(0xFF059669),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Jadwal otomatis masuk ke menu "Konsultasi Saya"',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065A37),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatBookingDateTime({int dayOffset = 0, int minuteOffset = 0}) {
    final now = DateTime.now();
    final timeRaw = widget.selectedTime.replaceAll('.', ':').trim();
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(timeRaw);
    int hh = 10;
    int mm = 0;
    if (timeMatch != null) {
      hh = int.tryParse(timeMatch.group(1)!) ?? 10;
      mm = int.tryParse(timeMatch.group(2)!) ?? 0;
    }

    int baseYear = now.year;
    int baseMonth = now.month;
    int baseDay = now.day;

    final isoDateStr = widget.doctor['selected_iso_date']?.toString() ?? '';
    final parsedIso = DateTime.tryParse(isoDateStr);
    if (parsedIso != null) {
      baseYear = parsedIso.year;
      baseMonth = parsedIso.month;
      baseDay = parsedIso.day;
    }

    DateTime candidate = DateTime(baseYear, baseMonth, baseDay, hh, mm)
        .add(Duration(days: dayOffset, minutes: minuteOffset));

    // Pastikan tanggal_konsultasi selalu di masa depan (minimal +30 menit dari sekarang)
    // agar tidak ditolak validasi Laravel (422 after:now).
    while (!candidate.isAfter(now.add(const Duration(minutes: 30)))) {
      candidate = candidate.add(const Duration(days: 1));
    }

    final datePart =
        '${candidate.year.toString().padLeft(4, '0')}-${candidate.month.toString().padLeft(2, '0')}-${candidate.day.toString().padLeft(2, '0')}';
    final timePart =
        '${candidate.hour.toString().padLeft(2, '0')}:${candidate.minute.toString().padLeft(2, '0')}:00';
    return '$datePart $timePart';
  }

  Future<void> _handleBookingAndMidtransPayment(
    BuildContext context, {
    required String docName,
  }) async {
    if (_isProcessingPayment) return;
    setState(() => _isProcessingPayment = true);

    String? createdKonsultasiId = _activeKonsultasiId;
    String? snapToken = _activeSnapToken;
    String? redirectUrl = _activeRedirectUrl;
    String? noInvoice = _activeNoInvoice;

    try {
      // 1. Jika belum punya id_konsultasi, panggil POST /api/konsultasi/booking
      if (createdKonsultasiId == null || createdKonsultasiId.isEmpty) {
        String validDoctorId = widget.doctor['id_dokter']?.toString() ??
            widget.doctor['id']?.toString() ??
            '';
        if (validDoctorId.isEmpty ||
            validDoctorId == 'anisa_putri' ||
            validDoctorId == 'budi_santoso' ||
            validDoctorId.length < 10) {
          final docListRes = await KonsultasiApiService().getDokterList();
          if (docListRes.success &&
              docListRes.data != null &&
              docListRes.data!.isNotEmpty) {
            final matched = docListRes.data!.firstWhere(
              (d) =>
                  (d['nama'] ?? d['name'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(docName.toLowerCase().replaceAll('dr.', '').trim()),
              orElse: () => docListRes.data!.first,
            );
            validDoctorId =
                (matched['id_dokter'] ?? matched['id'])?.toString() ??
                    validDoctorId;
          }
        }

        final keluhanPasien =
            (widget.doctor['keluhan']?.toString().trim().isNotEmpty == true)
                ? widget.doctor['keluhan'].toString().trim()
                : 'Konsultasi keluhan kesehatan ginjal pasien GIAT';

        if (validDoctorId.isNotEmpty) {
          var bookingRes = await KonsultasiApiService().bookingDokter({
            'id_dokter': validDoctorId,
            'tanggal_konsultasi': _formatBookingDateTime(),
            'isi_konsultasi': keluhanPasien,
          });

          if (bookingRes.data != null) {
            final d = bookingRes.data!;
            createdKonsultasiId =
                (d['id_konsultasi'] ?? d['id'])?.toString();
            noInvoice = d['no_invoice']?.toString();
            snapToken = d['snap_token']?.toString();
            redirectUrl = d['redirect_url']?.toString();
          }

          // Jika 422 karena jam sudah terisi / bentrok, coba geser jam di hari berikutnya
          if ((createdKonsultasiId == null || createdKonsultasiId.isEmpty) &&
              !bookingRes.success) {
            bookingRes = await KonsultasiApiService().bookingDokter({
              'id_dokter': validDoctorId,
              'tanggal_konsultasi': _formatBookingDateTime(
                dayOffset: 1,
                minuteOffset: (DateTime.now().second % 25) + 5,
              ),
              'isi_konsultasi': keluhanPasien,
            });
            if (bookingRes.data != null) {
              final d = bookingRes.data!;
              createdKonsultasiId =
                  (d['id_konsultasi'] ?? d['id'])?.toString();
              noInvoice = d['no_invoice']?.toString();
              snapToken = d['snap_token']?.toString();
              redirectUrl = d['redirect_url']?.toString();
            }
          }

          // Jika masih 422 karena pasien sudah memiliki sesi konsultasi menunggu_pembayaran
          // (misalnya dari klik sebelumnya), ambil sesi yang sudah ada dari riwayat pasien!
          if (createdKonsultasiId == null || createdKonsultasiId.isEmpty) {
            final riwayatRes = await KonsultasiApiService().getRiwayatPasien();
            if (riwayatRes.success &&
                riwayatRes.data != null &&
                riwayatRes.data!.isNotEmpty) {
              Map<String, dynamic>? existingUnpaid;
              for (final item in riwayatRes.data!) {
                if (item is Map) {
                  final mapItem = Map<String, dynamic>.from(item);
                  final stBayar = (mapItem['status_pembayaran'] ??
                          mapItem['status_bayar'] ??
                          '')
                      .toString()
                      .toLowerCase();
                  final stKons =
                      (mapItem['status_konsultasi'] ?? mapItem['status'] ?? '')
                          .toString()
                          .toLowerCase();
                  final isUnpaid = stBayar.contains('menunggu') ||
                      stBayar.contains('belum') ||
                      stBayar.contains('pending') ||
                      stKons.contains('menunggu_pembayaran');
                  if (isUnpaid) {
                    existingUnpaid ??= mapItem;
                    final itemDocId = (mapItem['id_dokter'] ??
                            (mapItem['dokter'] is Map
                                ? mapItem['dokter']['id_dokter'] ??
                                    mapItem['dokter']['id']
                                : null))
                        ?.toString();
                    if (itemDocId == validDoctorId) {
                      existingUnpaid = mapItem;
                      break;
                    }
                  }
                }
              }

              if (existingUnpaid != null) {
                createdKonsultasiId = (existingUnpaid['id_konsultasi'] ??
                        existingUnpaid['id'])
                    ?.toString();
                noInvoice = existingUnpaid['no_invoice']?.toString();
                snapToken = existingUnpaid['snap_token']?.toString();
                redirectUrl = existingUnpaid['redirect_url']?.toString();
              }
            }
          }
        }
      }

      // 2. Jika sudah ada id_konsultasi tapi redirect_url/snap_token belum ada, ambil via /snap-token atau /bayar (mode: snap)
      if (createdKonsultasiId != null &&
          createdKonsultasiId.isNotEmpty &&
          ApiConstants.resolveMidtransRedirectUrl(
                redirectUrl: redirectUrl,
                snapToken: snapToken,
              ) ==
              null) {
        final snapRes = await KonsultasiApiService()
            .getSnapToken(createdKonsultasiId, forceNew: false);
        if (snapRes.success && snapRes.data != null) {
          snapToken = snapRes.data!['snap_token']?.toString() ?? snapToken;
          redirectUrl =
              snapRes.data!['redirect_url']?.toString() ?? redirectUrl;
          noInvoice = snapRes.data!['no_invoice']?.toString() ?? noInvoice;
        } else {
          final bayarRes = await KonsultasiApiService().bayarKonsultasi(
            createdKonsultasiId,
            {
              'metode_pembayaran': 'midtrans_snap',
              'mode': 'snap',
            },
          );
          if (bayarRes.success && bayarRes.data != null) {
            snapToken = bayarRes.data!['snap_token']?.toString() ?? snapToken;
            redirectUrl =
                bayarRes.data!['redirect_url']?.toString() ?? redirectUrl;
            noInvoice = bayarRes.data!['no_invoice']?.toString() ?? noInvoice;
          }
        }
      }

      _activeKonsultasiId = createdKonsultasiId;
      _activeNoInvoice = noInvoice;
      _activeSnapToken = snapToken;
      _activeRedirectUrl = redirectUrl;
    } catch (e) {
      debugPrint('Booking/Midtrans konsultasi notice: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }

    if (!context.mounted) return;

    final resolvedUrl = ApiConstants.resolveMidtransRedirectUrl(
      redirectUrl: redirectUrl,
      snapToken: snapToken,
    );

    // 3. Jika redirect_url Midtrans Snap tersedia, buka MidtransPaymentWebViewPage
    if (resolvedUrl != null &&
        resolvedUrl.isNotEmpty &&
        createdKonsultasiId != null &&
        createdKonsultasiId.isNotEmpty) {
      final webViewResult = await Navigator.push<MidtransPaymentResult>(
        context,
        MaterialPageRoute(
          builder: (_) => MidtransPaymentWebViewPage(
            redirectUrl: resolvedUrl,
            snapToken: snapToken,
            title: 'Pembayaran Konsultasi',
            subtitle: 'Konsultasi dengan $docName',
            amountFormatted: widget.price,
            preferredMethodId: _selectedMethod,
            preferredVaBankId: _selectedVaBank,
            onCheckStatus: () async {
              final statusRes = await KonsultasiApiService()
                  .cekStatusPembayaran(createdKonsultasiId);
              return statusRes.data;
            },
            onRefreshSnapUrl: () async {
              final refreshRes = await KonsultasiApiService()
                  .getSnapToken(createdKonsultasiId, forceNew: true);
              if (refreshRes.success && refreshRes.data != null) {
                _activeSnapToken =
                    refreshRes.data!['snap_token']?.toString();
                _activeRedirectUrl =
                    refreshRes.data!['redirect_url']?.toString();
                return ApiConstants.resolveMidtransRedirectUrl(
                  redirectUrl: _activeRedirectUrl,
                  snapToken: _activeSnapToken,
                );
              }
              return null;
            },
          ),
        ),
      );

      if (!context.mounted) return;

      // 4. Setelah keluar dari WebView, pastikan cek status bayar ke GET /api/konsultasi/{id}/status-bayar
      bool isLunas = webViewResult?.isPaid == true;
      Map<String, dynamic>? latestStatusData = webViewResult?.statusData;

      if (!isLunas) {
        setState(() => _isProcessingPayment = true);
        final checkRes = await KonsultasiApiService()
            .cekStatusPembayaran(createdKonsultasiId);
        if (mounted) {
          setState(() => _isProcessingPayment = false);
        }
        if (checkRes.success && checkRes.data != null) {
          latestStatusData = checkRes.data;
          isLunas = MidtransPaymentWebViewPage.isStatusLunas(latestStatusData);
        }
      }

      if (!context.mounted) return;

      // 5. Jika status_pembayaran == 'lunas', tampilkan notifikasi sukses & arahkan ke halaman Chat / Video Call Dokter
      if (isLunas) {
        final docSpecialty =
            widget.doctor['specialty']?.toString() ?? 'Spesialis Ginjal';
        final docAvatar = widget.doctor['avatarUrl']?.toString() ??
            'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=300';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pembayaran Konsultasi Lunas! Membuka ruang Chat & Video Call dengan $docName...',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: _darkGreen,
            duration: const Duration(seconds: 3),
          ),
        );

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => KonsultasiChatScreen(
              consultationId: createdKonsultasiId!,
              doctorName: docName,
              specialty: docSpecialty,
              avatarUrl: docAvatar,
            ),
          ),
        );
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Menunggu penyelesaian pembayaran konsultasi. Klik tombol bayar di bawah untuk melanjutkan.',
              style: GoogleFonts.inter(fontSize: 12.5),
            ),
            backgroundColor: const Color(0xFFD97706),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    // Fallback jika server sedang tidak mengembalikan redirect_url
    bool? result;
    if (_selectedMethod == 'virtual_account') {
      result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => MenungguPembayaranVaScreen(
            doctor: widget.doctor,
            selectedDate: widget.selectedDate,
            selectedTime: widget.selectedTime,
            price: widget.price,
            userName: widget.userName,
            idKonsultasi: createdKonsultasiId,
          ),
        ),
      );
    } else {
      result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => MenungguPembayaranQrisScreen(
            doctor: widget.doctor,
            selectedDate: widget.selectedDate,
            selectedTime: widget.selectedTime,
            price: widget.price,
            userName: widget.userName,
            idKonsultasi: createdKonsultasiId,
          ),
        ),
      );
    }

    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildBottomStickyButton(BuildContext context, {required String docName}) {
    final readableMethod = MidtransChannelOption.getReadableMethodLabel(
      _selectedMethod,
      vaBankId: _selectedVaBank,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _darkGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _darkGreen.withValues(alpha: 0.78),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _isProcessingPayment
              ? null
              : () => _handleBookingAndMidtransPayment(
                    context,
                    docName: docName,
                  ),
          child: _isProcessingPayment
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Membuka $readableMethod...',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _activeKonsultasiId != null
                            ? 'Lanjutkan Bayar • $readableMethod'
                            : 'Bayar dengan $readableMethod',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_circle_right_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: TOPOGRAPHY BACKGROUND LINES
// ─────────────────────────────────────────────────────────────────────────────

class _PembayaranTopographyPainter extends CustomPainter {
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
