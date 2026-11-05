class AppConfig {
  AppConfig._();

  /// Backend base URL without /api/v1.
  ///
  /// Android emulator: http://10.0.2.2:8000
  /// Chrome/Linux:     http://localhost:8000
  /// Real phone:       http://<laptop-ip>:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String apiVersion = '/api/v1';

  /// Complete API base URL used by ApiClient.
  static const String apiBaseUrl = '$baseUrl$apiVersion';

  /// AI chat endpoint.
  static const String aiChatUrl = '$baseUrl$apiVersion/ai/chat';

  static const Duration requestTimeout = Duration(seconds: 20);
}
