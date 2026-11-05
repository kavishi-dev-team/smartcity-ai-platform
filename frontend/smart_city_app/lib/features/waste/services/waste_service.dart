import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class WasteService {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  Future<Map<String, dynamic>> getWasteIssues({
    int offset = 0,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/issues').replace(
      queryParameters: {
        'category': 'waste',
        'offset': offset.toString(),
        'limit': limit.toString(),
      },
    );

    return _getJson(uri);
  }

  Future<Map<String, dynamic>> getWasteIssue(int issueId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/issues/$issueId');

    return _getJson(uri);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    late http.Response response;

    try {
      response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    } on http.ClientException {
      throw Exception(
        'Could not connect to the API. Check that the backend is running.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('Waste issue not found.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Could not load waste data (HTTP ${response.statusCode}).',
      );
    }

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object.');
      }

      return decoded;
    } on FormatException {
      throw Exception('The API returned an invalid response.');
    }
  }
}
