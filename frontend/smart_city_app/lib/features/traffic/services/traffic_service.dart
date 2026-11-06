import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/traffic_issue_model.dart';
import '../models/department_model.dart';
import '../models/traffic_officer_model.dart';

class TrafficApiException implements Exception {
  final String message;
  const TrafficApiException(this.message);

  @override
  String toString() => message;
}

class TrafficService {
  // For Chrome: http://localhost:8000/api/v1
  // Android emulator: http://10.0.2.2:8000/api/v1
  // Real device: http://YOUR_COMPUTER_LAN_IP:8000/api/v1
  static const String defaultBaseUrl = String.fromEnvironment(
    'TRAFFIC_API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  final http.Client _client;
  final bool _ownsClient;
  final String baseUrl;
  // In-memory only. Will be supplied by Member 1 login after integration.
  String? _officerToken;

  bool get hasOfficerToken => _officerToken != null && _officerToken!.isNotEmpty;
  void setOfficerToken(String token) => _officerToken = token.trim();
  void clearOfficerToken() => _officerToken = null;

  TrafficService({http.Client? client, String baseUrl = defaultBaseUrl})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,
        baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 404) {
        throw const TrafficApiException('Traffic report not found.');
      }
      if (response.statusCode != 200) {
        throw TrafficApiException(
          'Unable to load traffic data (HTTP ${response.statusCode}).',
        );
      }
      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        throw const TrafficApiException('Unexpected response from server.');
      }
      return json;
    } on TrafficApiException {
      rethrow;
    } catch (_) {
      throw const TrafficApiException(
        'Cannot connect to the Traffic API. Check that FastAPI is running and the API URL is correct.',
      );
    }
  }

  Future<TrafficIssuePage> getIssues({
    String search = '',
    String status = '',
    String priority = '',
    String city = '',
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'category': 'traffic',
      'limit': '$limit',
      'offset': '$offset',
    };
    if (search.trim().isNotEmpty) params['search'] = search.trim();
    if (status.isNotEmpty) params['status'] = status;
    if (priority.isNotEmpty) params['priority'] = priority;
    if (city.trim().isNotEmpty) params['city'] = city.trim();
    if (dateFrom != null) params['date_from'] = trafficDate(dateFrom);
    if (dateTo != null) params['date_to'] = trafficDate(dateTo);

    final uri = Uri.parse('$baseUrl/issues').replace(queryParameters: params);
    return TrafficIssuePage.fromJson(await _get(uri));
  }

  Future<TrafficIssueDetail> getIssue(int issueId) async {
    final uri = Uri.parse('$baseUrl/issues/$issueId');
    return TrafficIssueDetail.fromJson(await _get(uri));
  }

  Future<TrafficMapPage> getMapMarkers({
    String status = '', String city = '', String search = '',
  }) async {
    final params = <String, String>{};
    if (status.trim().isNotEmpty) params['status'] = status.trim();
    if (city.trim().isNotEmpty) params['city'] = city.trim();
    if (search.trim().isNotEmpty) params['search'] = search.trim();
    final uri = Uri.parse('$baseUrl/traffic/map').replace(queryParameters: params);
    return TrafficMapPage.fromJson(await _get(uri));
  }

  Future<DepartmentPage> getDepartments({
    String search = '', int limit = 20, int offset = 0,
  }) async {
    final params = <String, String>{'limit': '$limit', 'offset': '$offset'};
    if (search.trim().isNotEmpty) params['search'] = search.trim();
    final uri = Uri.parse('$baseUrl/departments').replace(queryParameters: params);
    return DepartmentPage.fromJson(await _get(uri));
  }

  Future<DepartmentInfo> getDepartment(int departmentId) async {
    final uri = Uri.parse('$baseUrl/departments/$departmentId');
    return DepartmentInfo.fromJson(await _get(uri));
  }

  Future<DepartmentTrafficPage> getDepartmentIssues(
    int departmentId, {int limit = 10, int offset = 0}
  ) async {
    final uri = Uri.parse('$baseUrl/departments/$departmentId/issues')
        .replace(queryParameters: {'limit': '$limit', 'offset': '$offset'});
    return DepartmentTrafficPage.fromJson(await _get(uri));
  }

  Future<Map<String, dynamic>> _officerRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final token = _officerToken;
    if (token == null || token.isEmpty) {
      throw const TrafficApiException('Officer login is required.');
    }
    final uri = Uri.parse('$baseUrl/traffic/officer/$path');
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    http.Response response;
    try {
      if (method == 'GET') {
        response = await _client.get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
      } else if (method == 'PATCH') {
        response = await _client.patch(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 20));
      } else {
        response = await _client.post(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 20));
      }
    } catch (_) {
      throw const TrafficApiException('Cannot contact the Traffic Officer API. Check FastAPI.');
    }
    if (response.statusCode == 401) {
      throw const TrafficApiException('Officer token is invalid or expired. Sign in again.');
    }
    if (response.statusCode == 403) {
      throw const TrafficApiException('Your account is not authorized to manage traffic reports.');
    }
    dynamic payload;
    try {
      payload = jsonDecode(response.body);
    } catch (_) {
      throw TrafficApiException('Unexpected officer API response (HTTP ${response.statusCode}).');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = payload is Map ? payload['detail'] : null;
      final message = detail is String ? detail : 'Request failed (HTTP ${response.statusCode}).';
      throw TrafficApiException(message);
    }
    if (payload is! Map<String, dynamic>) {
      throw const TrafficApiException('Invalid officer API response.');
    }
    return payload;
  }

  Future<TrafficOfficerIssue> getOfficerIssue(int id) async {
    final data = await _officerRequest('GET', 'issues/$id');
    return TrafficOfficerIssue.fromJson(data);
  }

  Future<void> assignTrafficDepartment(int issueId, int departmentId) async {
    await _officerRequest('POST', 'issues/$issueId/department', body: {
      'department_id': departmentId,
    });
  }

  Future<void> assignTrafficOfficer(int issueId, int officerId) async {
    await _officerRequest('POST', 'issues/$issueId/officer', body: {
      'officer_id': officerId,
    });
  }

  Future<void> reviewTrafficPriority(int issueId, {
    required String decision,
    String? priority,
    String? reason,
  }) async {
    await _officerRequest('POST', 'issues/$issueId/priority-review', body: {
      'decision': decision,
      if (priority != null) 'priority': priority,
      if (reason != null) 'reason': reason,
    });
  }

  Future<void> saveTrafficOfficerUpdate(int issueId, {
    String? status,
    String? internalNote,
    String? publicUpdate,
  }) async {
    await _officerRequest('PATCH', 'issues/$issueId/status', body: {
      if (status != null) 'status': status,
      if (internalNote != null && internalNote.trim().isNotEmpty)
        'internal_note': internalNote.trim(),
      if (publicUpdate != null && publicUpdate.trim().isNotEmpty)
        'public_update': publicUpdate.trim(),
    });
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
