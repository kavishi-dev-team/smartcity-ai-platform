import 'dart:convert';

import 'package:http/http.dart' as http;

class CollectionService {
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  Future<List<Map<String, dynamic>>> getSchedules() async {
    final schedules = <Map<String, dynamic>>[];
    var offset = 0;

    while (true) {
      final uri = Uri.parse(
        '$_baseUrl/api/v1/collection-schedules',
      ).replace(queryParameters: {'offset': '$offset', 'limit': '100'});

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Could not load schedules (HTTP ${response.statusCode}).',
        );
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic> ||
          data['items'] is! List ||
          data['total'] is! int) {
        throw const FormatException('Invalid schedule response.');
      }

      final items = data['items'] as List;
      final total = data['total'] as int;

      if (items.isEmpty) break;

      for (final item in items) {
        schedules.add(Map<String, dynamic>.from(item as Map));
      }

      offset += items.length;
      if (offset >= total) break;
    }

    return schedules;
  }
}
