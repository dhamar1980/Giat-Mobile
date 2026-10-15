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

  /// Active Base URL in memory
  static String _activeBaseUrl = defaultBaseUrl;

  static String get baseUrl => _activeBaseUrl.trim();

  static void setBaseUrl(String url) {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    // Pastikan berakhiran /api jika belum ada
    if (!cleanUrl.endsWith('/api')) {
      cleanUrl = '$cleanUrl/api';
    }
    _activeBaseUrl = cleanUrl;
  }
}
