import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/traffic_issue_model.dart';

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

  Future<TrafficMapPage> getMapMarkers({String status = '', String city = ''}) async {
    final params = <String, String>{};
    if (status.trim().isNotEmpty) params['status'] = status.trim();
    if (city.trim().isNotEmpty) params['city'] = city.trim();
    final uri = Uri.parse('$baseUrl/traffic/map').replace(queryParameters: params);
    return TrafficMapPage.fromJson(await _get(uri));
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
