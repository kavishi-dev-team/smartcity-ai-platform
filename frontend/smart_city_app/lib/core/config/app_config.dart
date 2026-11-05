class AppConfig {
  AppConfig._();

  /// Backend base URL. Override at run time, for example:
  ///
  ///   Android emulator (default) : http://10.0.2.2:8000/api/v1
  ///   Chrome / Linux desktop     : --dart-define=API_BASE_URL=http://localhost:8000/api/v1
  ///   Real phone (same Wi-Fi)    : --dart-define=API_BASE_URL=http://<laptop-ip>:8000/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const Duration requestTimeout = Duration(seconds: 20);
}