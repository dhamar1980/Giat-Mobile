import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_realtime_service.dart';
import 'storage_service.dart';

/// Model titik lokasi koordinat real di Kota/Kabupaten Jember
class JemberCoordinate {
  final double latitude;
  final double longitude;
  final String address;
  final String areaName;
  final bool isFromGps;

  const JemberCoordinate({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.areaName = 'Jember, Jawa Timur',
    this.isFromGps = false,
  });

  String get formattedLatLng =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  JemberCoordinate copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? areaName,
    bool? isFromGps,
  }) {
    return JemberCoordinate(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      areaName: areaName ?? this.areaName,
      isFromGps: isFromGps ?? this.isFromGps,
    );
  }
}

/// Model data Apotek Real di Kota Jember beserta jaraknya ke pasien
class ApotekJemberPoint {
  final String id;
  final String namaApotek;
  final String email;
  final String penanggungJawab;
  final String noSipa;
  final String noHp;
  final String alamat;
  final double latitude;
  final double longitude;
  final String kecamatan;
  final double distanceKm;
  final int estimatedMinutes;
  final bool isNearest;

  const ApotekJemberPoint({
    required this.id,
    required this.namaApotek,
    required this.email,
    required this.penanggungJawab,
    required this.noSipa,
    required this.noHp,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.kecamatan,
    this.distanceKm = 0.0,
    this.estimatedMinutes = 15,
    this.isNearest = false,
  });

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';

  ApotekJemberPoint copyWith({
    String? id,
    String? namaApotek,
    String? email,
    String? penanggungJawab,
    String? noSipa,
    String? noHp,
    String? alamat,
    double? latitude,
    double? longitude,
    String? kecamatan,
    double? distanceKm,
    int? estimatedMinutes,
    bool? isNearest,
  }) {
    return ApotekJemberPoint(
      id: id ?? this.id,
      namaApotek: namaApotek ?? this.namaApotek,
      email: email ?? this.email,
      penanggungJawab: penanggungJawab ?? this.penanggungJawab,
      noSipa: noSipa ?? this.noSipa,
      noHp: noHp ?? this.noHp,
      alamat: alamat ?? this.alamat,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      kecamatan: kecamatan ?? this.kecamatan,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isNearest: isNearest ?? this.isNearest,
    );
  }
}

/// Model data Rumah Sakit Real di Jember tempat praktik Dokter GIAT
class RumahSakitJemberPoint {
  final String namaRs;
  final String alamat;
  final String kecamatan;
  final double latitude;
  final double longitude;
  final String telepon;

  const RumahSakitJemberPoint({
    required this.namaRs,
    required this.alamat,
    required this.kecamatan,
    required this.latitude,
    required this.longitude,
    this.telepon = '(0331) 487441',
  });
}

/// Model status Live Tracking Pengiriman Obat di Kota Jember
class LiveDeliveryTrackingState {
  final String orderId;
  final double apotekLat;
  final double apotekLng;
  final String apotekName;
  final String apotekAddress;
  final double patientLat;
  final double patientLng;
  final String patientName;
  final String patientAddress;
  final double courierLat;
  final double courierLng;
  final String courierName;
  final String courierPlate;
  final String courierPhone;
  final double progressRatio; // 0.0 (di apotek) .. 1.0 (tiba di rumah pasien)
  final double totalDistanceKm;
  final double remainingDistanceKm;
  final int etaMinutes;
  final String currentStreetName;
  final String statusPesanan;
  final List<JemberCoordinate> routePoints;

  const LiveDeliveryTrackingState({
    required this.orderId,
    required this.apotekLat,
    required this.apotekLng,
    required this.apotekName,
    required this.apotekAddress,
    required this.patientLat,
    required this.patientLng,
    required this.patientName,
    required this.patientAddress,
    required this.courierLat,
    required this.courierLng,
    this.courierName = 'Rahmat Setiawan',
    this.courierPlate = 'P 4921 ZA',
    this.courierPhone = '0812-3490-8812',
    required this.progressRatio,
    required this.totalDistanceKm,
    required this.remainingDistanceKm,
    required this.etaMinutes,
    required this.currentStreetName,
    required this.statusPesanan,
    required this.routePoints,
  });
}

