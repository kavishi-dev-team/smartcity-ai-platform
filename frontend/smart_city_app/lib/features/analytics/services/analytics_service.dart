import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../models/analytics_model.dart';

class AnalyticsService {
  final http.Client _client;

  AnalyticsService({http.Client? client})
      : _client = client ?? http.Client();

  Future<AnalyticsOverview> getOverview() async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}${AppConfig.apiVersion}/analytics/overview',
    );

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      return AnalyticsOverview.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to load analytics overview: ${response.statusCode}',
    );
  }

  Future<IssueAnalytics> getIssueAnalytics() async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}${AppConfig.apiVersion}/analytics/issues',
    );

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      return IssueAnalytics.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to load issue analytics: ${response.statusCode}',
    );
  }

  Future<DepartmentAnalyticsResponse> getDepartmentAnalytics() async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}${AppConfig.apiVersion}/analytics/departments',
    );

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      return DepartmentAnalyticsResponse.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Failed to load department analytics: ${response.statusCode}',
    );
  }

  void dispose() {
    _client.close();
  }
}
