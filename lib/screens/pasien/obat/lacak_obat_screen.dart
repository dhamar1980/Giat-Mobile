import 'dart:async';
import 'dart:io';
import 'package:giat/widgets/giat_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../profile/profile_pasien_screen.dart';
import '../widgets/midtrans_payment_webview_page.dart';
import 'pembayaran_model.dart';
import '../../../constants/api_constants.dart';
import '../../../services/pasien_api_service.dart';
import '../../../services/supabase_admin_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/jember_location_service.dart';
import '../../../widgets/app_top_action_pill.dart';
import '../../../widgets/giat_real_map_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HALAMAN LACAK OBAT (Figma Node: 977:10969)
// ─────────────────────────────────────────────────────────────────────────────

class LacakObatScreen extends StatefulWidget {
  final String userName;
  final String orderId;
  final String estimasiTiba;
  final String status;
  final OrderCheckoutData? orderData;
  final String? pesananId;

  const LacakObatScreen({
    super.key,
    this.userName = 'Pasien',
    this.orderId = '#G-9021',
    this.estimasiTiba = 'Hari ini, 15:30 WIB',
    this.status = 'Sedang Diproses',
    this.orderData,
    this.pesananId,
  });

  @override
  State<LacakObatScreen> createState() => _LacakObatScreenState();
}

class _LacakObatScreenState extends State<LacakObatScreen> {
  static const _darkGreen = Color(0xFF065A37);
  static const _bgColor = Color(0xFFF6FAF7);
  static const _cardBorderColor = Color(0xFFE2E8F0);
  static const _amberStatus = Color(0xFFE5A100);

  late String _displayOrderNo;
  late String _displayStatusPesanan;
  late String _statusPembayaran;
  String? _pesananUuid;
  String? _snapToken;
  String? _redirectUrl;
  bool _isCheckingPayment = false;

  String _recipientName = 'Pasien';
  String _recipientPhone = '0812-3456-7891';
  String _recipientAddress = 'Jl. Kalimantan No. 37, Sumbersari, Jember, Jawa Timur 68121';
  String _namaApotek = 'Apotek Kimia Farma Jember';
  String _alamatApotek = 'Jl. Gajah Mada No. 175, Kaliwates, Jember';
  List<Map<String, dynamic>> _orderItems = [];

  // ── Real-Time Jember Live Map & Courier Telemetry State ──
  JemberCoordinate _apotekCoord = const JemberCoordinate(
    latitude: -8.1747,
    longitude: 113.6882,
    address: 'Jl. Gajah Mada No. 175, Kaliwates, Jember',
    areaName: 'Apotek Kimia Farma Jember',
  );
  JemberCoordinate _patientCoord = const JemberCoordinate(
    latitude: -8.1668,
    longitude: 113.7162,
    address: 'Jl. Kalimantan No. 37, Sumbersari, Jember',
    areaName: 'Sumbersari, Jember',
  );
  JemberCoordinate _courierCoord = const JemberCoordinate(
    latitude: -8.1716,
    longitude: 113.7015,
    address: 'Jl. Gajah Mada, Kaliwates, Jember',
    areaName: 'Kurir GIAT Express',
  );
  List<JemberCoordinate> _routePoints = [];
  double _routeProgress = 0.45;
  double _totalDistanceKm = 2.8;
  double _remainingKm = 1.5;
  int _etaMinutes = 8;
  String _currentStreet = 'Kawasan Jl. Gajah Mada, Kaliwates, Jember';
  String _courierName = 'Rahmat Setiawan';
  String _courierPlate = 'P 4921 QV (Jember)';
  bool _isSimulatingLive = false;
  bool _isActivatingGps = false;
  Timer? _liveSimTimer;
  Timer? _firebasePollTimer;

