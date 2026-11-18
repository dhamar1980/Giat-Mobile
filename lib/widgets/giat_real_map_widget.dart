import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/jember_location_service.dart';

enum GiatMapMarkerType {
  pasien,
  apotek,
  dokter,
  kurir,
  admin,
}

class GiatMapMarker {
  final String id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final GiatMapMarkerType type;
  final bool isSelected;
  final bool isPulsing;
  final VoidCallback? onTap;

  const GiatMapMarker({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.latitude,
    required this.longitude,
    required this.type,
    this.isSelected = false,
    this.isPulsing = false,
    this.onTap,
  });
}

/// Widget Peta Real Kota Jember (OpenStreetMap Web Mercator Slippy Tiles + Road Route Polyline)
/// - Secara default `interactive = false` (TERKUNCI) untuk peta pratinjau yang sudah ditentukan lokasinya,
///   sehingga tidak bisa tergeser secara tidak sengaja saat halaman di-scroll.
/// - `interactive = true` HANYA aktif saat user membuka modal penentuan titik lokasi (`showJemberLocationPickerModal`).
class GiatRealMapWidget extends StatefulWidget {
  final double centerLat;
  final double centerLng;
  final double initialZoom; // 12.5 - 17.0
  final double height;
  final List<GiatMapMarker> markers;
  final List<JemberCoordinate> routePoints;
  final double routeProgress; // 0.0 - 1.0
  final bool interactive;
  final bool showControls;
  final bool showCoordinateBanner;
  final String? topBadgeText;
  final String? bottomBannerTitle;
  final String? bottomBannerSubtitle;
  final void Function(double lat, double lng)? onTapLocation;
  final VoidCallback? onRequestGps;

  const GiatRealMapWidget({
    super.key,
    this.centerLat = JemberLocationService.jemberCenterLat,
    this.centerLng = JemberLocationService.jemberCenterLng,
    this.initialZoom = 14.5,
    this.height = 230,
    this.markers = const [],
    this.routePoints = const [],
    this.routeProgress = 0.0,
    this.interactive = false,
    this.showControls = false,
    this.showCoordinateBanner = true,
    this.topBadgeText,
    this.bottomBannerTitle,
    this.bottomBannerSubtitle,
    this.onTapLocation,
    this.onRequestGps,
  });

  @override
  State<GiatRealMapWidget> createState() => _GiatRealMapWidgetState();
}

