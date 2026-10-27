import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Enum zona waktu Indonesia: WIB (UTC+7), WITA (UTC+8), WIT (UTC+9)
enum IndonesianTimeZone {
  wib(name: 'WIB', fullName: 'Waktu Indonesia Barat', offsetHours: 7),
  wita(name: 'WITA', fullName: 'Waktu Indonesia Tengah', offsetHours: 8),
  wit(name: 'WIT', fullName: 'Waktu Indonesia Timur', offsetHours: 9);

  final String name;
  final String fullName;
  final int offsetHours;

  const IndonesianTimeZone({
    required this.name,
    required this.fullName,
    required this.offsetHours,
  });

  Duration get offset => Duration(hours: offsetHours);

  static IndonesianTimeZone fromName(String? name) {
    if (name == null) return IndonesianTimeZone.wib;
    final upper = name.toUpperCase().trim();
    if (upper == 'WITA') return IndonesianTimeZone.wita;
    if (upper == 'WIT') return IndonesianTimeZone.wit;
    return IndonesianTimeZone.wib;
  }
}

/// Utilitas sentralisasi waktu Indonesia (WIB, WITA, WIT)
/// Otomatis mendeteksi zona waktu pengguna dari:
/// 1. Preferensi manual tersimpan di SharedPreferences
/// 2. Zona waktu perangkat (device local offset: +7 WIB, +8 WITA, +9 WIT)
/// 3. Alamat / lokasi profil pengguna (Provinsi / Kota)
class TimeUtils {
  static const String _prefKey = 'giat_user_timezone';
  static IndonesianTimeZone? _cachedZone;