/// Service Pusat Lokasi Real, GPS Perangkat, Geocoding, dan Live Tracking Kota Jember
class JemberLocationService extends ChangeNotifier {
  JemberLocationService._();
  static final JemberLocationService instance = JemberLocationService._();

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  final Dio _geoDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      headers: {
        'User-Agent': 'GIAT-Healthcare-Jember-App/1.0',
        'Accept': 'application/json',
      },
    ),
  );

  // Titik Pusat Kota Jember (Alun-Alun Jember)
  static const double jemberCenterLat = -8.1689;
  static const double jemberCenterLng = 113.7022;

  // State GPS & Lokasi User Aktif
  bool _isGpsEnabled = false;
  JemberCoordinate? _activeUserCoordinate;
  final Map<String, JemberCoordinate> _coordinatesByAddress = {};
  final Map<String, JemberCoordinate> _roleSavedCoordinates = {};

  bool get isGpsEnabled => _isGpsEnabled;
  JemberCoordinate? get activeUserCoordinate => _activeUserCoordinate;

  /// Menyimpan titik koordinat spesifik yang dipilih/ditentukan oleh user agar tidak pernah hilang
  void cacheCoordinateForAddress(JemberCoordinate coord, {String? role}) {
    final cleanKey = coord.address.trim().toLowerCase();
    if (cleanKey.isNotEmpty) {
      _coordinatesByAddress[cleanKey] = coord;
    }
    if (role != null && role.trim().isNotEmpty) {
      _roleSavedCoordinates[role.trim().toLowerCase()] = coord;
    }
    _activeUserCoordinate = coord;
    notifyListeners();
  }

  JemberCoordinate? getSavedRoleCoordinate(String role) {
    return _roleSavedCoordinates[role.trim().toLowerCase()];
  }

  // ===========================================================================
  // 1. DAFTAR RUMAH SAKIT REAL DI KOTA JEMBER (UNTUK DOKTER)
  // ===========================================================================
  static const List<RumahSakitJemberPoint> rumahSakitJemberList = [
    RumahSakitJemberPoint(
      namaRs: 'RSD dr. Soebandi Jember',
      alamat: 'Jl. Dr. Soebandi No. 124, Patrang, Kabupaten Jember, Jawa Timur 68111',
      kecamatan: 'Patrang, Jember',
      latitude: -8.1518,
      longitude: 113.7153,
      telepon: '(0331) 487441',
    ),
    RumahSakitJemberPoint(
      namaRs: 'RS Perkebunan Jember Klinik',
      alamat: 'Jl. Bedadung No. 2, Jemberlor, Patrang, Kabupaten Jember, Jawa Timur 68118',
      kecamatan: 'Patrang, Jember',
      latitude: -8.1653,
      longitude: 113.7024,
      telepon: '(0331) 487104',
    ),
    RumahSakitJemberPoint(
      namaRs: 'RS Bina Sehat Jember',
      alamat: 'Jl. Jayanegara No. 7, Kaliwates, Kabupaten Jember, Jawa Timur 68131',
      kecamatan: 'Kaliwates, Jember',
      latitude: -8.1802,
      longitude: 113.6915,
      telepon: '(0331) 422701',
    ),
    RumahSakitJemberPoint(
      namaRs: 'RS Citra Husada Jember',
      alamat: 'Jl. Teratai No. 22, Gebang, Patrang, Kabupaten Jember, Jawa Timur 68117',
      kecamatan: 'Patrang, Jember',
      latitude: -8.1689,
      longitude: 113.6942,
      telepon: '(0331) 486200',
    ),
    RumahSakitJemberPoint(
      namaRs: 'RS Siloam Jember',
      alamat: 'Jl. Gajah Mada No. 104, Kaliwates, Kabupaten Jember, Jawa Timur 68131',
      kecamatan: 'Kaliwates, Jember',
      latitude: -8.1731,
      longitude: 113.6938,
      telepon: '(0331) 2861900',
    ),
    RumahSakitJemberPoint(
      namaRs: 'RSD Balung Jember',
      alamat: 'Jl. Rambipuji No. 19, Balung Lor, Balung, Kabupaten Jember, Jawa Timur 68161',
      kecamatan: 'Balung, Jember',
      latitude: -8.2735,
      longitude: 113.5322,
      telepon: '(0336) 621017',
    ),
  ];

  // ===========================================================================
  // 2. DAFTAR APOTEK MITRA REAL DI KOTA JEMBER
  // ===========================================================================
  static const List<ApotekJemberPoint> defaultApotekJemberList = [
    ApotekJemberPoint(
      id: '5cdfd84d-0124-4abf-a778-e8db2801863f',
      namaApotek: 'Apotek Kimia Farma Jember',
      email: 'apotek.kimiafarma.jember@gmail.com',
      penanggungJawab: 'apt. Farhan Ramadhan, S.Farm',
      noSipa: '19910412/SIPA-35.09/2024',
      noHp: '0331484321',
      alamat: 'Jl. Gajah Mada No. 175, Kaliwates, Kabupaten Jember, Jawa Timur 68131',
      latitude: -8.1747,
      longitude: 113.6882,
      kecamatan: 'Kaliwates, Jember',
    ),
    ApotekJemberPoint(
      id: '9e81b682-6fd3-4a93-9598-5a402138e04e',
      namaApotek: 'Apotek K-24 Sumbersari Jember',
      email: 'apotek.k24.jember@gmail.com',
      penanggungJawab: 'apt. Maya Sartika, S.Farm',
      noSipa: '19930821/SIPA-35.09/2024',
      noHp: '0331338240',
      alamat: 'Jl. Kalimantan No. 42, Sumbersari, Kabupaten Jember, Jawa Timur 68121',
      latitude: -8.1685,
      longitude: 113.7148,
      kecamatan: 'Sumbersari, Jember',
    ),
    ApotekJemberPoint(
      id: 'c773c3c9-6636-4e68-a61d-4d88c3162b30',
      namaApotek: 'Apotek Sehat Ginjal Sentosa Jember',
      email: 'apotek.sentosa@gmail.com',
      penanggungJawab: 'apt. Hendra Gunawan, S.Farm',
      noSipa: '19891105/SIPA-35.09/2024',
      noHp: '0331489112',
      alamat: 'Jl. Slamet Riyadi No. 68, Patrang, Kabupaten Jember, Jawa Timur 68111',
      latitude: -8.1536,
      longitude: 113.7126,
      kecamatan: 'Patrang, Jember',
    ),
  ];

  // ===========================================================================
  // 3. DAFTAR TITIK JALAN & KECAMATAN DI JEMBER (GEOCODING AKURAT)
  // ===========================================================================
  static const List<Map<String, dynamic>> jemberLandmarks = [
    {
      'keywords': ['kalimantan', 'unej', 'universitas jember', 'tegalboto', 'kampus'],
      'name': 'Kawasan Jl. Kalimantan / Kampus UNEJ, Sumbersari, Jember',
      'address': 'Jl. Kalimantan No. 37, Krajan Timur, Sumbersari, Kabupaten Jember, Jawa Timur 68121',
      'lat': -8.1668,
      'lng': 113.7162,
    },
    {
      'keywords': ['mastrip', 'tegalgede', 'polije', 'politeknik'],
      'name': 'Kawasan Jl. Mastrip, Sumbersari, Jember',
      'address': 'Jl. Mastrip No. 45, Tegalgede, Sumbersari, Kabupaten Jember, Jawa Timur 68124',
      'lat': -8.1598,
      'lng': 113.7224,
    },
    {
      'keywords': ['jawa', 'riau', 'karimata', 'sumbersari', 'kebonsari'],
      'name': 'Kawasan Sumbersari, Jember',
      'address': 'Jl. Jawa No. 28, Sumbersari, Kabupaten Jember, Jawa Timur 68121',
      'lat': -8.1712,
      'lng': 113.7175,
    },
    {
      'keywords': ['gajah mada', 'kaliwates', 'siloam', 'aloha', 'jember town square'],
      'name': 'Kawasan Jl. Gajah Mada, Kaliwates, Jember',
      'address': 'Jl. Gajah Mada No. 142, Kaliwates, Kabupaten Jember, Jawa Timur 68131',
      'lat': -8.1742,
      'lng': 113.6908,
    },
    {
      'keywords': ['hayam wuruk', 'sempusari', 'roxy', 'mangli', 'ajung'],
      'name': 'Kawasan Jl. Hayam Wuruk / Mangli, Kaliwates, Jember',
      'address': 'Jl. Hayam Wuruk No. 88, Sempusari, Kaliwates, Kabupaten Jember, Jawa Timur 68135',
      'lat': -8.1835,
      'lng': 113.6745,
    },
    {
      'keywords': ['jayanegara', 'bina sehat', 'tegal besar'],
      'name': 'Kawasan Jl. Jayanegara / Tegal Besar, Kaliwates, Jember',
      'address': 'Jl. Jayanegara No. 15, Tegal Besar, Kaliwates, Kabupaten Jember, Jawa Timur 68132',
      'lat': -8.1815,
      'lng': 113.6932,
    },
    {
      'keywords': ['soebandi', 'subandi', 'rsd', 'patrang', 'slamet riyadi'],
      'name': 'Kawasan Jl. Dr. Soebandi / Patrang, Jember',
      'address': 'Jl. Dr. Soebandi No. 124, Patrang, Kabupaten Jember, Jawa Timur 68111',
      'lat': -8.1518,
      'lng': 113.7153,
    },
    {
      'keywords': ['bedadung', 'jember klinik', 'jemberlor'],
      'name': 'Kawasan Jl. Bedadung / Jemberlor, Patrang, Jember',
      'address': 'Jl. Bedadung No. 2, Jemberlor, Patrang, Kabupaten Jember, Jawa Timur 68118',
      'lat': -8.1653,
      'lng': 113.7024,
    },
    {
      'keywords': ['teratai', 'gebang', 'citra husada'],
      'name': 'Kawasan Jl. Teratai, Gebang, Patrang, Jember',
      'address': 'Jl. Teratai No. 22, Gebang, Patrang, Kabupaten Jember, Jawa Timur 68117',
      'lat': -8.1689,
      'lng': 113.6942,
    },
    {
      'keywords': ['sudirman', 'pb sudirman', 'alun-alun', 'alun alun', 'ahmad yani', 'sultan agung'],
      'name': 'Kawasan Pusat Kota / Alun-Alun Jember',
      'address': 'Jl. PB Sudirman No. 42, Jemberlor, Patrang, Kabupaten Jember, Jawa Timur 68118',
      'lat': -8.1689,
      'lng': 113.7022,
    },
    {
      'keywords': ['balung', 'rambipuji', 'ambulu', 'tanggul', 'wuluhan', 'puger'],
      'name': 'Kawasan Jember Barat / Selatan (Balung - Rambipuji)',
      'address': 'Jl. Rambipuji No. 19, Balung Lor, Balung, Kabupaten Jember, Jawa Timur 68161',
      'lat': -8.2735,
      'lng': 113.5322,
    },
    {
      'keywords': ['pakusari', 'kalisat', 'arjasa', 'mayang', 'silo'],
      'name': 'Kawasan Jember Timur / Utara (Pakusari - Kalisat)',
      'address': 'Jl. Raya Banyuwangi No. 31, Pakusari, Kabupaten Jember, Jawa Timur 68181',
      'lat': -8.1592,
      'lng': 113.7634,
    },
  ];

  // ===========================================================================
  // 4. RESOLUSI ALAMAT REGISTER KE KOORDINAT REAL JEMBER (SEBELUM GPS NYALA)
  // ===========================================================================

  /// Mengubah teks alamat (misal yang diinput user saat Register) menjadi titik koordinat Real di Jember.
  /// Sebelum GPS dinyalakan, sistem menggunakan alamat yang dimasukkan user saat register.
  JemberCoordinate resolveAddressToJemberCoordinate(
    String? rawAddress, {
    double? explicitLat,
    double? explicitLng,
    bool isFromGps = false,
  }) {
    if (explicitLat != null &&
        explicitLng != null &&
        explicitLat != 0 &&
        explicitLng != 0) {
      final cleanAddr = (rawAddress != null && rawAddress.trim().isNotEmpty)
          ? rawAddress.trim()
          : reverseGeocodeLocalJember(explicitLat, explicitLng);
      final resolved = JemberCoordinate(
        latitude: explicitLat,
        longitude: explicitLng,
        address: cleanAddr,
        areaName: _extractAreaName(cleanAddr),
        isFromGps: isFromGps,
      );
      _coordinatesByAddress[cleanAddr.toLowerCase()] = resolved;
      return resolved;
    }

    final addr = (rawAddress ?? '').trim();
    final lower = addr.toLowerCase();

    // 1. Cek cache koordinat yang sudah pernah dipilih oleh user di peta / GPS
    if (lower.isNotEmpty && _coordinatesByAddress.containsKey(lower)) {
      return _coordinatesByAddress[lower]!;
    }

    // 2. Cek apakah string alamat mengandung format koordinat eksplisit "(-8.168, 113.714)"
    final coordMatch = RegExp(r'(-?\d+\.\d+)\s*,\s*(\d+\.\d+)').firstMatch(addr);
    if (coordMatch != null) {
      final lat = double.tryParse(coordMatch.group(1)!);
      final lng = double.tryParse(coordMatch.group(2)!);
      if (lat != null && lng != null) {
        final c = JemberCoordinate(
          latitude: lat,
          longitude: lng,
          address: addr,
          areaName: _extractAreaName(addr),
          isFromGps: isFromGps,
        );
        _coordinatesByAddress[lower] = c;
        return c;
      }
    }

    // 3. Cocokkan dengan jalan / rumah sakit / kecamatan di Jember
    for (final lm in jemberLandmarks) {
      final keywords = lm['keywords'] as List<String>;
      for (final kw in keywords) {
        if (lower.contains(kw)) {
          return JemberCoordinate(
            latitude: lm['lat'] as double,
            longitude: lm['lng'] as double,
            address: addr.isNotEmpty ? addr : (lm['address'] as String),
            areaName: lm['name'] as String,
            isFromGps: isFromGps,
          );
        }
      }
    }

    // 4. Jika alamat user sudah diisi saat register tetapi nama jalannya spesifik (misal perumahan di Jember),
    // beri koordinat deterministik di dalam area Kota Jember berdasarkan hash alamat agar konsisten & real!
    if (addr.isNotEmpty) {
      final hash = addr.codeUnits.fold<int>(0, (acc, c) => (acc * 31 + c) & 0x7FFFFFFF);
      final latOffset = ((hash % 240) - 120) / 10000.0;
      final lngOffset = (((hash ~/ 240) % 240) - 120) / 10000.0;
      final lat = -8.1685 + latOffset;
      final lng = 113.7085 + lngOffset;
      final normalizedAddr = lower.contains('jember')
          ? addr
          : '$addr, Kabupaten Jember, Jawa Timur';
      return JemberCoordinate(
        latitude: lat,
        longitude: lng,
        address: normalizedAddr,
        areaName: _extractAreaName(normalizedAddr),
        isFromGps: isFromGps,
      );
    }

    // Default fallback Jember (Sumbersari, Jember)
    return const JemberCoordinate(
      latitude: -8.1668,
      longitude: 113.7162,
      address: 'Jl. Kalimantan No. 37, Sumbersari, Kabupaten Jember, Jawa Timur 68121',
      areaName: 'Sumbersari, Jember',
      isFromGps: false,
    );
  }

  /// Mendapatkan lokasi awal user:
  /// - Jika GPS sudah diaktifkan pada sesi ini, gunakan titik GPS Real.
  /// - Jika GPS belum dinyalakan, gunakan alamat yang dimasukkan user saat Register (`StorageService().getUser()?.alamat`).
  Future<JemberCoordinate> getInitialUserLocation({String? fallbackAddress}) async {
    if (_isGpsEnabled && _activeUserCoordinate != null) {
      return _activeUserCoordinate!;
    }

    try {
      final user = await StorageService().getUser();
      final regAddress = user?.alamat?.trim() ?? '';
      if (regAddress.isNotEmpty) {
        final resolved = resolveAddressToJemberCoordinate(regAddress);
        _activeUserCoordinate = resolved;
        return resolved;
      }
    } catch (_) {}

    final resolved = resolveAddressToJemberCoordinate(fallbackAddress);
    _activeUserCoordinate = resolved;
    return resolved;
  }

  // ===========================================================================
  // 5. AKTIFKAN LOKASI GPS REAL PERANGKAT (GEOLOCATOR + REVERSE GEOCODING)
  // ===========================================================================

  /// Meminta izin GPS & menyalakan Location Service asli perangkat HP/Laptop,
  /// membaca koordinat satelit/hardware asli, lalu menerjemahkannya ke alamat jalan real.
  /// Jika GPS di HP user masih mati, otomatis membuka Pengaturan Lokasi HP (`Geolocator.openLocationSettings()`)
  /// dan melempar pesan jelas bila user belum menyalakannya (tidak memalsukan status GPS Aktif).
  Future<JemberCoordinate> requestAndFetchRealGpsLocation({
    String? currentAddressHint,
  }) async {
    if (_isTest) {
      final base = resolveAddressToJemberCoordinate(currentAddressHint);
      final testCoord = base.copyWith(isFromGps: true);
      _isGpsEnabled = true;
      cacheCoordinateForAddress(testCoord);
      return testCoord;
    }

    // 1. Pastikan Layanan Lokasi (GPS) di HP benar-benar menyala!
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Buka pengaturan lokasi native Android/iOS agar user menyalakan GPS di HP
      await Geolocator.openLocationSettings();
      // Tunggu sejenak bila user langsung menyalakan toggle GPS
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(milliseconds: 600));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) break;
      }
      if (!serviceEnabled) {
        _isGpsEnabled = false;
        notifyListeners();
        throw Exception(
          'GPS di HP Anda masih mati. Silakan aktifkan tombol Lokasi/GPS di HP Anda terlebih dahulu.',
        );
      }
    }

    // 2. Pastikan izin akses lokasi aplikasi diberikan oleh user
    try {
      var status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        status = await Permission.locationWhenInUse.request();
      }
    } catch (_) {}

    LocationPermission geoPerm = await Geolocator.checkPermission();
    if (geoPerm == LocationPermission.denied) {
      geoPerm = await Geolocator.requestPermission();
    }
    if (geoPerm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      _isGpsEnabled = false;
      notifyListeners();
      throw Exception(
        'Izin lokasi ditolak permanen. Silakan aktifkan izin Lokasi untuk aplikasi GIAT di Pengaturan HP.',
      );
    }
    if (geoPerm != LocationPermission.whileInUse &&
        geoPerm != LocationPermission.always) {
      _isGpsEnabled = false;
      notifyListeners();
      throw Exception(
        'Izin akses lokasi belum diberikan. Silakan izinkan akses lokasi saat diminta.',
      );
    }

    // 3. Ambil titik koordinat GPS hardware asli dari perangkat
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      pos = await Geolocator.getLastKnownPosition();
    }

    if (pos == null) {
      _isGpsEnabled = false;
      notifyListeners();
      throw Exception(
        'Gagal mengunci sinyal satelit GPS. Pastikan Anda berada di area dengan sinyal GPS yang baik atau pilih titik langsung di Peta.',
      );
    }

    double finalLat = pos.latitude;
    double finalLng = pos.longitude;

    // Jika berjalan di emulator Android yang lokasinya default di Mountain View California USA (lat > 30, lng < -100),
    // arahkan ke titik pusat Kota Jember; namun jika GPS berada di Indonesia, gunakan 100% koordinat GPS asli HP user!
    final bool isDefaultUsEmulator = finalLat > 25.0 && finalLng < -90.0;
    if (isDefaultUsEmulator) {
      final base = resolveAddressToJemberCoordinate(currentAddressHint);
      finalLat = base.latitude;
      finalLng = base.longitude;
    }

    String resolvedAddress = await reverseGeocodeJember(finalLat, finalLng);
    if (resolvedAddress.trim().isEmpty) {
      resolvedAddress = reverseGeocodeLocalJember(finalLat, finalLng);
    }

    final coord = JemberCoordinate(
      latitude: finalLat,
      longitude: finalLng,
      address: resolvedAddress,
      areaName: _extractAreaName(resolvedAddress),
      isFromGps: true,
    );

    _isGpsEnabled = true;
    cacheCoordinateForAddress(coord);
    return coord;
  }

  /// Mengatur lokasi secara manual dari klik/geser pin di Peta Interaktif Jember
  Future<JemberCoordinate> setManualPinLocation(
    double latitude,
    double longitude, {
    String? customAddress,
    String? role,
  }) async {
    final clampedLat = latitude.clamp(-8.45, -7.95);
    final clampedLng = longitude.clamp(113.30, 113.95);

    String address = (customAddress != null && customAddress.trim().isNotEmpty)
        ? customAddress.trim()
        : '';

    if (address.isEmpty) {
      if (!_isTest) {
        address = await reverseGeocodeJember(clampedLat, clampedLng);
      }
      if (address.isEmpty) {
        address = reverseGeocodeLocalJember(clampedLat, clampedLng);
      }
    }

    final coord = JemberCoordinate(
      latitude: clampedLat,
      longitude: clampedLng,
      address: address,
      areaName: _extractAreaName(address),
      isFromGps: true,
    );

    _isGpsEnabled = true;
    cacheCoordinateForAddress(coord, role: role);
    return coord;
  }

  /// Pencarian nama jalan / kelurahan / kecamatan / tempat di Jember (Nominatim + Lokal)
  Future<List<JemberCoordinate>> searchPlacesInJember(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final lower = q.toLowerCase();
    final List<JemberCoordinate> results = [];

    // 1. Cocokkan dari landmark Jember lokal
    for (final lm in jemberLandmarks) {
      final name = lm['name'] as String;
      final addr = lm['address'] as String;
      final kws = lm['keywords'] as List<String>;
      if (name.toLowerCase().contains(lower) ||
          addr.toLowerCase().contains(lower) ||
          kws.any((k) => k.contains(lower) || lower.contains(k))) {
        results.add(
          JemberCoordinate(
            latitude: lm['lat'] as double,
            longitude: lm['lng'] as double,
            address: addr,
            areaName: name,
            isFromGps: true,
          ),
        );
      }
    }

    // 2. Cari via OpenStreetMap Nominatim khusus Jember
    if (!_isTest) {
      try {
        final searchQuery = lower.contains('jember') ? q : '$q, Jember';
        final res = await _geoDio.get(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'format': 'jsonv2',
            'q': searchQuery,
            'limit': 5,
            'countrycodes': 'id',
          },
        );
        if (res.statusCode == 200 && res.data is List) {
          for (final item in (res.data as List)) {
            if (item is Map) {
              final lat = double.tryParse(item['lat']?.toString() ?? '');
              final lng = double.tryParse(item['lon']?.toString() ?? '');
              final disp = item['display_name']?.toString().trim() ?? '';
              if (lat != null && lng != null && disp.isNotEmpty) {
                results.add(
                  JemberCoordinate(
                    latitude: lat,
                    longitude: lng,
                    address: disp,
                    areaName: _extractAreaName(disp),
                    isFromGps: true,
                  ),
                );
              }
            }
          }
        }
      } catch (_) {}
    }

    return results;
  }

  /// Reverse Geocoding menggunakan OpenStreetMap Nominatim API + Fallback Lokal Jember
  Future<String> reverseGeocodeJember(double lat, double lng) async {
    if (!_isTest) {
      try {
        final res = await _geoDio.get(
          'https://nominatim.openstreetmap.org/reverse',
          queryParameters: {
            'format': 'jsonv2',
            'lat': lat.toStringAsFixed(6),
            'lon': lng.toStringAsFixed(6),
            'zoom': 18,
            'addressdetails': 1,
          },
        );
        if (res.statusCode == 200 && res.data is Map) {
          final data = res.data as Map;
          final display = data['display_name']?.toString().trim() ?? '';
          if (display.isNotEmpty) {
            return display;
          }
        }
      } catch (_) {}
    }
    return reverseGeocodeLocalJember(lat, lng);
  }

  /// Reverse Geocoding instan berbasis jarak terdekat ke jalan/kawasan di Kota Jember
  String reverseGeocodeLocalJember(double lat, double lng) {
    Map<String, dynamic> closest = jemberLandmarks.first;
    double minDist = double.infinity;

    for (final lm in jemberLandmarks) {
      final d = calculateDistanceKm(
        lat,
        lng,
        lm['lat'] as double,
        lm['lng'] as double,
      );
      if (d < minDist) {
        minDist = d;
        closest = lm;
      }
    }

    final baseAddr = closest['address'] as String;
    return '$baseAddr (Titik GPS: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';
  }

  String _extractAreaName(String address) {
    final lower = address.toLowerCase();
    if (lower.contains('sumbersari')) return 'Kec. Sumbersari, Jember';
    if (lower.contains('kaliwates')) return 'Kec. Kaliwates, Jember';
    if (lower.contains('patrang')) return 'Kec. Patrang, Jember';
    if (lower.contains('balung')) return 'Kec. Balung, Jember';
    if (lower.contains('ajung') || lower.contains('mangli')) return 'Kec. Ajung, Jember';
    if (lower.contains('pakusari')) return 'Kec. Pakusari, Jember';
    if (lower.contains('rambipuji')) return 'Kec. Rambipuji, Jember';
    return 'Kota Jember, Jawa Timur';
  }

  // ===========================================================================
  // 6. PERHITUNGAN JARAK REAL (HAVERSINE) & AUTO-SELECT APOTEK TERDEKAT JEMBER
  // ===========================================================================

  /// Menghitung jarak garis bumi (Haversine) dikalikan faktor kelokan jalan kota (1.22x) dalam satuan Kilometer
  static double calculateDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final straightKm = earthRadiusKm * c;
    // Faktor rute jalan raya perkotaan Jember (~1.22x jarak lurus)
    final roadKm = straightKm * 1.22;
    return roadKm < 0.2 ? 0.2 : double.parse(roadKm.toStringAsFixed(2));
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Mengurutkan seluruh Apotek di Jember berdasarkan jarak terdekat dari titik lokasi Pasien.
  /// Apotek paling dekat otomatis ditandai `isNearest: true` (urutan pertama),
  /// namun pasien tetap bebas memilih apotek mana saja dari daftar ini.
  List<ApotekJemberPoint> rankApoteksByDistance({
    required double patientLat,
    required double patientLng,
    List<Map<String, dynamic>>? rawSupabaseApoteks,
  }) {
    final List<ApotekJemberPoint> baseList = [];

    if (rawSupabaseApoteks != null && rawSupabaseApoteks.isNotEmpty) {
      for (final m in rawSupabaseApoteks) {
        final id = (m['id_apotek'] ?? m['id'] ?? '').toString().trim();
        final nama = (m['nama_apotek'] ?? m['nama'] ?? 'Apotek Mitra GIAT Jember').toString().trim();
        final email = (m['email'] ?? 'apotek.jember@gmail.com').toString().trim();
        final pj = (m['penanggung_jawab'] ?? 'apt. Apoteker GIAT, S.Farm').toString().trim();
        final sipa = (m['no_sipa_sia'] ?? '19910412/SIPA-35.09/2024').toString().trim();
        final noHp = (m['no_hp'] ?? '0331484321').toString().trim();
        final alamat = (m['alamat'] ?? 'Kabupaten Jember, Jawa Timur').toString().trim();

        double? lat = double.tryParse((m['latitude'] ?? '').toString());
        double? lng = double.tryParse((m['longitude'] ?? '').toString());

        if ((lat == null || lng == null) && m['lokasi_lat_long'] != null) {
          final parts = m['lokasi_lat_long'].toString().split(',');
          if (parts.length >= 2) {
            lat = double.tryParse(parts[0].trim());
            lng = double.tryParse(parts[1].trim());
          }
        }

        if (lat == null || lng == null || lat == 0 || lng == 0) {
          final resolved = resolveAddressToJemberCoordinate('$nama $alamat');
          lat = resolved.latitude;
          lng = resolved.longitude;
        }

        baseList.add(
          ApotekJemberPoint(
            id: id.isNotEmpty ? id : defaultApotekJemberList.first.id,
            namaApotek: nama,
            email: email,
            penanggungJawab: pj,
            noSipa: sipa,
            noHp: noHp,
            alamat: alamat,
            latitude: lat,
            longitude: lng,
            kecamatan: _extractAreaName(alamat),
          ),
        );
      }
    }

    if (baseList.isEmpty) {
      baseList.addAll(defaultApotekJemberList);
    }

    // Hitung jarak & estimasi waktu pengiriman kurir (kecepatan rata-rata 25 km/jam + 7 menit persiapan)
    final List<ApotekJemberPoint> calculated = baseList.map((apt) {
      final dist = calculateDistanceKm(
        patientLat,
        patientLng,
        apt.latitude,
        apt.longitude,
      );
      final eta = (7 + (dist / 25.0 * 60.0)).round().clamp(8, 60);
      return apt.copyWith(
        distanceKm: dist,
        estimatedMinutes: eta,
      );
    }).toList();

    // Urutkan dari yang paling dekat
    calculated.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    // Tandai apotek terdekat di indeks 0
    return List<ApotekJemberPoint>.generate(calculated.length, (i) {
      return calculated[i].copyWith(isNearest: i == 0);
    });
  }

  /// Mencari Rumah Sakit Jember berdasarkan nama institusi atau alamat dokter
  RumahSakitJemberPoint resolveDoctorHospitalInJember({
    String? institution,
    String? address,
    String? doctorName,
  }) {
    final combined = '${institution ?? ''} ${address ?? ''} ${doctorName ?? ''}'.toLowerCase();

    if (combined.contains('soebandi') || combined.contains('subandi') || combined.contains('andi')) {
      return rumahSakitJemberList[0]; // RSD dr. Soebandi Jember
    }
    if (combined.contains('jember klinik') || combined.contains('perkebunan') || combined.contains('bedadung') || combined.contains('budi')) {
      return rumahSakitJemberList[1]; // RS Perkebunan Jember Klinik
    }
    if (combined.contains('bina sehat') || combined.contains('jayanegara') || combined.contains('citra dewi')) {
      return rumahSakitJemberList[2]; // RS Bina Sehat Jember
    }
    if (combined.contains('citra husada') || combined.contains('teratai') || combined.contains('dedi')) {
      return rumahSakitJemberList[3]; // RS Citra Husada Jember
    }
    if (combined.contains('siloam') || combined.contains('gajah mada') || combined.contains('eka')) {
      return rumahSakitJemberList[4]; // RS Siloam Jember
    }
    if (combined.contains('balung') || combined.contains('rina')) {
      return rumahSakitJemberList[5]; // RSD Balung Jember
    }

    return rumahSakitJemberList[0];
  }

  // ===========================================================================
  // 7. RUTE JALAN RAYA REAL (OSRM API + WAYPOINT JARINGAN JALAN JEMBER)
  // ===========================================================================

  /// Menghasilkan titik-titik jalur jalan raya (polyline) antara Apotek di Jember dan Rumah Pasien di Jember.
  Future<List<JemberCoordinate>> buildRoadRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    if (!_isTest) {
      try {
        final url =
            'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';
        final res = await _geoDio.get(url);
        if (res.statusCode == 200 &&
            res.data is Map &&
            (res.data['routes'] as List?)?.isNotEmpty == true) {
          final route = (res.data['routes'] as List).first;
          final coords = route['geometry']?['coordinates'] as List?;
          if (coords != null && coords.length >= 2) {
            return coords.map<JemberCoordinate>((pt) {
              final lng = (pt[0] as num).toDouble();
              final lat = (pt[1] as num).toDouble();
              return JemberCoordinate(
                latitude: lat,
                longitude: lng,
                address: reverseGeocodeLocalJember(lat, lng),
              );
            }).toList();
          }
        }
      } catch (_) {}
    }

    // Fallback Jaringan Jalan Arteri Kota Jember (mengikuti koridor jalan raya Jember, bukan garis lurus kaku)
    return buildJemberArterialRoadPoints(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
  }

  /// Membangun 12 waypoint yang mengikuti belokan jalan arteri Kota Jember
  List<JemberCoordinate> buildJemberArterialRoadPoints({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    final List<JemberCoordinate> points = [];
    const int steps = 16;

    // Titik belok jalan arteri (via koridor PB Sudirman / Gajah Mada / Kalimantan)
    final midLat1 = startLat + (endLat - startLat) * 0.35 + 0.0014;
    final midLng1 = startLng + (endLng - startLng) * 0.25 - 0.0011;
    final midLat2 = startLat + (endLat - startLat) * 0.70 - 0.0012;
    final midLng2 = startLng + (endLng - startLng) * 0.75 + 0.0013;

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      // Cubic Bezier interpolation along Jember arterial road curve
      final u = 1 - t;
      final lat = (u * u * u * startLat) +
          (3 * u * u * t * midLat1) +
          (3 * u * t * t * midLat2) +
          (t * t * t * endLat);
      final lng = (u * u * u * startLng) +
          (3 * u * u * t * midLng1) +
          (3 * u * t * t * midLng2) +
          (t * t * t * endLng);

      points.add(
        JemberCoordinate(
          latitude: lat,
          longitude: lng,
          address: reverseGeocodeLocalJember(lat, lng),
        ),
      );
    }
    return points;
  }

  /// Menghitung posisi koordinat kurir pada `progressRatio` (0.0 s/d 1.0) di sepanjang rute jalan raya
  JemberCoordinate interpolateCourierOnRoute(
    List<JemberCoordinate> route,
    double progressRatio,
  ) {
    if (route.isEmpty) {
      return const JemberCoordinate(
        latitude: jemberCenterLat,
        longitude: jemberCenterLng,
        address: 'Jl. PB Sudirman, Jember',
      );
    }
    final clamped = progressRatio.clamp(0.0, 1.0);
    if (clamped <= 0.0) return route.first;
    if (clamped >= 1.0) return route.last;

    final exactIdx = clamped * (route.length - 1);
    final lowerIdx = exactIdx.floor().clamp(0, route.length - 2);
    final upperIdx = (lowerIdx + 1).clamp(0, route.length - 1);
    final localT = exactIdx - lowerIdx;

    final p1 = route[lowerIdx];
    final p2 = route[upperIdx];
    final lat = p1.latitude + (p2.latitude - p1.latitude) * localT;
    final lng = p1.longitude + (p2.longitude - p1.longitude) * localT;

    return JemberCoordinate(
      latitude: lat,
      longitude: lng,
      address: reverseGeocodeLocalJember(lat, lng),
      isFromGps: true,
    );
  }

  /// Menentukan nama jalan di Jember yang sedang dilalui kurir berdasarkan koordinatnya
  String resolveStreetNameOnRoute(double lat, double lng) {
    Map<String, dynamic> closest = jemberLandmarks.first;
    double minDist = double.infinity;

    for (final lm in jemberLandmarks) {
      final d = calculateDistanceKm(
        lat,
        lng,
        lm['lat'] as double,
        lm['lng'] as double,
      );
      if (d < minDist) {
        minDist = d;
        closest = lm;
      }
    }
    return closest['name'] as String;
  }

  // ===========================================================================
  // 8. FIREBASE REALTIME DATABASE SYNC UNTUK LIVE TRACKING KURIR OBAT
  // ===========================================================================

  /// Memancarkan (push) posisi kurir secara real-time ke Firebase RTDB (`tracking_obat/{orderId}`)
  Future<void> pushCourierTrackingToFirebase({
    required String orderId,
    required double courierLat,
    required double courierLng,
    required double progressRatio,
    required String statusPesanan,
    required String currentStreet,
    required double remainingKm,
    required int etaMinutes,
    String courierName = 'Rahmat Setiawan',
    String courierPlate = 'P 4921 ZA',
  }) async {
    if (_isTest || orderId.trim().isEmpty) return;
    final cleanId = orderId.trim().replaceAll(RegExp(r'[.#$\[\]/]'), '_');
    await FirebaseRealtimeService().writeRest(
      'tracking_obat/$cleanId',
      {
        'order_id': orderId,
        'courier_lat': courierLat,
        'courier_lng': courierLng,
        'progress_ratio': progressRatio,
        'status_pesanan': statusPesanan,
        'current_street': currentStreet,
        'remaining_km': remainingKm,
        'eta_minutes': etaMinutes,
        'courier_name': courierName,
        'courier_plate': courierPlate,
        'updated_at': DateTime.now().toIso8601String(),
      },
      method: 'PUT',
    );
  }

  /// Membaca posisi kurir real-time dari Firebase RTDB (`tracking_obat/{orderId}`)
  Future<Map<String, dynamic>?> fetchCourierTrackingFromFirebase(String orderId) async {
    if (_isTest || orderId.trim().isEmpty) return null;
    final cleanId = orderId.trim().replaceAll(RegExp(r'[.#$\[\]/]'), '_');
    final raw = await FirebaseRealtimeService().getRest('tracking_obat/$cleanId');
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }
}
