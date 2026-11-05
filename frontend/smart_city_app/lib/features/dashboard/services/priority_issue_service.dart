import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../models/priority_issue_model.dart';

class PriorityIssueService {
  Future<List<PriorityIssue>> getPrioritizedIssues({
    String? priority,
    String? category,
    String? status,
  }) async {
    final query = <String, String>{};

    if (priority != null) query['priority'] = priority;
    if (category != null) query['category'] = category;
    if (status != null) query['status'] = status;

    final uri = Uri.parse(
      '${AppConfig.baseUrl}${AppConfig.apiVersion}/issues/prioritized',
    ).replace(queryParameters: query.isEmpty ? null : query);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((item) => PriorityIssue.fromJson(item))
          .toList();
    }

    throw Exception('Failed to load prioritized issues');
  }
}
