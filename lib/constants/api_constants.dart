/// Centralized API Constants for GIAT Backend
class ApiConstants {
  /// URL Server / Cloudflare tunnel
  static const String serverUrl = 'https://excerpt-dsl-items-hash.trycloudflare.com/api';

  /// URL Emulator Android
  static const String emulatorUrl = 'http://10.0.2.2:8000/api';

  /// URL Localhost (iOS Simulator / Desktop / Web)
  static const String localhostUrl = 'http://127.0.0.1:8000/api';

  /// Default active Base URL
  static const String defaultBaseUrl = serverUrl;
}
