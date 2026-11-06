import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/air_quality_model.dart';
import '../models/safety_alert_model.dart';
import '../models/safety_issue_model.dart';

/// Thrown when the server answers with an error we can explain to the user.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// TEMPORARY: replace with the team's shared api_constants / api_client
/// once the Flutter coordinator has set them up.
String get _baseUrl {
  const port = 8000; // use 8002 if you run the backend through docker-compose
  if (kIsWeb) return 'http://127.0.0.1:$port/api/v1';
  if (defaultTargetPlatform == TargetPlatform.android) {
    // Android emulator reaches your PC through 10.0.2.2.
    // On a real phone, use your PC's Wi-Fi IP, e.g. http://192.168.1.10:8000/api/v1
    return 'http://10.0.2.2:$port/api/v1';
  }
  return 'http://127.0.0.1:$port/api/v1';
}

String _dateParam(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class SafetyService {
  final http.Client _client;

  SafetyService({http.Client? client}) : _client = client ?? http.Client();

  /// Officer actions need the logged-in user's token. When Member 1's auth is merged,
  /// set this once at app start, for example:
  ///   SafetyService.accessTokenProvider = TokenStorage().readAccessToken;
  /// Until then no token is sent (the backend runs officer endpoints in dev mode).
  static Future<String?> Function()? accessTokenProvider;

  Future<http.Response> _send(
    String method,
    Uri uri, {
    Object? body,
    bool auth = false,
  }) async {
    final request = http.Request(method, uri);
    request.headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (auth) {
      final token = await accessTokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }
    final streamed = await _client.send(request).timeout(const Duration(seconds: 10));
    return http.Response.fromStream(streamed);
  }

  Future<http.Response> _get(Uri uri, {bool auth = false}) =>
      _send('GET', uri, auth: auth);

  ApiException _error(http.Response response) {
    var message = 'Server error (${response.statusCode}).';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] is String) {
        message = body['detail'] as String;
      } else if (response.statusCode == 422) {
        message = 'Please check the details you entered.';
      }
    } catch (_) {}
    if (response.statusCode == 401) message = 'Please log in again.';
    if (response.statusCode == 403) message = 'Only officers can do this.';
    return ApiException(message);
  }

  // ---------------- Air quality ----------------

  Future<List<AirQualityReading>> fetchLatestAirQuality() async {
    final response = await _get(Uri.parse('$_baseUrl/air-quality'));
    if (response.statusCode != 200) throw _error(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => AirQualityReading.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AirQualityHistory> fetchAirQualityHistory(
    String area,
    String period,
  ) async {
    final uri = Uri.parse('$_baseUrl/air-quality/history')
        .replace(queryParameters: {'area': area, 'period': period});
    final response = await _get(uri);

    if (response.statusCode == 404) {
      throw const ApiException('No history available for this area yet.');
    }
    if (response.statusCode != 200) throw _error(response);
    return AirQualityHistory.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // ---------------- Safety alerts ----------------

  Future<List<SafetyAlert>> fetchAlerts({bool? isActive, String? severity}) async {
    final query = <String, String>{'limit': '100'};
    if (isActive != null) query['is_active'] = isActive.toString();
    if (severity != null) query['severity'] = severity;

    final uri =
        Uri.parse('$_baseUrl/safety-alerts').replace(queryParameters: query);
    final response = await _get(uri);
    if (response.statusCode != 200) throw _error(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => SafetyAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SafetyAlert> fetchAlertDetail(int id) async {
    final response = await _get(Uri.parse('$_baseUrl/safety-alerts/$id'));

    if (response.statusCode == 404) {
      throw const ApiException('This alert no longer exists.');
    }
    if (response.statusCode != 200) throw _error(response);
    return SafetyAlert.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // ---------------- Safety problems and complaints (public) ----------------

  Future<SafetySummary> fetchSafetySummary() async {
    final response = await _get(Uri.parse('$_baseUrl/safety/summary'));
    if (response.statusCode != 200) throw _error(response);
    return SafetySummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<IssueCounts> fetchIssueCounts({String category = 'complaint'}) async {
    final uri = Uri.parse('$_baseUrl/safety/issues/counts')
        .replace(queryParameters: {'category': category});
    final response = await _get(uri);
    if (response.statusCode != 200) throw _error(response);
    return IssueCounts.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// [status] can be one status or several separated by commas, e.g. "assigned,in_progress".
  Future<SafetyIssuePage> fetchSafetyIssues({
    String category = 'safety',
    String? search,
    String? status,
    String? priority,
    DateTime? dateFrom,
    DateTime? dateTo,
    int page = 1,
    int pageSize = 10,
  }) async {
    final query = <String, String>{
      'category': category,
      'page': '$page',
      'page_size': '$pageSize',
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (priority != null) query['priority'] = priority;
    if (dateFrom != null) query['date_from'] = _dateParam(dateFrom);
    if (dateTo != null) query['date_to'] = _dateParam(dateTo);

    final uri =
        Uri.parse('$_baseUrl/safety/issues').replace(queryParameters: query);
    final response = await _get(uri);
    if (response.statusCode != 200) throw _error(response);
    return SafetyIssuePage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<SafetyIssueDetail> fetchSafetyIssueDetail(int id) async {
    final response = await _get(Uri.parse('$_baseUrl/safety/issues/$id'));
    if (response.statusCode == 404) {
      throw const ApiException('This report no longer exists.');
    }
    if (response.statusCode != 200) throw _error(response);
    return SafetyIssueDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // ---------------- Officer actions (need an officer login) ----------------

  Future<List<SafetyDepartment>> fetchDepartments() async {
    final response = await _get(Uri.parse('$_baseUrl/safety/departments'), auth: true);
    if (response.statusCode != 200) throw _error(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => SafetyDepartment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SafetyOfficer>> fetchOfficers(int departmentId) async {
    final response = await _get(
      Uri.parse('$_baseUrl/safety/departments/$departmentId/officers'),
      auth: true,
    );
    if (response.statusCode != 200) throw _error(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => SafetyOfficer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<InternalNote>> fetchInternalNotes(int issueId) async {
    final response = await _get(
      Uri.parse('$_baseUrl/safety/issues/$issueId/notes'),
      auth: true,
    );
    if (response.statusCode != 200) throw _error(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => InternalNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SafetyIssueDetail> assignIssue(
    int issueId, {
    required int departmentId,
    int? officerId,
    String? note,
  }) async {
    final response = await _send(
      'POST',
      Uri.parse('$_baseUrl/safety/issues/$issueId/assignments'),
      auth: true,
      body: {
        'department_id': departmentId,
        if (officerId != null) 'assigned_to': officerId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    if (response.statusCode != 200) throw _error(response);
    return SafetyIssueDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// [note] is shown to the citizen in the timeline.
  Future<SafetyIssueDetail> updateIssueStatus(
    int issueId,
    String status, {
    String? note,
  }) async {
    final response = await _send(
      'PATCH',
      Uri.parse('$_baseUrl/safety/issues/$issueId/status'),
      auth: true,
      body: {
        'status': status,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    if (response.statusCode != 200) throw _error(response);
    return SafetyIssueDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// A message the citizen can see in the timeline (the status does not change).
  Future<SafetyIssueDetail> addPublicUpdate(int issueId, String note) async {
    final response = await _send(
      'POST',
      Uri.parse('$_baseUrl/safety/issues/$issueId/updates'),
      auth: true,
      body: {'note': note},
    );
    if (response.statusCode != 201) throw _error(response);
    return SafetyIssueDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Staff-only note.
  Future<InternalNote> addInternalNote(int issueId, String note) async {
    final response = await _send(
      'POST',
      Uri.parse('$_baseUrl/safety/issues/$issueId/notes'),
      auth: true,
      body: {'note': note},
    );
    if (response.statusCode != 201) throw _error(response);
    return InternalNote.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
