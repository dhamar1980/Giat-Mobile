import 'package:flutter/foundation.dart';

/// Configuration for GIAT Backend API
class ApiConfig {
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api';
  static const String lanBaseUrl = 'http://192.168.1.16:8000/api';
  static const String localhostBaseUrl = 'http://127.0.0.1:8000/api';
  static const String tunnelBaseUrl = 'https://arbitration-daniel-least-pixel.trycloudflare.com/api';

  /// Default Base URL based on platform
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return localhostBaseUrl;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Default to emulator for Android testing, but easily configurable
        return emulatorBaseUrl;
      case TargetPlatform.iOS:
        return localhostBaseUrl;
      default:
        return localhostBaseUrl;
    }
  }

  /// Active Base URL in memory
  static String _activeBaseUrl = defaultBaseUrl;

  static String get baseUrl => _activeBaseUrl;

  static void setBaseUrl(String url) {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    _activeBaseUrl = cleanUrl;
  }
}