class _GiatRealMapWidgetState extends State<GiatRealMapWidget>
     with SingleTickerProviderStateMixin {
  static const _darkGreen = Color(0xFF065A37);

  late double _viewLat;
  late double _viewLng;
  late double _zoom;
  late AnimationController _pulseCtrl;
  bool _hasUserPanned = false;

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    _viewLat = widget.centerLat;
    _viewLng = widget.centerLng;
    _zoom = widget.initialZoom;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (!_isTest) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant GiatRealMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.centerLat - widget.centerLat).abs() > 0.00005 ||
        (oldWidget.centerLng - widget.centerLng).abs() > 0.00005 ||
        oldWidget.markers.length != widget.markers.length ||
        oldWidget.routePoints.length != widget.routePoints.length) {
      _viewLat = widget.centerLat;
      _viewLng = widget.centerLng;
      _hasUserPanned = false;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── PROYEKSI WEB MERCATOR PRESISI (SAMA PERSIS DENGAN OPENSTREETMAP 256px) ──
  static double _lngToWorldX(double lng, double zoom) {
    final scale = 256.0 * math.pow(2.0, zoom);
    return ((lng + 180.0) / 360.0) * scale;
  }

  static double _latToWorldY(double lat, double zoom) {
    final clampedLat = lat.clamp(-85.0511, 85.0511);
    final latRad = clampedLat * math.pi / 180.0;
    final scale = 256.0 * math.pow(2.0, zoom);
    final mercN = math.log(math.tan((math.pi / 4.0) + (latRad / 2.0)));
    return (0.5 - (mercN / (2.0 * math.pi))) * scale;
  }

  static double _worldXToLng(double worldX, double zoom) {
    final scale = 256.0 * math.pow(2.0, zoom);
    return ((worldX / scale) * 360.0) - 180.0;
  }

  static double _worldYToLat(double worldY, double zoom) {
    final scale = 256.0 * math.pow(2.0, zoom);
    final n = math.pi - (2.0 * math.pi * worldY / scale);
    return (180.0 / math.pi) * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  /// Menghitung center & zoom otomatis agar seluruh pin & rute jalan terlihat utuh di tengah peta
  (double, double, double) _resolveCamera(Size size) {
    if (_hasUserPanned || widget.interactive) {
      return (_viewLat, _viewLng, _zoom);
    }

    final List<(double, double)> allPts = [];
    for (final m in widget.markers) {
      allPts.add((m.latitude, m.longitude));
    }
    for (final r in widget.routePoints) {
      allPts.add((r.latitude, r.longitude));
    }

    if (allPts.length < 2) {
      if (allPts.length == 1) {
        return (allPts.first.$1, allPts.first.$2, widget.initialZoom.clamp(14.5, 16.0));
      }
      return (_viewLat, _viewLng, _zoom);
    }

    double minLat = allPts.first.$1;
    double maxLat = allPts.first.$1;
    double minLng = allPts.first.$2;
    double maxLng = allPts.first.$2;

    for (final p in allPts) {
      if (p.$1 < minLat) minLat = p.$1;
      if (p.$1 > maxLat) maxLat = p.$1;
      if (p.$2 < minLng) minLng = p.$2;
      if (p.$2 > maxLng) maxLng = p.$2;
    }

    final centerLat = (minLat + maxLat) / 2.0;
    final centerLng = (minLng + maxLng) / 2.0;

    final latSpan = (maxLat - minLat).abs();
    final lngSpan = (maxLng - minLng).abs();
    if (latSpan < 0.0008 && lngSpan < 0.0008) {
      return (centerLat, centerLng, 15.2);
    }

    // Cari level zoom terbaik dengan ruang padding 96px agar label pin tidak terpotong di tepi atas
    final usableW = math.max(120.0, size.width - 96.0);
    final usableH = math.max(90.0, size.height - 96.0);

    double bestZoom = 14.5;
    for (double z = 16.0; z >= 11.5; z -= 0.25) {
      final dx = (_lngToWorldX(maxLng, z) - _lngToWorldX(minLng, z)).abs();
      final dy = (_latToWorldY(minLat, z) - _latToWorldY(maxLat, z)).abs();
      if (dx <= usableW && dy <= usableH) {
        bestZoom = z;
        break;
      }
    }

    // Geser sedikit ke utara agar ruang callout label di atas pin tidak mentok batas atas
    final topPaddingLatOffset = (maxLat - minLat) * 0.08;
    return (centerLat + topPaddingLatOffset, centerLng, bestZoom.clamp(12.0, 15.8));
  }

  Offset _latLngToPixel(
    double lat,
    double lng,
    Size size,
    double camLat,
    double camLng,
    double camZoom,
  ) {
    final cx = _lngToWorldX(camLng, camZoom);
    final cy = _latToWorldY(camLat, camZoom);
    final px = _lngToWorldX(lng, camZoom);
    final py = _latToWorldY(lat, camZoom);
    return Offset(
      (size.width / 2.0) + (px - cx),
      (size.height / 2.0) + (py - cy),
    );
  }

  (double, double) _pixelToLatLng(
    Offset localPos,
    Size size,
    double camLat,
    double camLng,
    double camZoom,
  ) {
    final cx = _lngToWorldX(camLng, camZoom);
    final cy = _latToWorldY(camLat, camZoom);
    final wx = cx + (localPos.dx - (size.width / 2.0));
    final wy = cy + (localPos.dy - (size.height / 2.0));
    return (_worldYToLat(wy, camZoom), _worldXToLng(wx, camZoom));
  }

  void _zoomIn() {
    setState(() {
      _hasUserPanned = true;
      _zoom = (_zoom + 0.6).clamp(11.5, 17.5);
    });
  }

  void _zoomOut() {
    setState(() {
      _hasUserPanned = true;
      _zoom = (_zoom - 0.6).clamp(11.5, 17.5);
    });
  }

  void _recenter() {
    setState(() {
      _hasUserPanned = false;
      _viewLat = widget.centerLat;
      _viewLng = widget.centerLng;
      _zoom = widget.initialZoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasFooterBanner = widget.showCoordinateBanner &&
        (widget.bottomBannerTitle != null || widget.bottomBannerSubtitle != null);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── KANVAS PETA UTAMA (BEBAS DARI BANNER BESAR YANG MENUTUPI PETA) ──
            SizedBox(
              height: widget.height,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth.isFinite ? constraints.maxWidth : 360,
                    constraints.maxHeight.isFinite ? constraints.maxHeight : widget.height,
                  );
                  final (camLat, camLng, camZoom) = _resolveCamera(size);

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: widget.interactive
                        ? (details) {
                            setState(() {
                              _hasUserPanned = true;
                              final cx = _lngToWorldX(_viewLng, _zoom) - details.delta.dx;
                              final cy = _latToWorldY(_viewLat, _zoom) - details.delta.dy;
                              _viewLat = _worldYToLat(cy, _zoom).clamp(-8.45, -7.95);
                              _viewLng = _worldXToLng(cx, _zoom).clamp(113.30, 113.95);
                            });
                          }
                        : null,
                    onTapUp: (widget.interactive && widget.onTapLocation != null)
                        ? (details) {
                            final (lat, lng) = _pixelToLatLng(
                              details.localPosition,
                              size,
                              camLat,
                              camLng,
                              camZoom,
                            );
                            final clampedLat = lat.clamp(-8.45, -7.95);
                            final clampedLng = lng.clamp(113.30, 113.95);
                            setState(() {
                              _hasUserPanned = true;
                              _viewLat = clampedLat;
                              _viewLng = clampedLng;
                            });
                            widget.onTapLocation!(clampedLat, clampedLng);
                          }
                        : null,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // 1. Lapisan Dasar Geografis Jember (Fallback Offline / Test)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _JemberGeographicMapPainter(
                              camLat: camLat,
                              camLng: camLng,
                              camZoom: camZoom,
                            ),
                          ),
                        ),

                        // 2. Lapisan Tile Peta Asli OpenStreetMap (Web Mercator Presisi)
                        if (!_isTest)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: _buildOsmTileLayer(size, camLat, camLng, camZoom),
                            ),
                          ),

                        // 3. Lapisan Jalur Rute Jalan Raya (OSRM / Arteri Jember)
                        if (widget.routePoints.length >= 2)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (context, _) {
                                  return CustomPaint(
                                    painter: _JemberRoutePolylinePainter(
                                      routePoints: widget.routePoints,
                                      routeProgress: widget.routeProgress,
                                      camLat: camLat,
                                      camLng: camLng,
                                      camZoom: camZoom,
                                      pulseValue: _pulseCtrl.value,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                        // 4. Lapisan Pin Marker (Pasien, Apotek, Dokter RS, Kurir, Admin)
                        ...widget.markers.map(
                          (m) => _buildMarkerWidget(m, size, camLat, camLng, camZoom),
                        ),

                        // 5. Top-Left Badge Ringkas
                        if (widget.topBadgeText != null && widget.topBadgeText!.isNotEmpty)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.topBadgeText!,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // 6. Indikator Status Peta Terkunci vs Mode Geser Pilih Lokasi
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: widget.interactive
                                  ? _darkGreen.withValues(alpha: 0.92)
                                  : const Color(0xFF0F172A).withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.interactive
                                      ? Icons.open_with_rounded
                                      : Icons.lock_outline_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.interactive
                                      ? 'Geser / Ketuk Peta'
                                      : 'Lokasi Terkunci',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 7. Tombol Kontrol Zoom (+ / - / Recenter / GPS) HANYA saat mode interaktif
                        if (widget.showControls && widget.interactive)
                          Positioned(
                            right: 10,
                            bottom: 12,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.onRequestGps != null) ...[
                                  _buildMapControlBtn(
                                    icon: Icons.my_location_rounded,
                                    tooltip: 'Gunakan GPS Saya',
                                    onTap: widget.onRequestGps!,
                                    bgColor: _darkGreen,
                                    iconColor: Colors.white,
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                _buildMapControlBtn(
                                  icon: Icons.add_rounded,
                                  tooltip: 'Perbesar Peta',
                                  onTap: _zoomIn,
                                ),
                                const SizedBox(height: 5),
                                _buildMapControlBtn(
                                  icon: Icons.remove_rounded,
                                  tooltip: 'Perkecil Peta',
                                  onTap: _zoomOut,
                                ),
                                const SizedBox(height: 5),
                                _buildMapControlBtn(
                                  icon: Icons.center_focus_strong_rounded,
                                  tooltip: 'Pusatkan',
                                  onTap: _recenter,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── FOOTER INFORMASI LOKASI DI BAWAH KANVAS PETA (TIDAK MENUTUPI PETA) ──
            if (hasFooterBanner)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.place_rounded,
                        color: _darkGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.bottomBannerTitle ?? 'Kota Jember, Jawa Timur',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.2,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (widget.bottomBannerSubtitle != null &&
                              widget.bottomBannerSubtitle!.isNotEmpty)
                            Text(
                              widget.bottomBannerSubtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF475569),
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
      ),
    );
  }

  /// Render OpenStreetMap Slippy Tiles dengan penyelarasan piksel Web Mercator 100% akurat
  Widget _buildOsmTileLayer(
    Size size,
    double camLat,
    double camLng,
    double camZoom,
  ) {
    final int tileZ = camZoom.floor().clamp(11, 17);
    final double scaleFactor = math.pow(2.0, camZoom - tileZ).toDouble();
    final double renderedTileSize = 256.0 * scaleFactor;

    final double centerWorldXAtTileZ = _lngToWorldX(camLng, tileZ.toDouble());
    final double centerWorldYAtTileZ = _latToWorldY(camLat, tileZ.toDouble());

    final int centerTileX = (centerWorldXAtTileZ / 256.0).floor();
    final int centerTileY = (centerWorldYAtTileZ / 256.0).floor();

    final int cols = (size.width / renderedTileSize).ceil() + 1;
    final int rows = (size.height / renderedTileSize).ceil() + 1;

    final List<Widget> tiles = [];
    final int maxTileIndex = (1 << tileZ) - 1;

    for (int dx = -cols; dx <= cols; dx++) {
      for (int dy = -rows; dy <= rows; dy++) {
        final tx = (centerTileX + dx).clamp(0, maxTileIndex);
        final ty = (centerTileY + dy).clamp(0, maxTileIndex);

        final tileWorldLeft = tx * 256.0;
        final tileWorldTop = ty * 256.0;

        final screenLeft =
            (size.width / 2.0) + (tileWorldLeft - centerWorldXAtTileZ) * scaleFactor;
        final screenTop =
            (size.height / 2.0) + (tileWorldTop - centerWorldYAtTileZ) * scaleFactor;

        if (screenLeft + renderedTileSize < -50 ||
            screenLeft > size.width + 50 ||
            screenTop + renderedTileSize < -50 ||
            screenTop > size.height + 50) {
          continue;
        }

        final url = 'https://tile.openstreetmap.org/$tileZ/$tx/$ty.png';
        tiles.add(
          Positioned(
            left: screenLeft,
            top: screenTop,
            width: renderedTileSize + 0.8,
            height: renderedTileSize + 0.8,
            child: Image.network(
              url,
              fit: BoxFit.fill,
              headers: const {
                'User-Agent': 'GIAT-Healthcare-Jember-App/1.0',
              },
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        );
      }
    }

    return Stack(children: tiles);
  }

  Widget _buildMarkerWidget(
    GiatMapMarker marker,
    Size size,
    double camLat,
    double camLng,
    double camZoom,
  ) {
    final pos = _latLngToPixel(
      marker.latitude,
      marker.longitude,
      size,
      camLat,
      camLng,
      camZoom,
    );

    // Clamp agar marker tidak pernah keluar/terpotong di pinggir kanvas peta
    final safeDx = pos.dx.clamp(42.0, math.max(42.0, size.width - 42.0));
    final safeDy = pos.dy.clamp(48.0, math.max(48.0, size.height - 20.0));

    Color pinColor;
    IconData pinIcon;
    switch (marker.type) {
      case GiatMapMarkerType.pasien:
        pinColor = const Color(0xFF0284C7);
        pinIcon = Icons.home_rounded;
        break;
      case GiatMapMarkerType.apotek:
        pinColor = const Color(0xFF065A37);
        pinIcon = Icons.local_pharmacy_rounded;
        break;
      case GiatMapMarkerType.dokter:
        pinColor = const Color(0xFF7C3AED);
        pinIcon = Icons.local_hospital_rounded;
        break;
      case GiatMapMarkerType.kurir:
        pinColor = const Color(0xFFEA580C);
        pinIcon = Icons.delivery_dining_rounded;
        break;
      case GiatMapMarkerType.admin:
        pinColor = const Color(0xFF0F172A);
        pinIcon = Icons.verified_user_rounded;
        break;
    }

    return Positioned(
      left: safeDx - 65,
      top: safeDy - 56,
      width: 130,
      child: GestureDetector(
        onTap: marker.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label Callout di Atas Pin
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: marker.isSelected ? pinColor : Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: pinColor,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                marker.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: marker.isSelected ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Lingkaran Pin dengan Efek Pulse Halus
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                final scale = marker.isPulsing
                    ? 1.0 + (_pulseCtrl.value * 0.12)
                    : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: marker.isSelected ? 32 : 28,
                height: marker.isSelected ? 32 : 28,
                decoration: BoxDecoration(
                  color: pinColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: pinColor.withValues(alpha: 0.40),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  pinIcon,
                  size: marker.isSelected ? 16 : 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color bgColor = Colors.white,
    Color iconColor = const Color(0xFF0F172A),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER 1: LAPISAN GEOGRAFIS JEMBER (FALLBACK OFFLINE & TEST)
// ─────────────────────────────────────────────────────────────────────────────
class _JemberGeographicMapPainter extends CustomPainter {
  final double camLat;
  final double camLng;
  final double camZoom;

  _JemberGeographicMapPainter({
    required this.camLat,
    required this.camLng,
    required this.camZoom,
  });

  Offset _toPixel(double lat, double lng, Size size) {
    final cx = _GiatRealMapWidgetState._lngToWorldX(camLng, camZoom);
    final cy = _GiatRealMapWidgetState._latToWorldY(camLat, camZoom);
    final px = _GiatRealMapWidgetState._lngToWorldX(lng, camZoom);
    final py = _GiatRealMapWidgetState._latToWorldY(lat, camZoom);
    return Offset(
      (size.width / 2.0) + (px - cx),
      (size.height / 2.0) + (py - cy),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background daratan Kota Jember
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF1F5F0),
    );

    // Grid halus peta
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.7)
      ..strokeWidth = 1.0;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Sungai Bedadung Jember
    final riverPts = [
      _toPixel(-8.1480, 113.7250, size),
      _toPixel(-8.1580, 113.7110, size),
      _toPixel(-8.1670, 113.6990, size),
      _toPixel(-8.1770, 113.6860, size),
      _toPixel(-8.1900, 113.6680, size),
    ];
    final riverPath = Path()..moveTo(riverPts.first.dx, riverPts.first.dy);
    for (int i = 1; i < riverPts.length; i++) {
      riverPath.lineTo(riverPts[i].dx, riverPts[i].dy);
    }
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = const Color(0xFFBAE6FD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Koridor Jalan Utama Kota Jember
    final mainRoad = [
      _toPixel(-8.1880, 113.6650, size),
      _toPixel(-8.1835, 113.6745, size),
      _toPixel(-8.1747, 113.6882, size),
      _toPixel(-8.1705, 113.6980, size),
      _toPixel(-8.1689, 113.7022, size),
      _toPixel(-8.1605, 113.7080, size),
      _toPixel(-8.1518, 113.7153, size),
    ];
    final roadPath = Path()..moveTo(mainRoad.first.dx, mainRoad.first.dy);
    for (int i = 1; i < mainRoad.length; i++) {
      roadPath.lineTo(mainRoad[i].dx, mainRoad[i].dy);
    }
    canvas.drawPath(
      roadPath,
      Paint()
        ..color = const Color(0xFFFDE68A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _JemberGeographicMapPainter oldDelegate) {
    return oldDelegate.camLat != camLat ||
        oldDelegate.camLng != camLng ||
        oldDelegate.camZoom != camZoom;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTER 2: GARIS RUTE JALAN RAYA (POLYLINE) DI ATAS OPENSTREETMAP
// ─────────────────────────────────────────────────────────────────────────────
class _JemberRoutePolylinePainter extends CustomPainter {
  final List<JemberCoordinate> routePoints;
  final double routeProgress;
  final double camLat;
  final double camLng;
  final double camZoom;
  final double pulseValue;

  _JemberRoutePolylinePainter({
    required this.routePoints,
    required this.routeProgress,
    required this.camLat,
    required this.camLng,
    required this.camZoom,
    required this.pulseValue,
  });

  Offset _toPixel(double lat, double lng, Size size) {
    final cx = _GiatRealMapWidgetState._lngToWorldX(camLng, camZoom);
    final cy = _GiatRealMapWidgetState._latToWorldY(camLat, camZoom);
    final px = _GiatRealMapWidgetState._lngToWorldX(lng, camZoom);
    final py = _GiatRealMapWidgetState._latToWorldY(lat, camZoom);
    return Offset(
      (size.width / 2.0) + (px - cx),
      (size.height / 2.0) + (py - cy),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.length < 2) return;

    final pts = routePoints
        .map((c) => _toPixel(c.latitude, c.longitude, size))
        .toList();

    final fullPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      fullPath.lineTo(pts[i].dx, pts[i].dy);
    }

    // 1. Garis border putih pelindung agar rute kontras di atas jalan OpenStreetMap
    canvas.drawPath(
      fullPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 2. Garis dasar rute abu-hijau
    canvas.drawPath(
      fullPath,
      Paint()
        ..color = const Color(0xFF94A3B8).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 3. Garis aktif rute berwarna Hijau Emerald GIAT
    final activeCount = (pts.length * routeProgress.clamp(0.0, 1.0))
        .ceil()
        .clamp(2, pts.length);
    final activePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < activeCount; i++) {
      activePath.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      activePath,
      Paint()
        ..color = const Color(0xFF065A37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _JemberRoutePolylinePainter oldDelegate) {
    return oldDelegate.camLat != camLat ||
        oldDelegate.camLng != camLng ||
        oldDelegate.camZoom != camZoom ||
        oldDelegate.routeProgress != routeProgress ||
        oldDelegate.routePoints.length != routePoints.length;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL FULL-HEIGHT INTERAKTIF PEMILIHAN & PENGUNCIAN TITIK LOKASI (KOTA JEMBER)
// Hanya di dalam modal ini peta BISA DIGESER/DIKLIK untuk menentukan lokasi!
// ─────────────────────────────────────────────────────────────────────────────
Future<JemberCoordinate?> showJemberLocationPickerModal(
  BuildContext context, {
  String title = 'Tentukan Titik Lokasi di Peta Jember',
  String? initialAddress,
  double? initialLat,
  double? initialLng,
  String? role,
}) async {
  final locService = JemberLocationService.instance;
  JemberCoordinate currentCoord = locService.resolveAddressToJemberCoordinate(
    initialAddress,
    explicitLat: initialLat,
    explicitLng: initialLng,
  );

  final addressCtrl = TextEditingController(text: currentCoord.address);
  final searchCtrl = TextEditingController();
  bool isFetchingGps = false;
  bool isSearching = false;
  String? errorMessage;
  List<JemberCoordinate> searchResults = [];

  return showModalBottomSheet<JemberCoordinate>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> handleTurnOnGps() async {
            setModalState(() {
              isFetchingGps = true;
              errorMessage = null;
            });
            try {
              final gpsCoord = await locService.requestAndFetchRealGpsLocation(
                currentAddressHint: addressCtrl.text,
              );
              setModalState(() {
                currentCoord = gpsCoord;
                addressCtrl.text = gpsCoord.address;
                isFetchingGps = false;
                errorMessage = null;
              });
            } catch (e) {
              setModalState(() {
                isFetchingGps = false;
                errorMessage = e.toString().replaceAll('Exception: ', '');
              });
            }
          }

          Future<void> handleMapTap(double lat, double lng) async {
            setModalState(() => errorMessage = null);
            final pinCoord = await locService.setManualPinLocation(
              lat,
              lng,
              role: role,
            );
            setModalState(() {
              currentCoord = pinCoord;
              addressCtrl.text = pinCoord.address;
            });
          }

          Future<void> handleSearch(String query) async {
            if (query.trim().isEmpty) {
              setModalState(() => searchResults = []);
              return;
            }
            setModalState(() => isSearching = true);
            final res = await locService.searchPlacesInJember(query);
            setModalState(() {
              searchResults = res;
              isSearching = false;
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.90,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_location_alt_rounded,
                            color: Color(0xFF065A37),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Geser & ketuk peta di bawah ini untuk memilih titik lokasi, lalu kunci lokasi Anda.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Peringatan jika GPS HP masih mati
                    if (errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_disabled_rounded,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF991B1B),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Baris Pencarian Jalan / Kecamatan di Jember + Tombol GPS Asli
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: TextField(
                              controller: searchCtrl,
                              onSubmitted: handleSearch,
                              textInputAction: TextInputAction.search,
                              style: GoogleFonts.inter(fontSize: 12.5),
                              decoration: InputDecoration(
                                hintText: 'Cari jalan/kecamatan di Jember...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                ),
                                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                suffixIcon: isSearching
                                    ? const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                                        onPressed: () => handleSearch(searchCtrl.text),
                                      ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: isFetchingGps ? null : handleTurnOnGps,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF065A37),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: isFetchingGps
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.my_location_rounded, size: 16),
                            label: Text(
                              'GPS Saya',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Hasil Pencarian Lokasi Cepat Jember
                    if (searchResults.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 130),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, idx) {
                            final item = searchResults[idx];
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.place_rounded,
                                color: Color(0xFF065A37),
                                size: 18,
                              ),
                              title: Text(
                                item.areaName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                item.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 11),
                              ),
                              onTap: () {
                                locService.cacheCoordinateForAddress(item, role: role);
                                setModalState(() {
                                  currentCoord = item;
                                  addressCtrl.text = item.address;
                                  searchResults = [];
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // ── PETA INTERAKTIF BESAR (BISA DIGESER & DIKETUK) ──
                    GiatRealMapWidget(
                      centerLat: currentCoord.latitude,
                      centerLng: currentCoord.longitude,
                      initialZoom: 15.2,
                      height: 300,
                      interactive: true,
                      showControls: true,
                      topBadgeText: 'Ketuk / Geser Peta untuk Menentukan Titik',
                      bottomBannerTitle: currentCoord.areaName,
                      bottomBannerSubtitle:
                          'Koordinat: ${currentCoord.formattedLatLng}',
                      onTapLocation: handleMapTap,
                      onRequestGps: handleTurnOnGps,
                      markers: [
                        GiatMapMarker(
                          id: 'selected_pin',
                          title: 'Titik Lokasi Pilihan',
                          subtitle: currentCoord.address,
                          latitude: currentCoord.latitude,
                          longitude: currentCoord.longitude,
                          type: GiatMapMarkerType.pasien,
                          isSelected: true,
                          isPulsing: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Detail Alamat Lengkap (Dapat disesuaikan):',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addressCtrl,
                      maxLines: 2,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        hintText: 'Contoh: Jl. Kalimantan No. 37, Sumbersari, Jember',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF065A37),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final finalAddr = addressCtrl.text.trim().isNotEmpty
                              ? addressCtrl.text.trim()
                              : currentCoord.address;
                          final savedCoord = currentCoord.copyWith(
                            address: finalAddr,
                            isFromGps: true,
                          );
                          locService.cacheCoordinateForAddress(
                            savedCoord,
                            role: role,
                          );
                          Navigator.pop(ctx, savedCoord);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF044E2F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.lock_rounded, size: 18),
                        label: Text(
                          'Simpan & Kunci Titik Lokasi Ini',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
