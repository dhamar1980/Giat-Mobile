/// Configuration for GIAT Backend API
class ApiConfig {
  static const String tunnelBaseUrl = 'https://fair-what-fingers-places.trycloudflare.com/api';

  /// Default Base URL
  static String get defaultBaseUrl => tunnelBaseUrl;

  /// Active Base URL in memory
  static String _activeBaseUrl = defaultBaseUrl;

  static String get baseUrl => _activeBaseUrl;

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
