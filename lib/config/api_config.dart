import '../constants/api_constants.dart';

/// Configuration for GIAT Backend API
class ApiConfig {
  static const String serverUrl = ApiConstants.serverUrl;
  static const String emulatorUrl = ApiConstants.emulatorUrl;
  static const String localhostUrl = ApiConstants.localhostUrl;

  /// Compatibility getter
  static String get tunnelBaseUrl => serverUrl;

  /// Default Base URL
  static String get defaultBaseUrl => ApiConstants.defaultBaseUrl.trim();

  /// Active Base URL override in memory
  static String? _customBaseUrl;

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      final customHost = Uri.tryParse(_customBaseUrl!)?.host ?? '';
      final constantHost = Uri.tryParse(ApiConstants.serverUrl)?.host ?? '';
      // If the override is an outdated trycloudflare tunnel that differs from the code, discard it
      if (customHost.contains('trycloudflare.com') &&
          constantHost.isNotEmpty &&
          customHost != constantHost) {
        _customBaseUrl = null;
        return defaultBaseUrl;
      }
      return _customBaseUrl!.trim();
    }
    return defaultBaseUrl;
  }

  static void setBaseUrl(String url) {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    // Pastikan berakhiran /api jika belum ada
    if (!cleanUrl.endsWith('/api')) {
      cleanUrl = '$cleanUrl/api';
    }
    _customBaseUrl = cleanUrl;
  }

  static void resetToDefault() {
    _customBaseUrl = null;
  }
}
