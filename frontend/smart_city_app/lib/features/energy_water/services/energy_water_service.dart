
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../models/energy_issue_model.dart';
import '../models/water_issue_model.dart';
import '../models/energy_water_statistics_model.dart';
import '../models/issue_details_model.dart';

class EnergyWaterService {
  static String get baseUrl => AppConfig.apiBaseUrl;

    // Fetch complete Energy Issue Details
  Future<IssueDetails> fetchEnergyIssueDetails(int issueId) async {
    final uri = Uri.parse('$baseUrl/energy/issues/$issueId');

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return IssueDetails.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(
      'Failed to load energy issue details: '
      '${response.statusCode} ${response.body}',
    );
  }

  // Fetch complete Water Issue Details
  Future<IssueDetails> fetchWaterIssueDetails(int issueId) async {
    final uri = Uri.parse('$baseUrl/water/issues/$issueId');

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return IssueDetails.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(
      'Failed to load water issue details: '
      '${response.statusCode} ${response.body}',
    );
  }

  // Fetch Energy Issues
  Future<List<EnergyIssue>> fetchEnergyIssues({
    String? search,
    String? status,
    String? priority,
    int? reportedBy,
  }) async {
    final queryParameters = <String, String>{};

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    if (priority != null && priority.isNotEmpty) {
      queryParameters['priority'] = priority;
    }

    if (reportedBy != null) {
      queryParameters['reported_by'] = reportedBy.toString();
    }

    final uri = Uri.parse('$baseUrl/energy/issues').replace(
      queryParameters:
          queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;

      return items
          .map(
            (item) => EnergyIssue.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Failed to load energy issues: '
      '${response.statusCode} ${response.body}',
    );
  }

  // Fetch Water Issues and Water Leakage Reports
  Future<List<WaterIssue>> fetchWaterIssues({
    String? search,
    String? status,
    String? priority,
    bool leakageOnly = false,
    int? reportedBy,
  }) async {
    final queryParameters = <String, String>{};

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }

    if (priority != null && priority.isNotEmpty) {
      queryParameters['priority'] = priority;
    }

    if (leakageOnly) {
      queryParameters['subcategory'] = 'leakage';
    }

    if (reportedBy != null) {
      queryParameters['reported_by'] = reportedBy.toString();
    }

    final uri = Uri.parse('$baseUrl/water/issues').replace(
      queryParameters:
          queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;

      return items
          .map(
            (item) => WaterIssue.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Failed to load water issues: '
      '${response.statusCode} ${response.body}',
    );
  }
  // Fetch Departments
Future<List<Map<String, dynamic>>> fetchDepartments() async {
  final uri = Uri.parse('$baseUrl/departments');

  final response = await http.get(
    uri,
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return List<Map<String, dynamic>>.from(decoded);
    } else if (decoded is Map<String, dynamic> && decoded['items'] is List) {
      return List<Map<String, dynamic>>.from(decoded['items'] as List);
    }
    return [];
  }

  throw Exception(
    'Failed to load departments: ${response.statusCode}',
  );
}

// Assign Issue to Department
Future<void> assignIssue({
  required int issueId,
  required int assignedTo,
  required int assignedBy,
  required int departmentId,
  String? note,
}) async {
  final uri = Uri.parse('$baseUrl/assignments');

  final response = await http.post(
    uri,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'issue_id': issueId,
      'assigned_to': assignedTo,
      'assigned_by': assignedBy,
      'department_id': departmentId,
      'note': note,
    }),
  );

  if (response.statusCode != 201) {
    throw Exception(
      'Failed to assign issue: '
      '${response.statusCode} ${response.body}',
    );
  }
}

    // Create Energy Issue
  Future<void> createEnergyIssue({
    required String title,
    required String description,
    required String priority,
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    int reportedBy = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/energy/issues');

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'priority': priority,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'city': city,
        'reported_by': reportedBy,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create energy issue: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  // Create Water Issue
  Future<void> createWaterIssue({
    required String title,
    required String description,
    required String priority,
    required double latitude,
    required double longitude,
    String? subcategory,
    String? address,
    String? city,
    int reportedBy = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/water/issues');

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'subcategory': subcategory,
        'priority': priority,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'city': city,
        'reported_by': reportedBy,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create water issue: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  // Fetch Energy & Water Statistics
  Future<EnergyWaterStatistics> fetchStatistics(
    String category, {
    int? reportedBy,
  }) async {
    final uri = Uri.parse('$baseUrl/energy-water/statistics').replace(
      queryParameters: reportedBy != null
          ? {'reported_by': reportedBy.toString()}
          : null,
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final selectedData =
          data[category] as Map<String, dynamic>?;

      if (selectedData == null) {
        throw Exception('Statistics not found for $category');
      }

      // Convert category and status breakdowns
      Map<String, int> convertBreakdown(dynamic items) {
        final result = <String, int>{};

        if (items is List) {
          for (final item in items) {
            final row = item as Map<String, dynamic>;

            result[row['name'].toString()] =
                (row['count'] as num).toInt();
          }
        }

        return result;
      }

      // Convert monthly trends
      Map<String, int> convertMonthlyTrend(dynamic items) {
        final result = <String, int>{};

        if (items is List) {
          for (final item in items) {
            final row = item as Map<String, dynamic>;
            final month = row['month'].toString();

            result[month] =
                (row['total_reports'] as num).toInt();
          }
        }

        return result;
      }

      // Convert area-wise statistics
      Map<String, int> convertAreas(dynamic items) {
        final result = <String, int>{};

        if (items is List) {
          for (final item in items) {
            final row = item as Map<String, dynamic>;
            final area = row['area'].toString();

            result[area] =
                (row['total_reports'] as num).toInt();
          }
        }

        return result;
      }

      return EnergyWaterStatistics(
        totalReports:
            (selectedData['total_reports'] as num?)?.toInt() ?? 0,
        resolvedReports:
            (selectedData['resolved_reports'] as num?)?.toInt() ?? 0,
        byCategory:
            convertBreakdown(selectedData['category_breakdown']),
        byStatus:
            convertBreakdown(selectedData['status_breakdown']),
        monthlyTrend:
            convertMonthlyTrend(selectedData['monthly_trends']),
        areaWise:
            convertAreas(selectedData['area_wise']),
      );
    }

    throw Exception(
      'Failed to load statistics: '
      '${response.statusCode} ${response.body}',
    );
  }
}