  static const List<String> indonesianMonths = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static const List<String> indonesianMonthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  /// Inisialisasi awal saat aplikasi start
  static Future<void> init([UserModel? user]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.isNotEmpty) {
        _cachedZone = IndonesianTimeZone.fromName(saved);
        debugPrint('🕒 [TimeUtils] Menggunakan zona waktu tersimpan: ${_cachedZone!.name}');
        return;
      }
    } catch (_) {}

    // Auto-detect dari device offset atau profil user
    _cachedZone = detectTimeZone(address: user?.alamat);
    debugPrint('🕒 [TimeUtils] Auto-detect zona waktu: ${_cachedZone!.name} (${_cachedZone!.fullName})');
  }

  /// Deteksi zona waktu Indonesia berdasarkan offset jam sistem perangkat & alamat
  static IndonesianTimeZone detectTimeZone({String? address}) {
    // 1. Cek offset sistem perangkat pengguna saat ini
    final deviceOffset = DateTime.now().timeZoneOffset;
    final hours = deviceOffset.inHours;

    if (hours == 7) return IndonesianTimeZone.wib;
    if (hours == 8) return IndonesianTimeZone.wita;
    if (hours == 9) return IndonesianTimeZone.wit;

    // Untuk offset dengan toleransi menit (misal +07:00, +08:00, +09:00)
    final totalMinutes = deviceOffset.inMinutes;
    if (totalMinutes >= 390 && totalMinutes <= 450) return IndonesianTimeZone.wib; // ~7 jam
    if (totalMinutes >= 451 && totalMinutes <= 510) return IndonesianTimeZone.wita; // ~8 jam
    if (totalMinutes >= 511 && totalMinutes <= 570) return IndonesianTimeZone.wit; // ~9 jam

    // 2. Jika perangkat di luar zona +7 s/d +9 (misal emulator UTC / PC bawaan US),
    // deteksi dari teks alamat profil user jika tersedia
    if (address != null && address.trim().isNotEmpty) {
      final addr = address.toLowerCase();

      // WIT (Papua, Maluku)
      if (addr.contains('papua') ||
          addr.contains('jayapura') ||
          addr.contains('merauke') ||
          addr.contains('sorong') ||
          addr.contains('manokwari') ||
          addr.contains('biak') ||
          addr.contains('nabire') ||
          addr.contains('mimika') ||
          addr.contains('maluku') ||
          addr.contains('ambon') ||
          addr.contains('ternate') ||
          addr.contains('tidore')) {
        return IndonesianTimeZone.wit;
      }

      // WITA (Bali, Nusa Tenggara, Kalimantan Selatan/Timur/Utara, Sulawesi)
      if (addr.contains('bali') ||
          addr.contains('denpasar') ||
          addr.contains('badung') ||
          addr.contains('gianyar') ||
          addr.contains('buleleng') ||
          addr.contains('tabanan') ||
          addr.contains('ntb') ||
          addr.contains('lombok') ||
          addr.contains('mataram') ||
          addr.contains('bima') ||
          addr.contains('sumbawa') ||
          addr.contains('ntt') ||
          addr.contains('kupang') ||
          addr.contains('flores') ||
          addr.contains('labuan bajo') ||
          addr.contains('sulawesi') ||
          addr.contains('makassar') ||
          addr.contains('gowa') ||
          addr.contains('manado') ||
          addr.contains('palu') ||
          addr.contains('kendari') ||
          addr.contains('gorontalo') ||
          addr.contains('mamuju') ||
          addr.contains('kalsel') ||
          addr.contains('banjarmasin') ||
          addr.contains('banjarbaru') ||
          addr.contains('kaltim') ||
          addr.contains('samarinda') ||
          addr.contains('balikpapan') ||
          addr.contains('kaltara') ||
          addr.contains('tarakan')) {
        return IndonesianTimeZone.wita;
      }

      // WIB (Sumatra, Jawa, Madura, Kalimantan Barat & Tengah)
      if (addr.contains('jakarta') ||
          addr.contains('jawa') ||
          addr.contains('jabar') ||
          addr.contains('jateng') ||
          addr.contains('jatim') ||
          addr.contains('bandung') ||
          addr.contains('surabaya') ||
          addr.contains('semarang') ||
          addr.contains('yogyakarta') ||
          addr.contains('jogja') ||
          addr.contains('banten') ||
          addr.contains('tangerang') ||
          addr.contains('bekasi') ||
          addr.contains('bogor') ||
          addr.contains('depok') ||
          addr.contains('aceh') ||
          addr.contains('medan') ||
          addr.contains('sumut') ||
          addr.contains('padang') ||
          addr.contains('sumbar') ||
          addr.contains('riau') ||
          addr.contains('pekanbaru') ||
          addr.contains('batam') ||
          addr.contains('kepri') ||
          addr.contains('jambi') ||
          addr.contains('palembang') ||
          addr.contains('sumsel') ||
          addr.contains('bengkulu') ||
          addr.contains('lampung') ||
          addr.contains('kalbar') ||
          addr.contains('pontianak') ||
          addr.contains('kalteng') ||
          addr.contains('palangkaraya')) {
        return IndonesianTimeZone.wib;
      }
    }

    // 3. Fallback default jika tidak terdeteksi: WIB
    return IndonesianTimeZone.wib;
  }

  /// Mengambil zona waktu aktif saat ini (Synchronous)
  static IndonesianTimeZone get activeTimeZone {
    if (_cachedZone != null) return _cachedZone!;
    _cachedZone = detectTimeZone();
    return _cachedZone!;
  }

  /// Mengambil singkatan zona waktu aktif (e.g. 'WIB', 'WITA', 'WIT')
  static String getTimeZoneName() => activeTimeZone.name;

  /// Mengambil nama lengkap zona waktu aktif
  static String getTimeZoneFullName() => activeTimeZone.fullName;

  /// Ubah preferensi zona waktu secara manual
  static Future<void> setTimeZone(IndonesianTimeZone zone) async {
    _cachedZone = zone;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, zone.name);
    } catch (_) {}
  }

  /// Waktu saat ini di zona waktu pengguna
  static DateTime get nowInUserZone {
    return _convertToZone(DateTime.now().toUtc(), activeTimeZone);
  }

  /// Konversi input (String UTC / SQL datetime / DateTime / Epoch ms) ke DateTime zona waktu Indonesia
  static DateTime toIndonesianTime(dynamic input, {IndonesianTimeZone? overrideZone}) {
    final targetZone = overrideZone ?? activeTimeZone;
    if (input == null) return _convertToZone(DateTime.now().toUtc(), targetZone);

    DateTime? parsed;

    if (input is DateTime) {
      parsed = input;
    } else if (input is int) {
      if (input > 1000000000000) {
        parsed = DateTime.fromMillisecondsSinceEpoch(input, isUtc: true);
      } else {
        parsed = DateTime.fromMillisecondsSinceEpoch(input * 1000, isUtc: true);
      }
    } else {
      final rawStr = input.toString().trim();
      if (rawStr.isEmpty) return _convertToZone(DateTime.now().toUtc(), targetZone);

      // Cek jika hanya waktu murni seperti "08:00" atau "08:00 WIB"
      final timeOnlyMatch = RegExp(r'^(\d{1,2})[:.](\d{2})(:\d{2})?').firstMatch(rawStr);
      if (timeOnlyMatch != null && !rawStr.contains('-') && !rawStr.contains('/')) {
        final h = int.tryParse(timeOnlyMatch.group(1)!) ?? 0;
        final m = int.tryParse(timeOnlyMatch.group(2)!) ?? 0;
        final now = nowInUserZone;
        return DateTime(now.year, now.month, now.day, h, m);
      }

      // Deteksi format ISO atau SQL datetime
      // Backend GIAT (Laravel / MySQL) biasanya mengirim UTC timestamp:
      // "2026-10-27T09:01:30.000000Z" atau "2026-10-27 09:01:30"
      final hasTimezoneOffset = rawStr.endsWith('Z') ||
          rawStr.contains('+') ||
          RegExp(r'-\d{2}:\d{2}$').hasMatch(rawStr);

      if (hasTimezoneOffset) {
        parsed = DateTime.tryParse(rawStr);
      } else {
        // Jika tidak ada 'Z' atau offset, backend menyimpannya sebagai UTC
        final iso = rawStr.replaceFirst(' ', 'T');
        parsed = DateTime.tryParse('${iso}Z') ?? DateTime.tryParse(rawStr);
      }
    }

    if (parsed == null) {
      return _convertToZone(DateTime.now().toUtc(), targetZone);
    }

    return _convertToZone(parsed, targetZone);
  }

  /// Internal conversion ke zona waktu target
  static DateTime _convertToZone(DateTime dt, IndonesianTimeZone zone) {
    final utc = dt.isUtc ? dt : dt.toUtc();

    // Jika offset perangkat lokal sama persis dengan target zone, gunakan .toLocal()
    if (DateTime.now().timeZoneOffset.inHours == zone.offsetHours) {
      return utc.toLocal();
    }

    // Jika berbeda (misal diuji di komputer dengan offset berbeda atau emulator),
    // sesuaikan offset ke zona target
    final adjusted = utc.add(zone.offset);
    return DateTime(
      adjusted.year,
      adjusted.month,
      adjusted.day,
      adjusted.hour,
      adjusted.minute,
      adjusted.second,
      adjusted.millisecond,
    );
  }

  /// Format waktu chat room (misal: "17.01" atau "17:01")
  /// Otomatis mengonversi UTC dari server ke jam lokal Indonesia
  static String formatChatTime(dynamic input, {String separator = '.'}) {
    if (input == null) return '12${separator}00';
    final str = input.toString().trim();

    // Jika string sudah murni jam seperti "14.30" atau "14:30" tanpa format tanggal
    if (RegExp(r'^\d{1,2}[:.]\d{2}$').hasMatch(str)) {
      return str.replaceAll(':', separator).replaceAll('.', separator);
    }

    final dt = toIndonesianTime(input);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h$separator$m';
  }

  /// Format jam dengan label zona waktu (misal: "17:01 WITA" / "16:01 WIB")
  static String formatTimeWithZone(dynamic input, {String separator = ':'}) {
    final dt = toIndonesianTime(input);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h$separator$m ${getTimeZoneName()}';
  }

  /// Format tanggal dengan zona waktu (misal: "27/10/2026 • 17:01 WITA")
  static String formatDateTimeWithZone(dynamic input, {bool useIndonesianMonth = false}) {
    final dt = toIndonesianTime(input);
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final zone = getTimeZoneName();

    if (useIndonesianMonth) {
      final monthName = indonesianMonths[dt.month - 1];
      return '$day $monthName $year • $h:$m $zone';
    } else {
      final month = dt.month.toString().padLeft(2, '0');
      return '$day/$month/$year • $h:$m $zone';
    }
  }

  static const List<String> indonesianDays = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  /// Format tanggal saja (misal: "27/10/2026" atau "27 Oktober 2026" atau "Jumat, 27 Oktober 2026")
  static String formatDate(dynamic input, {bool useIndonesianMonth = false, bool withDayName = false}) {
    final dt = toIndonesianTime(input);
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year.toString();

    String result;
    if (useIndonesianMonth) {
      final monthName = indonesianMonths[dt.month - 1];
      result = '$day $monthName $year';
    } else {
      final month = dt.month.toString().padLeft(2, '0');
      result = '$day/$month/$year';
    }

    if (withDayName) {
      final dayName = indonesianDays[dt.weekday - 1];
      return '$dayName, $result';
    }
    return result;
  }

  /// Format waktu relatif untuk notifikasi atau riwayat ("Baru saja", "5 menit lalu", dsb.)
  static String formatRelativeTime(dynamic input) {
    if (input == null) return 'Baru saja';
    final dt = toIndonesianTime(input);
    final now = nowInUserZone;
    final diff = now.difference(dt);

    if (diff.isNegative || diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return formatDate(dt);
    }
  }

  /// Ganti label WIB / WITA / WIT yang ter-hardcode di teks statis atau mock data
  /// Contoh: "14:00 WIB" -> "14:00 WITA" (jika user di WITA)
  static String replaceTimezoneSuffix(String text) {
    if (text.isEmpty) return text;
    final currentZone = getTimeZoneName();
    return text
        .replaceAll(' WIB', ' $currentZone')
        .replaceAll(' WITA', ' $currentZone')
        .replaceAll(' WIT', ' $currentZone');
  }

  /// Format rentang jadwal dokter sesuai zona waktu
  /// Contoh: "14.00 – 14.30 WITA (30 Menit)"
  static String formatScheduleRange(String startTime, {int durationMinutes = 30}) {
    final parts = startTime.split(RegExp(r'[:.]'));
    if (parts.length >= 2) {
      int hour = int.tryParse(parts[0]) ?? 14;
      int minute = int.tryParse(parts[1]) ?? 0;
      int endMinute = minute + durationMinutes;
      int endHour = hour;
      if (endMinute >= 60) {
        endHour += endMinute ~/ 60;
        endMinute = endMinute % 60;
      }
      final endHourStr = endHour.toString().padLeft(2, '0');
      final endMinStr = endMinute.toString().padLeft(2, '0');
      return '$startTime – $endHourStr.$endMinStr ${getTimeZoneName()} ($durationMinutes Menit)';
    }
    return '$startTime – 14.30 ${getTimeZoneName()} ($durationMinutes Menit)';
  }
}
