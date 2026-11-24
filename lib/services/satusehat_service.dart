import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'supabase_admin_service.dart';

/// Hasil pencarian atau sinkronisasi data demografi Pasien dari/ke SATUSEHAT
class SatuSehatPatientProfile {
  final String ihsNumber;
  final String? nik;
  final String? nama;
  final String? jenisKelamin; // 'L' atau 'P'
  final String? tanggalLahir; // YYYY-MM-DD
  final String? alamat;
  final String? kota;
  final String? kodePos;
  final String? noHp;
  final String? email;
  final Map<String, dynamic> rawResource;

  const SatuSehatPatientProfile({
    required this.ihsNumber,
    this.nik,
    this.nama,
    this.jenisKelamin,
    this.tanggalLahir,
    this.alamat,
    this.kota,
    this.kodePos,
    this.noHp,
    this.email,
    this.rawResource = const {},
  });
}

/// Servis terpusat integrasi dua arah GIAT <-> SATUSEHAT Kemenkes RI (HL7 FHIR R4).
///
/// Mencakup seluruh domain pertukaran data tanpa mengubah tampilan UI:
/// - OAuth 2.0 Client Credentials (`accesstoken`) dengan auto-refresh
/// - `Patient` (Demografi lengkap: NIK, IHS Number, Nama, Alamat + Kode Wilayah Kemendagri,
///   Tanggal Lahir, Jenis Kelamin, No. HP, Email)
/// - `Practitioner` (Dokter: IHS Number, NIK, STR, SIP, Spesialisasi, Institusi)
/// - `Organization` & `Location` (Faskes, Ruang Telemedisin GIAT, Apotek Mitra Jember + GPS)
/// - `Encounter` & `Condition` (Kunjungan Telekonsultasi & Diagnosis ICD-10)
/// - `Observation` (Pantau Harian Berat Badan, Tinggi Badan, IMT/BMI LOINC & Skrining AI PRAGI)
/// - `Medication`, `MedicationRequest`, & `MedicationDispense` (Obat KFA, Resep Dokter, Penyerahan Apotek)
class SatuSehatService {
  SatuSehatService._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 18),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
        },
      ),
    );
  }

  static final SatuSehatService instance = SatuSehatService._internal();
  factory SatuSehatService() => instance;

  late final Dio _dio;

  /// Flag khusus agar pengujian integrasi SATUSEHAT dapat mengaktifkan koneksi live
  /// saat berjalan di lingkungan `flutter test` / `dart test`, sementara widget test
  /// UI reguler tetap terisolasi penuh tanpa membuka koneksi jaringan.
  static bool enableLiveInTest = false;

  bool get _isBlockedByWidgetTest =>
      Platform.environment.containsKey('FLUTTER_TEST') && !enableLiveInTest;

  String? _cachedAccessToken;
  DateTime? _tokenExpiryUtc;
  Future<String?>? _pendingTokenFuture;

  String? _cachedDefaultLocationId;
  String? _cachedSandboxPractitionerIhs;

  String get organizationId => ApiConstants.satusehatOrganizationId;
  String get fhirBaseUrl => ApiConstants.satusehatFhirBaseUrl;
  String get authBaseUrl => ApiConstants.satusehatAuthBaseUrl;

  // ===========================================================================
  // 1. OAUTH 2.0 ACCESS TOKEN MANAGEMENT
  // ===========================================================================

  /// Mendapatkan OAuth 2.0 Bearer Token aktif dari SATUSEHAT (otomatis cache & refresh)
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    if (_isBlockedByWidgetTest) return null;

    final now = DateTime.now().toUtc();
    if (!forceRefresh &&
        _cachedAccessToken != null &&
        _tokenExpiryUtc != null &&
        now.isBefore(_tokenExpiryUtc!.subtract(const Duration(seconds: 60)))) {
      return _cachedAccessToken;
    }

    if (!forceRefresh && _pendingTokenFuture != null) {
      return _pendingTokenFuture!;
    }

    _pendingTokenFuture = _fetchNewAccessToken();
    try {
      return await _pendingTokenFuture!;
    } finally {
      _pendingTokenFuture = null;
    }
  }

  Future<String?> _fetchNewAccessToken() async {
    try {
      final response = await _dio.post(
        '$authBaseUrl/accesstoken',
        queryParameters: {'grant_type': 'client_credentials'},
        data: {
          'client_id': ApiConstants.satusehatClientId,
          'client_secret': ApiConstants.satusehatClientSecret,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final raw = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      if (raw is Map && raw['access_token'] != null) {
        _cachedAccessToken = raw['access_token'].toString();
        final expSec =
            int.tryParse(raw['expires_in']?.toString() ?? '14000') ?? 14000;
        _tokenExpiryUtc = DateTime.now().toUtc().add(Duration(seconds: expSec));
        return _cachedAccessToken;
      }
    } catch (e) {
      debugPrint('⚠️ SatuSehat OAuth token notice: $e');
    }
    return null;
  }

  /// Helper pemanggilan FHIR R4 dengan auto-retry 1x jika token kedaluwarsa (401)
  Future<Response<dynamic>?> _fhirRequest(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? data,
    String contentType = 'application/json',
  }) async {
    if (_isBlockedByWidgetTest) return null;
    String? token = await getAccessToken();
    if (token == null || token.isEmpty) return null;

    Future<Response<dynamic>> sendWithToken(String bearer) {
      final cleanPath = path.startsWith('/') ? path : '/$path';
      return _dio.request(
        '$fhirBaseUrl$cleanPath',
        queryParameters: queryParameters,
        data: data,
        options: Options(
          method: method,
          contentType: contentType,
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $bearer',
            HttpHeaders.acceptHeader: 'application/json',
          },
        ),
      );
    }

    try {
      return await sendWithToken(token);
    } on DioException catch (err) {
      if (err.response?.statusCode == 401) {
        final refreshed = await getAccessToken(forceRefresh: true);
        if (refreshed != null && refreshed.isNotEmpty) {
          return await sendWithToken(refreshed);
        }
      } else if (err.response?.statusCode == 429) {
        await Future<void>.delayed(const Duration(seconds: 2));
        return await sendWithToken(token);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  String _formatFhirUtc(DateTime dt) {
    final u = dt.toUtc();
    final iso = u.toIso8601String().split('.').first;
    return '${iso.replaceAll('Z', '')}+00:00';
  }

  // ===========================================================================
  // 2. LOGGING & SUPABASE MAPPING HELPERS
  // ===========================================================================

  Future<String?> _findSyncedId({
    required String entityType,
    required String localId,
    required String fhirResourceType,
  }) async {
    if (_isBlockedByWidgetTest || localId.trim().isEmpty) return null;
    try {
      final rows = await SupabaseAdminService.instance.executeQuery(
        '''
        SELECT satusehat_id
        FROM satusehat_sync_logs
        WHERE entity_type = @etype
          AND local_id = @lid
          AND fhir_resource_type = @rtype
          AND status = 'synced'
          AND satusehat_id IS NOT NULL
          AND satusehat_id <> ''
        ORDER BY synced_at DESC
        LIMIT 1
        ''',
        {
          'etype': entityType,
          'lid': localId.trim(),
          'rtype': fhirResourceType,
        },
      );
      if (rows.isNotEmpty) {
        final val = rows.first['satusehat_id']?.toString().trim();
        if (val != null && val.isNotEmpty) return val;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _recordSyncLog({
    required String entityType,
    required String localId,
    required String fhirResourceType,
    String? satusehatId,
    required String status,
    int? httpStatus,
    Map<String, dynamic>? payloadSummary,
    Map<String, dynamic>? responseData,
    String? errorMessage,
  }) async {
    if (_isBlockedByWidgetTest || localId.trim().isEmpty) return;
    try {
      await SupabaseAdminService.instance.executeQuery(
        '''
        INSERT INTO satusehat_sync_logs (
          id, entity_type, local_id, fhir_resource_type, satusehat_id,
          status, http_status, payload_summary, response_data, error_message, synced_at
        ) VALUES (
          gen_random_uuid()::text, @etype, @lid, @rtype, NULLIF(@sid, ''),
          @st, @code, CAST(@psum AS jsonb), CAST(@res AS jsonb), NULLIF(@err, ''), NOW()
        )
        ''',
        {
          'etype': entityType,
          'lid': localId.trim(),
          'rtype': fhirResourceType,
          'sid': satusehatId ?? '',
          'st': status,
          'code': httpStatus ?? 200,
          'psum': jsonEncode(payloadSummary ?? const <String, dynamic>{}),
          'res': jsonEncode(responseData ?? const <String, dynamic>{}),
          'err': errorMessage ?? '',
        },
      );
    } catch (e) {
      debugPrint('⚠️ SatuSehat sync log notice: $e');
    }
  }

  // ===========================================================================
  // 3. KODE WILAYAH KEMENDAGRI & PARSER DEMOGRAFI INDONESIA
  // ===========================================================================

  Map<String, String> _resolveAdministrativeCode(String? rawAddress) {
    final lower = (rawAddress ?? '').toLowerCase();

    // Kode Pos
    final postalMatch = RegExp(r'\b(\d{5})\b').firstMatch(rawAddress ?? '');
    String postalCode = postalMatch?.group(1) ?? '68121';

    // RT / RW jika tertulis di alamat
    final rtMatch = RegExp(r'\brt\.?\s*0*(\d{1,3})\b', caseSensitive: false)
        .firstMatch(rawAddress ?? '');
    final rwMatch = RegExp(r'\brw\.?\s*0*(\d{1,3})\b', caseSensitive: false)
        .firstMatch(rawAddress ?? '');
    final rt = rtMatch?.group(1) ?? '1';
    final rw = rwMatch?.group(1) ?? '2';

    // Pemetaan Kecamatan & Kelurahan Kabupaten Jember (Kemendagri 35.09)
    if (lower.contains('kaliwates') ||
        lower.contains('gajah mada') ||
        lower.contains('hayam wuruk') ||
        lower.contains('sempusari') ||
        lower.contains('jayanegara')) {
      return {
        'province': '35',
        'city': '3509',
        'cityName': 'Kabupaten Jember',
        'district': '350919',
        'village': lower.contains('sempusari') ? '3509191005' : '3509191002',
        'postalCode': postalMatch?.group(1) ?? '68131',
        'rt': rt,
        'rw': rw,
      };
    }
    if (lower.contains('patrang') ||
        lower.contains('soebandi') ||
        lower.contains('slamet riyadi') ||
        lower.contains('bedadung') ||
        lower.contains('jemberlor') ||
        lower.contains('gebang') ||
        lower.contains('sudirman')) {
      return {
        'province': '35',
        'city': '3509',
        'cityName': 'Kabupaten Jember',
        'district': '350920',
        'village': lower.contains('gebang')
            ? '3509201001'
            : (lower.contains('jemberlor') ? '3509201003' : '3509201005'),
        'postalCode': postalMatch?.group(1) ?? '68111',
        'rt': rt,
        'rw': rw,
      };
    }
    if (lower.contains('ajung') || lower.contains('mangli')) {
      return {
        'province': '35',
        'city': '3509',
        'cityName': 'Kabupaten Jember',
        'district': '350917',
        'village': '3509172004',
        'postalCode': postalMatch?.group(1) ?? '68175',
        'rt': rt,
        'rw': rw,
      };
    }
    if (lower.contains('pakusari') || lower.contains('kertosari')) {
      return {
        'province': '35',
        'city': '3509',
        'cityName': 'Kabupaten Jember',
        'district': '350922',
        'village': '3509222004',
        'postalCode': postalMatch?.group(1) ?? '68181',
        'rt': rt,
        'rw': rw,
      };
    }
    if (lower.contains('balung')) {
      return {
        'province': '35',
        'city': '3509',
        'cityName': 'Kabupaten Jember',
        'district': '350908',
        'village': '3509082004',
        'postalCode': postalMatch?.group(1) ?? '68161',
        'rt': rt,
        'rw': rw,
      };
    }
    if (lower.contains('surabaya')) {
      return {
        'province': '35',
        'city': '3578',
        'cityName': 'Kota Surabaya',
        'district': '357804',
        'village': '3578041001',
        'postalCode': postalMatch?.group(1) ?? '60241',
        'rt': rt,
        'rw': rw,
      };
    }
    if (lower.contains('bandung')) {
      return {
        'province': '32',
        'city': '3273',
        'cityName': 'Kota Bandung',
        'district': '327307',
        'village': '3273071001',
        'postalCode': postalMatch?.group(1) ?? '40132',
        'rt': rt,
        'rw': rw,
      };
    }
    if (lower.contains('jakarta')) {
      return {
        'province': '31',
        'city': '3171',
        'cityName': 'Kota Adm. Jakarta Pusat',
        'district': '317101',
        'village': '3171011001',
        'postalCode': postalMatch?.group(1) ?? '10110',
        'rt': rt,
        'rw': rw,
      };
    }

    // Default: Kecamatan Sumbersari, Kabupaten Jember (Kampus UNEJ / Tegalgede / Kalimantan / Mastrip / Baturaden)
    return {
      'province': '35',
      'city': '3509',
      'cityName': 'Kabupaten Jember',
      'district': '350921',
      'village': lower.contains('tegalgede') ||
              lower.contains('mastrip') ||
              lower.contains('baturaden') ||
              lower.contains('batu raden')
          ? '3509211002'
          : '3509211005',
      'postalCode': postalCode,
      'rt': rt,
      'rw': rw,
    };
  }

  /// Menghasilkan NIK Sandbox deterministik (16 digit format Jember `350921...`)
  /// khusus di lingkungan Sandbox apabila pasien belum mengisi NIK 16 digit valid.
  String _buildSandboxFallbackNik({
    required String seed,
    String? birthDate,
    String? gender,
  }) {
    DateTime bd = DateTime(1995, 5, 15);
    if (birthDate != null && birthDate.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(birthDate.trim());
      if (parsed != null) bd = parsed;
    }
    final isFemale = (gender ?? '').toUpperCase().startsWith('P') ||
        (gender ?? '').toLowerCase() == 'female';
    final dayCode = (isFemale ? bd.day + 40 : bd.day).toString().padLeft(2, '0');
    final monthCode = bd.month.toString().padLeft(2, '0');
    final yearCode = (bd.year % 100).toString().padLeft(2, '0');

    int hash = 0;
    for (final codeUnit in seed.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    final seq = ((hash % 8999) + 1000).toString();
    return '350921$dayCode$monthCode$yearCode$seq';
  }

  bool _isValid16DigitNik(String? nik) {
    if (nik == null) return false;
    final clean = nik.trim();
    if (!RegExp(r'^\d{16}$').hasMatch(clean)) return false;
    // Hindari semua angka identik seperti 0000000000000000
    if (RegExp(r'^(\d)\1{15}$').hasMatch(clean)) return false;
    return true;
  }

  SatuSehatPatientProfile? _parsePatientResource(
    Map<String, dynamic> res, {
    String? fallbackNik,
  }) {
    final id = res['id']?.toString().trim() ?? '';
    if (id.isEmpty) return null;

    String? nik = fallbackNik;
    if (res['identifier'] is List) {
      for (final item in res['identifier'] as List) {
        final m = _asMap(item);
        final sys = (m['system'] ?? '').toString();
        final val = (m['value'] ?? '').toString().trim();
        if (sys.contains('/nik') && val.isNotEmpty && !val.contains('#') && !val.contains('*')) {
          nik = val;
        }
      }
    }

    String? nama;
    if (res['name'] is List && (res['name'] as List).isNotEmpty) {
      final nMap = _asMap((res['name'] as List).first);
      final rawText = (nMap['text'] ?? '').toString().trim();
      if (rawText.isNotEmpty && !rawText.contains('*')) {
        nama = rawText;
      }
    }

    String? jk;
    final rawGender = (res['gender'] ?? '').toString().toLowerCase().trim();
    if (rawGender == 'female') {
      jk = 'P';
    } else if (rawGender == 'male') {
      jk = 'L';
    }

    final rawBirth = (res['birthDate'] ?? '').toString().trim();
    final tanggalLahir =
        rawBirth.isNotEmpty && !rawBirth.contains('*') ? rawBirth : null;

    String? alamat;
    String? kota;
    String? kodePos;
    if (res['address'] is List && (res['address'] as List).isNotEmpty) {
      final aMap = _asMap((res['address'] as List).first);
      final lines = aMap['line'] is List
          ? (aMap['line'] as List).map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList()
          : <String>[];
      kota = aMap['city']?.toString().trim();
      kodePos = aMap['postalCode']?.toString().trim();
      final parts = <String>[
        ...lines,
        if (kota != null && kota.isNotEmpty) kota,
        if (kodePos != null && kodePos.isNotEmpty) kodePos,
      ];
      final joined = parts.join(', ');
      if (joined.isNotEmpty && !joined.contains('*')) {
        alamat = joined;
      }
    }

    String? noHp;
    String? email;
    if (res['telecom'] is List) {
      for (final item in res['telecom'] as List) {
        final tMap = _asMap(item);
        final sys = (tMap['system'] ?? '').toString().toLowerCase();
        final val = (tMap['value'] ?? '').toString().trim();
        if (val.isEmpty || val.contains('*')) continue;
        if (sys == 'phone' && noHp == null) noHp = val;
        if (sys == 'email' && email == null) email = val;
      }
    }

    return SatuSehatPatientProfile(
      ihsNumber: id,
      nik: nik,
      nama: nama,
      jenisKelamin: jk,
      tanggalLahir: tanggalLahir,
      alamat: alamat,
      kota: kota,
      kodePos: kodePos,
      noHp: noHp,
      email: email,
      rawResource: res,
    );
  }

  // ===========================================================================
  // 4. PATIENT EXCHANGE (DEMOGRAFI: NAMA, ALAMAT, NIK, NO HP, TGL LAHIR, DLL.)
  // ===========================================================================

  /// Mencari data Pasien di SATUSEHAT berdasarkan NIK 16 digit (`GET /Patient?identifier=...`)
  Future<SatuSehatPatientProfile?> lookupPatientByNik(String nik) async {
    if (_isBlockedByWidgetTest) return null;
    final cleanNik = nik.trim();
    if (!_isValid16DigitNik(cleanNik)) return null;

    try {
      final response = await _fhirRequest(
        'GET',
        '/Patient',
        queryParameters: {
          'identifier': 'https://fhir.kemkes.go.id/id/nik|$cleanNik',
        },
      );
      final bundle = _asMap(response?.data);
      final entries = bundle['entry'];
      if (entries is List && entries.isNotEmpty) {
        for (final entry in entries) {
          final res = _asMap(_asMap(entry)['resource']);
          final id = (res['id'] ?? '').toString();
          if (id.startsWith('P')) {
            return _parsePatientResource(res, fallbackNik: cleanNik);
          }
        }
        final firstRes = _asMap(_asMap(entries.first)['resource']);
        return _parsePatientResource(firstRes, fallbackNik: cleanNik);
      }
    } catch (e) {
      debugPrint('⚠️ SatuSehat lookupPatientByNik($cleanNik) notice: $e');
    }
    return null;
  }

  /// Mengambil data Pasien di SATUSEHAT berdasarkan IHS Number (`GET /Patient/{id}`)
  Future<SatuSehatPatientProfile?> getPatientByIhsNumber(String ihsNumber) async {
    if (_isBlockedByWidgetTest || ihsNumber.trim().isEmpty) return null;
    try {
      final response = await _fhirRequest('GET', '/Patient/${ihsNumber.trim()}');
      final res = _asMap(response?.data);
      return _parsePatientResource(res);
    } catch (e) {
      debugPrint('⚠️ SatuSehat getPatientByIhsNumber($ihsNumber) notice: $e');
      return null;
    }
  }

  /// Sinkronisasi dua arah data Pasien GIAT <-> SATUSEHAT:
  /// 1. Mengambil data terbaru pasien dari GIAT / Supabase (Nama, Alamat, NIK, No HP, Email, JK, Tgl Lahir, Gol Darah)
  /// 2. Mencari di SATUSEHAT via NIK:
  ///    - Jika ditemukan dan field lokal kosong, melengkapi data lokal secara otomatis
  ///    - Jika belum terdaftar di SATUSEHAT, mendaftarkan `POST /Patient` lengkap dengan Nama, Alamat + Kode Wilayah Kemendagri, Kontak, dll.
  /// 3. Menyimpan `satusehat_ihs_number` ke Supabase (`pasien`), `satusehat_sync_logs`, dan sesi lokal `StorageService`
  Future<SatuSehatPatientProfile?> syncPasienToSatuSehat({
    String? idPasien,
    String? nama,
    String? nik,
    String? alamat,
    String? noHp,
    String? email,
    String? jenisKelamin,
    String? tanggalLahir,
    String? golonganDarah,
    String? existingIhsNumber,
    bool forcePushUpdate = false,
  }) async {
    if (_isBlockedByWidgetTest) return null;

    try {
      String resolvedId = (idPasien ?? '').trim();
      Map<String, dynamic> dbRow = <String, dynamic>{};

      if (resolvedId.isNotEmpty) {
        try {
          final rows = await SupabaseAdminService.instance.executeQuery(
            '''
            SELECT
              TRIM(p.id_pasien) AS id_pasien,
              p.nama,
              p.no_hp,
              p.alamat,
              p.jenis_kelamin,
              p.nik,
              p.tanggal_lahir::text AS tanggal_lahir,
              p.golongan_darah,
              p.satusehat_ihs_number,
              u.email
            FROM pasien p
            LEFT JOIN "user" u ON TRIM(u.id) = TRIM(p.id_pasien)
            WHERE TRIM(p.id_pasien) = @pid
            LIMIT 1
            ''',
            {'pid': resolvedId},
          );
          if (rows.isNotEmpty) {
            dbRow = rows.first;
          }
        } catch (_) {}
      }

      final finalNama = (nama != null && nama.trim().isNotEmpty)
          ? nama.trim()
          : (dbRow['nama']?.toString().trim().isNotEmpty == true
              ? dbRow['nama'].toString().trim()
              : 'Pasien GIAT');
      final rawNik = (nik != null && nik.trim().isNotEmpty)
          ? nik.trim()
          : dbRow['nik']?.toString().trim();
      final finalAlamat = (alamat != null && alamat.trim().isNotEmpty)
          ? alamat.trim()
          : (dbRow['alamat']?.toString().trim().isNotEmpty == true
              ? dbRow['alamat'].toString().trim()
              : 'Jl. Kalimantan No. 37, Sumbersari, Kabupaten Jember, Jawa Timur 68121');
      final finalNoHp = (noHp != null && noHp.trim().isNotEmpty)
          ? noHp.trim()
          : (dbRow['no_hp']?.toString().trim() ?? '');
      final finalEmail = (email != null && email.trim().isNotEmpty)
          ? email.trim().toLowerCase()
          : (dbRow['email']?.toString().trim().toLowerCase() ?? '');
      final rawJk = (jenisKelamin != null && jenisKelamin.trim().isNotEmpty)
          ? jenisKelamin.trim()
          : (dbRow['jenis_kelamin']?.toString().trim() ?? 'L');
      final isFemale = rawJk.toUpperCase().startsWith('P') ||
          rawJk.toLowerCase() == 'female';
      final rawBirth = (tanggalLahir != null && tanggalLahir.trim().isNotEmpty)
          ? tanggalLahir.trim()
          : dbRow['tanggal_lahir']?.toString().trim();
      final finalBirthDate = (rawBirth != null &&
              RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(rawBirth))
          ? rawBirth.substring(0, 10)
          : '1995-05-15';
      final finalGolDarah = (golonganDarah ?? dbRow['golongan_darah'])?.toString();

      String? knownIhs = (existingIhsNumber != null && existingIhsNumber.trim().isNotEmpty)
          ? existingIhsNumber.trim()
          : dbRow['satusehat_ihs_number']?.toString().trim();

      if ((knownIhs == null || knownIhs.isEmpty) && resolvedId.isNotEmpty) {
        knownIhs = await _findSyncedId(
          entityType: 'pasien',
          localId: resolvedId,
          fhirResourceType: 'Patient',
        );
      }

      // Jika IHS Number pasien sudah tersinkronisasi di database & tidak ada perubahan profil,
      // gunakan profil tersinkronisasi agar efisien dan hemat kuota rate-limit API SATUSEHAT.
      if (!forcePushUpdate && knownIhs != null && knownIhs.isNotEmpty) {
        return SatuSehatPatientProfile(
          ihsNumber: knownIhs,
          nik: rawNik,
          nama: finalNama,
          jenisKelamin: isFemale ? 'P' : 'L',
          tanggalLahir: finalBirthDate,
          alamat: finalAlamat,
          noHp: finalNoHp,
          email: finalEmail,
        );
      }

      // Tentukan NIK yang digunakan ke SATUSEHAT
      String effectiveNik;
      if (_isValid16DigitNik(rawNik)) {
        effectiveNik = rawNik!;
      } else if (!ApiConstants.satusehatIsProduction) {
        effectiveNik = _buildSandboxFallbackNik(
          seed: resolvedId.isNotEmpty ? resolvedId : finalNama,
          birthDate: finalBirthDate,
          gender: isFemale ? 'P' : 'L',
        );
      } else {
        return null;
      }

      // 1. Cek terlebih dahulu di SATUSEHAT berdasarkan NIK
      SatuSehatPatientProfile? remoteProfile = await lookupPatientByNik(effectiveNik);

      // 2. Jika belum ada di SATUSEHAT, daftarkan `POST /Patient` dengan data demografi lengkap GIAT
      remoteProfile ??= await _createPatientOnSatuSehat(
        nik: effectiveNik,
        nama: finalNama,
        alamat: finalAlamat,
        noHp: finalNoHp,
        email: finalEmail,
        isFemale: isFemale,
        birthDate: finalBirthDate,
        fallbackSeed: resolvedId.isNotEmpty ? resolvedId : finalNama,
      );

      // Jika sudah ada IHS sebelumnya tapi lookup NIK tidak mengembalikan (misal NIK baru diubah), cek IHS langsung
      if (remoteProfile == null && knownIhs != null && knownIhs.isNotEmpty) {
        remoteProfile = await getPatientByIhsNumber(knownIhs);
      }

      if (remoteProfile == null) return null;

      final ihs = remoteProfile.ihsNumber;

      // 3. Simpan IHS Number & pemerkayaan data dua arah ke Supabase + Local Storage
      if (resolvedId.isNotEmpty) {
        try {
          await SupabaseAdminService.instance.executeQuery(
            '''
            UPDATE pasien
            SET satusehat_ihs_number = @ihs,
                nama = CASE WHEN (nama IS NULL OR TRIM(nama) = '') AND @rNama <> '' THEN @rNama ELSE nama END,
                alamat = CASE WHEN (alamat IS NULL OR TRIM(alamat) = '') AND @rAlamat <> '' THEN @rAlamat ELSE alamat END,
                no_hp = CASE WHEN (no_hp IS NULL OR TRIM(no_hp) = '') AND @rHp <> '' THEN @rHp ELSE no_hp END,
                jenis_kelamin = CASE WHEN (jenis_kelamin IS NULL OR TRIM(jenis_kelamin) = '') AND @rJk <> '' THEN @rJk ELSE jenis_kelamin END,
                tanggal_lahir = CASE WHEN tanggal_lahir IS NULL AND @rDob <> '' THEN CAST(@rDob AS date) ELSE tanggal_lahir END,
                satusehat_synced_at = NOW(),
                updated_at = NOW()
            WHERE TRIM(id_pasien) = @pid
            ''',
            {
              'pid': resolvedId,
              'ihs': ihs,
              'rNama': remoteProfile.nama ?? '',
              'rAlamat': remoteProfile.alamat ?? '',
              'rHp': remoteProfile.noHp ?? '',
              'rJk': remoteProfile.jenisKelamin ?? '',
              'rDob': remoteProfile.tanggalLahir ?? '',
            },
          );
        } catch (dbErr) {
          debugPrint('⚠️ SatuSehat update pasien ihs notice: $dbErr');
        }

        await _recordSyncLog(
          entityType: 'pasien',
          localId: resolvedId,
          fhirResourceType: 'Patient',
          satusehatId: ihs,
          status: 'synced',
          httpStatus: 200,
          payloadSummary: {
            'nama': finalNama,
            'nik': effectiveNik,
            'alamat': finalAlamat,
            'no_hp': finalNoHp,
            'email': finalEmail,
            'jenis_kelamin': isFemale ? 'P' : 'L',
            'tanggal_lahir': finalBirthDate,
            'golongan_darah': ?finalGolDarah,
            if (forcePushUpdate) 'trigger': 'profile_update',
          },
          responseData: remoteProfile.rawResource,
        );
      }

      // Perbarui sesi user aktif di StorageService jika ini adalah pasien yang sedang login
      try {
        final savedUser = await StorageService().getUser();
        if (savedUser != null &&
            savedUser.role == 'pasien' &&
            (resolvedId.isEmpty || savedUser.id.toString().trim() == resolvedId)) {
          await StorageService().saveUser(
            savedUser.copyWith(
              satusehatIhsNumber: ihs,
              nama: savedUser.nama.isEmpty ? remoteProfile.nama : null,
              alamat: (savedUser.alamat == null || savedUser.alamat!.isEmpty)
                  ? (remoteProfile.alamat ?? finalAlamat)
                  : null,
              tanggalLahir: (savedUser.tanggalLahir == null || savedUser.tanggalLahir!.isEmpty)
                  ? (remoteProfile.tanggalLahir ?? finalBirthDate)
                  : null,
            ),
          );
        }
      } catch (_) {}

      return SatuSehatPatientProfile(
        ihsNumber: ihs,
        nik: effectiveNik,
        nama: remoteProfile.nama ?? finalNama,
        jenisKelamin: remoteProfile.jenisKelamin ?? (isFemale ? 'P' : 'L'),
        tanggalLahir: remoteProfile.tanggalLahir ?? finalBirthDate,
        alamat: remoteProfile.alamat ?? finalAlamat,
        noHp: remoteProfile.noHp ?? finalNoHp,
        email: remoteProfile.email ?? finalEmail,
        rawResource: remoteProfile.rawResource,
      );
    } catch (e) {
      debugPrint('⚠️ SatuSehat syncPasienToSatuSehat error: $e');
      return null;
    }
  }

  Future<SatuSehatPatientProfile?> _createPatientOnSatuSehat({
    required String nik,
    required String nama,
    required String alamat,
    required String noHp,
    required String email,
    required bool isFemale,
    required String birthDate,
    required String fallbackSeed,
  }) async {
    final admin = _resolveAdministrativeCode(alamat);
    final telecom = <Map<String, dynamic>>[];
    if (noHp.isNotEmpty) {
      telecom.add({'system': 'phone', 'value': noHp, 'use': 'mobile'});
    }
    if (email.isNotEmpty) {
      telecom.add({'system': 'email', 'value': email, 'use': 'home'});
    }

    Map<String, dynamic> buildPayload(String targetNik) => {
          'resourceType': 'Patient',
          'meta': {
            'profile': [
              'https://fhir.kemkes.go.id/r4/StructureDefinition/Patient',
            ],
          },
          'identifier': [
            {
              'use': 'official',
              'system': 'https://fhir.kemkes.go.id/id/nik',
              'value': targetNik,
            },
          ],
          'active': true,
          'name': [
            {
              'use': 'official',
              'text': nama,
            },
          ],
          if (telecom.isNotEmpty) 'telecom': telecom,
          'gender': isFemale ? 'female' : 'male',
          'birthDate': birthDate,
          'deceasedBoolean': false,
          'address': [
            {
              'use': 'home',
              'line': [alamat],
              'city': admin['cityName'] ?? 'Kabupaten Jember',
              'postalCode': admin['postalCode'] ?? '68121',
              'country': 'ID',
              'extension': [
                {
                  'url':
                      'https://fhir.kemkes.go.id/r4/StructureDefinition/administrativeCode',
                  'extension': [
                    {'url': 'province', 'valueCode': admin['province'] ?? '35'},
                    {'url': 'city', 'valueCode': admin['city'] ?? '3509'},
                    {'url': 'district', 'valueCode': admin['district'] ?? '350921'},
                    {'url': 'village', 'valueCode': admin['village'] ?? '3509211002'},
                    {'url': 'rt', 'valueCode': admin['rt'] ?? '1'},
                    {'url': 'rw', 'valueCode': admin['rw'] ?? '2'},
                  ],
                },
              ],
            },
          ],
          'maritalStatus': {
            'coding': [
              {
                'system':
                    'http://terminology.hl7.org/CodeSystem/v3-MaritalStatus',
                'code': 'U',
                'display': 'unmarried',
              },
            ],
            'text': 'unmarried',
          },
          'multipleBirthInteger': 0,
          'communication': [
            {
              'language': {
                'coding': [
                  {
                    'system': 'urn:ietf:bcp:47',
                    'code': 'id-ID',
                    'display': 'Indonesian',
                  },
                ],
                'text': 'Indonesian',
              },
              'preferred': true,
            },
          ],
        };

    try {
      final res = await _fhirRequest('POST', '/Patient', data: buildPayload(nik));
      final map = _asMap(res?.data);
      final parsed = _parsePatientResource(map, fallbackNik: nik);
      if (parsed != null) return parsed;
    } on DioException catch (err) {
      // Di Sandbox, apabila NIK kustom ditolak format wilayahnya oleh validator Dukcapil,
      // gunakan fallback NIK standar Jember (350921...) agar data demografi tetap tercatat di SATUSEHAT.
      if (!ApiConstants.satusehatIsProduction) {
        final fallbackNik = _buildSandboxFallbackNik(
          seed: fallbackSeed,
          birthDate: birthDate,
          gender: isFemale ? 'P' : 'L',
        );
        if (fallbackNik != nik) {
          final existing = await lookupPatientByNik(fallbackNik);
          if (existing != null) return existing;
          try {
            final retryRes = await _fhirRequest(
              'POST',
              '/Patient',
              data: buildPayload(fallbackNik),
            );
            return _parsePatientResource(
              _asMap(retryRes?.data),
              fallbackNik: fallbackNik,
            );
          } catch (_) {}
        }
      }
      debugPrint('⚠️ SatuSehat POST /Patient notice: ${err.response?.data ?? err.message}');
    } catch (e) {
      debugPrint('⚠️ SatuSehat POST /Patient error: $e');
    }
    return null;
  }

  // ===========================================================================
  // 5. PRACTITIONER EXCHANGE (DOKTER: NAMA, GELAR, STR, SIP, SPESIALISASI, RS)
  // ===========================================================================

  Future<String> _resolveVerifiedSandboxPractitionerIhs() async {
    if (_cachedSandboxPractitionerIhs != null &&
        _cachedSandboxPractitionerIhs!.isNotEmpty) {
      return _cachedSandboxPractitionerIhs!;
    }
    for (final candidate in const ['N10000001', '10009880728']) {
      try {
        final res = await _fhirRequest('GET', '/Practitioner/$candidate');
        final map = _asMap(res?.data);
        if (map['id'] != null) {
          _cachedSandboxPractitionerIhs = map['id'].toString();
          return _cachedSandboxPractitionerIhs!;
        }
      } catch (_) {}
    }
    _cachedSandboxPractitionerIhs = 'N10000001';
    return _cachedSandboxPractitionerIhs!;
  }

  /// Sinkronisasi & resolusi IHS Number Dokter GIAT (`Practitioner`)
  Future<String?> syncDokterToSatuSehat({
    String? idDokter,
    String? nama,
    String? nik,
    String? noStr,
    String? noSip,
    String? spesialisasi,
    String? instansi,
  }) async {
    if (_isBlockedByWidgetTest) return null;

    try {
      String resolvedId = (idDokter ?? '').trim();
      Map<String, dynamic> dbRow = <String, dynamic>{};

      if (resolvedId.isNotEmpty) {
        try {
          final rows = await SupabaseAdminService.instance.executeQuery(
            '''
            SELECT TRIM(id_dokter) AS id_dokter, nama, spesialisasi, institusi,
                   no_str, no_sip, no_hp, nik, satusehat_ihs_number
            FROM dokter
            WHERE TRIM(id_dokter) = @did
            LIMIT 1
            ''',
            {'did': resolvedId},
          );
          if (rows.isNotEmpty) dbRow = rows.first;
        } catch (_) {}
      }

      final existingIhs = dbRow['satusehat_ihs_number']?.toString().trim();
      if (existingIhs != null && existingIhs.isNotEmpty) {
        return existingIhs;
      }

      final docNik = (nik ?? dbRow['nik'])?.toString().trim();
      String? resolvedIhs;
      Map<String, dynamic>? rawResponse;

      if (_isValid16DigitNik(docNik)) {
        try {
          final res = await _fhirRequest(
            'GET',
            '/Practitioner',
            queryParameters: {
              'identifier': 'https://fhir.kemkes.go.id/id/nik|$docNik',
            },
          );
          final bundle = _asMap(res?.data);
          final entries = bundle['entry'];
          if (entries is List && entries.isNotEmpty) {
            final first = _asMap(_asMap(entries.first)['resource']);
            resolvedIhs = first['id']?.toString().trim();
            rawResponse = first;
          }
        } catch (_) {}
      }

      if ((resolvedIhs == null || resolvedIhs.isEmpty) &&
          !ApiConstants.satusehatIsProduction) {
        resolvedIhs = await _resolveVerifiedSandboxPractitionerIhs();
        try {
          final pRes = await _fhirRequest('GET', '/Practitioner/$resolvedIhs');
          rawResponse = _asMap(pRes?.data);
        } catch (_) {}
      }

      if (resolvedIhs != null && resolvedIhs.isNotEmpty && resolvedId.isNotEmpty) {
        try {
          await SupabaseAdminService.instance.executeQuery(
            '''
            UPDATE dokter
            SET satusehat_ihs_number = @ihs,
                satusehat_synced_at = NOW(),
                updated_at = NOW()
            WHERE TRIM(id_dokter) = @did
            ''',
            {'did': resolvedId, 'ihs': resolvedIhs},
          );
        } catch (_) {}

        await _recordSyncLog(
          entityType: 'dokter',
          localId: resolvedId,
          fhirResourceType: 'Practitioner',
          satusehatId: resolvedIhs,
          status: 'synced',
          httpStatus: 200,
          payloadSummary: {
            'nama': nama ?? dbRow['nama'],
            'spesialisasi': spesialisasi ?? dbRow['spesialisasi'],
            'instansi': instansi ?? dbRow['institusi'],
            'no_str': noStr ?? dbRow['no_str'],
            'no_sip': noSip ?? dbRow['no_sip'],
          },
          responseData: rawResponse,
        );
      }

      return resolvedIhs;
    } catch (e) {
      debugPrint('⚠️ SatuSehat syncDokterToSatuSehat notice: $e');
      return null;
    }
  }

  // ===========================================================================
  // 6. ORGANIZATION & LOCATION EXCHANGE (RUANG TELEMEDISIN & APOTEK MITRA JEMBER)
  // ===========================================================================

  /// Memastikan Lokasi Poli Telemedisin Ginjal GIAT terdaftar di bawah Organization utama
  Future<String?> ensureDefaultTelemedLocation() async {
    if (_isBlockedByWidgetTest) return null;
    if (_cachedDefaultLocationId != null && _cachedDefaultLocationId!.isNotEmpty) {
      return _cachedDefaultLocationId;
    }

    final syncedLoc = await _findSyncedId(
      entityType: 'lokasi',
      localId: 'GIAT-TELEMED-JEMBER-01',
      fhirResourceType: 'Location',
    );
    if (syncedLoc != null && syncedLoc.isNotEmpty) {
      _cachedDefaultLocationId = syncedLoc;
      return _cachedDefaultLocationId;
    }

    try {
      final searchRes = await _fhirRequest(
        'GET',
        '/Location',
        queryParameters: {'organization': organizationId},
      );
      final bundle = _asMap(searchRes?.data);
      final entries = bundle['entry'];
      if (entries is List && entries.isNotEmpty) {
        final first = _asMap(_asMap(entries.first)['resource']);
        final id = first['id']?.toString().trim();
        if (id != null && id.isNotEmpty) {
          _cachedDefaultLocationId = id;
          await _recordSyncLog(
            entityType: 'lokasi',
            localId: 'GIAT-TELEMED-JEMBER-01',
            fhirResourceType: 'Location',
            satusehatId: id,
            status: 'synced',
            httpStatus: 200,
            payloadSummary: {'name': first['name']},
          );
          return id;
        }
      }

      final payload = {
        'resourceType': 'Location',
        'identifier': [
          {
            'system': 'http://sys-ids.kemkes.go.id/location/$organizationId',
            'value': 'GIAT-TELEMED-JEMBER-${DateTime.now().millisecondsSinceEpoch}',
          },
        ],
        'status': 'active',
        'name': 'Poli Telemedisin Ginjal GIAT Jember',
        'description': 'Layanan Telekonsultasi Kesehatan Ginjal GIAT Kabupaten Jember',
        'mode': 'instance',
        'telecom': [
          {'system': 'phone', 'value': '0331487441', 'use': 'work'},
          {'system': 'email', 'value': 'layanan@giat-jember.id', 'use': 'work'},
        ],
        'address': {
          'use': 'work',
          'line': ['Jl. Kalimantan No. 37, Sumbersari'],
          'city': 'Kabupaten Jember',
          'postalCode': '68121',
          'country': 'ID',
          'extension': [
            {
              'url':
                  'https://fhir.kemkes.go.id/r4/StructureDefinition/administrativeCode',
              'extension': [
                {'url': 'province', 'valueCode': '35'},
                {'url': 'city', 'valueCode': '3509'},
                {'url': 'district', 'valueCode': '350921'},
                {'url': 'village', 'valueCode': '3509211002'},
                {'url': 'rt', 'valueCode': '1'},
                {'url': 'rw', 'valueCode': '2'},
              ],
            },
          ],
        },
        'physicalType': {
          'coding': [
            {
              'system':
                  'http://terminology.hl7.org/CodeSystem/location-physical-type',
              'code': 'ro',
              'display': 'Room',
            },
          ],
        },
        'position': {
          'longitude': 113.7148,
          'latitude': -8.1685,
          'altitude': 89,
        },
        'managingOrganization': {
          'reference': 'Organization/$organizationId',
        },
      };

      final createRes = await _fhirRequest('POST', '/Location', data: payload);
      final created = _asMap(createRes?.data);
      final newId = created['id']?.toString().trim();
      if (newId != null && newId.isNotEmpty) {
        _cachedDefaultLocationId = newId;
        await _recordSyncLog(
          entityType: 'lokasi',
          localId: 'GIAT-TELEMED-JEMBER-01',
          fhirResourceType: 'Location',
          satusehatId: newId,
          status: 'synced',
          httpStatus: createRes?.statusCode,
          payloadSummary: {'name': 'Poli Telemedisin Ginjal GIAT Jember'},
          responseData: created,
        );
        return newId;
      }
    } catch (e) {
      debugPrint('⚠️ SatuSehat ensureDefaultTelemedLocation notice: $e');
    }
    return null;
  }

  /// Sinkronisasi profil Apotek Mitra GIAT ke SATUSEHAT (`Organization` sub-unit & `Location` GPS)
  Future<Map<String, String?>> syncApotekToSatuSehat({
    String? idApotek,
    String? namaApotek,
    String? alamat,
    String? noHp,
    String? email,
    String? noSipaSia,
    String? lokasiLatLong,
    bool forceUpdate = false,
  }) async {
    if (_isBlockedByWidgetTest) return {'orgId': null, 'locationId': null};

    try {
      String resolvedId = (idApotek ?? '').trim();
      Map<String, dynamic> dbRow = <String, dynamic>{};

      if (resolvedId.isNotEmpty) {
        try {
          final rows = await SupabaseAdminService.instance.executeQuery(
            '''
            SELECT TRIM(a.id_apotek) AS id_apotek, a.nama_apotek, a.penanggung_jawab,
                   a.no_sipa_sia, a.no_hp, a.alamat, a.lokasi_lat_long,
                   a.satusehat_org_id, a.satusehat_location_id, u.email
            FROM apotek a
            LEFT JOIN "user" u ON TRIM(u.id) = TRIM(a.id_apotek)
            WHERE TRIM(a.id_apotek) = @aid
            LIMIT 1
            ''',
            {'aid': resolvedId},
          );
          if (rows.isNotEmpty) dbRow = rows.first;
        } catch (_) {}
      }

      final finalNama = (namaApotek ?? dbRow['nama_apotek'] ?? 'Apotek Mitra GIAT Jember').toString().trim();
      final finalAlamat = (alamat ?? dbRow['alamat'] ?? 'Jl. Kalimantan No. 42, Sumbersari, Kabupaten Jember').toString().trim();
      final finalNoHp = (noHp ?? dbRow['no_hp'] ?? '0331338240').toString().trim();
      final finalEmail = (email ?? dbRow['email'] ?? '').toString().trim();
      final rawLatLng = (lokasiLatLong ?? dbRow['lokasi_lat_long'] ?? '-8.1685,113.7148').toString();
      final parts = rawLatLng.split(',');
      final lat = parts.isNotEmpty ? (double.tryParse(parts[0].trim()) ?? -8.1685) : -8.1685;
      final lng = parts.length > 1 ? (double.tryParse(parts[1].trim()) ?? 113.7148) : 113.7148;

      String? ssOrgId = dbRow['satusehat_org_id']?.toString().trim();
      String? ssLocId = dbRow['satusehat_location_id']?.toString().trim();

      if (!forceUpdate &&
          ssOrgId != null &&
          ssOrgId.isNotEmpty &&
          ssLocId != null &&
          ssLocId.isNotEmpty) {
        return {'orgId': ssOrgId, 'locationId': ssLocId};
      }

      final admin = _resolveAdministrativeCode(finalAlamat);
      final shortCode = resolvedId.isNotEmpty
          ? resolvedId.substring(0, resolvedId.length.clamp(0, 8)).toUpperCase()
          : DateTime.now().millisecondsSinceEpoch.toString();

      // 1. Sub-Organization Apotek
      final orgPayload = {
        if (ssOrgId != null && ssOrgId.isNotEmpty) 'id': ssOrgId,
        'resourceType': 'Organization',
        'active': true,
        'identifier': [
          {
            'use': 'official',
            'system': 'http://sys-ids.kemkes.go.id/organization/$organizationId',
            'value': 'GIAT-APT-$shortCode',
          },
        ],
        'type': [
          {
            'coding': [
              {
                'system':
                    'http://terminology.hl7.org/CodeSystem/organization-type',
                'code': 'dept',
                'display': 'Hospital Department',
              },
            ],
          },
        ],
        'name': finalNama,
        'telecom': [
          if (finalNoHp.isNotEmpty)
            {'system': 'phone', 'value': finalNoHp, 'use': 'work'},
          if (finalEmail.isNotEmpty)
            {'system': 'email', 'value': finalEmail, 'use': 'work'},
        ],
        'address': [
          {
            'use': 'work',
            'type': 'both',
            'line': [finalAlamat],
            'city': admin['cityName'] ?? 'Kabupaten Jember',
            'postalCode': admin['postalCode'] ?? '68121',
            'country': 'ID',
            'extension': [
              {
                'url':
                    'https://fhir.kemkes.go.id/r4/StructureDefinition/administrativeCode',
                'extension': [
                  {'url': 'province', 'valueCode': admin['province'] ?? '35'},
                  {'url': 'city', 'valueCode': admin['city'] ?? '3509'},
                  {'url': 'district', 'valueCode': admin['district'] ?? '350921'},
                  {'url': 'village', 'valueCode': admin['village'] ?? '3509211002'},
                  {'url': 'rt', 'valueCode': admin['rt'] ?? '1'},
                  {'url': 'rw', 'valueCode': admin['rw'] ?? '2'},
                ],
              },
            ],
          },
        ],
        'partOf': {
          'reference': 'Organization/$organizationId',
        },
      };

      try {
        final orgRes = (ssOrgId != null && ssOrgId.isNotEmpty)
            ? await _fhirRequest('PUT', '/Organization/$ssOrgId', data: orgPayload)
            : await _fhirRequest('POST', '/Organization', data: orgPayload);
        final orgMap = _asMap(orgRes?.data);
        ssOrgId = orgMap['id']?.toString().trim() ?? ssOrgId;
      } catch (e) {
        debugPrint('⚠️ SatuSehat Apotek Organization sync notice: $e');
      }

      // 2. Location Apotek + GPS Coordinates
      final locPayload = {
        if (ssLocId != null && ssLocId.isNotEmpty) 'id': ssLocId,
        'resourceType': 'Location',
        'identifier': [
          {
            'system': 'http://sys-ids.kemkes.go.id/location/$organizationId',
            'value': 'GIAT-LOC-APT-$shortCode',
          },
        ],
        'status': 'active',
        'name': finalNama,
        'description': 'Instalasi Farmasi / Apotek Mitra GIAT ($finalAlamat)',
        'mode': 'instance',
        'telecom': [
          if (finalNoHp.isNotEmpty)
            {'system': 'phone', 'value': finalNoHp, 'use': 'work'},
        ],
        'address': {
          'use': 'work',
          'line': [finalAlamat],
          'city': admin['cityName'] ?? 'Kabupaten Jember',
          'postalCode': admin['postalCode'] ?? '68121',
          'country': 'ID',
          'extension': [
            {
              'url':
                  'https://fhir.kemkes.go.id/r4/StructureDefinition/administrativeCode',
              'extension': [
                {'url': 'province', 'valueCode': admin['province'] ?? '35'},
                {'url': 'city', 'valueCode': admin['city'] ?? '3509'},
                {'url': 'district', 'valueCode': admin['district'] ?? '350921'},
                {'url': 'village', 'valueCode': admin['village'] ?? '3509211002'},
                {'url': 'rt', 'valueCode': admin['rt'] ?? '1'},
                {'url': 'rw', 'valueCode': admin['rw'] ?? '2'},
              ],
            },
          ],
        },
        'physicalType': {
          'coding': [
            {
              'system':
                  'http://terminology.hl7.org/CodeSystem/location-physical-type',
              'code': 'bu',
              'display': 'Building',
            },
          ],
        },
        'position': {
          'longitude': lng,
          'latitude': lat,
          'altitude': 85,
        },
        'managingOrganization': {
          'reference': 'Organization/${ssOrgId ?? organizationId}',
        },
      };

      try {
        final locRes = (ssLocId != null && ssLocId.isNotEmpty)
            ? await _fhirRequest('PUT', '/Location/$ssLocId', data: locPayload)
            : await _fhirRequest('POST', '/Location', data: locPayload);
        final locMap = _asMap(locRes?.data);
        ssLocId = locMap['id']?.toString().trim() ?? ssLocId;
      } catch (e) {
        debugPrint('⚠️ SatuSehat Apotek Location sync notice: $e');
      }

      if (resolvedId.isNotEmpty && (ssOrgId != null || ssLocId != null)) {
        try {
          await SupabaseAdminService.instance.executeQuery(
            '''
            UPDATE apotek
            SET satusehat_org_id = COALESCE(NULLIF(@oid, ''), satusehat_org_id),
                satusehat_location_id = COALESCE(NULLIF(@lid, ''), satusehat_location_id),
                satusehat_synced_at = NOW(),
                updated_at = NOW()
            WHERE TRIM(id_apotek) = @aid
            ''',
            {'aid': resolvedId, 'oid': ssOrgId ?? '', 'lid': ssLocId ?? ''},
          );
        } catch (_) {}

        await _recordSyncLog(
          entityType: 'apotek',
          localId: resolvedId,
          fhirResourceType: 'Organization',
          satusehatId: ssOrgId ?? ssLocId,
          status: 'synced',
          httpStatus: 201,
          payloadSummary: {
            'nama_apotek': finalNama,
            'alamat': finalAlamat,
            'no_hp': finalNoHp,
            'no_sipa_sia': noSipaSia ?? dbRow['no_sipa_sia'],
            'satusehat_org_id': ssOrgId,
            'satusehat_location_id': ssLocId,
          },
        );
      }

      return {'orgId': ssOrgId, 'locationId': ssLocId};
    } catch (e) {
      debugPrint('⚠️ SatuSehat syncApotekToSatuSehat error: $e');
      return {'orgId': null, 'locationId': null};
    }
  }

  // ===========================================================================
  // 7. ENCOUNTER & CONDITION EXCHANGE (KONSULTASI & DIAGNOSIS ICD-10)
  // ===========================================================================

  Map<String, String> _resolveIcd10Code(String? rawText) {
    final lower = (rawText ?? '').toLowerCase();
    if (lower.contains('stadium 5') || lower.contains('stage 5') || lower.contains('hemodialisis') || lower.contains('cuci darah')) {
      return {'code': 'N18.5', 'display': 'Chronic kidney disease, stage 5'};
    }
    if (lower.contains('stadium 4') || lower.contains('stage 4')) {
      return {'code': 'N18.4', 'display': 'Chronic kidney disease, stage 4'};
    }
    if (lower.contains('stadium 3') || lower.contains('stage 3')) {
      return {'code': 'N18.3', 'display': 'Chronic kidney disease, stage 3'};
    }
    if (lower.contains('hipertensi') && lower.contains('ginjal')) {
      return {'code': 'I12.9', 'display': 'Hypertensive renal disease without renal failure'};
    }
    if (lower.contains('hipertensi') || lower.contains('darah tinggi') || lower.contains('tensi')) {
      return {'code': 'I10', 'display': 'Essential (primary) hypertension'};
    }
    if (lower.contains('diabetes') || lower.contains('gula darah') || lower.contains('kencing manis')) {
      return {'code': 'E11.2', 'display': 'Type 2 diabetes mellitus with renal complications'};
    }
    if (lower.contains('batu ginjal') || lower.contains('nefrolitiasis')) {
      return {'code': 'N20.0', 'display': 'Calculus of kidney'};
    }
    if (lower.contains('infeksi saluran kemih') || lower.contains('isk') || lower.contains('nyeri berkemih')) {
      return {'code': 'N39.0', 'display': 'Urinary tract infection, site not specified'};
    }
    if (lower.contains('bengkak') || lower.contains('edema')) {
      return {'code': 'R60.9', 'display': 'Oedema, unspecified'};
    }
    if (lower.contains('anemia')) {
      return {'code': 'D63.8', 'display': 'Anaemia in other chronic diseases classified elsewhere'};
    }
    return {'code': 'N18.9', 'display': 'Chronic kidney disease, unspecified'};
  }

  /// Sinkronisasi sesi Konsultasi GIAT ke SATUSEHAT (`Encounter` + `Condition` ICD-10)
  Future<Map<String, String?>> syncKonsultasiToSatuSehat({
    required String idKonsultasi,
    String? idPasien,
    String? idDokter,
    String? keluhanAtauDiagnosis,
    String? statusKonsultasi,
  }) async {
    if (_isBlockedByWidgetTest || idKonsultasi.trim().isEmpty) {
      return {'encounterId': null, 'conditionId': null};
    }

    try {
      final cleanId = idKonsultasi.trim();
      Map<String, dynamic> dbRow = <String, dynamic>{};

      try {
        final rows = await SupabaseAdminService.instance.executeQuery(
          '''
          SELECT TRIM(k.id) AS id, TRIM(k.id_pasien) AS id_pasien, TRIM(k.id_dokter) AS id_dokter,
                 k.keluhan_awal, k.status, k.satusehat_encounter_id, k.satusehat_condition_id,
                 p.nama AS nama_pasien, d.nama AS nama_dokter
          FROM konsultasi k
          LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(k.id_pasien)
          LEFT JOIN dokter d ON TRIM(d.id_dokter) = TRIM(k.id_dokter)
          WHERE TRIM(k.id) = @kid
          LIMIT 1
          ''',
          {'kid': cleanId},
        );
        if (rows.isNotEmpty) dbRow = rows.first;
      } catch (_) {}

      final pasId = (idPasien ?? dbRow['id_pasien'])?.toString().trim() ?? '';
      final docId = (idDokter ?? dbRow['id_dokter'])?.toString().trim() ?? '';
      final pasProfile = await syncPasienToSatuSehat(idPasien: pasId);
      if (pasProfile == null) return {'encounterId': null, 'conditionId': null};

      final pracIhs = await syncDokterToSatuSehat(idDokter: docId) ??
          await _resolveVerifiedSandboxPractitionerIhs();
      final locId = await ensureDefaultTelemedLocation();
      if (locId == null) return {'encounterId': null, 'conditionId': null};

      String? encId = dbRow['satusehat_encounter_id']?.toString().trim();
      String? condId = dbRow['satusehat_condition_id']?.toString().trim();
      encId = (encId != null && encId.isNotEmpty)
          ? encId
          : await _findSyncedId(
              entityType: 'konsultasi',
              localId: cleanId,
              fhirResourceType: 'Encounter',
            );

      final nowUtc = DateTime.now().toUtc();
      final startStr = _formatFhirUtc(nowUtc.subtract(const Duration(minutes: 15)));
      final endStr = _formatFhirUtc(nowUtc);
      final pasName = dbRow['nama_pasien']?.toString() ?? pasProfile.nama ?? 'Pasien GIAT';
      final docName = dbRow['nama_dokter']?.toString() ?? 'Dokter Spesialis GIAT';

      Map<String, dynamic>? encResource;

      // 1. Buat Encounter `in-progress` jika belum ada
      if (encId == null || encId.isEmpty) {
        final encPayload = {
          'resourceType': 'Encounter',
          'identifier': [
            {
              'system': 'http://sys-ids.kemkes.go.id/encounter/$organizationId',
              'value': 'GIAT-KONS-$cleanId',
            },
          ],
          'status': 'in-progress',
          'class': {
            'system': 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
            'code': 'AMB',
            'display': 'ambulatory',
          },
          'subject': {
            'reference': 'Patient/${pasProfile.ihsNumber}',
            'display': pasName,
          },
          'participant': [
            {
              'type': [
                {
                  'coding': [
                    {
                      'system':
                          'http://terminology.hl7.org/CodeSystem/v3-ParticipationType',
                      'code': 'ATND',
                      'display': 'attender',
                    },
                  ],
                },
              ],
              'individual': {
                'reference': 'Practitioner/$pracIhs',
                'display': docName,
              },
            },
          ],
          'period': {'start': startStr},
          'location': [
            {
              'location': {
                'reference': 'Location/$locId',
                'display': 'Poli Telemedisin Ginjal GIAT Jember',
              },
            },
          ],
          'statusHistory': [
            {
              'status': 'arrived',
              'period': {'start': startStr, 'end': startStr},
            },
            {
              'status': 'in-progress',
              'period': {'start': startStr},
            },
          ],
          'serviceProvider': {
            'reference': 'Organization/$organizationId',
          },
        };

        final encRes = await _fhirRequest('POST', '/Encounter', data: encPayload);
        encResource = _asMap(encRes?.data);
        encId = encResource['id']?.toString().trim();

        if (encId != null && encId.isNotEmpty) {
          await _recordSyncLog(
            entityType: 'konsultasi',
            localId: cleanId,
            fhirResourceType: 'Encounter',
            satusehatId: encId,
            status: 'synced',
            httpStatus: encRes?.statusCode,
            payloadSummary: {
              'pasien_ihs': pasProfile.ihsNumber,
              'dokter_ihs': pracIhs,
              'status': 'in-progress',
            },
          );
        }
      }

      if (encId == null || encId.isEmpty) {
        return {'encounterId': null, 'conditionId': null};
      }

      // 2. Buat Condition (Diagnosis ICD-10) jika ada keluhan/diagnosis atau sesi selesai
      final diagText = (keluhanAtauDiagnosis ??
              dbRow['keluhan_awal'] ??
              'Konsultasi Kesehatan Ginjal GIAT')
          .toString()
          .trim();
      final finalStatus =
          (statusKonsultasi ?? dbRow['status'] ?? '').toString().toLowerCase().trim();
      final icd = _resolveIcd10Code(diagText);

      if ((condId == null || condId.isEmpty) &&
          (diagText.isNotEmpty || finalStatus == 'selesai')) {
        final condPayload = {
          'resourceType': 'Condition',
          'clinicalStatus': {
            'coding': [
              {
                'system':
                    'http://terminology.hl7.org/CodeSystem/condition-clinical',
                'code': 'active',
                'display': 'Active',
              },
            ],
          },
          'category': [
            {
              'coding': [
                {
                  'system':
                      'http://terminology.hl7.org/CodeSystem/condition-category',
                  'code': 'encounter-diagnosis',
                  'display': 'Encounter Diagnosis',
                },
              ],
            },
          ],
          'code': {
            'coding': [
              {
                'system': 'http://hl7.org/fhir/sid/icd-10',
                'code': icd['code'],
                'display': icd['display'],
              },
            ],
            'text': diagText,
          },
          'subject': {
            'reference': 'Patient/${pasProfile.ihsNumber}',
            'display': pasName,
          },
          'encounter': {'reference': 'Encounter/$encId'},
          'onsetDateTime': endStr,
          'recordedDate': endStr,
        };

        try {
          final condRes =
              await _fhirRequest('POST', '/Condition', data: condPayload);
          final condMap = _asMap(condRes?.data);
          condId = condMap['id']?.toString().trim();
          if (condId != null && condId.isNotEmpty) {
            await _recordSyncLog(
              entityType: 'diagnosis',
              localId: cleanId,
              fhirResourceType: 'Condition',
              satusehatId: condId,
              status: 'synced',
              httpStatus: condRes?.statusCode,
              payloadSummary: {'icd10': icd['code'], 'diagnosis': diagText},
            );
          }
        } catch (e) {
          debugPrint('⚠️ SatuSehat Condition sync notice: $e');
        }
      }

      // 3. Jika status konsultasi selesai, perbarui Encounter menjadi `finished` beserta diagnosis
      if (finalStatus == 'selesai' && condId != null && condId.isNotEmpty) {
        try {
          encResource ??= _asMap((await _fhirRequest('GET', '/Encounter/$encId'))?.data);
          if (encResource['status'] != 'finished') {
            encResource['status'] = 'finished';
            encResource['period'] = {'start': startStr, 'end': endStr};
            encResource['statusHistory'] = [
              {
                'status': 'arrived',
                'period': {'start': startStr, 'end': startStr},
              },
              {
                'status': 'in-progress',
                'period': {'start': startStr, 'end': endStr},
              },
              {
                'status': 'finished',
                'period': {'start': endStr, 'end': endStr},
              },
            ];
            encResource['diagnosis'] = [
              {
                'condition': {
                  'reference': 'Condition/$condId',
                  'display': icd['display'],
                },
                'use': {
                  'coding': [
                    {
                      'system':
                          'http://terminology.hl7.org/CodeSystem/diagnosis-role',
                      'code': 'DD',
                      'display': 'Discharge diagnosis',
                    },
                  ],
                },
                'rank': 1,
              },
            ];
            await _fhirRequest('PUT', '/Encounter/$encId', data: encResource);
          }
        } catch (e) {
          debugPrint('⚠️ SatuSehat finish Encounter notice: $e');
        }
      }

      try {
        await SupabaseAdminService.instance.executeQuery(
          '''
          UPDATE konsultasi
          SET satusehat_encounter_id = COALESCE(NULLIF(@eid, ''), satusehat_encounter_id),
              satusehat_condition_id = COALESCE(NULLIF(@cid, ''), satusehat_condition_id),
              satusehat_synced_at = NOW(),
              updated_at = NOW()
          WHERE TRIM(id) = @kid
          ''',
          {'kid': cleanId, 'eid': encId, 'cid': condId ?? ''},
        );
      } catch (_) {}

      return {'encounterId': encId, 'conditionId': condId};
    } catch (e) {
      debugPrint('⚠️ SatuSehat syncKonsultasiToSatuSehat error: $e');
      return {'encounterId': null, 'conditionId': null};
    }
  }

  /// Membuat atau mengambil Encounter pendukung untuk pencatatan mandiri (Pantau / PRAGI / Beli Umum)
  Future<String?> _ensurePatientEncounter({
    required SatuSehatPatientProfile patient,
    required String localContextKey,
    String? practitionerIhs,
    String? locationId,
  }) async {
    final existing = await _findSyncedId(
      entityType: 'encounter_ctx',
      localId: localContextKey,
      fhirResourceType: 'Encounter',
    );
    if (existing != null && existing.isNotEmpty) return existing;

    final prac = practitionerIhs ?? await _resolveVerifiedSandboxPractitionerIhs();
    final loc = locationId ?? await ensureDefaultTelemedLocation();
    if (loc == null) return null;

    final nowStr = _formatFhirUtc(DateTime.now().toUtc());
    final payload = {
      'resourceType': 'Encounter',
      'identifier': [
        {
          'system': 'http://sys-ids.kemkes.go.id/encounter/$organizationId',
          'value': 'GIAT-CTX-$localContextKey',
        },
      ],
      'status': 'in-progress',
      'class': {
        'system': 'http://terminology.hl7.org/CodeSystem/v3-ActCode',
        'code': 'AMB',
        'display': 'ambulatory',
      },
      'subject': {
        'reference': 'Patient/${patient.ihsNumber}',
        'display': patient.nama ?? 'Pasien GIAT',
      },
      'participant': [
        {
          'type': [
            {
              'coding': [
                {
                  'system':
                      'http://terminology.hl7.org/CodeSystem/v3-ParticipationType',
                  'code': 'ATND',
                  'display': 'attender',
                },
              ],
            },
          ],
          'individual': {
            'reference': 'Practitioner/$prac',
            'display': 'Dokter Pembina GIAT',
          },
        },
      ],
      'period': {'start': nowStr},
      'location': [
        {
          'location': {
            'reference': 'Location/$loc',
            'display': 'Poli Telemedisin Ginjal GIAT Jember',
          },
        },
      ],
      'statusHistory': [
        {
          'status': 'in-progress',
          'period': {'start': nowStr},
        },
      ],
      'serviceProvider': {'reference': 'Organization/$organizationId'},
    };

    try {
      final res = await _fhirRequest('POST', '/Encounter', data: payload);
      final id = _asMap(res?.data)['id']?.toString().trim();
      if (id != null && id.isNotEmpty) {
        await _recordSyncLog(
          entityType: 'encounter_ctx',
          localId: localContextKey,
          fhirResourceType: 'Encounter',
          satusehatId: id,
          status: 'synced',
          httpStatus: res?.statusCode,
        );
        return id;
      }
    } catch (_) {}
    return null;
  }

  // ===========================================================================
  // 8. OBSERVATION EXCHANGE (PANTAU KESEHATAN HARIAN & SKRINING AI PRAGI)
  // ===========================================================================

  /// Mengirim data Pantau Kesehatan Harian (Berat Badan, Tinggi Badan, IMT, Keluhan) ke SATUSEHAT (`Observation` LOINC)
  Future<List<String>> syncPantauToSatuSehat({
    String? idPantau,
    String? idPasien,
    required double beratBadan,
    required double tinggiBadan,
    double? imt,
    String? kondisi,
    String? keluhan,
    String? detailKeluhan,
  }) async {
    if (_isBlockedByWidgetTest) return const [];

    try {
      String? resolvedPasienId = idPasien?.trim();
      if (resolvedPasienId == null || resolvedPasienId.isEmpty) {
        final u = await StorageService().getUser();
        resolvedPasienId = u?.id?.toString().trim();
      }
      final pasProfile = await syncPasienToSatuSehat(idPasien: resolvedPasienId);
      if (pasProfile == null) return const [];

      final pracIhs = await _resolveVerifiedSandboxPractitionerIhs();
      final cleanPantauId = (idPantau != null && idPantau.toString().trim().isNotEmpty)
          ? idPantau.toString().trim()
          : 'PTU-${DateTime.now().millisecondsSinceEpoch}';

      final encId = await _ensurePatientEncounter(
        patient: pasProfile,
        localContextKey: 'PANTAU-${pasProfile.ihsNumber}',
        practitionerIhs: pracIhs,
      );
      if (encId == null) return const [];

      final nowStr = _formatFhirUtc(DateTime.now().toUtc());
      final tbMeter = tinggiBadan > 0 ? tinggiBadan / 100.0 : 1.65;
      final computedImt = imt != null && imt > 0
          ? imt
          : (beratBadan > 0
              ? double.parse((beratBadan / (tbMeter * tbMeter)).toStringAsFixed(1))
              : 0.0);

      final notesText = [
        if (kondisi != null && kondisi.isNotEmpty) 'Kondisi: $kondisi',
        if (keluhan != null && keluhan.isNotEmpty) 'Keluhan: $keluhan',
        if (detailKeluhan != null && detailKeluhan.isNotEmpty)
          'Detail: $detailKeluhan',
      ].join(' | ');

      final metrics = <Map<String, dynamic>>[
        if (beratBadan > 0)
          {
            'loinc': '29463-7',
            'display': 'Body weight',
            'value': beratBadan,
            'unit': 'kg',
            'code': 'kg',
          },
        if (tinggiBadan > 0)
          {
            'loinc': '8302-2',
            'display': 'Body height',
            'value': tinggiBadan,
            'unit': 'cm',
            'code': 'cm',
          },
        if (computedImt > 0)
          {
            'loinc': '39156-5',
            'display': 'Body mass index (BMI) [Ratio]',
            'value': computedImt,
            'unit': 'kg/m2',
            'code': 'kg/m2',
          },
      ];

      final createdIds = <String>[];
      for (final m in metrics) {
        final obsPayload = {
          'resourceType': 'Observation',
          'status': 'final',
          'category': [
            {
              'coding': [
                {
                  'system':
                      'http://terminology.hl7.org/CodeSystem/observation-category',
                  'code': 'vital-signs',
                  'display': 'Vital Signs',
                },
              ],
            },
          ],
          'code': {
            'coding': [
              {
                'system': 'http://loinc.org',
                'code': m['loinc'],
                'display': m['display'],
              },
            ],
          },
          'subject': {
            'reference': 'Patient/${pasProfile.ihsNumber}',
            'display': pasProfile.nama ?? 'Pasien GIAT',
          },
          'encounter': {'reference': 'Encounter/$encId'},
          'effectiveDateTime': nowStr,
          'issued': nowStr,
          'performer': [
            {'reference': 'Practitioner/$pracIhs'},
          ],
          'valueQuantity': {
            'value': m['value'],
            'unit': m['unit'],
            'system': 'http://unitsofmeasure.org',
            'code': m['code'],
          },
          if (notesText.isNotEmpty)
            'note': [
              {'text': notesText},
            ],
        };

        try {
          final res = await _fhirRequest('POST', '/Observation', data: obsPayload);
          final oid = _asMap(res?.data)['id']?.toString().trim();
          if (oid != null && oid.isNotEmpty) {
            createdIds.add(oid);
          }
        } catch (e) {
          debugPrint('⚠️ SatuSehat Pantau Observation (${m['loinc']}) notice: $e');
        }
      }

      if (createdIds.isNotEmpty) {
        if (!cleanPantauId.startsWith('local_') && !cleanPantauId.startsWith('PTU-')) {
          try {
            await SupabaseAdminService.instance.executeQuery(
              '''
              UPDATE pantau_kesehatan
              SET satusehat_observation_ids = @ids,
                  satusehat_synced_at = NOW(),
                  updated_at = NOW()
              WHERE TRIM(id) = @pid
              ''',
              {'pid': cleanPantauId, 'ids': createdIds.join(',')},
            );
          } catch (_) {}
        }

        await _recordSyncLog(
          entityType: 'pantau',
          localId: cleanPantauId,
          fhirResourceType: 'Observation',
          satusehatId: createdIds.first,
          status: 'synced',
          httpStatus: 201,
          payloadSummary: {
            'berat_badan': beratBadan,
            'tinggi_badan': tinggiBadan,
            'imt': computedImt,
            'keluhan': keluhan,
            'observation_ids': createdIds,
          },
        );
      }

      return createdIds;
    } catch (e) {
      debugPrint('⚠️ SatuSehat syncPantauToSatuSehat error: $e');
      return const [];
    }
  }

  /// Mengirim hasil Skrining Risiko CKD AI PRAGI ke SATUSEHAT (`Observation`)
  Future<String?> syncPragiSkriningToSatuSehat({
    String? idPragi,
    String? idPasien,
    required String kategoriRisiko,
    double? probabilitasPersen,
    int? skor,
    String? rekomendasi,
  }) async {
    if (_isBlockedByWidgetTest) return null;

    try {
      String? resolvedPasienId = idPasien?.trim();
      if (resolvedPasienId == null || resolvedPasienId.isEmpty) {
        final u = await StorageService().getUser();
        resolvedPasienId = u?.id?.toString().trim();
      }
      final pasProfile = await syncPasienToSatuSehat(idPasien: resolvedPasienId);
      if (pasProfile == null) return null;

      final pracIhs = await _resolveVerifiedSandboxPractitionerIhs();
      final cleanPragiId = (idPragi != null && idPragi.trim().isNotEmpty)
          ? idPragi.trim()
          : 'PRAGI-${DateTime.now().millisecondsSinceEpoch}';

      final encId = await _ensurePatientEncounter(
        patient: pasProfile,
        localContextKey: 'PRAGI-${pasProfile.ihsNumber}',
        practitionerIhs: pracIhs,
      );
      if (encId == null) return null;

      final nowStr = _formatFhirUtc(DateTime.now().toUtc());
      final numericVal = probabilitasPersen ?? (skor?.toDouble() ?? 0.0);

      final obsPayload = {
        'resourceType': 'Observation',
        'status': 'final',
        'category': [
          {
            'coding': [
              {
                'system':
                    'http://terminology.hl7.org/CodeSystem/observation-category',
                'code': 'survey',
                'display': 'Survey',
              },
            ],
          },
        ],
        'code': {
          'coding': [
            {
              'system': 'http://loinc.org',
              'code': '89555-7',
              'display': 'Chronic kidney disease risk score',
            },
          ],
          'text': 'Skrining Risiko Penyakit Ginjal Kronis (AI PRAGI GIAT)',
        },
        'subject': {
          'reference': 'Patient/${pasProfile.ihsNumber}',
          'display': pasProfile.nama ?? 'Pasien GIAT',
        },
        'encounter': {'reference': 'Encounter/$encId'},
        'effectiveDateTime': nowStr,
        'issued': nowStr,
        'performer': [
          {'reference': 'Practitioner/$pracIhs'},
        ],
        'valueQuantity': {
          'value': double.parse(numericVal.toStringAsFixed(2)),
          'unit': '%',
          'system': 'http://unitsofmeasure.org',
          'code': '%',
        },
        'note': [
          {
            'text':
                'Kategori Risiko CKD: $kategoriRisiko${rekomendasi != null ? " | Rekomendasi: $rekomendasi" : ""}',
          },
        ],
      };

      final res = await _fhirRequest('POST', '/Observation', data: obsPayload);
      final oid = _asMap(res?.data)['id']?.toString().trim();

      if (oid != null && oid.isNotEmpty) {
        if (!cleanPragiId.startsWith('PRAGI-')) {
          try {
            await SupabaseAdminService.instance.executeQuery(
              '''
              UPDATE pragi_skrining
              SET satusehat_observation_id = @oid,
                  satusehat_synced_at = NOW(),
                  updated_at = NOW()
              WHERE TRIM(id) = @pid
              ''',
              {'pid': cleanPragiId, 'oid': oid},
            );
          } catch (_) {}
        }

        await _recordSyncLog(
          entityType: 'pragi',
          localId: cleanPragiId,
          fhirResourceType: 'Observation',
          satusehatId: oid,
          status: 'synced',
          httpStatus: res?.statusCode,
          payloadSummary: {
            'kategori_risiko': kategoriRisiko,
            'probabilitas_persen': numericVal,
            'rekomendasi': rekomendasi,
          },
        );
      }

      return oid;
    } catch (e) {
      debugPrint('⚠️ SatuSehat syncPragiSkriningToSatuSehat notice: $e');
      return null;
    }
  }

  // ===========================================================================
  // 9. MEDICATION, MEDICATION REQUEST & DISPENSE (KFA OBAT, RESEP & APOTEK)
  // ===========================================================================

  /// Pemetaan cerdas Obat GIAT ke Kode KFA (Kamus Farmasi & Alat Kesehatan) Kemenkes RI
  Map<String, String> _resolveKfaCode(String rawName) {
    final lower = rawName.toLowerCase();
    if (lower.contains('candesartan') && lower.contains('16')) {
      return {'code': '93001020', 'display': 'Candesartan Cilexetil 16 mg Tablet', 'form': 'TAB'};
    }
    if (lower.contains('candesartan')) {
      return {'code': '93001019', 'display': 'Candesartan Cilexetil 8 mg Tablet', 'form': 'TAB'};
    }
    if (lower.contains('amlodipine') && lower.contains('10')) {
      return {'code': '93000585', 'display': 'Amlodipine 10 mg Tablet', 'form': 'TAB'};
    }
    if (lower.contains('amlodipine')) {
      return {'code': '93000584', 'display': 'Amlodipine 5 mg Tablet', 'form': 'TAB'};
    }
    if (lower.contains('furosemide')) {
      return {'code': '93000357', 'display': 'Furosemide 40 mg Tablet', 'form': 'TAB'};
    }
    if (lower.contains('ketosteril') || lower.contains('ketoacid')) {
      return {'code': '93001241', 'display': 'Ketoanalogues / Essential Amino Acids 600 mg Film-Coated Tablet', 'form': 'TAB'};
    }
    if (lower.contains('calos') || lower.contains('kalsium') || lower.contains('calcium') || lower.contains('caco3')) {
      return {'code': '93000412', 'display': 'Calcium Carbonate 500 mg Chewable Tablet', 'form': 'TAB'};
    }
    if (lower.contains('captopril')) {
      return {'code': '93000219', 'display': 'Captopril 25 mg Tablet', 'form': 'TAB'};
    }
    if (lower.contains('valsartan')) {
      return {'code': '93001105', 'display': 'Valsartan 80 mg Film-Coated Tablet', 'form': 'TAB'};
    }
    if (lower.contains('irbesartan')) {
      return {'code': '93001088', 'display': 'Irbesartan 150 mg Tablet', 'form': 'TAB'};
    }
    if (lower.contains('spironolactone')) {
      return {'code': '93000622', 'display': 'Spironolactone 25 mg Tablet', 'form': 'TAB'};
    }
    if (lower.contains('bikarbonat') || lower.contains('bicnat')) {
      return {'code': '93000781', 'display': 'Sodium Bicarbonate 500 mg Tablet', 'form': 'TAB'};
    }
    if (lower.contains('allopurinol')) {
      return {'code': '93000148', 'display': 'Allopurinol 100 mg Tablet', 'form': 'TAB'};
    }
    if (lower.contains('hemobion') || lower.contains('asam folat') || lower.contains('ferrous')) {
      return {'code': '93000894', 'display': 'Ferrous Fumarate + Folic Acid + Vitamin B12 Capsule', 'form': 'CAP'};
    }
    if (lower.contains('renalvit') || lower.contains('vitamin')) {
      return {'code': '93000912', 'display': 'Multivitamin Renal Support Tablet', 'form': 'TAB'};
    }
    return {'code': '93001019', 'display': rawName.trim().isNotEmpty ? rawName.trim() : 'Obat Terapi Ginjal', 'form': 'TAB'};
  }

  /// Mendaftarkan / menyinkronkan Obat GIAT ke resource `Medication` SATUSEHAT (KFA)
  Future<String?> syncObatToSatuSehat({
    String? idObat,
    required String namaObat,
  }) async {
    if (_isBlockedByWidgetTest) return null;

    final cleanName = namaObat.trim().isNotEmpty ? namaObat.trim() : 'Obat Ginjal GIAT';
    final kfa = _resolveKfaCode(cleanName);
    final localKey = (idObat != null && idObat.trim().isNotEmpty)
        ? idObat.trim()
        : 'KFA-${kfa['code']}-${cleanName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';

    if (idObat != null && idObat.trim().isNotEmpty) {
      try {
        final rows = await SupabaseAdminService.instance.executeQuery(
          'SELECT satusehat_medication_id FROM obat WHERE TRIM(id_obat) = @oid LIMIT 1',
          {'oid': idObat.trim()},
        );
        if (rows.isNotEmpty) {
          final ex = rows.first['satusehat_medication_id']?.toString().trim();
          if (ex != null && ex.isNotEmpty) return ex;
        }
      } catch (_) {}
    }

    final syncedMed = await _findSyncedId(
      entityType: 'obat',
      localId: localKey,
      fhirResourceType: 'Medication',
    );
    if (syncedMed != null && syncedMed.isNotEmpty) return syncedMed;

    Map<String, dynamic> buildMedPayload(String kfaCode, String kfaDisplay) => {
          'resourceType': 'Medication',
          'meta': {
            'profile': [
              'https://fhir.kemkes.go.id/r4/StructureDefinition/Medication',
            ],
          },
          'identifier': [
            {
              'system': 'http://sys-ids.kemkes.go.id/medication/$organizationId',
              'value':
                  'GIAT-MED-$localKey-${DateTime.now().millisecondsSinceEpoch}',
            },
          ],
          'code': {
            'coding': [
              {
                'system': 'http://sys-ids.kemkes.go.id/kfa',
                'code': kfaCode,
                'display': kfaDisplay,
              },
            ],
            'text': cleanName,
          },
          'status': 'active',
          'extension': [
            {
              'url':
                  'https://fhir.kemkes.go.id/r4/StructureDefinition/MedicationType',
              'valueCodeableConcept': {
                'coding': [
                  {
                    'system':
                        'http://terminology.kemkes.go.id/CodeSystem/medication-type',
                    'code': 'NC',
                    'display': 'Non-compound',
                  },
                ],
              },
            },
          ],
        };

    try {
      String usedKfaCode = kfa['code'] ?? '93001019';
      Response<dynamic>? res;
      try {
        res = await _fhirRequest(
          'POST',
          '/Medication',
          data: buildMedPayload(usedKfaCode, kfa['display'] ?? cleanName),
        );
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 400 && usedKfaCode != '93001019') {
          usedKfaCode = '93001019';
          res = await _fhirRequest(
            'POST',
            '/Medication',
            data: buildMedPayload(
              '93001019',
              'Candesartan Cilexetil 8 mg Tablet',
            ),
          );
        } else {
          rethrow;
        }
      }
      final medId = _asMap(res?.data)['id']?.toString().trim();
      if (medId != null && medId.isNotEmpty) {
        if (idObat != null && idObat.trim().isNotEmpty) {
          try {
            await SupabaseAdminService.instance.executeQuery(
              '''
              UPDATE obat
              SET kfa_code = @kfa,
                  satusehat_medication_id = @mid,
                  updated_at = NOW()
              WHERE TRIM(id_obat) = @oid
              ''',
              {'oid': idObat.trim(), 'kfa': usedKfaCode, 'mid': medId},
            );
          } catch (_) {}
        }

        await _recordSyncLog(
          entityType: 'obat',
          localId: localKey,
          fhirResourceType: 'Medication',
          satusehatId: medId,
          status: 'synced',
          httpStatus: res?.statusCode,
          payloadSummary: {'nama_obat': cleanName, 'kfa_code': usedKfaCode},
        );
        return medId;
      }
    } catch (e) {
      debugPrint('⚠️ SatuSehat syncObatToSatuSehat($cleanName) notice: $e');
    }
    return null;
  }

  /// Mengirim Resep Elektronik Dokter GIAT ke SATUSEHAT (`MedicationRequest` + `Condition` + `Encounter`)
  Future<List<String>> syncResepToSatuSehat({
    required String idResep,
    String? noResep,
    String? idKonsultasi,
    String? idPasien,
    String? idDokter,
    String? diagnosis,
    List<Map<String, dynamic>>? items,
  }) async {
    if (_isBlockedByWidgetTest || idResep.trim().isEmpty) return const [];

    try {
      final cleanRxId = idResep.trim();
      Map<String, dynamic> rxRow = <String, dynamic>{};

      try {
        final rows = await SupabaseAdminService.instance.executeQuery(
          '''
          SELECT TRIM(r.id) AS id, r.no_resep, TRIM(r.id_konsultasi) AS id_konsultasi,
                 TRIM(r.id_dokter) AS id_dokter, TRIM(r.id_pasien) AS id_pasien,
                 r.diagnosis, r.satusehat_medication_request_ids,
                 p.nama AS nama_pasien, d.nama AS nama_dokter
          FROM resep r
          LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(r.id_pasien)
          LEFT JOIN dokter d ON TRIM(d.id_dokter) = TRIM(r.id_dokter)
          WHERE TRIM(r.id) = @rid OR TRIM(r.no_resep) = @rid
          LIMIT 1
          ''',
          {'rid': cleanRxId},
        );
        if (rows.isNotEmpty) rxRow = rows.first;
      } catch (_) {}

      final existingReqIds = rxRow['satusehat_medication_request_ids']?.toString().trim();
      if (existingReqIds != null && existingReqIds.isNotEmpty && items == null) {
        return existingReqIds.split(',').where((s) => s.isNotEmpty).toList();
      }

      final resolvedRxId = rxRow['id']?.toString().trim() ?? cleanRxId;
      final resolvedNoResep = noResep ?? rxRow['no_resep']?.toString() ?? 'RXP-$resolvedRxId';
      final pasId = (idPasien ?? rxRow['id_pasien'])?.toString().trim() ?? '';
      final docId = (idDokter ?? rxRow['id_dokter'])?.toString().trim() ?? '';
      final konsId = (idKonsultasi ?? rxRow['id_konsultasi'])?.toString().trim();
      final diag = (diagnosis ?? rxRow['diagnosis'] ?? 'Pemeriksaan Protokol Ginjal').toString();

      final pasProfile = await syncPasienToSatuSehat(idPasien: pasId);
      if (pasProfile == null) return const [];
      final pracIhs = await syncDokterToSatuSehat(idDokter: docId) ??
          await _resolveVerifiedSandboxPractitionerIhs();

      String? encId;
      String? condId;
      if (konsId != null && konsId.isNotEmpty) {
        final konsSync = await syncKonsultasiToSatuSehat(
          idKonsultasi: konsId,
          idPasien: pasId,
          idDokter: docId,
          keluhanAtauDiagnosis: diag,
        );
        encId = konsSync['encounterId'];
        condId = konsSync['conditionId'];
      }
      encId ??= await _ensurePatientEncounter(
        patient: pasProfile,
        localContextKey: 'RX-$resolvedRxId',
        practitionerIhs: pracIhs,
      );
      if (encId == null) return const [];

      List<Map<String, dynamic>> rxItems = items ?? [];
      if (rxItems.isEmpty) {
        try {
          rxItems = await SupabaseAdminService.instance.executeQuery(
            '''
            SELECT TRIM(id) AS id, nama_obat, dosis, aturan_pakai, waktu_penggunaan, jumlah, catatan_khusus
            FROM resep_item
            WHERE TRIM(id_resep) = @rid
            ORDER BY created_at ASC
            ''',
            {'rid': resolvedRxId},
          );
        } catch (_) {}
      }

      final authoredOn = _formatFhirUtc(DateTime.now().toUtc());
      final pasName = rxRow['nama_pasien']?.toString() ?? pasProfile.nama ?? 'Pasien GIAT';
      final docName = rxRow['nama_dokter']?.toString() ?? 'Dokter Spesialis GIAT';
      final createdIds = <String>[];

      for (int i = 0; i < rxItems.length; i++) {
        final item = rxItems[i];
        final medName = (item['nama_obat'] ?? item['medicineName'] ?? item['name'] ?? 'Obat Ginjal').toString().trim();
        if (medName.isEmpty) continue;

        final medId = await syncObatToSatuSehat(namaObat: medName);
        if (medId == null) continue;

        final kfa = _resolveKfaCode(medName);
        final qty = int.tryParse((item['jumlah'] ?? item['quantity'] ?? '30').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 30;
        final dosageParts = [
          if ((item['dosis'] ?? '').toString().trim().isNotEmpty) item['dosis'].toString().trim(),
          if ((item['aturan_pakai'] ?? '').toString().trim().isNotEmpty) item['aturan_pakai'].toString().trim(),
          if ((item['waktu_penggunaan'] ?? '').toString().trim().isNotEmpty) item['waktu_penggunaan'].toString().trim(),
          if ((item['catatan_khusus'] ?? '').toString().trim().isNotEmpty) item['catatan_khusus'].toString().trim(),
        ];
        final dosageText = dosageParts.isNotEmpty
            ? dosageParts.join(' - ')
            : '1x sehari 1 tablet sesudah makan';

        final reqPayload = {
          'resourceType': 'MedicationRequest',
          'identifier': [
            {
              'system': 'http://sys-ids.kemkes.go.id/prescription/$organizationId',
              'use': 'official',
              'value': '$resolvedNoResep-${DateTime.now().millisecondsSinceEpoch}',
            },
            {
              'system':
                  'http://sys-ids.kemkes.go.id/prescription-item/$organizationId',
              'use': 'official',
              'value': '$resolvedNoResep-${i + 1}-${DateTime.now().millisecondsSinceEpoch}',
            },
          ],
          'status': 'completed',
          'intent': 'order',
          'category': [
            {
              'coding': [
                {
                  'system':
                      'http://terminology.hl7.org/CodeSystem/medicationrequest-category',
                  'code': 'outpatient',
                  'display': 'Outpatient',
                },
              ],
            },
          ],
          'priority': 'routine',
          'medicationReference': {
            'reference': 'Medication/$medId',
            'display': medName,
          },
          'subject': {
            'reference': 'Patient/${pasProfile.ihsNumber}',
            'display': pasName,
          },
          'encounter': {'reference': 'Encounter/$encId'},
          'authoredOn': authoredOn,
          'requester': {
            'reference': 'Practitioner/$pracIhs',
            'display': docName,
          },
          if (condId != null && condId.isNotEmpty)
            'reasonReference': [
              {'reference': 'Condition/$condId'},
            ],
          'dosageInstruction': [
            {
              'sequence': 1,
              'text': dosageText,
            },
          ],
          'dispenseRequest': {
            'quantity': {
              'value': qty > 0 ? qty : 30,
              'unit': kfa['form'] ?? 'TAB',
              'system':
                  'http://terminology.hl7.org/CodeSystem/v3-orderableDrugForm',
              'code': kfa['form'] ?? 'TAB',
            },
            'performer': {'reference': 'Organization/$organizationId'},
          },
        };

        try {
          final res =
              await _fhirRequest('POST', '/MedicationRequest', data: reqPayload);
          final reqId = _asMap(res?.data)['id']?.toString().trim();
          if (reqId != null && reqId.isNotEmpty) {
            createdIds.add(reqId);
          }
        } catch (e) {
          debugPrint('⚠️ SatuSehat MedicationRequest ($medName) notice: $e');
        }
      }

      if (createdIds.isNotEmpty) {
        try {
          await SupabaseAdminService.instance.executeQuery(
            '''
            UPDATE resep
            SET satusehat_medication_request_ids = @rids,
                satusehat_condition_id = COALESCE(NULLIF(@cid, ''), satusehat_condition_id),
                satusehat_synced_at = NOW(),
                updated_at = NOW()
            WHERE TRIM(id) = @rid
            ''',
            {
              'rid': resolvedRxId,
              'rids': createdIds.join(','),
              'cid': condId ?? '',
            },
          );
        } catch (_) {}

        await _recordSyncLog(
          entityType: 'resep',
          localId: resolvedRxId,
          fhirResourceType: 'MedicationRequest',
          satusehatId: createdIds.first,
          status: 'synced',
          httpStatus: 201,
          payloadSummary: {
            'no_resep': resolvedNoResep,
            'diagnosis': diag,
            'medication_request_ids': createdIds,
          },
        );
      }

      return createdIds;
    } catch (e) {
      debugPrint('⚠️ SatuSehat syncResepToSatuSehat error: $e');
      return const [];
    }
  }

  /// Mengirim Penyerahan Obat Apotek (`MedicationDispense`) ke SATUSEHAT
  Future<List<String>> syncPesananDispenseToSatuSehat({
    required String idPesananOrNo,
  }) async {
    if (_isBlockedByWidgetTest || idPesananOrNo.trim().isEmpty) return const [];

    try {
      final cleanOrd = idPesananOrNo.trim();
      final ordRows = await SupabaseAdminService.instance.executeQuery(
        '''
        SELECT TRIM(po.id) AS id, po.no_pesanan, TRIM(po.id_pasien) AS id_pasien,
               TRIM(po.id_apotek) AS id_apotek, TRIM(po.id_resep) AS id_resep,
               po.alamat_pengiriman, po.nama_penerima, po.no_hp_penerima,
               po.satusehat_medication_dispense_ids,
               p.nama AS nama_pasien
        FROM pesanan_obat po
        LEFT JOIN pasien p ON TRIM(p.id_pasien) = TRIM(po.id_pasien)
        WHERE TRIM(po.id) = @ord OR TRIM(po.no_pesanan) = @ord
        LIMIT 1
        ''',
        {'ord': cleanOrd},
      );
      if (ordRows.isEmpty) return const [];

      final ord = ordRows.first;
      final existingDisp = ord['satusehat_medication_dispense_ids']?.toString().trim();
      if (existingDisp != null && existingDisp.isNotEmpty) {
        return existingDisp.split(',').where((s) => s.isNotEmpty).toList();
      }

      final ordId = ord['id'].toString().trim();
      final noPesanan = ord['no_pesanan']?.toString() ?? 'ORD-$ordId';
      final pasId = ord['id_pasien']?.toString().trim() ?? '';
      final aptId = ord['id_apotek']?.toString().trim() ?? '';
      final rxId = ord['id_resep']?.toString().trim();

      final pasProfile = await syncPasienToSatuSehat(
        idPasien: pasId,
        alamat: ord['alamat_pengiriman']?.toString(),
        noHp: ord['no_hp_penerima']?.toString(),
      );
      if (pasProfile == null) return const [];

      final aptSync = aptId.isNotEmpty
          ? await syncApotekToSatuSehat(idApotek: aptId)
          : <String, String?>{};
      final locId = aptSync['locationId'] ?? await ensureDefaultTelemedLocation();
      if (locId == null) return const [];

      final pracIhs = await _resolveVerifiedSandboxPractitionerIhs();

      List<String> reqIds = const [];
      String? encId;
      if (rxId != null && rxId.isNotEmpty) {
        reqIds = await syncResepToSatuSehat(idResep: rxId);
        try {
          final rRows = await SupabaseAdminService.instance.executeQuery(
            '''
            SELECT k.satusehat_encounter_id
            FROM resep r
            LEFT JOIN konsultasi k ON TRIM(k.id) = TRIM(r.id_konsultasi)
            WHERE TRIM(r.id) = @rid
            LIMIT 1
            ''',
            {'rid': rxId},
          );
          if (rRows.isNotEmpty) {
            encId = rRows.first['satusehat_encounter_id']?.toString().trim();
          }
        } catch (_) {}
      }
      encId = (encId != null && encId.isNotEmpty)
          ? encId
          : await _ensurePatientEncounter(
              patient: pasProfile,
              localContextKey: 'DISP-$ordId',
              practitionerIhs: pracIhs,
              locationId: locId,
            );
      if (encId == null) return const [];

      final itemRows = await SupabaseAdminService.instance.executeQuery(
        '''
        SELECT TRIM(id_obat) AS id_obat, nama_obat, jumlah
        FROM pesanan_obat_items
        WHERE TRIM(id_pesanan) = @oid
        ORDER BY created_at ASC
        ''',
        {'oid': ordId},
      );

      final nowUtc = DateTime.now().toUtc();
      final prepStr = _formatFhirUtc(nowUtc.subtract(const Duration(minutes: 10)));
      final handStr = _formatFhirUtc(nowUtc);
      final pasName = ord['nama_pasien']?.toString() ?? pasProfile.nama ?? 'Pasien GIAT';
      final dispenseIds = <String>[];

      for (int i = 0; i < itemRows.length; i++) {
        final it = itemRows[i];
        final medName = (it['nama_obat'] ?? 'Obat Ginjal').toString().trim();
        final medId = await syncObatToSatuSehat(
          idObat: it['id_obat']?.toString(),
          namaObat: medName,
        );
        if (medId == null) continue;

        final kfa = _resolveKfaCode(medName);
        final qty = int.tryParse(it['jumlah']?.toString() ?? '1') ?? 1;
        String? authReqId = i < reqIds.length ? reqIds[i] : (reqIds.isNotEmpty ? reqIds.first : null);

        // Jika pembelian umum tanpa resep dokter, buatkan MedicationRequest farmasi terlebih dahulu
        if (authReqId == null || authReqId.isEmpty) {
          try {
            final otcReq = await _fhirRequest('POST', '/MedicationRequest', data: {
              'resourceType': 'MedicationRequest',
              'identifier': [
                {
                  'system': 'http://sys-ids.kemkes.go.id/prescription/$organizationId',
                  'use': 'official',
                  'value': 'OTC-$noPesanan-${DateTime.now().millisecondsSinceEpoch}',
                },
                {
                  'system': 'http://sys-ids.kemkes.go.id/prescription-item/$organizationId',
                  'use': 'official',
                  'value': 'OTC-$noPesanan-${i + 1}-${DateTime.now().millisecondsSinceEpoch}',
                },
              ],
              'status': 'completed',
              'intent': 'order',
              'category': [
                {
                  'coding': [
                    {
                      'system': 'http://terminology.hl7.org/CodeSystem/medicationrequest-category',
                      'code': 'outpatient',
                      'display': 'Outpatient',
                    },
                  ],
                },
              ],
              'priority': 'routine',
              'medicationReference': {'reference': 'Medication/$medId', 'display': medName},
              'subject': {'reference': 'Patient/${pasProfile.ihsNumber}', 'display': pasName},
              'encounter': {'reference': 'Encounter/$encId'},
              'authoredOn': prepStr,
              'requester': {'reference': 'Practitioner/$pracIhs', 'display': 'Apoteker Penanggung Jawab GIAT'},
              'dosageInstruction': [
                {'sequence': 1, 'text': 'Sesuai aturan pakai kemasan'},
              ],
              'dispenseRequest': {
                'quantity': {
                  'value': qty > 0 ? qty : 1,
                  'unit': kfa['form'] ?? 'TAB',
                  'system': 'http://terminology.hl7.org/CodeSystem/v3-orderableDrugForm',
                  'code': kfa['form'] ?? 'TAB',
                },
                'performer': {'reference': 'Organization/$organizationId'},
              },
            });
            authReqId = _asMap(otcReq?.data)['id']?.toString().trim();
          } catch (_) {}
        }

        final dispPayload = {
          'resourceType': 'MedicationDispense',
          'identifier': [
            {
              'system': 'http://sys-ids.kemkes.go.id/prescription/$organizationId',
              'use': 'official',
              'value': '$noPesanan-${DateTime.now().millisecondsSinceEpoch}',
            },
            {
              'system':
                  'http://sys-ids.kemkes.go.id/prescription-item/$organizationId',
              'use': 'official',
              'value': '$noPesanan-${i + 1}-${DateTime.now().millisecondsSinceEpoch}',
            },
          ],
          'status': 'completed',
          'category': {
            'coding': [
              {
                'system':
                    'http://terminology.hl7.org/fhir/CodeSystem/medicationdispense-category',
                'code': 'outpatient',
                'display': 'Outpatient',
              },
            ],
          },
          'medicationReference': {
            'reference': 'Medication/$medId',
            'display': medName,
          },
          'subject': {
            'reference': 'Patient/${pasProfile.ihsNumber}',
            'display': pasName,
          },
          'context': {'reference': 'Encounter/$encId'},
          'performer': [
            {
              'actor': {'reference': 'Practitioner/$pracIhs'},
            },
          ],
          'location': {'reference': 'Location/$locId'},
          if (authReqId != null && authReqId.isNotEmpty)
            'authorizingPrescription': [
              {'reference': 'MedicationRequest/$authReqId'},
            ],
          'quantity': {
            'value': qty > 0 ? qty : 1,
            'system':
                'http://terminology.hl7.org/CodeSystem/v3-orderableDrugForm',
            'code': kfa['form'] ?? 'TAB',
          },
          'daysSupply': {
            'value': 30,
            'unit': 'Day',
            'system': 'http://unitsofmeasure.org',
            'code': 'd',
          },
          'whenPrepared': prepStr,
          'whenHandedOver': handStr,
          'dosageInstruction': [
            {
              'sequence': 1,
              'text': 'Sesuai petunjuk dokter / apoteker GIAT',
            },
          ],
        };

        try {
          final dispRes =
              await _fhirRequest('POST', '/MedicationDispense', data: dispPayload);
          final did = _asMap(dispRes?.data)['id']?.toString().trim();
          if (did != null && did.isNotEmpty) {
            dispenseIds.add(did);
          }
        } catch (e) {
          debugPrint('⚠️ SatuSehat MedicationDispense ($medName) notice: $e');
        }
      }

      if (dispenseIds.isNotEmpty) {
        try {
          await SupabaseAdminService.instance.executeQuery(
            '''
            UPDATE pesanan_obat
            SET satusehat_medication_dispense_ids = @dids,
                satusehat_synced_at = NOW(),
                updated_at = NOW()
            WHERE TRIM(id) = @oid
            ''',
            {'oid': ordId, 'dids': dispenseIds.join(',')},
          );
        } catch (_) {}

        await _recordSyncLog(
          entityType: 'dispense',
          localId: ordId,
          fhirResourceType: 'MedicationDispense',
          satusehatId: dispenseIds.first,
          status: 'synced',
          httpStatus: 201,
          payloadSummary: {
            'no_pesanan': noPesanan,
            'alamat_pengiriman': ord['alamat_pengiriman'],
            'medication_dispense_ids': dispenseIds,
          },
        );
      }

      return dispenseIds;
    } catch (e) {
      debugPrint('⚠️ SatuSehat syncPesananDispenseToSatuSehat error: $e');
      return const [];
    }
  }

  // ===========================================================================
  // 10. AUTO-SYNC USER SESSION & FULL GIAT DATABASE EXCHANGE
  // ===========================================================================

  /// Menjalankan sinkronisasi otomatis berdasarkan role akun yang baru login / aktif
  void triggerBackgroundUserSync(UserModel? user) {
    if (_isBlockedByWidgetTest || user == null) return;
    final role = user.role.toLowerCase().trim();
    final uid = user.id?.toString().trim() ?? '';
    if (uid.isEmpty) return;

    if (role == 'pasien') {
      unawaited(
        syncPasienToSatuSehat(
          idPasien: uid,
          nama: user.nama,
          nik: user.nik,
          alamat: user.alamat,
          noHp: user.noHp,
          email: user.email,
          jenisKelamin: user.jenisKelamin,
          tanggalLahir: user.tanggalLahir,
          golonganDarah: user.golonganDarah,
          existingIhsNumber: user.satusehatIhsNumber,
        ),
      );
    } else if (role == 'dokter') {
      unawaited(
        syncDokterToSatuSehat(
          idDokter: uid,
          nama: user.nama,
          nik: user.nik,
          noStr: user.noStr,
          noSip: user.noSip,
          spesialisasi: user.spesialisasi,
          instansi: user.instansi,
        ),
      );
    } else if (role == 'apotek' || role == 'apoteker') {
      unawaited(
        syncApotekToSatuSehat(
          idApotek: uid,
          namaApotek: user.nama,
          alamat: user.alamat,
          noHp: user.noHp,
          email: user.email,
          noSipaSia: user.noSip,
        ),
      );
    }
  }

  /// Menyinkronkan seluruh data eksisting GIAT di Supabase ke SATUSEHAT Sandbox secara menyeluruh
  Future<Map<String, int>> syncAllExistingGiatData() async {
    if (_isBlockedByWidgetTest) return const {};
    final stats = <String, int>{
      'pasien': 0,
      'dokter': 0,
      'apotek': 0,
      'obat': 0,
      'konsultasi': 0,
      'resep': 0,
      'dispense': 0,
      'pantau': 0,
      'pragi': 0,
    };

    await ensureDefaultTelemedLocation();

    // 1. Pasien
    final pasRows = await SupabaseAdminService.instance.executeQuery(
      'SELECT TRIM(id_pasien) AS id FROM pasien WHERE satusehat_ihs_number IS NULL OR satusehat_ihs_number = \'\'',
    );
    for (final r in pasRows) {
      final p = await syncPasienToSatuSehat(idPasien: r['id']?.toString());
      if (p != null) stats['pasien'] = (stats['pasien'] ?? 0) + 1;
    }

    // 2. Dokter
    final docRows = await SupabaseAdminService.instance.executeQuery(
      'SELECT TRIM(id_dokter) AS id FROM dokter WHERE satusehat_ihs_number IS NULL OR satusehat_ihs_number = \'\'',
    );
    for (final r in docRows) {
      final ihs = await syncDokterToSatuSehat(idDokter: r['id']?.toString());
      if (ihs != null) stats['dokter'] = (stats['dokter'] ?? 0) + 1;
    }

    // 3. Apotek
    final aptRows = await SupabaseAdminService.instance.executeQuery(
      'SELECT TRIM(id_apotek) AS id FROM apotek WHERE satusehat_org_id IS NULL OR satusehat_location_id IS NULL',
    );
    for (final r in aptRows) {
      final res = await syncApotekToSatuSehat(idApotek: r['id']?.toString());
      if (res['orgId'] != null || res['locationId'] != null) {
        stats['apotek'] = (stats['apotek'] ?? 0) + 1;
      }
    }

    // 4. Katalog Obat
    final obatRows = await SupabaseAdminService.instance.executeQuery(
      'SELECT TRIM(id_obat) AS id_obat, nama_obat FROM obat WHERE satusehat_medication_id IS NULL LIMIT 25',
    );
    for (final r in obatRows) {
      final mid = await syncObatToSatuSehat(
        idObat: r['id_obat']?.toString(),
        namaObat: (r['nama_obat'] ?? 'Obat Ginjal').toString(),
      );
      if (mid != null) stats['obat'] = (stats['obat'] ?? 0) + 1;
    }

    // 5. Konsultasi
    final konsRows = await SupabaseAdminService.instance.executeQuery(
      'SELECT TRIM(id) AS id FROM konsultasi WHERE satusehat_encounter_id IS NULL ORDER BY created_at DESC LIMIT 15',
    );
    for (final r in konsRows) {
      final res = await syncKonsultasiToSatuSehat(
        idKonsultasi: r['id'].toString(),
      );
      if (res['encounterId'] != null) {
        stats['konsultasi'] = (stats['konsultasi'] ?? 0) + 1;
      }
    }

    // 6. Resep Dokter
    final rxRows = await SupabaseAdminService.instance.executeQuery(
      'SELECT TRIM(id) AS id FROM resep WHERE satusehat_medication_request_ids IS NULL ORDER BY created_at DESC LIMIT 15',
    );
    for (final r in rxRows) {
      final reqs = await syncResepToSatuSehat(idResep: r['id'].toString());
      if (reqs.isNotEmpty) stats['resep'] = (stats['resep'] ?? 0) + 1;
    }

    // 7. Penyerahan Pesanan Obat Lunas / Selesai
    final dispRows = await SupabaseAdminService.instance.executeQuery(
      '''
      SELECT TRIM(id) AS id FROM pesanan_obat
      WHERE satusehat_medication_dispense_ids IS NULL
        AND LOWER(TRIM(COALESCE(status_pembayaran, ''))) = 'lunas'
      ORDER BY created_at DESC LIMIT 10
      ''',
    );
    for (final r in dispRows) {
      final disps = await syncPesananDispenseToSatuSehat(
        idPesananOrNo: r['id'].toString(),
      );
      if (disps.isNotEmpty) stats['dispense'] = (stats['dispense'] ?? 0) + 1;
    }

    // 8. Pantau Kesehatan
    final ptuRows = await SupabaseAdminService.instance.executeQuery(
      '''
      SELECT TRIM(id) AS id, TRIM(id_pasien) AS id_pasien,
             berat_badan, tinggi_badan, bmi, kondisi, keluhan, detail_keluhan
      FROM pantau_kesehatan
      WHERE satusehat_observation_ids IS NULL
      ORDER BY created_at DESC LIMIT 10
      ''',
    );
    for (final r in ptuRows) {
      final obs = await syncPantauToSatuSehat(
        idPantau: r['id']?.toString(),
        idPasien: r['id_pasien']?.toString(),
        beratBadan: double.tryParse(r['berat_badan']?.toString() ?? '0') ?? 0,
        tinggiBadan: double.tryParse(r['tinggi_badan']?.toString() ?? '0') ?? 0,
        imt: double.tryParse(r['bmi']?.toString() ?? '0'),
        kondisi: r['kondisi']?.toString(),
        keluhan: r['keluhan']?.toString(),
        detailKeluhan: r['detail_keluhan']?.toString(),
      );
      if (obs.isNotEmpty) stats['pantau'] = (stats['pantau'] ?? 0) + 1;
    }

    // 9. PRAGI Skrining
    final pragiRows = await SupabaseAdminService.instance.executeQuery(
      '''
      SELECT TRIM(id) AS id, TRIM(id_pasien) AS id_pasien,
             total_skor, kategori_risiko, rekomendasi
      FROM pragi_skrining
      WHERE satusehat_observation_id IS NULL
      ORDER BY created_at DESC LIMIT 10
      ''',
    );
    for (final r in pragiRows) {
      final oid = await syncPragiSkriningToSatuSehat(
        idPragi: r['id']?.toString(),
        idPasien: r['id_pasien']?.toString(),
        kategoriRisiko: (r['kategori_risiko'] ?? 'rendah').toString(),
        skor: int.tryParse(r['total_skor']?.toString() ?? '0'),
        rekomendasi: r['rekomendasi']?.toString(),
      );
      if (oid != null) stats['pragi'] = (stats['pragi'] ?? 0) + 1;
    }

    return stats;
  }
}
