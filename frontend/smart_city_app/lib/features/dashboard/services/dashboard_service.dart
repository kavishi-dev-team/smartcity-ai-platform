import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  final http.Client _client;

  DashboardService({http.Client? client})
      : _client = client ?? http.Client();

  Future<CitizenDashboard> getCitizenDashboard(int userId) async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}${AppConfig.apiVersion}/dashboard/citizen?user_id=$userId',
    );

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      return CitizenDashboard.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to load citizen dashboard: ${response.statusCode}',
    );
  }

  Future<OfficerDashboard> getOfficerDashboard() async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}${AppConfig.apiVersion}/dashboard/officer',
    );

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      return OfficerDashboard.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to load officer dashboard: ${response.statusCode}',
    );
  }

  void dispose() {
    _client.close();
  }
}
