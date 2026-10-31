import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/air_quality_model.dart';
import '../models/safety_alert_model.dart';

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

class SafetyService {
  final http.Client _client;

  SafetyService({http.Client? client}) : _client = client ?? http.Client();

  // ---------------- Air quality ----------------

  Future<List<AirQualityReading>> fetchLatestAirQuality() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/air-quality'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ApiException('Server error (${response.statusCode}).');
    }
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
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 404) {
      throw const ApiException('No history available for this area yet.');
    }
    if (response.statusCode != 200) {
      throw ApiException('Server error (${response.statusCode}).');
    }
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
    final response = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw ApiException('Server error (${response.statusCode}).');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((e) => SafetyAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SafetyAlert> fetchAlertDetail(int id) async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/safety-alerts/$id'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 404) {
      throw const ApiException('This alert no longer exists.');
    }
    if (response.statusCode != 200) {
      throw ApiException('Server error (${response.statusCode}).');
    }
    return SafetyAlert.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
