import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import '../models/notification_model.dart';

class NotificationApiException implements Exception {
  final String message;

  const NotificationApiException(this.message);

  @override
  String toString() => message;
}

class NotificationService {
  // The auth member can supply the current access token through this callback.
  final Future<String?> Function()? accessToken;

  NotificationService({Future<String?> Function()? accessToken})
    : accessToken = accessToken ?? TokenStorage().readAccessToken;

  static String get _baseUrl => AppConfig.baseUrl;

  Future<Map<String, dynamic>> _request(
    String path, {
    bool patch = false,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/v1/notifications$path',
    ).replace(queryParameters: query);

    final token = await accessToken?.call();
    final headers = {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      final response =
          await (patch
                  ? http.patch(uri, headers: headers)
                  : http.get(uri, headers: headers))
              .timeout(const Duration(seconds: 15));

      if (response.statusCode == 503) {
        throw const NotificationApiException(
          'Notifications are unavailable while login integration is pending.',
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const NotificationApiException(
          'Please sign in again to access notifications.',
        );
      }

      if (response.statusCode == 404) {
        throw const NotificationApiException('Notification not found.');
      }

      if (response.statusCode != 200) {
        throw NotificationApiException(
          'Notification request failed (HTTP ${response.statusCode}).',
        );
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw const FormatException();
      }

      return data;
    } on TimeoutException {
      throw const NotificationApiException(
        'Request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const NotificationApiException(
        'Cannot connect to the backend. Check your connection and try again.',
      );
    } on FormatException {
      throw const NotificationApiException(
        'The backend returned an invalid notification response.',
      );
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    final notifications = <NotificationModel>[];
    var offset = 0;

    while (true) {
      final data = await _request(
        '',
        query: {'offset': '$offset', 'limit': '100'},
      );

      final items = data['items'];
      final total = data['total'];

      if (items is! List || total is! int) {
        throw const NotificationApiException(
          'The backend returned an invalid notification list.',
        );
      }

      if (items.isEmpty) break;

      for (final item in items) {
        notifications.add(
          NotificationModel.fromJson(Map<String, dynamic>.from(item as Map)),
        );
      }

      offset += items.length;
      if (offset >= total) break;
    }

    return notifications;
  }

  Future<NotificationModel> getNotification(String id) async {
    return NotificationModel.fromJson(await _request('/$id'));
  }

  Future<int> getUnreadCount() async {
    final data = await _request('/unread-count');
    return data['unread_count'] as int;
  }

  Future<NotificationModel> markAsRead(String id) async {
    return NotificationModel.fromJson(await _request('/$id/read', patch: true));
  }

  Future<void> markAllAsRead() async {
    await _request('/read-all', patch: true);
  }
}
