/// Centralized API Constants for GIAT Backend
class ApiConstants {
  /// URL Server / Cloudflare tunnel
  static const String serverUrl = 'https://jonathan-evaluating-hydraulic-impressive.trycloudflare.com/api';

  /// URL LAN Wi-Fi (untuk HP di jaringan Wi-Fi lokal)
  static const String lanUrl = 'http://10.80.131.1:8000/api';

  /// URL Emulator Android
  static const String emulatorUrl = 'http://10.0.2.2:8000/api';

  /// URL Localhost (iOS Simulator / Desktop / Web)
  static const String localhostUrl = 'http://127.0.0.1:8000/api';

  /// Default active Base URL
  static const String defaultBaseUrl = serverUrl;

  /// Konfigurasi Database Real Supabase PostgreSQL (GIAT)
  static const String supabaseDirectUrl =
      'postgresql://postgres:KnWPC0g1ajTd2VJ8@db.auaejgogiyfrefsurahd.supabase.co:5432/postgres';
  static const String supabaseProjectRef = 'auaejgogiyfrefsurahd';
  static const String supabaseDirectHost =
      'db.auaejgogiyfrefsurahd.supabase.co';
  static const String supabasePoolerHost =
      'aws-0-ap-northeast-1.pooler.supabase.com';
  static const int supabaseDirectPort = 5432;
  static const int supabasePoolerPort = 6543;
  static const String supabaseDatabase = 'postgres';
  static const String supabaseDirectUser = 'postgres';
  static const String supabasePoolerUser = 'postgres.auaejgogiyfrefsurahd';
  static const String supabasePassword = 'KnWPC0g1ajTd2VJ8';

  /// Konfigurasi Kredensial Midtrans Payment Gateway (Sandbox)
  static const String midtransMerchantId = 'M187509004';
  static const String midtransClientKey = 'Mid-client-uy4tnHFnIkOeFo0R';
  static const bool midtransIsProduction = false;
  static const String midtransEnvironment = 'sandbox';
  static const String midtransSnapJsUrl =
      'https://app.sandbox.midtrans.com/snap/snap.js';
  static const String midtransRedirectionBaseUrl =
      'https://app.sandbox.midtrans.com/snap/v4/redirection/';

  /// Helper untuk membangun Redirect URL Midtrans Snap dari redirect_url atau snap_token
  static String? resolveMidtransRedirectUrl({
    String? redirectUrl,
    String? snapToken,
  }) {
    if (redirectUrl != null && redirectUrl.trim().isNotEmpty) {
      return redirectUrl.trim();
    }
    if (snapToken != null && snapToken.trim().isNotEmpty) {
      return '$midtransRedirectionBaseUrl${snapToken.trim()}';
    }
    return null;
  }

  /// Helper untuk meresolusi URL foto profil / storage backend ke server aktif
  static String resolveImageUrl(String? rawUrl, [String? baseUrlOverride]) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final trimmed = rawUrl.trim();
    final activeBase = (baseUrlOverride != null && baseUrlOverride.isNotEmpty)
        ? baseUrlOverride
        : defaultBaseUrl;
    String baseHost = activeBase.replaceAll(RegExp(r'/api/?$'), '');
    if (baseHost.contains('trycloudflare.com') && baseHost.startsWith('http://')) {
      baseHost = baseHost.replaceFirst('http://', 'https://');
    }

    if (trimmed.startsWith('/storage/') || trimmed.startsWith('storage/')) {
      final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
      return '$baseHost$cleanPath';
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri == null) return trimmed;
      if (uri.path.contains('/storage/')) {
        final storagePath = uri.path.substring(uri.path.indexOf('/storage/'));
        return '$baseHost$storagePath';
      }
      if (trimmed.contains('trycloudflare.com') && trimmed.startsWith('http://')) {
        return trimmed.replaceFirst('http://', 'https://');
      }
      return trimmed;
    }

    return trimmed;
  }
}