  @override
  void initState() {
    super.initState();
    _pesananUuid = widget.pesananId ?? widget.orderData?.idPesanan;
    _displayOrderNo = widget.orderData?.orderNumber ?? widget.orderId;
    _displayStatusPesanan = widget.orderData != null
        ? _formatStatusPesanan(widget.orderData!.statusPesanan)
        : widget.status;
    _statusPembayaran =
        widget.orderData?.statusPembayaran ?? 'lunas';
    _snapToken = widget.orderData?.snapToken;
    _redirectUrl = widget.orderData?.redirectUrl;

    if (widget.orderData?.recipientName != null &&
        widget.orderData!.recipientName.isNotEmpty &&
        widget.orderData!.recipientName != 'Pasien') {
      _recipientName = widget.orderData!.recipientName;
    } else if (widget.userName.isNotEmpty && widget.userName != 'Pasien') {
      _recipientName = widget.userName;
    }

    if (widget.orderData?.recipientPhone != null &&
        widget.orderData!.recipientPhone.isNotEmpty) {
      _recipientPhone = widget.orderData!.recipientPhone;
    }

    if (widget.orderData?.recipientAddress != null &&
        widget.orderData!.recipientAddress.isNotEmpty) {
      _recipientAddress = widget.orderData!.recipientAddress;
    }

    if (widget.orderData?.apotekName != null &&
        widget.orderData!.apotekName.isNotEmpty) {
      _namaApotek = widget.orderData!.apotekName;
    }
    if (widget.orderData?.apotekAddress != null &&
        widget.orderData!.apotekAddress.isNotEmpty) {
      _alamatApotek = widget.orderData!.apotekAddress;
    }

    if (widget.orderData?.items != null && widget.orderData!.items!.isNotEmpty) {
      _orderItems = List<Map<String, dynamic>>.from(widget.orderData!.items!);
    }

    _initializeJemberMapAndRoute();
    _loadInitialUserData();

    if (_pesananUuid != null && _pesananUuid!.isNotEmpty) {
      _syncPaymentAndTrackingStatus(silent: true);
    }

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _firebasePollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
        _pullLiveTrackingFromFirebase();
      });
    }
  }

  @override
  void dispose() {
    _liveSimTimer?.cancel();
    _firebasePollTimer?.cancel();
    super.dispose();
  }

  void _initializeJemberMapAndRoute() {
    // 1. Resolve titik koordinat pasien dari orderData atau alamat registrasi Jember
    if (widget.orderData?.patientLat != null &&
        widget.orderData?.patientLng != null) {
      _patientCoord = JemberCoordinate(
        latitude: widget.orderData!.patientLat!,
        longitude: widget.orderData!.patientLng!,
        address: _recipientAddress,
        areaName: 'Lokasi Tujuan Pasien',
      );
    } else {
      _patientCoord = JemberLocationService.instance
          .resolveAddressToJemberCoordinate(_recipientAddress);
    }

    // 2. Resolve titik koordinat Apotek Jember (dari orderData atau apotek terdekat)
    if (widget.orderData?.apotekLat != null &&
        widget.orderData?.apotekLng != null) {
      _apotekCoord = JemberCoordinate(
        latitude: widget.orderData!.apotekLat!,
        longitude: widget.orderData!.apotekLng!,
        address: _alamatApotek,
        areaName: _namaApotek,
      );
    } else {
      final ranked = JemberLocationService.instance.rankApoteksByDistance(
        patientLat: _patientCoord.latitude,
        patientLng: _patientCoord.longitude,
      );
      final matchedApotek = ranked.firstWhere(
        (a) => a.namaApotek.toLowerCase() == _namaApotek.toLowerCase(),
        orElse: () => ranked.first,
      );
      _namaApotek = matchedApotek.namaApotek;
      _alamatApotek = matchedApotek.alamat;
      _apotekCoord = JemberCoordinate(
        latitude: matchedApotek.latitude,
        longitude: matchedApotek.longitude,
        address: matchedApotek.alamat,
        areaName: matchedApotek.namaApotek,
      );
    }

    // 3. Tentukan progress awal berdasarkan status pesanan
    final s = _displayStatusPesanan.toLowerCase();
    if (s.contains('selesai') || s.contains('terima')) {
      _routeProgress = 1.0;
    } else if (s.contains('kirim') || s.contains('antar')) {
      _routeProgress = 0.62;
    } else if (s.contains('proses') || s.contains('racik') || s.contains('kemas')) {
      _routeProgress = 0.35;
    } else {
      _routeProgress = 0.12;
    }

    // 4. Bangun rute jalan Jember & posisi kurir
    _routePoints = JemberLocationService.instance.buildJemberArterialRoadPoints(
      startLat: _apotekCoord.latitude,
      startLng: _apotekCoord.longitude,
      endLat: _patientCoord.latitude,
      endLng: _patientCoord.longitude,
    );
    _recalculateCourierTelemetry(_routeProgress);

    // 5. Jika online, perhalus rute dengan OSRM road geometry
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      JemberLocationService.instance
          .buildRoadRoute(
        startLat: _apotekCoord.latitude,
        startLng: _apotekCoord.longitude,
        endLat: _patientCoord.latitude,
        endLng: _patientCoord.longitude,
      )
          .then((pts) {
        if (!mounted || pts.length < 2) return;
        setState(() {
          _routePoints = pts;
          _recalculateCourierTelemetry(_routeProgress);
        });
      });
    }
  }

  void _recalculateCourierTelemetry(double progress) {
    final p = progress.clamp(0.0, 1.0);
    _routeProgress = p;
    _totalDistanceKm = JemberLocationService.calculateDistanceKm(
      _apotekCoord.latitude,
      _apotekCoord.longitude,
      _patientCoord.latitude,
      _patientCoord.longitude,
    );
    if (_totalDistanceKm < 0.3) _totalDistanceKm = 1.4;

    _courierCoord = JemberLocationService.instance.interpolateCourierOnRoute(
      _routePoints,
      p,
    );
    _currentStreet = JemberLocationService.instance.resolveStreetNameOnRoute(
      _courierCoord.latitude,
      _courierCoord.longitude,
    );
    _remainingKm = double.parse((_totalDistanceKm * (1.0 - p)).toStringAsFixed(2));
    _etaMinutes = p >= 0.98
        ? 0
        : (_remainingKm * 4.5 + 2).round().clamp(1, 45);
  }

  Future<void> _pullLiveTrackingFromFirebase() async {
    final trackKey = _pesananUuid ?? _displayOrderNo;
    final raw = await JemberLocationService.instance
        .fetchCourierTrackingFromFirebase(trackKey);
    if (raw != null && mounted && !_isSimulatingLive) {
      final p = double.tryParse((raw['progress_ratio'] ?? '').toString());
      final cLat = double.tryParse((raw['courier_lat'] ?? '').toString());
      final cLng = double.tryParse((raw['courier_lng'] ?? '').toString());
      final street = raw['current_street']?.toString();
      final remKm = double.tryParse((raw['remaining_km'] ?? '').toString());
      final eta = int.tryParse((raw['eta_minutes'] ?? '').toString());
      final stage = (raw['status_pesanan'] ?? '').toString().toLowerCase();

      setState(() {
        if (p != null) {
          _recalculateCourierTelemetry(p);
        }
        if (cLat != null && cLng != null) {
          _courierCoord = JemberCoordinate(
            latitude: cLat,
            longitude: cLng,
            address: street ?? _currentStreet,
            isFromGps: true,
          );
        }
        if (street != null && street.isNotEmpty) {
          _currentStreet = street;
        }
        if (remKm != null) _remainingKm = remKm;
        if (eta != null) _etaMinutes = eta;
        if (stage.contains('kirim')) {
          _displayStatusPesanan = 'Dalam Pengiriman';
        } else if (stage.contains('selesai')) {
          _displayStatusPesanan = 'Pesanan Selesai';
        }
      });
    }
  }

  void _toggleLiveCourierSimulation() {
    if (_isSimulatingLive) {
      _liveSimTimer?.cancel();
      setState(() => _isSimulatingLive = false);
      return;
    }

    setState(() {
      _isSimulatingLive = true;
      if (_routeProgress >= 0.98) {
        _routeProgress = 0.08;
      }
      _displayStatusPesanan = 'Dalam Pengiriman';
      _recalculateCourierTelemetry(_routeProgress);
    });

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      setState(() {
        _recalculateCourierTelemetry((_routeProgress + 0.25).clamp(0.0, 1.0));
        _isSimulatingLive = false;
      });
      return;
    }

    _liveSimTimer?.cancel();
    _liveSimTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final nextProgress = _routeProgress + 0.06;
      if (nextProgress >= 1.0) {
        timer.cancel();
        setState(() {
          _isSimulatingLive = false;
          _displayStatusPesanan = 'Pesanan Selesai';
          _recalculateCourierTelemetry(1.0);
        });
        _broadcastCurrentTrackingToFirebase('selesai');
      } else {
        setState(() {
          _displayStatusPesanan = 'Dalam Pengiriman';
          _recalculateCourierTelemetry(nextProgress);
        });
        _broadcastCurrentTrackingToFirebase('dikirim');
      }
    });
  }

  Future<void> _broadcastCurrentTrackingToFirebase(String stage) async {
    final trackKey = _pesananUuid ?? _displayOrderNo;
    await JemberLocationService.instance.pushCourierTrackingToFirebase(
      orderId: trackKey,
      courierLat: _courierCoord.latitude,
      courierLng: _courierCoord.longitude,
      progressRatio: _routeProgress,
      statusPesanan: stage,
      currentStreet: _currentStreet,
      remainingKm: _remainingKm,
      etaMinutes: _etaMinutes,
      courierName: _courierName,
      courierPlate: _courierPlate,
    );
  }

  Future<void> _activateRealPatientGpsOnTrack() async {
    setState(() => _isActivatingGps = true);
    try {
      final gpsCoord = await JemberLocationService.instance
          .requestAndFetchRealGpsLocation(currentAddressHint: _recipientAddress);
      if (!mounted) return;
      setState(() {
        _patientCoord = gpsCoord;
        if (gpsCoord.address.isNotEmpty) {
          _recipientAddress = gpsCoord.address;
        }
        _routePoints = JemberLocationService.instance.buildJemberArterialRoadPoints(
          startLat: _apotekCoord.latitude,
          startLng: _apotekCoord.longitude,
          endLat: _patientCoord.latitude,
          endLng: _patientCoord.longitude,
        );
        _recalculateCourierTelemetry(_routeProgress);
        _isActivatingGps = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Titik GPS Real-Time diperbarui (${_patientCoord.latitude.toStringAsFixed(5)}, ${_patientCoord.longitude.toStringAsFixed(5)}) — Rute kurir Jember disesuaikan!',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          backgroundColor: _darkGreen,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _isActivatingGps = false);
    }
  }

  Future<void> _loadInitialUserData() async {
    try {
      final user = await StorageService().getUser();
      if (user != null && mounted) {
        setState(() {
          if (_recipientName == 'Pasien' && user.nama.isNotEmpty) {
            _recipientName = user.nama;
          }
          if (user.noHp != null && user.noHp!.isNotEmpty) {
            _recipientPhone = user.noHp!;
          }
          if (user.alamat != null &&
              user.alamat!.isNotEmpty &&
              widget.orderData?.recipientAddress == null) {
            _recipientAddress = user.alamat!;
            _patientCoord = JemberLocationService.instance
                .resolveAddressToJemberCoordinate(_recipientAddress);
            _routePoints = JemberLocationService.instance.buildJemberArterialRoadPoints(
              startLat: _apotekCoord.latitude,
              startLng: _apotekCoord.longitude,
              endLat: _patientCoord.latitude,
              endLng: _patientCoord.longitude,
            );
            _recalculateCourierTelemetry(_routeProgress);
          }
        });
      }
    } catch (_) {}
  }

  String _formatStatusPesanan(String raw) {
    final s = raw.toLowerCase().trim();
    if (s == 'menunggu_konfirmasi') return 'Menunggu Konfirmasi';
    if (s == 'diproses') return 'Sedang Diproses';
    if (s == 'dikirim') return 'Dalam Pengiriman';
    if (s == 'selesai') return 'Pesanan Selesai';
    if (s == 'dibatalkan') return 'Dibatalkan';
    return widget.status;
  }

  Future<void> _syncPaymentAndTrackingStatus({bool silent = false}) async {
    final id = _pesananUuid;
    if (id == null || id.isEmpty) return;

    if (!silent && mounted) {
      setState(() => _isCheckingPayment = true);
    }

    try {
      final statusRes = await PasienApiService().cekStatusPembayaranObat(id);
      if (!mounted) return;
      if (statusRes.success && statusRes.data != null) {
        final d = statusRes.data!;
        final isPaid = MidtransPaymentWebViewPage.isStatusLunas(d);
        if (isPaid) {
          await SupabaseAdminService.instance.completePasienObatPaymentInSupabase(
            idPesanan: id,
            noPesanan: d['no_pesanan']?.toString() ?? _displayOrderNo,
            noResep: widget.orderData?.prescriptionNumber,
            patientName: widget.userName,
          );
        }
        setState(() {
          _statusPembayaran = isPaid
              ? 'lunas'
              : (d['status_pembayaran']?.toString() ?? _statusPembayaran);
          if (d['no_pesanan'] != null) {
            _displayOrderNo = d['no_pesanan'].toString();
          }
          if (d['status_pesanan'] != null) {
            _displayStatusPesanan =
                _formatStatusPesanan(d['status_pesanan'].toString());
          }
          _snapToken = d['snap_token']?.toString() ?? _snapToken;
          _redirectUrl = d['redirect_url']?.toString() ?? _redirectUrl;
        });

        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPaid
                    ? 'Pembayaran Pesanan $_displayOrderNo telah LUNAS!'
                    : 'Status pembayaran masih ${_statusPembayaran.replaceAll('_', ' ')}.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor:
                  isPaid ? _darkGreen : const Color(0xFFD97706),
            ),
          );
        }
      }

      final detailRes = await PasienApiService().getDetailPesanan(id);
      if (detailRes.success && detailRes.data != null && mounted) {
        final det = detailRes.data!;
        setState(() {
          if (det['nama_penerima'] != null && det['nama_penerima'].toString().isNotEmpty) {
            _recipientName = det['nama_penerima'].toString();
          }
          if (det['no_hp_penerima'] != null && det['no_hp_penerima'].toString().isNotEmpty) {
            _recipientPhone = det['no_hp_penerima'].toString();
          }
          if (det['alamat_pengiriman'] != null && det['alamat_pengiriman'].toString().isNotEmpty) {
            _recipientAddress = det['alamat_pengiriman'].toString();
          }
          if (det['nama_apotek'] != null && det['nama_apotek'].toString().isNotEmpty) {
            _namaApotek = det['nama_apotek'].toString();
          } else if (det['apotek'] is Map && det['apotek']['nama'] != null) {
            _namaApotek = det['apotek']['nama'].toString();
          }
          if (det['items'] is List && (det['items'] as List).isNotEmpty) {
            _orderItems = List<Map<String, dynamic>>.from(
              (det['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Sync status bayar obat notice: $e');
    } finally {
      if (mounted && !silent) {
        setState(() => _isCheckingPayment = false);
      }
    }
  }

  Future<void> _openMidtransSnapPayment() async {
    final id = _pesananUuid;
    String? resolvedUrl = ApiConstants.resolveMidtransRedirectUrl(
      redirectUrl: _redirectUrl,
      snapToken: _snapToken,
    );

    if (resolvedUrl == null && id != null && id.isNotEmpty) {
      setState(() => _isCheckingPayment = true);
      final snapRes =
          await PasienApiService().getSnapTokenObat(id, forceNew: false);
      if (mounted) {
        setState(() => _isCheckingPayment = false);
      }
      if (snapRes.success && snapRes.data != null) {
        _snapToken = snapRes.data!['snap_token']?.toString() ?? _snapToken;
        _redirectUrl =
            snapRes.data!['redirect_url']?.toString() ?? _redirectUrl;
        resolvedUrl = ApiConstants.resolveMidtransRedirectUrl(
          redirectUrl: _redirectUrl,
          snapToken: _snapToken,
        );
      }
    }

    if (!mounted) return;
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'URL pembayaran Midtrans tidak ditemukan untuk pesanan ini.',
            style: GoogleFonts.inter(fontSize: 12.5),
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    final webViewRes = await Navigator.push<MidtransPaymentResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MidtransPaymentWebViewPage(
          redirectUrl: resolvedUrl,
          snapToken: _snapToken,
          title: 'Pembayaran Obat Apotek',
          subtitle: 'Pesanan Obat Apotek Mitra GIAT',
          amountFormatted: widget.orderData?.totalAmountFormatted,
          onCheckStatus: id != null && id.isNotEmpty
              ? () async {
                  final r =
                      await PasienApiService().cekStatusPembayaranObat(id);
                  return r.data;
                }
              : null,
          onRefreshSnapUrl: id != null && id.isNotEmpty
              ? () async {
                  final r = await PasienApiService()
                      .getSnapTokenObat(id, forceNew: true);
                  if (r.success && r.data != null) {
                    _snapToken = r.data!['snap_token']?.toString();
                    _redirectUrl = r.data!['redirect_url']?.toString();
                    return ApiConstants.resolveMidtransRedirectUrl(
                      redirectUrl: _redirectUrl,
                      snapToken: _snapToken,
                    );
                  }
                  return null;
                }
              : null,
        ),
      ),
    );

    if (!mounted) return;
    if (webViewRes?.isPaid == true) {
      setState(() => _statusPembayaran = 'lunas');
      await SupabaseAdminService.instance.completePasienObatPaymentInSupabase(
        idPesanan: id,
        noPesanan: _displayOrderNo,
        noResep: widget.orderData?.prescriptionNumber,
        patientName: widget.userName,
      );
    }
    await _syncPaymentAndTrackingStatus(silent: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Background Topography
          Positioned.fill(
            child: CustomPaint(
              painter: _LacakObatTopographyPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. Top Navigation Bar (<- Kembali & Action Pill) ──
                        _buildTopBar(context),

                        const SizedBox(height: 16),

                        // ── 2. Screen Title Pill: Lacak Obat ──
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
                              'Lacak Obat',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── 3. Header Status Pesanan Card ──
                        _buildHeaderStatusCard(),

                        const SizedBox(height: 16),

                        // ── 4. Peta Live Tracking Pengiriman Obat Kota Jember ──
                        _buildLiveMapTrackingCard(),

                        const SizedBox(height: 16),

                        // ── 5. Telemetri Pergerakan Kurir Real-Time & Kontrol ──
                        _buildLiveCourierTelemetryCard(),

                        const SizedBox(height: 16),

                        // ── 6. Timeline Pelacakan Pengiriman ──
                        _buildTimelineCard(),

                        const SizedBox(height: 16),

                        // ── 7. Kurir & Apotek Mitra Card ──
                        _buildKurirApotekCard(),

                        const SizedBox(height: 16),

                        // ── 8. Alamat Pengiriman Card ──
                        _buildAlamatPengirimanCard(),

                        const SizedBox(height: 16),

                        // ── 9. Rincian Obat yang Dikirim Card ──
                        _buildRincianObatCard(),
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
  // 2A. LIVE MAP TRACKING PENGIRIMAN OBAT REAL-TIME (KOTA JEMBER)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLiveMapTrackingCard() {
    final midLat = (_apotekCoord.latitude + _patientCoord.latitude) / 2.0;
    final midLng = (_apotekCoord.longitude + _patientCoord.longitude) / 2.0;

    final markers = <GiatMapMarker>[
      GiatMapMarker(
        id: 'apotek_jember',
        title: _namaApotek,
        subtitle: _alamatApotek,
        latitude: _apotekCoord.latitude,
        longitude: _apotekCoord.longitude,
        type: GiatMapMarkerType.apotek,
      ),
      GiatMapMarker(
        id: 'pasien_jember',
        title: 'Rumah $_recipientName',
        subtitle: _recipientAddress,
        latitude: _patientCoord.latitude,
        longitude: _patientCoord.longitude,
        type: GiatMapMarkerType.pasien,
      ),
      GiatMapMarker(
        id: 'kurir_giat',
        title: 'Kurir: $_courierName ($_courierPlate)',
        subtitle: 'Melintasi $_currentStreet',
        latitude: _courierCoord.latitude,
        longitude: _courierCoord.longitude,
        type: GiatMapMarkerType.kurir,
        isSelected: true,
        isPulsing: true,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE GPS TRACKING JEMBER',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: _darkGreen,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${(_routeProgress * 100).round()}% Perjalanan',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GiatRealMapWidget(
            centerLat: midLat,
            centerLng: midLng,
            initialZoom: 14.3,
            height: 255,
            markers: markers,
            routePoints: _routePoints,
            routeProgress: _routeProgress,
            topBadgeText: 'Peta Live Kurir Obat • Kota Jember',
            bottomBannerTitle: 'Posisi Kurir: $_currentStreet',
            bottomBannerSubtitle:
                'Dari $_namaApotek → $_recipientAddress ($_remainingKm km lagi • ~$_etaMinutes mnt)',
            onRequestGps: _activateRealPatientGpsOnTrack,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2B. TELEMETRI PERGERAKAN KURIR REAL-TIME & SIMULASI / GPS KONTROL
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLiveCourierTelemetryCard() {
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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
                  color: _darkGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posisi Paket Obat Saat Ini (Real-Time)',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      _currentStreet,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bar Statistik Jarak, Sisa Jarak, & ETA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTelemetryMetric(
                  label: 'Total Rute',
                  value: '${_totalDistanceKm.toStringAsFixed(1)} km',
                  icon: Icons.route_outlined,
                ),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                _buildTelemetryMetric(
                  label: 'Sisa Jarak',
                  value: '$_remainingKm km lagi',
                  icon: Icons.social_distance_rounded,
                ),
                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                _buildTelemetryMetric(
                  label: 'Estimasi Tiba',
                  value: _etaMinutes == 0 ? 'Tiba di Tujuan' : '~$_etaMinutes menit',
                  icon: Icons.timer_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar visual rute Apotek -> Rumah Pasien
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _routeProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(_darkGreen),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '🏥 $_namaApotek',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '🏠 Tujuan: $_recipientName (Jember)',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _darkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tombol Interaktif: Simulasi Live Pergerakan Kurir & Perbarui GPS Pasien
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isActivatingGps ? null : _activateRealPatientGpsOnTrack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _darkGreen,
                    side: const BorderSide(color: _darkGreen, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.my_location_rounded, size: 15),
                  label: Text(
                    'Hidupkan GPS Saya',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleLiveCourierSimulation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSimulatingLive
                        ? const Color(0xFFDC2626)
                        : _darkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    _isSimulatingLive
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _isSimulatingLive ? 'Hentikan Live' : 'Pantau Live Kurir',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: _darkGreen),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. TOP BAR NAVIGATION
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

  // ───────────────────────────────────────────────────────────────────────────
  // 2. HEADER STATUS PESANAN CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderStatusCard() {
    final isWaitingPayment =
        _statusPembayaran.toLowerCase() == 'menunggu_pembayaran';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWaitingPayment ? const Color(0xFFF59E0B) : _cardBorderColor,
          width: isWaitingPayment ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF8F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_shipping_outlined,
                        color: _darkGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Pengiriman',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            'Pesanan Obat Pasien',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
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
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isWaitingPayment
                      ? const Color(0xFFD97706)
                      : _amberStatus,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _amberStatus.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  isWaitingPayment
                      ? 'Menunggu Pembayaran'
                      : _displayStatusPesanan,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: _darkGreen),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: 'Estimasi tiba: ',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                    children: [
                      TextSpan(
                        text: widget.orderData?.estimatedArrival ??
                            widget.estimasiTiba,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isWaitingPayment) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.payment_rounded,
                        size: 17,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pesanan ini menunggu pembayaran via Midtrans Snap.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: _isCheckingPayment
                                ? null
                                : () =>
                                    _syncPaymentAndTrackingStatus(silent: false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _darkGreen,
                              side: const BorderSide(
                                color: _darkGreen,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: _isCheckingPayment
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _darkGreen,
                                    ),
                                  )
                                : const Icon(Icons.verified_outlined, size: 16),
                            label: Text(
                              'Cek Status',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: _isCheckingPayment
                                ? null
                                : _openMidtransSnapPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _darkGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.payment_rounded, size: 16),
                            label: Text(
                              'Bayar Sekarang',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 6),
                Text(
                  'Status Pembayaran: LUNAS (Midtrans)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. TIMELINE PELACAKAN PENGIRIMAN
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTimelineCard() {
    final s = _displayStatusPesanan.toLowerCase().trim();
    final isMenunggu = s.contains('menunggu') || s.contains('pending');
    final isDiproses = s.contains('proses') || s.contains('racik') || s.contains('kemas');
    final isDikirim = s.contains('kirim') || s.contains('antar');
    final isSelesai = s.contains('selesai') || s.contains('terima');
    final isBatal = s.contains('batal');

    final apotekName = _namaApotek.isNotEmpty ? _namaApotek : 'Apotek Mitra GIAT';
    final targetAddress = _recipientAddress.isNotEmpty ? _recipientAddress : 'alamat tujuan pengiriman';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Text(
            'Aktivitas Pengiriman',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          // Step 1: Resep Diterima
          _buildTrackingStep(
            title: 'Pesanan Diterima & Terverifikasi Digital',
            time: 'Terverifikasi Sistem',
            desc: 'Pesanan obat diverifikasi oleh sistem GIAT Smart Pharmacy.',
            isCompleted: true,
            isCurrent: isMenunggu,
          ),

          // Step 2: Telaah Resep Apoteker
          _buildTrackingStep(
            title: isMenunggu
                ? 'Menunggu Telaah Resep oleh Apoteker'
                : 'Telaah Resep oleh Apoteker Selesai',
            time: isMenunggu ? 'Dalam Antrean' : 'Telah Divalidasi',
            desc: 'Apoteker mitra memvalidasi keamanan dosis dan interaksi obat.',
            isCompleted: !isMenunggu && !isBatal,
          ),

          // Step 3: Pengemasan Kedap Suhu
          _buildTrackingStep(
            title: isDiproses
                ? 'Obat Sedang Dikemas Kedap Suhu'
                : (isDikirim || isSelesai
                    ? 'Pengemasan Obat Kedap Suhu Selesai'
                    : 'Persiapan Pengemasan Kedap Suhu'),
            time: (isDiproses || isDikirim || isSelesai) ? 'Higienis & Aman' : 'Estimasi',
            desc: 'Kemasan tersegel rapi dan higienis dari $apotekName.',
            isCompleted: isDiproses || isDikirim || isSelesai,
            isCurrent: isDiproses,
          ),

          // Step 4: Penjemputan Kurir
          _buildTrackingStep(
            title: (isDikirim || isSelesai)
                ? 'Kurir Telah Mengambil Paket Obat'
                : 'Kurir GIAT Mengambil Paket Obat',
            time: (isDikirim || isSelesai) ? 'Paket Dibawa Kurir' : 'Estimasi Pengambilan',
            desc: 'Driver spesialis logistik medis GIAT ditugaskan menuju apotek.',
            isCompleted: isDikirim || isSelesai,
          ),

          // Step 5: Dalam Perjalanan
          _buildTrackingStep(
            title: isDikirim
                ? 'Kurir Sedang Menuju Alamat Tujuan'
                : (isSelesai ? 'Kurir Telah Tiba di Lokasi Tujuan' : 'Pengantaran Menuju Alamat'),
            time: isDikirim ? 'Dalam Perjalanan' : (isSelesai ? 'Tiba di Lokasi' : 'Estimasi'),
            desc: 'Paket dalam perjalanan ke $targetAddress.',
            isCompleted: isDikirim || isSelesai,
            isCurrent: isDikirim,
          ),

          // Step 6: Selesai
          _buildTrackingStep(
            title: isSelesai ? 'Pesanan Selesai Diterima' : 'Pesanan Selesai Diterima Pasien',
            time: isSelesai ? 'Telah Diterima' : 'Konfirmasi Penerima',
            desc: 'Tanda tangan konfirmasi dan verifikasi fisik obat oleh pasien.',
            isCompleted: isSelesai,
            isCurrent: isSelesai,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStep({
    required String title,
    required String time,
    required String desc,
    required bool isCompleted,
    bool isCurrent = false,
    bool isLast = false,
  }) {
    Color indicatorBg;
    Widget indicatorChild;

    if (isCompleted && !isCurrent) {
      indicatorBg = _darkGreen;
      indicatorChild = const Icon(Icons.check, size: 13, color: Colors.white);
    } else if (isCurrent) {
      indicatorBg = const Color(0xFFDCFCE7);
      indicatorChild = Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: _darkGreen,
          shape: BoxShape.circle,
        ),
      );
    } else {
      indicatorBg = const Color(0xFFF1F5F9);
      indicatorChild = Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator & Vertical Line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: indicatorBg,
                  shape: BoxShape.circle,
                  border: isCurrent ? Border.all(color: _darkGreen, width: 2.2) : null,
                ),
                child: Center(child: indicatorChild),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? _darkGreen : const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: isCurrent ? FontWeight.w800 : (isCompleted ? FontWeight.w700 : FontWeight.w600),
                      color: isCurrent
                          ? _darkGreen
                          : (isCompleted ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isCurrent ? _darkGreen : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. KURIR & APOTEK MITRA CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildKurirApotekCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded, color: _darkGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apotek Pengirim',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                    ),
                    Text(
                      _namaApotek,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.moped_outlined, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kurir GIAT Express',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                    ),
                    Text(
                      (_displayStatusPesanan.toLowerCase().contains('kirim') ||
                              _displayStatusPesanan.toLowerCase().contains('selesai'))
                          ? 'Rahmat Setiawan (L-4921-ZA)'
                          : 'Menunggu Penugasan Kurir',
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. ALAMAT PENGIRIMAN CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAlamatPengirimanCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: _darkGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Alamat Tujuan Pengiriman',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$_recipientName • $_recipientPhone',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 3),
          Text(
            _recipientAddress,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w400, color: const Color(0xFF475569), height: 1.35),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Catatan: Pastikan penerima berada di alamat tujuan saat kurir mengantar paket obat.',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569)),
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
  // 6. RINCIAN OBAT YANG DIKIRIM CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRincianObatCard() {
    final count = _orderItems.isNotEmpty ? _orderItems.length : 1;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Obat dalam Paket',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count Obat',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _darkGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_orderItems.isNotEmpty) ...[
            for (int i = 0; i < _orderItems.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _buildItemRow(
                (_orderItems[i]['nama_obat'] ?? _orderItems[i]['nama'] ?? 'Obat').toString(),
                (_orderItems[i]['aturan_pakai'] ??
                    _orderItems[i]['dosage'] ??
                    '${_orderItems[i]['jumlah'] ?? 1} unit')
                    .toString(),
                _orderItems[i]['harga_formatted']?.toString() ??
                    _formatCurrency((double.tryParse((_orderItems[i]['subtotal'] ?? _orderItems[i]['harga_satuan'] ?? 50000).toString()) ?? 50000).toInt()),
              ),
            ],
          ] else ...[
            _buildItemRow(
              'Obat Terapi Ginjal',
              'Sesuai petunjuk dokter • 30 tablet',
              _formatCurrency(50000),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
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

  Widget _buildItemRow(String name, String dosage, String price) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.medication_rounded, color: _darkGreen, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
              Text(
                dosage,
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: BACKGROUND CONTOUR LINES FOR LACAK OBAT
// ─────────────────────────────────────────────────────────────────────────────

class _LacakObatTopographyPainter extends CustomPainter {
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
