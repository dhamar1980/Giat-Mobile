/// Centralized API Constants for GIAT Backend
class ApiConstants {
  /// URL Server / Cloudflare tunnel
  static const String serverUrl = 'https://workshops-producers-smile-realize.trycloudflare.com/api';

  /// URL LAN Wi-Fi (untuk HP di jaringan Wi-Fi lokal)
  static const String lanUrl = 'http://192.168.1.14:8000/api';

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
}