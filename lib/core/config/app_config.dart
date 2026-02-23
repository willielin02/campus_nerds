/// 應用程式環境設定
///
/// 透過 `--dart-define=ENV=prod` 切換環境：
/// - `flutter run` → dev（預設）
/// - `flutter run --dart-define=ENV=prod` → prod
/// - `flutter build apk --dart-define=ENV=prod` → prod APK
class AppConfig {
  AppConfig._();

  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  /// 是否為正式環境
  static bool get isProd => _env == 'prod';

  /// 是否為開發環境
  static bool get isDev => !isProd;

  /// 環境名稱（用於除錯訊息）
  static String get envName => isProd ? 'prod' : 'dev';

  /// Supabase URL
  static String get supabaseUrl => isProd ? _prodUrl : _devUrl;

  /// Supabase Anon Key（公開金鑰，可安全放在客戶端）
  static String get supabaseAnonKey => isProd ? _prodAnonKey : _devAnonKey;

  // --- Dev (lzafwlmznlkvmbdxcxop) ---
  static const _devUrl = 'https://lzafwlmznlkvmbdxcxop.supabase.co';
  static const _devAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6YWZ3bG16bmxrdm1iZHhjeG9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNTcyODIsImV4cCI6MjA4MTYzMzI4Mn0.5i_r7IRg1ZDjFIvlki_Oy9IYQ6dCXeA5PrCZ-g-XAFQ';

  // --- Prod (nvnbqkboovavnvohbcpy) ---
  static const _prodUrl = 'https://nvnbqkboovavnvohbcpy.supabase.co';
  static const _prodAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im52bmJxa2Jvb3Zhdm52b2hiY3B5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MzA2MDAsImV4cCI6MjA4NzQwNjYwMH0.ZzZj_jv01n3yvCE-0BF8IH1Fz4mLZyhwupgKoQ-h1oc';
}
