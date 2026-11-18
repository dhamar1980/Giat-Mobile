import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_resep_screen.dart';
import 'lacak_obat_screen.dart';
import '../profile/profile_pasien_screen.dart';
import '../widgets/midtrans_payment_webview_page.dart';
import 'pembayaran_model.dart';
import 'pembayaran_qris_screen.dart';
import 'pembayaran_transfer_bank_screen.dart';
import '../../../constants/api_constants.dart';
import '../../../services/pasien_api_service.dart';
import '../../../services/supabase_admin_service.dart';
import '../../../services/cart_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/jember_location_service.dart';
import '../../../utils/time_utils.dart';
import '../../../widgets/app_top_action_pill.dart';
import '../../../widgets/giat_real_map_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN CHECKOUT RESEP DOKTER (Sesuai Desain Figma / 3 Screenshot Checkout)
// ─────────────────────────────────────────────────────────────────────────────

class CheckoutResepScreen extends StatefulWidget {
  final String userName;
  final ResepDokterData? resepData;
  final List<Map<String, dynamic>>? cartItems;

  const CheckoutResepScreen({
    super.key,
    this.userName = 'Pasien',
    this.resepData,
    this.cartItems,
  });

  @override
  State<CheckoutResepScreen> createState() => _CheckoutResepScreenState();
}

