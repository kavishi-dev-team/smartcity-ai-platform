import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

/// Error returned by the backend (or a network failure).
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;

  /// Machine readable code sent by the backend, e.g. `email_not_verified`.
  final String? code;

  @override
  String toString() => message;
}

/// Small wrapper around `package:http` that
///  * adds the JSON headers and the `Authorization: Bearer` token,
///  * transparently refreshes an expired access token once and retries,
///  * turns error responses into [ApiException]s with a readable message.
class ApiClient {
  ApiClient({http.Client? client, TokenStorage? tokenStorage})
      : _client = client ?? http.Client(),
        tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _client;
  final TokenStorage tokenStorage;

  /// Called when the refresh token is rejected, so the UI can go to login.
  void Function()? onSessionExpired;

  Future<dynamic> get(String path, {bool auth = true}) =>
      _send('GET', path, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) =>
      _send('PATCH', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {Object? body, bool auth = true}) =>
      _send('DELETE', path, body: body, auth: auth);

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    bool auth = true,
    bool isRetry = false,
  }) async {
    final request = http.Request(method, Uri.parse('${AppConfig.apiBaseUrl}$path'));
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (auth) {
      final token = await tokenStorage.readAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    late final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(AppConfig.requestTimeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Please try again.');
    } catch (_) {
      throw ApiException(
        'Cannot reach the server. Check your internet connection and try again.',
      );
    }

    if (response.statusCode == 401 && auth && !isRetry) {
      final refreshed = await _refreshTokens();
      if (refreshed) {
        return _send(method, path, body: body, auth: auth, isRetry: true);
      }
    }

    return _decode(response);
  }

  Future<bool> _refreshTokens() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      onSessionExpired?.call();
      return false;
    }

    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}${ApiConstants.refresh}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await tokenStorage.saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
        return true;
      }
      if (response.statusCode == 401) {
        await tokenStorage.clear();
        onSessionExpired?.call();
      }
    } catch (_) {
      // Network problem: keep the tokens, the caller will see the 401.
    }
    return false;
  }

  dynamic _decode(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        data = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw _toException(response.statusCode, data);
  }

  ApiException _toException(int statusCode, dynamic data) {
    String message = 'Something went wrong (error $statusCode). Please try again.';
    String? code;

    final detail = data is Map<String, dynamic> ? data['detail'] : null;

    if (detail is String) {
      message = detail;
    } else if (detail is Map<String, dynamic>) {
      message = (detail['message'] as String?) ?? message;
      code = detail['code'] as String?;
    } else if (detail is List && detail.isNotEmpty) {
      // FastAPI validation errors: [{loc: [...], msg: "Value error, ..."}]
      final first = detail.first;
      if (first is Map && first['msg'] is String) {
        message = (first['msg'] as String).replaceFirst('Value error, ', '');
      }
    }

    return ApiException(message, statusCode: statusCode, code: code);
  }
}