class _CheckoutResepScreenState extends State<CheckoutResepScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _badgeDark = Color(0xFF0F172A);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);
  static const _redAlert = Color(0xFFDC2626);

  // Delivery method state: 'antar' or 'ambil'
  String _metodePengambilan = 'antar';

  // Payment method state: 'gopay', 'virtual_account', 'credit_card', 'shopeepay', 'qris'
  String _metodePembayaran = 'gopay';
  String _selectedVaBank = 'bca_va';
  bool _isProcessingCheckout = false;
  String? _activePesananId;
  String? _activeNoPesanan;
  String? _activeSnapToken;
  String? _activeRedirectUrl;

  // Patient address & Real GPS Jember state
  String _recipientName = 'Pasien';
  String _recipientPhone = '0812-3456-7891';
  String _recipientAddress = 'Jl. Kalimantan No. 37, Sumbersari, Jember, Jawa Timur 68121';
  late JemberCoordinate _patientCoord;
  bool _isGpsActive = false;
  bool _isFetchingGps = false;

  // Daftar Apotek Mitra GIAT di Kota Jember (Otomatis pilih terdekat + bebas pilih manual)
  List<Map<String, dynamic>> _rawSupabaseApoteks = [];
  List<ApotekJemberPoint> _rankedApoteks = [];
  late ApotekJemberPoint _selectedApotek;
  bool _hasManualApotekOverride = false;
  List<JemberCoordinate> _previewRoute = [];

  @override
  void initState() {
    super.initState();
    if (widget.userName.isNotEmpty && widget.userName != 'Pasien') {
      _recipientName = widget.userName;
    }
    _patientCoord = JemberLocationService.instance
        .resolveAddressToJemberCoordinate(_recipientAddress);
    _rankedApoteks = JemberLocationService.instance.rankApoteksByDistance(
      patientLat: _patientCoord.latitude,
      patientLng: _patientCoord.longitude,
    );
    _selectedApotek = _rankedApoteks.first;
    _previewRoute = JemberLocationService.instance.buildJemberArterialRoadPoints(
      startLat: _selectedApotek.latitude,
      startLng: _selectedApotek.longitude,
      endLat: _patientCoord.latitude,
      endLng: _patientCoord.longitude,
    );
    _loadUserProfile();
  }

  void _recalculateNearestApotek({bool autoSelectNearest = true}) {
    final ranked = JemberLocationService.instance.rankApoteksByDistance(
      patientLat: _patientCoord.latitude,
      patientLng: _patientCoord.longitude,
      rawSupabaseApoteks: _rawSupabaseApoteks.isNotEmpty ? _rawSupabaseApoteks : null,
    );
    _rankedApoteks = ranked;
    if (autoSelectNearest || !_hasManualApotekOverride) {
      _selectedApotek = ranked.first;
    } else {
      _selectedApotek = ranked.firstWhere(
        (a) => a.id == _selectedApotek.id || a.namaApotek == _selectedApotek.namaApotek,
        orElse: () => ranked.first,
      );
    }
    _previewRoute = JemberLocationService.instance.buildJemberArterialRoadPoints(
      startLat: _selectedApotek.latitude,
      startLng: _selectedApotek.longitude,
      endLat: _patientCoord.latitude,
      endLng: _patientCoord.longitude,
    );
    _fetchRealOsrmRoute();
  }

  void _fetchRealOsrmRoute() {
    JemberLocationService.instance
        .buildRoadRoute(
      startLat: _selectedApotek.latitude,
      startLng: _selectedApotek.longitude,
      endLat: _patientCoord.latitude,
      endLng: _patientCoord.longitude,
    )
        .then((pts) {
      if (!mounted || pts.length < 2) return;
      setState(() {
        _previewRoute = pts;
      });
    });
  }

  Future<void> _activateRealGpsLocation() async {
    if (_isFetchingGps) return;
    setState(() => _isFetchingGps = true);
    try {
      final gpsCoord = await JemberLocationService.instance.requestAndFetchRealGpsLocation(
        currentAddressHint: _recipientAddress,
      );
      if (!mounted) return;
      setState(() {
        _patientCoord = gpsCoord;
        _recipientAddress = gpsCoord.address;
        _isGpsActive = true;
        _hasManualApotekOverride = false;
        _recalculateNearestApotek(autoSelectNearest: true);
      });
      await _persistPatientAddress(_recipientAddress, gpsCoord);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'GPS Aktif (${gpsCoord.formattedLatLng})! Apotek terdekat dipilih otomatis: ${_selectedApotek.namaApotek} (${_selectedApotek.formattedDistance}).',
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          backgroundColor: _darkGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGpsActive = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isFetchingGps = false);
      }
    }
  }

  Future<void> _persistPatientAddress(String address, JemberCoordinate coord) async {
    JemberLocationService.instance.cacheCoordinateForAddress(coord, role: 'pasien');
    try {
      final user = await StorageService().getUser();
      if (user != null) {
        await StorageService().saveUser(user.copyWith(alamat: address));
      }
    } catch (_) {}
    await PasienApiService().updateProfile({'alamat': address});
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await StorageService().getUser();
      if (user != null && mounted) {
        setState(() {
          if (user.nama.isNotEmpty) _recipientName = user.nama;
          if (user.noHp != null && user.noHp!.isNotEmpty) _recipientPhone = user.noHp!;
          if (user.alamat != null && user.alamat!.isNotEmpty) {
            _recipientAddress = user.alamat!;
            _patientCoord = JemberLocationService.instance
                .resolveAddressToJemberCoordinate(_recipientAddress);
            _recalculateNearestApotek(autoSelectNearest: true);
          }
        });
      }
      final apotekRes = await PasienApiService().getApotekJemberList();
      if (apotekRes.success && apotekRes.data != null && apotekRes.data!.isNotEmpty && mounted) {
        setState(() {
          _rawSupabaseApoteks = apotekRes.data!;
          _recalculateNearestApotek(autoSelectNearest: true);
        });
      }
      final profileRes = await PasienApiService().getProfile();
      if (profileRes.success && profileRes.data != null && mounted) {
        final d = profileRes.data!;
        setState(() {
          if (d['nama'] != null && d['nama'].toString().isNotEmpty) {
            _recipientName = d['nama'].toString();
          }
          if (d['no_hp'] != null && d['no_hp'].toString().isNotEmpty) {
            _recipientPhone = d['no_hp'].toString();
          }
          if (!_isGpsActive && d['alamat'] != null && d['alamat'].toString().isNotEmpty) {
            _recipientAddress = d['alamat'].toString();
            _patientCoord = JemberLocationService.instance
                .resolveAddressToJemberCoordinate(_recipientAddress);
            _recalculateNearestApotek(autoSelectNearest: true);
          }
        });
      }
    } catch (_) {}
  }

  // Pricing constants & dynamic calculation
  int get _subtotalObat {
    if (widget.resepData != null && widget.resepData!.medications.isNotEmpty) {
      return widget.resepData!.medications.fold<int>(
        0,
        (sum, m) => sum + (m.price > 0 ? m.price : 50000),
      );
    }
    if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      return widget.cartItems!.fold<int>(0, (sum, ci) {
        final p = int.tryParse(ci['harga']?.toString() ?? '') ?? 50000;
        final q = int.tryParse(ci['jumlah']?.toString() ?? '') ?? 1;
        return sum + (p * q);
      });
    }
    return 50000;
  }

  final int _biayaLayanan = 2000;
  int get _biayaPengiriman => _metodePengambilan == 'antar' ? 15000 : 0;
  int get _totalPembayaran => _subtotalObat + _biayaPengiriman + _biayaLayanan;

  String _formatCurrency(int amount) {
    // Format: Rp. 770.000,00
    final str = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    final reversed = buffer.toString().split('').reversed.join('');
    return 'Rp. $reversed,00';
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
              painter: _CheckoutTopographyPainter(),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Top Navigation Bar ──
                  _buildTopBar(context),

                  const SizedBox(height: 16),

                  // ── 2. Screen Title Pill: Checkout ──
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
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
                        'Checkout',
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

                  // ── 3. Resep Digital Terverifikasi Title & Card ──
                  Text(
                    'Resep Digital Terverifikasi',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '*Periksa kembali rincian pesanan obat Anda.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildVerifiedResepCard(),

                  const SizedBox(height: 18),

                  // ── 4. Metode Pengambilan ──
                  _buildMetodePengambilanSection(),

                  const SizedBox(height: 22),

                  // ── 5. Pesanan Obat ──
                  _buildPesananObatSection(),

                  const SizedBox(height: 22),

                  // ── 6. Apotek Mitra GIAT ──
                  _buildApotekMitraSection(),

                  const SizedBox(height: 22),

                  // ── 7. Metode Pembayaran ──
                  _buildMetodePembayaranSection(),

                  const SizedBox(height: 22),

                  // ── 8. Ringkasan Pembayaran ──
                  _buildRingkasanPembayaranSection(),

                  const SizedBox(height: 24),

                  // ── 9. Tombol Konfirmasi & Bayar ──
                  _buildKonfirmasiDanBayarButton(context),
                ],
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

        // Action Pill (Bell & Profile Avatar Konsisten)
        PasienTopActionPill(userName: widget.userName),
      ],
    );
  }

  Widget _buildVerifiedResepCard() {
    final rxNo = widget.resepData?.rxNumber ?? 'No. RX-2026-GIAT';
    final docName = widget.resepData?.doctorName ?? 'dr. Andi Wijaya, Sp.PD-KGH';
    final docSpec = widget.resepData?.doctorSpecialty ?? 'Spesialis Ginjal & Hipertensi • RSD dr. Soebandi Jember';
    final tgl = widget.resepData?.tanggalTerbit ?? 'Hari ini';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: _darkGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        rxNo,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _darkGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Terverifikasi',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  docName,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _darkGreen,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$docSpec • Diterbitkan $tgl',
                  style: GoogleFonts.inter(
                    fontSize: 11.2,
                    color: const Color(0xFF64748B),
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
  // SECTION 4: METODE PENGAMBILAN
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMetodePengambilanSection() {
    final isAntar = _metodePengambilan == 'antar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metode Pengambilan',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),

        // Opsi 1: Antar ke Alamat (Card)
        GestureDetector(
          onTap: () => setState(() => _metodePengambilan = 'antar'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isAntar ? _darkGreen.withValues(alpha: 0.4) : _cardBorderColor,
                width: isAntar ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRadioIcon(selected: isAntar),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Antar ke Alamat',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Obat dikirim langsung ke alamat pasien via kurir farmasi higienis berstandar rantai dingin.',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Address & Real GPS Container Box (shown if Antar ke Alamat)
                if (isAntar) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              flex: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _isGpsActive
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isGpsActive
                                          ? Icons.my_location_rounded
                                          : Icons.home_rounded,
                                      size: 11,
                                      color: _isGpsActive
                                          ? _darkGreen
                                          : const Color(0xFF1E40AF),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _isGpsActive ? 'GPS Aktif' : 'Register',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _isGpsActive
                                            ? _darkGreen
                                            : const Color(0xFF1E40AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _recipientName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _showUbahAlamatModal(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Ubah Alamat',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(
                                    Icons.arrow_circle_right_outlined,
                                    size: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _recipientPhone,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _recipientAddress,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.pin_drop_rounded, size: 14, color: _darkGreen),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Koordinat: ${_patientCoord.formattedLatLng} • Jarak Apotek: ${_selectedApotek.formattedDistance}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _darkGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  onPressed: _isFetchingGps ? null : _activateRealGpsLocation,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _darkGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: _isFetchingGps
                                      ? const SizedBox(
                                          width: 13,
                                          height: 13,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.my_location_rounded, size: 15),
                                  label: Text(
                                    _isGpsActive ? 'Perbarui GPS' : 'Hidupkan GPS',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showJemberLocationPickerModal(
                                      context,
                                      title: 'Tentukan Titik Lokasi Pengiriman (Jember)',
                                      initialAddress: _recipientAddress,
                                      initialLat: _patientCoord.latitude,
                                      initialLng: _patientCoord.longitude,
                                      role: 'pasien',
                                    );
                                    if (picked != null && mounted) {
                                      setState(() {
                                        _patientCoord = picked;
                                        _recipientAddress = picked.address;
                                        _isGpsActive = true;
                                        _hasManualApotekOverride = false;
                                        _recalculateNearestApotek(autoSelectNearest: true);
                                      });
                                      await _persistPatientAddress(_recipientAddress, picked);
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: _darkGreen,
                                    side: const BorderSide(color: _darkGreen, width: 1.2),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.map_outlined, size: 15),
                                  label: Text(
                                    'Tentukan di Peta',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Peta Rute Pengiriman (TERKUNCI agar tidak bergeser saat scroll)
                        GiatRealMapWidget(
                          height: 215,
                          centerLat: (_patientCoord.latitude + _selectedApotek.latitude) / 2.0,
                          centerLng: (_patientCoord.longitude + _selectedApotek.longitude) / 2.0,
                          initialZoom: 14.0,
                          interactive: false,
                          showControls: false,
                          topBadgeText: 'Rute Pengiriman • ${_selectedApotek.formattedDistance}',
                          bottomBannerTitle: '${_selectedApotek.namaApotek} → $_recipientName',
                          bottomBannerSubtitle: 'Estimasi waktu tempuh kurir: ~${_selectedApotek.estimatedMinutes} menit',
                          routePoints: _previewRoute,
                          routeProgress: 1.0,
                          markers: [
                            GiatMapMarker(
                              id: 'apotek_pin',
                              title: _selectedApotek.namaApotek,
                              latitude: _selectedApotek.latitude,
                              longitude: _selectedApotek.longitude,
                              type: GiatMapMarkerType.apotek,
                              isSelected: true,
                            ),
                            GiatMapMarker(
                              id: 'pasien_pin',
                              title: _recipientName,
                              latitude: _patientCoord.latitude,
                              longitude: _patientCoord.longitude,
                              type: GiatMapMarkerType.pasien,
                              isSelected: true,
                              isPulsing: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Opsi 2: Ambil di Apotek (Card)
        GestureDetector(
          onTap: () => setState(() => _metodePengambilan = 'ambil'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: !isAntar ? _darkGreen.withValues(alpha: 0.4) : _cardBorderColor,
                width: !isAntar ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRadioIcon(selected: !isAntar),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambil di Apotek',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Ambil obat secara langsung setelah pesanan selesai disiapkan oleh apoteker.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                          height: 1.35,
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 5: PESANAN OBAT
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPesananObatSection() {
    final int jenisCount;
    if (widget.resepData != null && widget.resepData!.medications.isNotEmpty) {
      jenisCount = widget.resepData!.medications.length;
    } else if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      jenisCount = widget.cartItems!.length;
    } else {
      jenisCount = 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pesanan Obat',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
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
                '$jenisCount Jenis Obat',
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

        // Warning Alert Row: Obat mengikuti resep dokter
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.info_outline_rounded, color: _redAlert, size: 16),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Obat mengikuti resep dokter. Jenis, dosis, frekuensi, dan jumlah tidak dapat diubah.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _redAlert,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (widget.resepData != null && widget.resepData!.medications.isNotEmpty) ...[
          for (final med in widget.resepData!.medications) ...[
            _buildCheckoutMedicationCard(
              name: med.name,
              dosageInstruction: '${med.aturanPakai} • ${med.jumlahObat}',
              priceStr: _formatCurrency(med.price > 0 ? med.price : 50000),
            ),
            const SizedBox(height: 12),
          ],
        ] else if (widget.cartItems != null && widget.cartItems!.isNotEmpty) ...[
          for (final ci in widget.cartItems!) ...[
            _buildCheckoutMedicationCard(
              name: (ci['nama'] ?? ci['nama_obat'] ?? 'Obat').toString(),
              dosageInstruction: '${ci['aturan_pakai'] ?? 'Sesuai aturan'} • ${ci['jumlah'] ?? 1} unit',
              priceStr: _formatCurrency(int.tryParse(ci['harga']?.toString() ?? '') ?? 50000),
            ),
            const SizedBox(height: 12),
          ],
        ] else ...[
          _buildCheckoutMedicationCard(
            name: 'Obat Terapi Ginjal',
            dosageInstruction: 'Sesuai petunjuk dokter • 30 tablet',
            priceStr: _formatCurrency(50000),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildCheckoutMedicationCard({
    required String name,
    required String dosageInstruction,
    required String priceStr,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_pharmacy_outlined,
              color: _darkGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Mitra Resmi Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _darkGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Mitra Resmi',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dosageInstruction,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                // Badge Sesuai Resep + Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _darkGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Sesuai Resep',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        priceStr,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 6: APOTEK MITRA GIAT (OTOMATIS TERDEKAT + BEBAS PILIH DI JEMBER)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildApotekMitraSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Apotek Mitra GIAT',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me_rounded, size: 12, color: _darkGreen),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Otomatis Terdekat • Jember',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _darkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Sistem otomatis memilih apotek terdekat dari titik lokasi Anda. Anda juga bebas memilih apotek mitra lainnya di Jember:',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),

        ...List.generate(_rankedApoteks.length, (idx) {
          final apt = _rankedApoteks[idx];
          final isSelected = apt.id == _selectedApotek.id ||
              apt.namaApotek == _selectedApotek.namaApotek;

          return Padding(
            padding: EdgeInsets.only(bottom: idx == _rankedApoteks.length - 1 ? 0 : 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedApotek = apt;
                  _hasManualApotekOverride = true;
                  _previewRoute = JemberLocationService.instance.buildJemberArterialRoadPoints(
                    startLat: apt.latitude,
                    startLng: apt.longitude,
                    endLat: _patientCoord.latitude,
                    endLng: _patientCoord.longitude,
                  );
                });
                _fetchRealOsrmRoute();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? _darkGreen.withValues(alpha: 0.55)
                        : _cardBorderColor,
                    width: isSelected ? 1.6 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRadioIcon(selected: isSelected),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      apt.namaApotek,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: apt.isNearest
                                          ? _darkGreen
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      apt.isNearest
                                          ? 'Terdekat • ${apt.formattedDistance}'
                                          : apt.formattedDistance,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: apt.isNearest
                                            ? Colors.white
                                            : const Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                apt.alamat,
                                style: GoogleFonts.inter(
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF475569),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SIPA: ${apt.noSipa} • Estimasi tiba ~${apt.estimatedMinutes} menit',
                                style: GoogleFonts.inter(
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check, size: 16, color: Color(0xFF059669)),
                                const SizedBox(width: 8),
                                Text(
                                  'Menerima pesanan obat',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF065A37),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.check, size: 16, color: Color(0xFF059669)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Diproses oleh apoteker berizin (${apt.penanggungJawab})',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF065A37),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF475569)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Estimasi pengantaran Jember: ${apt.estimatedMinutes} menit (${apt.formattedDistance})',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.8,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 7: METODE PEMBAYARAN (DIPECAH PER KANAL MIDTRANS)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMetodePembayaranSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Metode Pembayaran',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 6),
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
        MidtransPaymentMethodSelector(
          selectedMethodId: _metodePembayaran,
          selectedVaBankId: _selectedVaBank,
          onMethodChanged: (methodId) {
            setState(() {
              _metodePembayaran = methodId;
            });
          },
          onVaBankChanged: (bankId) {
            setState(() {
              _selectedVaBank = bankId;
            });
          },
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SECTION 8: RINGKASAN PEMBAYARAN
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRingkasanPembayaranSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: _darkGreen, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ringkasan Pembayaran',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _cardBorderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Inner light blue box with subtotal items
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal Obat', _formatCurrency(_subtotalObat)),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Biaya Pengiriman',
                      _biayaPengiriman == 0 ? 'Gratis (Ambil di Apotek)' : _formatCurrency(_biayaPengiriman),
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Biaya Layanan', _formatCurrency(_biayaLayanan)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Total Pembayaran Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Total Pembayaran',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _formatCurrency(_totalPembayaran),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
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

  // ───────────────────────────────────────────────────────────────────────────
  // TOMBOL KONFIRMASI & BAYAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKonfirmasiDanBayarButton(BuildContext context) {
    final readableMethod = MidtransChannelOption.getReadableMethodLabel(
      _metodePembayaran,
      vaBankId: _selectedVaBank,
    );
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isProcessingCheckout
            ? null
            : () => _handleKonfirmasiDanBayar(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _darkGreen.withValues(alpha: 0.78),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isProcessingCheckout
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
                        fontSize: 13.5,
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
                      _activePesananId != null
                          ? 'Lanjutkan Bayar • $readableMethod'
                          : 'Bayar dengan $readableMethod',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_circle_right_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HELPER RADIO ICON
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRadioIcon({required bool selected}) {
    if (selected) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _darkGreen, width: 2.2),
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: _darkGreen,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MODAL UBAH ALAMAT
  // ───────────────────────────────────────────────────────────────────────────
  void _showUbahAlamatModal(BuildContext context) {
    final nameCtrl = TextEditingController(text: _recipientName);
    final phoneCtrl = TextEditingController(text: _recipientPhone);
    final addressCtrl = TextEditingController(text: _recipientAddress);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
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
                'Ubah Alamat Pengiriman',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Penerima',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alamat Lengkap',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _recipientName = nameCtrl.text.trim();
                      _recipientPhone = phoneCtrl.text.trim();
                      _recipientAddress = addressCtrl.text.trim();
                      _patientCoord = JemberLocationService.instance
                          .resolveAddressToJemberCoordinate(_recipientAddress);
                      _hasManualApotekOverride = false;
                      _recalculateNearestApotek(autoSelectNearest: true);
                    });
                    PasienApiService().updateProfile({'alamat': _recipientAddress});
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Simpan Alamat',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ACTION: KONFIRMASI & BAYAR (MIDTRANS SNAP)
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _handleKonfirmasiDanBayar(BuildContext context) async {
    if (_isProcessingCheckout) return;
    setState(() => _isProcessingCheckout = true);

    final rxNumber = widget.resepData?.rxNumber ?? '';
    final itemCount = widget.resepData != null
        ? '${widget.resepData!.medications.length} jenis obat'
        : (widget.cartItems != null && widget.cartItems!.isNotEmpty
            ? '${widget.cartItems!.length} jenis obat'
            : '2 jenis obat');

    String? idPesanan = _activePesananId;
    String? noPesanan = _activeNoPesanan;
    String? snapToken = _activeSnapToken;
    String? redirectUrl = _activeRedirectUrl;
    int finalTotalAmount = _totalPembayaran;

    try {
      // 1. Jika belum punya pesanan yang dibuat pada sesi checkout ini, buat pesanan baru dengan mode: "snap"
      if (idPesanan == null || idPesanan.isEmpty) {
        String? validApotekId = _selectedApotek.id;
        List<Map<String, dynamic>> resolvedItems = [];

        // Ambil katalog obat dari backend untuk memastikan id_obat dan id_apotek valid (UUID)
        final katalogRes = await PasienApiService().getObatList();
        final katalogList = katalogRes.data ?? [];
        if ((validApotekId == null || validApotekId.isEmpty) && katalogList.isNotEmpty) {
          final firstObat = katalogList.first;
          if (firstObat is Map) {
            validApotekId = (firstObat['id_apotek'] ??
                    (firstObat['apotek'] is Map
                        ? firstObat['apotek']['id'] ??
                            firstObat['apotek']['id_apotek']
                        : null))
                ?.toString();
          }
        }

        // Susun items untuk POST /api/pasien/obat/checkout
        if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
          for (final ci in widget.cartItems!) {
            String rawId = (ci['id_obat'] ?? ci['id'] ?? '').toString();
            final qty = int.tryParse((ci['jumlah'] ?? 1).toString()) ?? 1;
            if (rawId.length < 10 && katalogList.isNotEmpty) {
              final namaMatch = (ci['nama'] ?? '').toString().toLowerCase();
              final matched = katalogList.firstWhere(
                (k) =>
                    k is Map &&
                    (k['nama_obat'] ?? k['nama'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(namaMatch.split(' ').first),
                orElse: () => katalogList.first,
              );
              if (matched is Map) {
                rawId = (matched['id_obat'] ?? matched['id'] ?? rawId).toString();
                validApotekId ??= (matched['id_apotek'] ??
                        (matched['apotek'] is Map
                            ? matched['apotek']['id'] ??
                                matched['apotek']['id_apotek']
                            : null))
                    ?.toString();
              }
            }
            if (rawId.isNotEmpty) {
              resolvedItems.add({'id_obat': rawId, 'jumlah': qty});
            }
          }
        } else if (katalogList.isNotEmpty) {
          final first = katalogList.first;
          if (first is Map) {
            final idObat = (first['id_obat'] ?? first['id'] ?? '').toString();
            if (idObat.isNotEmpty) {
              resolvedItems.add({'id_obat': idObat, 'jumlah': 1});
            }
          }
        }

        Map<String, dynamic>? createdData;

        // A. Jika dari resep, dahulukan POST /api/pasien/obat/beli-resep dengan resep asli
        if (widget.resepData != null) {
          final cleanRx = widget.resepData!.id ?? rxNumber.replaceAll('No.', '').trim();
          final resepRes = await PasienApiService().beliObatResep({
            'id_resep': cleanRx,
            'resep_id': cleanRx,
            if (validApotekId != null && validApotekId.isNotEmpty)
              'id_apotek': validApotekId,
            'alamat_pengiriman': _recipientAddress,
            'nama_penerima': _recipientName,
            'no_hp_penerima': _recipientPhone,
            'metode_pengambilan': _metodePengambilan,
            'metode_pembayaran': 'midtrans_snap',
            'mode': 'snap',
            'subtotal': _subtotalObat,
            'ongkos_kirim': _biayaPengiriman,
            'total_bayar': _totalPembayaran,
          });
          if (resepRes.success && resepRes.data != null) {
            createdData = resepRes.data;
          }
        }

        // B. Coba POST /api/pasien/obat/checkout jika dari keranjang atau belum ada createdData
        if (createdData == null && resolvedItems.isNotEmpty) {
          final checkoutPayload = <String, dynamic>{
            if (validApotekId != null && validApotekId.isNotEmpty)
              'id_apotek': validApotekId,
            'alamat_pengiriman': _recipientAddress,
            'nama_penerima': _recipientName,
            'no_hp_penerima': _recipientPhone,
            'metode_pengambilan': _metodePengambilan,
            'metode_pembayaran': 'midtrans_snap',
            'mode': 'snap',
            'items': resolvedItems,
          };
          final checkoutRes =
              await PasienApiService().checkoutObat(checkoutPayload);
          if (checkoutRes.success && checkoutRes.data != null) {
            createdData = checkoutRes.data;
          }
        }

        // C. Fallback ke POST /api/pasien/obat/beli-umum jika diperlukan
        if (createdData == null && resolvedItems.isNotEmpty) {
          final firstItem = resolvedItems.first;
          final beliUmumRes = await PasienApiService().beliObatUmum({
            'id_obat': firstItem['id_obat'],
            if (validApotekId != null && validApotekId.isNotEmpty)
              'id_apotek': validApotekId,
            'jumlah': firstItem['jumlah'] ?? 1,
            'alamat_pengiriman': _recipientAddress,
            'nama_penerima': _recipientName,
            'no_hp_penerima': _recipientPhone,
            'metode_pengambilan': _metodePengambilan,
            'metode_pembayaran': 'midtrans_snap',
            'mode': 'snap',
          });
          if (beliUmumRes.success && beliUmumRes.data != null) {
            createdData = beliUmumRes.data;
          }
        }

        if (createdData != null) {
          idPesanan =
              (createdData['id'] ?? createdData['id_pembelian'])?.toString();
          noPesanan = createdData['no_pesanan']?.toString();
          snapToken = createdData['snap_token']?.toString();
          redirectUrl = createdData['redirect_url']?.toString();
          final parsedTotal = double.tryParse(
                (createdData['total_bayar'] ??
                        createdData['total_harga'] ??
                        _totalPembayaran)
                    .toString(),
              )?.round();
          if (parsedTotal != null && parsedTotal > 0) {
            finalTotalAmount = parsedTotal;
          }
        }
      }

      // 2. Jika idPesanan sudah ada namun redirect_url / snap_token belum ada, panggil /snap-token
      if (idPesanan != null &&
          idPesanan.isNotEmpty &&
          ApiConstants.resolveMidtransRedirectUrl(
                redirectUrl: redirectUrl,
                snapToken: snapToken,
              ) ==
              null) {
        final snapRes = await PasienApiService()
            .getSnapTokenObat(idPesanan, forceNew: false);
        if (snapRes.success && snapRes.data != null) {
          snapToken = snapRes.data!['snap_token']?.toString() ?? snapToken;
          redirectUrl =
              snapRes.data!['redirect_url']?.toString() ?? redirectUrl;
          noPesanan = snapRes.data!['no_pesanan']?.toString() ?? noPesanan;
        }
      }

      _activePesananId = idPesanan;
      _activeNoPesanan = noPesanan;
      _activeSnapToken = snapToken;
      _activeRedirectUrl = redirectUrl;
    } catch (e) {
      debugPrint('Checkout Midtrans obat notice: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessingCheckout = false);
      }
    }

    if (!context.mounted) return;

    final resolvedUrl = ApiConstants.resolveMidtransRedirectUrl(
      redirectUrl: redirectUrl,
      snapToken: snapToken,
    );

    final readableMethod = MidtransChannelOption.getReadableMethodLabel(
      _metodePembayaran,
      vaBankId: _selectedVaBank,
    );

    final List<Map<String, dynamic>> orderItemsList = [];
    if (widget.resepData != null && widget.resepData!.medications.isNotEmpty) {
      for (final m in widget.resepData!.medications) {
        orderItemsList.add({
          'nama_obat': m.name,
          'aturan_pakai': '${m.aturanPakai} • ${m.jumlahObat}',
          'dosage': m.aturanPakai,
          'jumlah': m.jumlahObat,
          'harga_satuan': m.price > 0 ? m.price : 50000,
          'subtotal': m.price > 0 ? m.price : 50000,
          'harga_formatted': _formatCurrency(m.price > 0 ? m.price : 50000),
        });
      }
    } else if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
      for (final ci in widget.cartItems!) {
        final p = int.tryParse(ci['harga']?.toString() ?? '') ?? 50000;
        final q = int.tryParse(ci['jumlah']?.toString() ?? '') ?? 1;
        orderItemsList.add({
          'nama_obat': (ci['nama'] ?? ci['nama_obat'] ?? 'Obat').toString(),
          'aturan_pakai': (ci['aturan_pakai'] ?? 'Sesuai aturan').toString(),
          'dosage': (ci['aturan_pakai'] ?? 'Sesuai aturan').toString(),
          'jumlah': '$q unit',
          'harga_satuan': p,
          'subtotal': p * q,
          'harga_formatted': _formatCurrency(p * q),
        });
      }
    } else {
      orderItemsList.add({
        'nama_obat': 'Obat Terapi Ginjal',
        'aturan_pakai': 'Sesuai petunjuk dokter • 30 tablet',
        'dosage': 'Sesuai petunjuk dokter',
        'jumlah': '30 tab',
        'harga_satuan': 50000,
        'subtotal': 50000,
        'harga_formatted': _formatCurrency(50000),
      });
    }

    final orderData = OrderCheckoutData(
      idPesanan: idPesanan,
      orderNumber: noPesanan ??
          'ORD-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-001',
      prescriptionNumber: rxNumber,
      itemCount: itemCount,
      totalAmount: finalTotalAmount,
      totalAmountFormatted: _formatCurrency(finalTotalAmount),
      paymentMethod: readableMethod,
      virtualAccountNumber: '8077 0812 3456 7890',
      transactionTime: TimeUtils.formatDate(
        DateTime.now().toIso8601String(),
        useIndonesianMonth: true,
      ),
      pickupMethod: _metodePengambilan == 'antar'
          ? 'Antar ke Alamat'
          : 'Ambil di Apotek',
      recipientName: _recipientName,
      recipientPhone: _recipientPhone,
      recipientAddress: _recipientAddress,
      estimatedArrival: 'Hari ini (~${_selectedApotek.estimatedMinutes} menit • ${_selectedApotek.formattedDistance})',
      snapToken: snapToken,
      redirectUrl: resolvedUrl,
      statusPembayaran: 'menunggu_pembayaran',
      items: orderItemsList,
      apotekId: _selectedApotek.id,
      apotekName: _selectedApotek.namaApotek,
      apotekAddress: _selectedApotek.alamat,
      apotekLat: _selectedApotek.latitude,
      apotekLng: _selectedApotek.longitude,
      patientLat: _patientCoord.latitude,
      patientLng: _patientCoord.longitude,
      distanceKm: _selectedApotek.distanceKm,
    );

    // 3. Jika redirect_url Midtrans Snap tersedia, buka MidtransPaymentWebViewPage
    if (resolvedUrl != null &&
        resolvedUrl.isNotEmpty &&
        idPesanan != null &&
        idPesanan.isNotEmpty) {
      final webViewResult = await Navigator.push<MidtransPaymentResult>(
        context,
        MaterialPageRoute(
          builder: (_) => MidtransPaymentWebViewPage(
            redirectUrl: resolvedUrl,
            snapToken: snapToken,
            title: 'Pembayaran Obat Apotek',
            subtitle: 'Pesanan Obat Apotek Mitra GIAT',
            amountFormatted: orderData.totalAmountFormatted,
            preferredMethodId: _metodePembayaran,
            preferredVaBankId: _selectedVaBank,
            onCheckStatus: () async {
              final statusRes =
                  await PasienApiService().cekStatusPembayaranObat(idPesanan);
              return statusRes.data;
            },
            onRefreshSnapUrl: () async {
              final refreshRes = await PasienApiService()
                  .getSnapTokenObat(idPesanan, forceNew: true);
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

      // 4. Setelah keluar dari WebView, panggil GET /api/pasien/obat/pesanan/{id}/status-bayar
      bool isLunas = webViewResult?.isPaid == true;
      Map<String, dynamic>? latestStatusData = webViewResult?.statusData;

      if (!isLunas) {
        setState(() => _isProcessingCheckout = true);
        final checkRes =
            await PasienApiService().cekStatusPembayaranObat(idPesanan);
        if (mounted) {
          setState(() => _isProcessingCheckout = false);
        }
        if (checkRes.success && checkRes.data != null) {
          latestStatusData = checkRes.data;
          isLunas = MidtransPaymentWebViewPage.isStatusLunas(latestStatusData);
        }
      }

      if (!context.mounted) return;

      final updatedOrderData = orderData.copyWith(
        statusPembayaran: isLunas ? 'lunas' : 'menunggu_pembayaran',
        statusPesanan: latestStatusData?['status_pesanan']?.toString() ??
            orderData.statusPesanan,
      );

      // 5. Jika status_pembayaran == 'lunas', tandai resep dokter sudah ditebus, kirim ke Apotek & arahkan pasien ke Lacak Obat
      if (isLunas) {
        if (widget.resepData != null) {
          final cleanRx = widget.resepData!.id ?? rxNumber.replaceAll('No.', '').trim();
          await PasienApiService().markResepDitebus(cleanRx);
        }

        await SupabaseAdminService.instance.completePasienObatPaymentInSupabase(
          idPesanan: idPesanan,
          noPesanan: noPesanan,
          idResep: widget.resepData?.id,
          noResep: rxNumber,
          patientName: widget.userName,
          idApotek: _selectedApotek.id,
          metodePengambilan: _metodePengambilan,
          namaPenerima: _recipientName,
          noHpPenerima: _recipientPhone,
          alamatPengiriman: _recipientAddress,
          metodePembayaran: _metodePembayaran,
          subtotal: _subtotalObat,
          ongkosKirim: _biayaPengiriman,
          totalBayar: finalTotalAmount,
          items: orderItemsList,
        );

        if (widget.cartItems != null && widget.cartItems!.isNotEmpty) {
          CartService.instance.clearSelected();
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pembayaran Obat Berhasil (Lunas)! Mengarahkan ke halaman Detail & Lacak Pesanan...',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: _darkGreen,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LacakObatScreen(
              userName: widget.userName,
              orderData: updatedOrderData,
              pesananId: idPesanan,
            ),
          ),
        );
        return;
      } else {
        // Pastikan jika belum dibayar lunas, resep tetap berstatus 'aktif' (belum masuk ke Apotek)
        if (widget.resepData != null) {
          await SupabaseAdminService.instance.revertResepToAktifIfUnpaid(
            idResep: widget.resepData!.id,
            noResep: rxNumber,
          );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pesanan obat berstatus Menunggu Pembayaran. Anda dapat melanjutkan pembayaran di halaman Detail / Riwayat Pesanan.',
              style: GoogleFonts.inter(fontSize: 12.5),
            ),
            backgroundColor: const Color(0xFFD97706),
            duration: const Duration(seconds: 4),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LacakObatScreen(
              userName: widget.userName,
              orderData: updatedOrderData,
            ),
          ),
        );
        return;
      }
    }

    // Fallback jika redirect_url tidak tersedia
    if (_metodePembayaran == 'virtual_account') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PembayaranTransferBankScreen(
            userName: widget.userName,
            orderData: orderData,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PembayaranQrisScreen(
            userName: widget.userName,
            orderData: orderData,
          ),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: BACKGROUND CONTOUR LINES FOR CHECKOUT
// ─────────────────────────────────────────────────────────────────────────────

class _CheckoutTopographyPainter extends CustomPainter {
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
